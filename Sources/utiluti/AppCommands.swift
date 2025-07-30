//
//  AppCommands.swift
//  utiluti
//
//  Created by Armin on 20/03/2025.
//

import Foundation
import ArgumentParser
import UniformTypeIdentifiers
import AppKit // for NSWorkspace

struct AppCommands: AsyncParsableCommand {

  static var subCommands: [ParsableCommand.Type] {
    if #available(macOS 12.0, *) {
      [Types.self, Schemes.self, BundleID.self, ForBundleID.self, Version.self]
    } else {
      [Types.self, Schemes.self, BundleID.self, Version.self]
    }
  }

  static let configuration = CommandConfiguration(
    commandName: "app",
    abstract: "list uniform types identifiers and url schemes associated with an app",
    subcommands: subCommands
   )
  
  struct Types: AsyncParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "List the uniform type identifiers this app can open")
    
    @Argument(help:ArgumentHelp("the app identifier", valueName: "app-identifier"))
    var appID: String
    
    @Flag(name: .shortAndLong,
          help: "show more information")
    var verbose: Bool = false
    
    func run() async {
      guard
        let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appID),
        let appBundle = Bundle(url: appURL),
        let infoDictionary = appBundle.infoDictionary,
        let docTypes: [[String: Any]] = infoDictionary["CFBundleDocumentTypes"] as? [[String: Any]]
      else {
        Self.exit(withError: ExitCode(7))
      }
      
      for docType in docTypes {
        guard
          let name = docType["CFBundleTypeName"] as? String
        else { continue }
        
        let types = docType["LSItemContentTypes"] as? [String] ?? []
        let extensions = docType["CFBundleTypeExtensions"] as? [String] ?? []
        
        for type in types {
          if verbose {
            print("\(type) - \(name)")
          } else {
            print(type)
          }
        }
        
        for ext in extensions {
          guard let utype = UTType(filenameExtension: ext) else {
            Self.exit(withError: ExitCode(3))
          }
          
          if types.contains(utype.identifier) {
            continue
          }
          
          print("file extension: \(ext)", terminator: "")
          
          if !utype.isDynamic {
            print(" (\(utype.identifier))", terminator: "")
          }
          
          if verbose {
            print(" - \(name)")
          } else {
            print()
          }
        }
      }
    }
  }
  
  struct Schemes: AsyncParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "List the urls schemes this app can open")
    
    @Argument(help:ArgumentHelp("the app identifier", valueName: "app-identifier"))
    var appID: String
    
    @Flag(name: .shortAndLong,
          help: "show more information")
    var verbose: Bool = false
    
    func run() async {
      guard
        let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appID),
        let appBundle = Bundle(url: appURL),
        let infoDictionary = appBundle.infoDictionary,
        let urlSchemes: [[String: Any]] = infoDictionary["CFBundleURLTypes"] as? [[String: Any]]
      else {
        Self.exit(withError: ExitCode(7))
      }
      
      for docType in urlSchemes {
        guard
          let name = docType["CFBundleURLName"] as? String,
          let schemes = docType["CFBundleURLSchemes"] as? [String]
        else { continue }
        for type in schemes {
          if verbose {
            print("\(type) - \(name)")
          } else {
            print(type)
          }
        }
      }
    }
  }

  struct BundleID: AsyncParsableCommand {
    static let configuration
    = CommandConfiguration(
      commandName: "identifier",
      abstract: "Show the bundle identifier for an app at the path",
      aliases: ["id"]
    )

    @Argument(help:ArgumentHelp("path to the app", valueName: "path"))
    var path: String

    func run() async {
      guard
        let bundle = Bundle(path: path),
        let bundleID = bundle.bundleIdentifier
      else {
        Self.exit(withError: ExitCode(11))
      }
      print(bundleID)
    }
  }

  struct Version: AsyncParsableCommand {
    static let configuration
    = CommandConfiguration(
      commandName: "version",
      abstract: "Show the version for an app at the path",
    )

    @Argument(help:ArgumentHelp("path to the app", valueName: "path"))
    var path: String

    func run() async {
      guard
        let bundle = Bundle(path: path),
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? bundle.infoDictionary?["CFBundleVersion"] as? String
      else {
        Self.exit(withError: ExitCode(12))
      }
      print(version)
    }
  }

  @available(macOS 12, *)
  struct ForBundleID: AsyncParsableCommand {
    static let configuration
    = CommandConfiguration(
      commandName: "for-identifier",
      abstract: "Show apps with the given bundle identifier",
      aliases: ["for-id"]
    )

    @Argument(help:ArgumentHelp("the app identifier", valueName: "app-identifier"))
    var appID: String

    func run() async throws {
      let apps = NSWorkspace.shared.urlsForApplications(withBundleIdentifier: appID)
      for app in apps {
        print(app.path)
      }
    }
  }
}
