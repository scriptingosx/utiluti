//
//  LSKit.swift
//  LSKit
//
//  Created by Armin Briegel on 2021-08-30.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

struct LSKit {
  
  /**
   returns a list of URLs to applications that can open URLs starting with the scheme
   - Parameter scheme: url scheme (excluding the `:` or `/`, e.g. `http`)
   - Returns: array of app URLs
   */
  static func appURLs(forScheme scheme: String) -> [URL] {
    guard let url = URL(string: "\(scheme):") else { return [URL]() }
    
    if #available(macOS 12, *) {
      //print("running on macOS 12, using NSWorkspace")
      let ws = NSWorkspace.shared
      return ws.urlsForApplications(toOpen: url)
    } else {
      var urlList = [URL]()
      if let result = LSCopyApplicationURLsForURL(url as CFURL, .all) {
        let cfURLList = result.takeRetainedValue() as Array
        for item in cfURLList {
          if let appURL = item as? URL {
            urlList.append(appURL)
          }
        }
      }
      return urlList
    }
  }
  
  /**
   returns URL to the default application for URLs starting with scheme
   - Parameter scheme: url scheme (excluding the `:` or `/`, e.g. `http`)
   - Returns: urls to default application
   */
  static func defaultAppURL(forScheme scheme: String) -> URL? {
    guard let url = URL(string: "\(scheme):") else { return nil }
    
    if #available(macOS 12, *) {
      //print("running on macOS 12, using NSWorkspace")
      let ws = NSWorkspace.shared
      return ws.urlForApplication(toOpen: url)
    } else {
      if let result = LSCopyDefaultApplicationURLForURL(url as CFURL, .all, nil) {
        let appURL = result.takeRetainedValue() as URL
        return appURL
      }
      return nil
    }
  }
  
  /**
   set the default app for scheme to the app with the identifier
   - Parameters:
   - identifier: bundle id of the new default application
   - scheme: url scheme (excluding the `:` or `/`, e.g. `http`)
   - Returns: OSStatus (discardable)
   */
  @discardableResult static func setDefaultApp(identifier: String, forScheme scheme: String) -> OSStatus {
    if #available(macOS 12, *) {
      // print("running on macOS 12, using NSWorkspace")
      let ws = NSWorkspace.shared
      
      // since the new NSWorkspace function is asynchronous we have to use semaphores here
      let semaphore = DispatchSemaphore(value: 0)
      var errCode: OSStatus = 0
      
      guard let appURL = ws.urlForApplication(withBundleIdentifier: identifier) else { return 1 }
      ws.setDefaultApplication(at: appURL, toOpenURLsWithScheme: scheme) { err in
        // err is an NSError wrapped in a CocoaError
        if let err = err as? CocoaError {
          if let underlyingError = err.errorUserInfo["NSUnderlyingError"] as? NSError {
            errCode = OSStatus(clamping: underlyingError.code)
          }
        }
        semaphore.signal()
      }
      semaphore.wait()
      return errCode
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
      print("running on macOS 12, using NSWorkspace")
      let ws = NSWorkspace.shared
      guard let utype = UTType(utidentifier) else {
        return [URL]()
      }
      return ws.urlsForApplications(toOpen: utype)
    } else {
      var urlList = [URL]()
      if let result = LSCopyAllRoleHandlersForContentType(utidentifier as CFString, .all) {
        let cfURLList = result.takeRetainedValue() as Array
        for item in cfURLList {
          if let appURL = item as? URL {
            urlList.append(appURL)
          }
        }
      }
      return urlList
    }
  }
  
  /**
   returns URL to the default application for the given type identifier
   - Parameter forTypeIdentifier: url scheme (excluding the `:` or `/`, e.g. `http`)
   - Returns: url to default application
   */
  static func defaultAppURL(forTypeIdentifier utidentifier: String) -> URL? {
    if #available(macOS 12, *) {
      //print("running on macOS 12, using NSWorkspace")
      guard let utype = UTType(utidentifier) else {
        return nil
      }
      let ws = NSWorkspace.shared
      return ws.urlForApplication(toOpen: utype)
    } else {
      if let result = LSCopyDefaultApplicationURLForContentType(utidentifier as CFString, .all, nil) {
        let appURL = result.takeRetainedValue() as URL
        return appURL
      }
      return nil
    }
  }

  /**
   set the default app for type identifier to the app with the bundle indentifier
   - Parameters:
   - identifier: bundle id of the new default application
   - forTypeIdentifier: uniform type identifier ( e.g. `public.html`)
   - Returns: OSStatus (discardable)
   */
  @discardableResult static func setDefaultApp(identifier: String, forTypeIdentifier utidentifier: String) -> OSStatus {
    if #available(macOS 12, *) {
      // print("running on macOS 12, using NSWorkspace")
      guard let utype = UTType(utidentifier) else {
        return 1
      }

      let ws = NSWorkspace.shared
      
      // since the new NSWorkspace function is asynchronous we have to use semaphores here
      let semaphore = DispatchSemaphore(value: 0)
      var errCode: OSStatus = 0
      
      guard let appURL = ws.urlForApplication(withBundleIdentifier: identifier) else { return 1 }
      ws.setDefaultApplication(at: appURL, toOpen: utype) { err in
        // err is an NSError wrapped in a CocoaError
        if let err = err as? CocoaError {
          if let underlyingError = err.errorUserInfo["NSUnderlyingError"] as? NSError {
            errCode = OSStatus(clamping: underlyingError.code)
          }
        }
        semaphore.signal()
      }
      semaphore.wait()
      return errCode
    } else {
      return LSSetDefaultRoleHandlerForContentType(utidentifier as CFString, .all, identifier as CFString)
    }
  }
}
