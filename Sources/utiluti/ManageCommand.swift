//
//  File.swift
//  utiluti
//
//  Created by Armin Briegel on 2025-07-04.
//

import Foundation
import ArgumentParser

struct ManageCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "manage",
    abstract: "read and apply settings from a managed preferences or a file"
  )

  @Option(help: "path to a local plist file containing type associations")
  var typeFile: String?

  @Option(help: "path to a local plist file containing url scheme associations")
  var urlFile: String?

  @Flag(help: "increase output")
  var verbose = false

  @Flag(help: "includes unmanaged (local) keys")
  var includeUnmanaged = false

  func dictionary(forFile path: String?, orDomain domain: String) throws -> [String:Any] {
    if let path {
      guard let dictFromFile = NSDictionary(contentsOfFile: path) as? [String:Any] else {
        throw ExitCode(4)
      }
      return dictFromFile
    } else {
      guard let prefs = Preferences(suiteName: domain) else { throw ExitCode(3)}

      let keys = includeUnmanaged ? prefs.nonGlobalKeys : prefs.managedKeys
      return prefs.dictionaryRepresentation(forKeys: keys)
    }
  }

  func manageTypes() throws {
    let types = try dictionary(
      forFile: typeFile,
      orDomain: "com.scriptingosx.utiluti.type"
    )

    for (uti, value) in types {
      guard let bundleID = value as? String
      else {
        if verbose { print("skipping non-string value '\(value)' for \(uti)")}
        continue
      }

      let result = LSKit.setDefaultApp(identifier: bundleID, forTypeIdentifier: uti)
      if result == 0 {
        print("set \(bundleID) for \(uti)")
      } else {
        print("ERROR: cannot set \(bundleID) for \(uti) (error \(result))")
      }
    }
  }

  func manageURLs() throws {
    let urls = try dictionary(
      forFile: urlFile,
      orDomain: "com.scriptingosx.utiluti.url"
    )

    for (urlScheme, value) in urls {
      guard let bundleID = value as? String
      else {
        if verbose { print("skipping non-string value '\(value)' for \(urlScheme)")}
        continue
      }

      let result = LSKit.setDefaultApp(identifier: bundleID, forScheme: urlScheme)

      if result == 0 {
        print("set \(bundleID) for \(urlScheme)")
      } else {
        print("ERROR: cannot set \(bundleID) for \(urlScheme) (error \(result))")
      }
    }
  }

  func run() throws {
    try manageTypes()
    try manageURLs()
  }
}

