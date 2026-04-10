//
//  ApplicationResolver.swift
//  utiluti
//

import Foundation
import CoreServices

enum ApplicationResolver {
  private struct Cache {
    var appURLs = [String: URL]()
    var missingAppURLs = Set<String>()
    var bundleIdentifiers = [String: String]()
    var missingBundleIdentifiers = Set<String>()
  }

  private static let cache = LockedValue(Cache())

  /**
   The application directories Foundation reports for all domains on this Mac.
   */
  private static let searchRoots: [URL] = {
    let urls = FileManager.default.urls(for: .allApplicationsDirectory, in: .allDomainsMask)
    var seenPaths = Set<String>()

    return urls.compactMap { url in
      let standardizedURL = url.standardizedFileURL
      guard seenPaths.insert(standardizedURL.path).inserted else { return nil }
      guard FileManager.default.fileExists(atPath: standardizedURL.path) else { return nil }
      return standardizedURL
    }
  }()

  /**
   Resolve a bundle identifier to an application bundle URL.
   */
  static func appURL(forBundleIdentifier identifier: String) -> URL? {
    let cacheKey = identifier.lowercased()
    let cachedResult = cache.withLock { cache -> (Bool, URL?) in
      if let appURL = cache.appURLs[cacheKey] {
        return (true, appURL)
      }
      if cache.missingAppURLs.contains(cacheKey) {
        return (true, nil)
      }
      return (false, nil)
    }
    if cachedResult.0 {
      return cachedResult.1
    }

    if let result = LSCopyApplicationURLsForBundleIdentifier(identifier as CFString, nil) {
      let appURLs = result.takeRetainedValue() as Array
      if let appURL = appURLs.first as? URL {
        let standardizedURL = appURL.standardizedFileURL
        cache.withLock { cache in
          cache.appURLs[cacheKey] = standardizedURL
          cache.missingAppURLs.remove(cacheKey)
        }
        return standardizedURL
      }
    }

    let appURL = appURLFromFilesystem(forBundleIdentifier: identifier)
    cache.withLock { cache in
      if let appURL {
        cache.appURLs[cacheKey] = appURL
        cache.missingAppURLs.remove(cacheKey)
      } else {
        cache.missingAppURLs.insert(cacheKey)
      }
    }

    return appURL
  }

  /**
   Read the bundle identifier from an application bundle URL when command
   output needs an identifier rather than a filesystem path.
   */
  static func bundleIdentifier(for appURL: URL) -> String? {
    let standardizedURL = appURL.standardizedFileURL
    let cacheKey = standardizedURL.path

    let cachedResult = cache.withLock { cache -> (Bool, String?) in
      if let bundleIdentifier = cache.bundleIdentifiers[cacheKey] {
        return (true, bundleIdentifier)
      }
      if cache.missingBundleIdentifiers.contains(cacheKey) {
        return (true, nil)
      }
      return (false, nil)
    }
    if cachedResult.0 {
      return cachedResult.1
    }

    let bundleIdentifier = Bundle(url: standardizedURL)?.bundleIdentifier
    cache.withLock { cache in
      if let bundleIdentifier {
        cache.bundleIdentifiers[cacheKey] = bundleIdentifier
        cache.missingBundleIdentifiers.remove(cacheKey)
      } else {
        cache.missingBundleIdentifiers.insert(cacheKey)
      }
    }

    return bundleIdentifier
  }

  /**
   Scan the known application directories for a matching bundle identifier.
   */
  private static func appURLFromFilesystem(forBundleIdentifier identifier: String) -> URL? {
    for root in searchRoots {
      if let appURL = findApplication(in: root, bundleIdentifier: identifier) {
        return appURL.standardizedFileURL
      }
    }

    return nil
  }

  /**
   Walk one application root and inspect application bundles found there.
   */
  private static func findApplication(in root: URL, bundleIdentifier targetBundleIdentifier: String) -> URL? {
    guard let enumerator = FileManager.default.enumerator(
      at: root,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles, .skipsPackageDescendants]
    ) else { return nil }

    for case let url as URL in enumerator {
      guard url.pathExtension == "app" else { continue }

      if let discoveredBundleIdentifier = bundleIdentifier(for: url),
         discoveredBundleIdentifier.caseInsensitiveCompare(targetBundleIdentifier) == .orderedSame {
        return url.standardizedFileURL
      }
    }

    return nil
  }
}
