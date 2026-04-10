//
//  LaunchServicesSupport.swift
//  utiluti
//

import Foundation

enum LaunchServicesSupport {
  /**
   Some Launch Services APIs return URLs directly, while others return bundle
   identifiers that still need to be resolved back to app bundles.
   */
  static func appURLs(from result: Unmanaged<CFArray>?) -> [URL] {
    guard let result else { return [] }

    let items = result.takeRetainedValue() as Array
    var appURLs = [URL]()

    for item in items {
      if let appURL = item as? URL {
        appURLs.append(appURL)
      } else if let bundleIdentifier = item as? String,
                let appURL = ApplicationResolver.appURL(forBundleIdentifier: bundleIdentifier) {
        appURLs.append(appURL)
      }
    }

    return uniqueAppURLs(appURLs)
  }

  static func standardizedAppURL(_ appURL: URL?) -> URL? {
    appURL?.standardizedFileURL
  }

  static func uniqueAppURLs(_ appURLs: [URL]) -> [URL] {
    var seenPaths = Set<String>()

    return appURLs.compactMap { appURL in
      let standardizedURL = appURL.standardizedFileURL
      guard seenPaths.insert(standardizedURL.path).inserted else { return nil }
      return standardizedURL
    }
  }

  /**
   AppKit wraps Launch Services failures in `CocoaError`. Pull the underlying
   Launch Services status code back out so the CLI keeps reporting `OSStatus`.
   */
  static func osStatus(from error: Error) -> OSStatus {
    if let error = error as? CocoaError,
       let underlyingError = error.errorUserInfo["NSUnderlyingError"] as? NSError {
      return OSStatus(clamping: underlyingError.code)
    }

    return 1
  }
}
