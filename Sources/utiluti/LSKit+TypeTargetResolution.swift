//
//  LSKit+TypeTargetResolution.swift
//  utiluti
//

import Foundation
import AppKit
import CoreServices
import UniformTypeIdentifiers

extension LSKit {
  private struct HandlerResolution {
    let bundleIdentifier: String?
    let appURL: URL?
  }

  static func appURLs(for target: TypeTarget) -> [URL] {
    for candidate in candidates(for: target) {
      let candidateAppURLs = appURLs(for: candidate)
      if !candidateAppURLs.isEmpty {
        return candidateAppURLs
      }
    }

    return []
  }

  static func defaultAppDetails(for target: TypeTarget) -> (bundleIdentifier: String?, appURL: URL?) {
    let resolution = handlerResolution(for: target)
    return (resolution?.bundleIdentifier, resolution?.appURL)
  }

  private static func handlerResolution(for target: TypeTarget) -> HandlerResolution? {
    for candidate in candidates(for: target) {
      if let resolution = handlerResolution(for: candidate) {
        return resolution
      }
    }

    return nil
  }

  static func defaultAppURL(for target: TypeTarget) -> URL? {
    defaultAppDetails(for: target).appURL
  }

  static func defaultBundleIdentifier(for target: TypeTarget) -> String? {
    defaultAppDetails(for: target).bundleIdentifier
  }

  @discardableResult
  static func setDefaultApp(identifier: String, for target: TypeTarget) async -> OSStatus {
    let candidates = candidates(for: target)

    for (index, candidate) in candidates.enumerated() {
      let result = await setDefaultApp(identifier: identifier, for: candidate)
      if result == 0 || index == candidates.index(before: candidates.endIndex) {
        return result
      }
    }

    return 1
  }

  /**
   When reading Launch Services defaults, prefer the most general role first,
   then progressively more specific roles so we can still recover a usable app
   when only an editor/viewer-specific override exists.
   */
  private static let preferredRoles: [LSRolesMask] = [.all, .editor, .viewer, .shell]

  private enum Candidate {
    case typeIdentifier(String)
    case fileExtension(String)
  }

  /**
   Build the lookup order for a type target.
   */
  private static func candidates(for target: TypeTarget) -> [Candidate] {
    switch target {
    case .uti(let utidentifier):
      return [.typeIdentifier(utidentifier)]
    case .fileExtension(let fileExtension):
      if let utidentifier = target.preferredTypeIdentifier {
        return [.typeIdentifier(utidentifier), .fileExtension(fileExtension)]
      } else {
        return [.fileExtension(fileExtension)]
      }
    }
  }

  private static func appURLs(for candidate: Candidate) -> [URL] {
    switch candidate {
    case .typeIdentifier(let utidentifier):
      return appURLs(forTypeIdentifier: utidentifier)
    case .fileExtension(let fileExtension):
      return appURLsFromFileExtension(fileExtension)
    }
  }

  private static func handlerResolution(for candidate: Candidate) -> HandlerResolution? {
    switch candidate {
    case .typeIdentifier(let utidentifier):
      return handlerResolution(forTypeIdentifier: utidentifier)
    case .fileExtension(let fileExtension):
      return handlerResolution(forExtension: fileExtension)
    }
  }

  private static func setDefaultApp(identifier: String, for candidate: Candidate) async -> OSStatus {
    switch candidate {
    case .typeIdentifier(let utidentifier):
      return await setDefaultApp(identifier: identifier, forTypeIdentifier: utidentifier)
    case .fileExtension(let fileExtension):
      return LaunchServicesPreferences().setDefaultEditor(
        bundleIdentifier: identifier,
        forExtension: fileExtension
      ) ? 0 : 1
    }
  }

  private static func handlerResolution(forTypeIdentifier utidentifier: String) -> HandlerResolution? {
    let bundleIdentifier = preferredBundleIdentifierOverride(forTypeIdentifier: utidentifier)
    let appURL = bundleIdentifier.flatMap { ApplicationResolver.appURL(forBundleIdentifier: $0) }
      ?? defaultAppURLFromLaunchServices(forTypeIdentifier: utidentifier)
    let resolvedBundleIdentifier = bundleIdentifier ?? appURL.flatMap { ApplicationResolver.bundleIdentifier(for: $0) }

    if resolvedBundleIdentifier == nil && appURL == nil {
      return nil
    }

    return HandlerResolution(bundleIdentifier: resolvedBundleIdentifier, appURL: appURL)
  }

  private static func handlerResolution(forExtension fileExtension: String) -> HandlerResolution? {
    let bundleIdentifier = LaunchServicesPreferences().preferredBundleIdentifier(forExtension: fileExtension)
    let appURL = bundleIdentifier.flatMap { ApplicationResolver.appURL(forBundleIdentifier: $0) }
      ?? defaultAppURLFromFileExtension(fileExtension)
    let resolvedBundleIdentifier = bundleIdentifier ?? appURL.flatMap { ApplicationResolver.bundleIdentifier(for: $0) }

    if resolvedBundleIdentifier == nil && appURL == nil {
      return nil
    }

    return HandlerResolution(bundleIdentifier: resolvedBundleIdentifier, appURL: appURL)
  }

  private static func preferredBundleIdentifierOverride(forTypeIdentifier utidentifier: String) -> String? {
    if let bundleIdentifier = LaunchServicesPreferences().preferredBundleIdentifier(forTypeIdentifier: utidentifier) {
      return bundleIdentifier
    }

    for role in preferredRoles {
      if let bundleIdentifier = LSCopyDefaultRoleHandlerForContentType(utidentifier as CFString, role)?
        .takeRetainedValue() as String? {
        return bundleIdentifier
      }
    }

    return nil
  }

  private static func appURLsFromFileExtension(_ fileExtension: String) -> [URL] {
    FileTypeProbe.withTemporaryFileURL(forExtension: fileExtension) { fileURL in
      if #available(macOS 12, *) {
        return LaunchServicesSupport.uniqueAppURLs(NSWorkspace.shared.urlsForApplications(toOpen: fileURL))
      } else {
        return LaunchServicesSupport.appURLs(from: LSCopyApplicationURLsForURL(fileURL as CFURL, .all))
      }
    }
  }

  private static func defaultAppURLFromLaunchServices(forTypeIdentifier utidentifier: String) -> URL? {
    if #available(macOS 12, *) {
      guard let utype = UTType(utidentifier) else { return nil }
      return LaunchServicesSupport.standardizedAppURL(NSWorkspace.shared.urlForApplication(toOpen: utype))
    } else {
      return LaunchServicesSupport.standardizedAppURL(
        LSCopyDefaultApplicationURLForContentType(utidentifier as CFString, .all, nil)?
          .takeRetainedValue() as URL?
      )
    }
  }

  private static func defaultAppURLFromFileExtension(_ fileExtension: String) -> URL? {
    FileTypeProbe.withTemporaryFileURL(forExtension: fileExtension) { fileURL in
      if #available(macOS 12, *) {
        return LaunchServicesSupport.standardizedAppURL(NSWorkspace.shared.urlForApplication(toOpen: fileURL))
      } else {
        return LaunchServicesSupport.standardizedAppURL(
          LSCopyDefaultApplicationURLForURL(fileURL as CFURL, .all, nil)?.takeRetainedValue() as URL?
        )
      }
    }
  }
}
