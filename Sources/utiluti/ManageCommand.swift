//
//  File.swift
//  utiluti
//
//  Created by Armin Briegel on 2025-07-04.
//

import Foundation
import ArgumentParser

struct ManageCommand: AsyncParsableCommand {
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

  func dictionary(forFile path: String) throws -> [String:Any] {
    if !FileManager.default.fileExists(atPath: path) {
      print("no file at \(path)")
      throw ExitCode(7)
    }

    guard let dictFromFile = NSDictionary(contentsOfFile: path) as? [String:Any] else {
      throw ExitCode(4)
    }
    return dictFromFile
  }

  func dictionary(fromDefaults domain: String) throws -> [String:Any] {
    guard let prefs = Preferences(suiteName: domain)
    else { throw ExitCode(3)}

    var keys = Set(prefs.managedKeys)
    if includeUnmanaged { keys.formUnion(prefs.nonGlobalKeys) }
    return prefs.dictionaryRepresentation(forKeys: Array(keys))
  }

  func manageTypes(types: [String:Any]) async throws {
    for (uti, value) in types {
      guard let bundleID = value as? String
      else {
        if verbose { print("skipping non-string value '\(value)' for \(uti)")}
        continue
      }

      let result = await LSKit.setDefaultApp(identifier: bundleID, forTypeIdentifier: uti)
      if result == 0 {
        print("set \(bundleID) for \(uti)")
      } else {
        print("ERROR: cannot set \(bundleID) for \(uti) (error \(result))")
      }
    }
  }

  func manageURLs(urls: [String:Any]) async throws {
    for (urlScheme, value) in urls {
      guard let bundleID = value as? String
      else {
        if verbose { print("skipping non-string value '\(value)' for \(urlScheme)")}
        continue
      }

      let result = await LSKit.setDefaultApp(identifier: bundleID, forScheme: urlScheme)

      if result == 0 {
        print("set \(bundleID) for \(urlScheme)")
      } else {
        print("ERROR: cannot set \(bundleID) for \(urlScheme) (error \(result))")
      }
    }
  }

  func run() async throws {
    if typeFile == nil && urlFile == nil {
      // neither file path is set, read from defaults
      let types = try dictionary(fromDefaults: "com.scriptingosx.utiluti.type")
      try await manageTypes(types: types)

      let urls = try dictionary(fromDefaults: "com.scriptingosx.utiluti.url")
      try await manageURLs(urls: urls)
    } else {
      // one or both of the file paths are set
      if let typeFile {
        let types = try dictionary(forFile: typeFile)
        try await manageTypes(types: types)
      }

      if let urlFile {
        let urls = try dictionary(forFile: urlFile)
        try await manageURLs(urls: urls)
      }
    }
  }
}

