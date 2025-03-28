//
//  TypeCommands.swift
//  utiluti
//
//  Created by Armin Briegel on 2022-11-10.
//

import Foundation
import ArgumentParser
import UniformTypeIdentifiers

struct TypeCommands: ParsableCommand {
  
  static var subCommands: [ParsableCommand.Type] {
    if #available(macOS 11.0, *) {
      return [Get.self, List.self, Set.self, Info.self, FileExtensions.self]
    } else {
      return[Get.self, List.self, Set.self]
    }
  }
  
  static let configuration = CommandConfiguration(
    commandName: "type",
    abstract: "Manipulate default file type handlers",
    subcommands: subCommands,
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
  
  struct Get: ParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "Get the path to the default application.")
    
    @OptionGroup var utidentifier: UTIdentifier
    @OptionGroup var bundleID: IdentifierFlag
    
    func run() {
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
  
  struct List: ParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "List all applications that can handle this type identifier.")
    
    @OptionGroup var utidentifier: UTIdentifier
    @OptionGroup var bundleID: IdentifierFlag

    func run() {
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
  
  struct Set: ParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "Set the default app for this type identifier.")
    
    @OptionGroup var utidentifier: UTIdentifier
    @Argument var identifier: String
    
    func run() {
      let result = LSKit.setDefaultApp(identifier: identifier, forTypeIdentifier: utidentifier.value)
      
      if result == 0 {
        print("set \(identifier) for \(utidentifier.value)")
      } else {
        print("cannot set default app for \(utidentifier.value) (error \(result))")
        TypeCommands.exit(withError: ExitCode(result))
      }
    }
  }
  
  @available(macOS 11.0, *)
  struct FileExtensions: ParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "prints the file extensions for the given type identifier")
    
    @OptionGroup var utidentifier: UTIdentifier
    
    func run() {
      guard let utype = UTType(utidentifier.value) else {
        print("<none>")
        TypeCommands.exit(withError: ExitCode(3))
      }
      
      let extensions = utype.tags[.filenameExtension] ?? []
      print(extensions.joined(separator: " "))
    }
  }

  @available(macOS 11.0, *)
  struct Info: ParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "prints information for the given type identifier")

    @OptionGroup var utidentifier: UTIdentifier
    
    func run() {
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
