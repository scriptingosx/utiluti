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
  static let configuration = CommandConfiguration(
    commandName: "app",
    abstract: "list uniform types identifiers and url schemes associated with an app",
    subcommands: [
      Types.self,
      Schemes.self
    ]
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
}
