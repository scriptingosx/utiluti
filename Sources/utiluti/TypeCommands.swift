//
//  TypeCommands.swift
//  utiluti
//
//  Created by Armin Briegel on 2022-11-10.
//

import Foundation
import ArgumentParser
import UniformTypeIdentifiers

struct TypeCommands: AsyncParsableCommand {

  static let configuration = CommandConfiguration(
    commandName: "type",
    abstract: "Manipulate default file type handlers",
    subcommands: [
      Get.self,
      List.self,
      Set.self,
      Info.self,
      FileExtensions.self
    ],
    defaultSubcommand: Get.self
  )
  
  struct UTIdentifier: ParsableArguments {
    @Argument(help: ArgumentHelp(
      "universal type identifier, e.g. 'public.html'",
      valueName: "uti"))
    var value: String
  }
  
  struct IdentifierFlag: ParsableArguments {
    @Flag(help: ArgumentHelp(
      "list bundle identifiers instead of paths",
      valueName: "bundleID"))
    var bundleID = false
  }
  
  struct Get: AsyncParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "Get the path to the default application.")
    
    @OptionGroup var utidentifier: UTIdentifier
    @OptionGroup var bundleID: IdentifierFlag
    
    func run() async {
      guard let appURL = LSKit.defaultAppURL(forTypeIdentifier: utidentifier.value) else {
        print("<no default app found>")
        return
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
  
  struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "list",
      abstract: "List all applications that can handle this type identifier.",
      aliases: ["ls"]
    )

    @OptionGroup var utidentifier: UTIdentifier
    @OptionGroup var bundleID: IdentifierFlag

    func run() async {
      let appURLs = LSKit.appURLs(forTypeIdentifier: utidentifier.value)
      
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
  
  struct Set: AsyncParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "Set the default app for this type identifier.")
    
    @OptionGroup var utidentifier: UTIdentifier
    @Argument var identifier: String
    
    func run() async {
      let result = await LSKit.setDefaultApp(identifier: identifier, forTypeIdentifier: utidentifier.value)
      
      if result == 0 {
        print("set \(identifier) for \(utidentifier.value)")
      } else {
        print("cannot set default app for \(utidentifier.value) (error \(result))")
        TypeCommands.exit(withError: ExitCode(result))
      }
    }
  }
  
  struct FileExtensions: AsyncParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "prints the file extensions for the given type identifier")
    
    @OptionGroup var utidentifier: UTIdentifier
    
    func run() async {
      guard let utype = UTType(utidentifier.value) else {
        print("<none>")
        TypeCommands.exit(withError: ExitCode(3))
      }
      
      let extensions = utype.tags[.filenameExtension] ?? []
      print(extensions.joined(separator: " "))
    }
  }

  struct Info: AsyncParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "prints information for the given type identifier")

    @OptionGroup var utidentifier: UTIdentifier
    
    func run() async {
      guard let utype = UTType(utidentifier.value) else {
        print("<none>")
        TypeCommands.exit(withError: ExitCode(3))
      }
      
      for (key, value) in utype.tags {
        print("\(key): \(value)")
      }
    }
  }
}
