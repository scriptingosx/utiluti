//
//  FileCommands.swift
//  utiluti
//
//  Created by Armin on 25/03/2025.
//

import Foundation

import Foundation
import ArgumentParser
import UniformTypeIdentifiers
import AppKit // for NSWorkspace

struct FileCommands: AsyncParsableCommand {
  
  static var subCommands: [ParsableCommand.Type] {
    if #available(macOS 12.0, *) {
      return [ GetUTI.self, App.self, ListApps.self, Set.self ]
    } else {
      return [ GetUTI.self, App.self ]
    }
  }

  static let configuration = CommandConfiguration(
    commandName: "file",
    abstract: "commands to manage specific files",
    subcommands: subCommands
  )
  
  struct GetUTI: AsyncParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "get the uniform type identifier of a file")
    
    @Argument(help:ArgumentHelp("file path", valueName: "path"))
    var path: String
    
    func run() async {
      let url = URL(fileURLWithPath: path)
      let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier
      print(typeIdentifier ?? "<unknown>")
    }
  }
  
  struct App: AsyncParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "get the app that will open this file")
    
    @Argument(help:ArgumentHelp("file path", valueName: "path"))
    var path: String
    
    @Flag(help: ArgumentHelp(
      "list bundle identifiers instead of paths",
      valueName: "bundleID"))
    var bundleID = false
    
    func run() async {
      let url = URL(fileURLWithPath: path)
      if let app = NSWorkspace.shared.urlForApplication(toOpen: url) {
        if bundleID {
          guard let appBundle = Bundle(url: app) else {
            Self.exit(withError: ExitCode(6))
          }
          print(appBundle.bundleIdentifier ?? "<no identifier>")
        } else {
          print(app.path)
        }
      } else {
        print("no app found")
        Self.exit(withError: ExitCode(9))
      }
    }
  }
  
  @available(macOS 12, *)
  struct ListApps: AsyncParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "get all app that can open this file")
    
    @Argument(help:ArgumentHelp("file path", valueName: "path"))
    var path: String
    
    @Flag(help: ArgumentHelp(
      "list bundle identifiers instead of paths",
      valueName: "bundleID"))
    var bundleID = false
    
    func run() async {
      let url = URL(fileURLWithPath: path)
      let apps = NSWorkspace.shared.urlsForApplications(toOpen: url)
      for app in apps {
        if bundleID {
          guard let appBundle = Bundle(url: app) else {
            Self.exit(withError: ExitCode(6))
          }
          print(appBundle.bundleIdentifier ?? "<no identifier>")
        } else {
          print(app.path)
        }
      }
    }
  }
  
  @available(macOS 12, *)
  struct Set: AsyncParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "Set the default app for this specific file")
    
    @Argument(help:ArgumentHelp("file path", valueName: "path"))
    var path: String
    
    @Argument(help: "the bundle identifier for the new default app")
    var identifier: String

    func run() async throws {
      let url = URL(fileURLWithPath: path)
      guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier)
      else {
        Self.exit(withError: ExitCode(11))
      }
      try await NSWorkspace.shared.setDefaultApplication(at: appURL, toOpenFileAt: url)
      print("set \(identifier) for \(path)")
    }
  }
}
    
