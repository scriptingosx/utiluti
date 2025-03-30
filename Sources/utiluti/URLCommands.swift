//
//  URLScheme.swift
//  utiluti
//
//  Created by Armin Briegel on 2022-11-10.
//

import Foundation
import ArgumentParser

struct URLCommands: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "url",
    abstract: "Manipulate default URL scheme handlers",
    subcommands: [
      Get.self,
      List.self,
      Set.self
    ],
    defaultSubcommand: Get.self
  )
  
  struct URLScheme: ParsableArguments {
    @Argument(
      help: ArgumentHelp(
        "the url scheme, e.g. 'http' or 'mailto'",
        valueName: "scheme"
      )
    )
    var value: String
  }
  
  struct IdentifierFlag: ParsableArguments {
    @Flag(help: ArgumentHelp(
      "list bundle identifiers instead of paths",
      valueName: "bundleID"))
    var bundleID = false
  }
  
  struct Get: ParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "Get the path to the default application.")
    
    @OptionGroup var scheme: URLScheme
    @OptionGroup var bundleID: IdentifierFlag
    
    func run() {
      guard let appURL = LSKit.defaultAppURL(forScheme: scheme.value) else {
        print("<no default app found>")
        Self.exit(withError: ExitCode(1))
      }
      if bundleID.bundleID {
        guard let appBundle = Bundle(url: appURL) else {
          Self.exit(withError: ExitCode(6))
        }
        print(appBundle.bundleIdentifier ?? "<no identifier>")
      } else {
        print(appURL.path)
      }
    }
  }
  
  struct List: ParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "List all applications that can handle this URL scheme.")
    
    @OptionGroup var scheme: URLScheme
    @OptionGroup var bundleID: IdentifierFlag

    func run() {
      let appURLs = LSKit.appURLs(forScheme: scheme.value)
      
      for appURL in appURLs {
        if bundleID.bundleID {
          if let appBundle = Bundle(url: appURL) {
            print(appBundle.bundleIdentifier ?? "<no identifier>")
          } else {
            print("<'\(appURL.path)' is not a bundle>")
          }
         } else {
          print(appURL.path)
        }
      }
    }
  }
  
  struct Set: ParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "Set the default app for this URL scheme.")
    
    @OptionGroup var scheme: URLScheme
    @Argument(help: ArgumentHelp("bundle identifier for the app",
                                valueName: "bundleID"))
    var identifier: String
    
    func run() {
      let result = LSKit.setDefaultApp(identifier: identifier, forScheme: scheme.value)
      
      if result == 0 {
        print("set \(identifier) for \(scheme.value)")
      } else {
        print("cannot set default app for \(scheme.value) (error \(result))")
      }
    }
  }
}
