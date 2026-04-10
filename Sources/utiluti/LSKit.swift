//
//  LSKit.swift
//  LSKit
//
//  Created by Armin Briegel on 2021-08-30.
//

import Foundation
import AppKit
import CoreServices
import UniformTypeIdentifiers

struct LSKit {
  /**
   returns a list of URLs to applications that can open URLs starting with the scheme
   - Parameter scheme: url scheme (excluding the `:` or `/`, e.g. `http`)
   - Returns: array of app URLs
   */
  static func appURLs(forScheme scheme: String) -> [URL] {
    guard let schemeURL = URL(string: "\(scheme):") else { return [] }

    if #available(macOS 12, *) {
      let ws = NSWorkspace.shared
      return LaunchServicesSupport.uniqueAppURLs(ws.urlsForApplications(toOpen: schemeURL))
    } else {
      return LaunchServicesSupport.appURLs(from: LSCopyApplicationURLsForURL(schemeURL as CFURL, .all))
    }
  }

  /**
   returns URL to the default application for URLs starting with scheme
   - Parameter scheme: url scheme (excluding the `:` or `/`, e.g. `http`)
   - Returns: urls to default application
   */
  static func defaultAppURL(forScheme scheme: String) -> URL? {
    guard let schemeURL = URL(string: "\(scheme):") else { return nil }

    if #available(macOS 12, *) {
      let ws = NSWorkspace.shared
      return LaunchServicesSupport.standardizedAppURL(ws.urlForApplication(toOpen: schemeURL))
    } else {
      return LaunchServicesSupport.standardizedAppURL(
        LSCopyDefaultApplicationURLForURL(schemeURL as CFURL, .all, nil)?.takeRetainedValue() as URL?
      )
    }
  }

  /**
   set the default app for scheme to the app with the identifier
   - Parameters:
   - identifier: bundle id of the new default application
   - scheme: url scheme (excluding the `:` or `/`, e.g. `http`)
   - Returns: OSStatus (discardable)
   */
  @discardableResult
  static func setDefaultApp(identifier: String, forScheme scheme: String) async -> OSStatus {
    if #available(macOS 12, *) {
      do {
        let ws = NSWorkspace.shared
        guard let appURL = ApplicationResolver.appURL(forBundleIdentifier: identifier) else { return 1 }
        try await ws.setDefaultApplication(at: appURL, toOpenURLsWithScheme: scheme)
        return 0
      } catch {
        return LaunchServicesSupport.osStatus(from: error)
      }
    } else {
      return LSSetDefaultHandlerForURLScheme(scheme as CFString, identifier as CFString)
    }
  }

  /**
   returns a list of URLs to applications that can open the given type identifier
   - Parameter forTypeIdentifier: Uniform Type Identifier, e.g. `public.html`
   - Returns: array of URLs to apps
   */
  static func appURLs(forTypeIdentifier utidentifier: String) -> [URL] {
    if #available(macOS 12, *) {
      let ws = NSWorkspace.shared
      guard let utype = UTType(utidentifier) else { return [] }
      return LaunchServicesSupport.uniqueAppURLs(ws.urlsForApplications(toOpen: utype))
    } else {
      return LaunchServicesSupport.appURLs(from: LSCopyAllRoleHandlersForContentType(utidentifier as CFString, .all))
    }
  }

  /**
   returns URL to the default application for the given type identifier
   - Parameter forTypeIdentifier: Uniform Type Identifier, e.g. `public.html`
   - Returns: url to default application
   */
  static func defaultAppURL(forTypeIdentifier utidentifier: String) -> URL? {
    defaultAppDetails(for: .uti(utidentifier)).appURL
  }

  static func defaultBundleIdentifier(forTypeIdentifier utidentifier: String) -> String? {
    defaultAppDetails(for: .uti(utidentifier)).bundleIdentifier
  }

  /**
   set the default app for type identifier to the app with the bundle identifier
   - Parameters:
   - identifier: bundle id of the new default application
   - forTypeIdentifier: uniform type identifier ( e.g. `public.html`)
   - Returns: OSStatus (discardable)
   */
  @discardableResult
  static func setDefaultApp(identifier: String, forTypeIdentifier utidentifier: String) async -> OSStatus {
    if #available(macOS 12, *) {
      guard let utype = UTType(utidentifier),
            let appURL = ApplicationResolver.appURL(forBundleIdentifier: identifier)
      else { return 1 }

      do {
        let ws = NSWorkspace.shared
        try await ws.setDefaultApplication(at: appURL, toOpen: utype)
        return 0
      } catch {
        return LaunchServicesSupport.osStatus(from: error)
      }
    } else {
      return LSSetDefaultRoleHandlerForContentType(utidentifier as CFString, .all, identifier as CFString)
    }
  }
}
