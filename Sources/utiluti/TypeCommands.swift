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
    defaultSubcommand: Get.self,
    aliases: ["uti"]
  )
  
  struct TypeIdentifier: ParsableArguments {
    @Argument(help: ArgumentHelp(
      "universal type identifier, e.g. 'public.html'",
      discussion: "when --extension is present, this argument provides a file extension, e.g. 'txt'",
      valueName: "identifier"))
    var value: String
    
    @Flag(
      name: [.customLong("extension"), .customLong("ext"), .customShort("e")],
      help: "provide a file extension instead of a UTI",
    )
    var fileExtension = false

    var target: TypeTarget {
      TypeTarget(value: value, isFileExtension: fileExtension)
    }
  }
  
  struct IdentifierFlag: ParsableArguments {
    @Flag(
      name: [.customShort("b"), .customLong("bundle-id")],
      help: ArgumentHelp(
      "list bundle identifiers instead of paths",
      valueName: "bundleID"
      )
    )
    var bundleID = false
  }
  
  struct Get: AsyncParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "Get the path to the default application.")
    
    @OptionGroup var utidentifier: TypeIdentifier
    @OptionGroup var bundleID: IdentifierFlag
    
    func run() async {
      let target = utidentifier.target
      let details = LSKit.defaultAppDetails(for: target)

      if bundleID.bundleID {
        print(details.bundleIdentifier ?? "<no default app found>")
      } else {
        let appURL = details.appURL
        guard let appURL else {
          print("<no default app found>")
          return
        }

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

    @OptionGroup var utidentifier: TypeIdentifier
    @OptionGroup var bundleID: IdentifierFlag

    func run() async {
      let appURLs = LSKit.appURLs(for: utidentifier.target)
      
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
    
    @OptionGroup var utidentifier: TypeIdentifier
    @Argument var identifier: String
    
    func run() async {
      let result = await LSKit.setDefaultApp(identifier: identifier, for: utidentifier.target)
      
      if result == 0 {
        print("set \(identifier) for \(utidentifier.target.displayValue)")
      } else {
        print("cannot set default app for \(utidentifier.target.displayValue) (error \(result))")
        TypeCommands.exit(withError: ExitCode(result))
      }
    }
  }
  
  struct FileExtensions: AsyncParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "prints the file extensions for the given type identifier")
    
    @OptionGroup var utidentifier: TypeIdentifier
    
    func run() async {
      let utype = utidentifier.target.resolvedType
      guard let utype else {
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

    @OptionGroup var utidentifier: TypeIdentifier

    func printTypeInfo(for utype: UTType, includeIdentifier: Bool = true) {
      if includeIdentifier {
        print("uniform type identifier: \(utype.identifier)")
      }

      if let description = utype.localizedDescription {
        print("description: \(description)")
      }

      for (key, value) in utype.tags {
        print("\(key): \(value)")
      }

      if !utype.supertypes.isEmpty {
        print("super types: \(utype.supertypes.map(\.identifier))")
      }
    }

    func printDefaultApp(bundleIdentifier: String?, appURL: URL?) {
      guard let bundleIdentifier else {
        if let appURL {
          print("default app: \(appURL.path)")
        }
        return
      }

      if let appURL {
        print("default app: \(bundleIdentifier) (\(appURL.path))")
      } else {
        print("default app: \(bundleIdentifier)")
      }
    }

    func run() async {
      let target = utidentifier.target
      let details = LSKit.defaultAppDetails(for: target)

      switch target {
      case .uti:
        guard let utype = target.resolvedType else {
          print("<none>")
          TypeCommands.exit(withError: ExitCode(3))
        }

        printTypeInfo(for: utype)
        printDefaultApp(
          bundleIdentifier: details.bundleIdentifier,
          appURL: details.appURL
        )

      case .fileExtension(let fileExtension):
        print("requested extension: \(fileExtension)")

        if let utype = target.resolvedType,
           let resolvedIdentifier = target.resolvedIdentifier {
          print("resolved UTI: \(resolvedIdentifier)")
          print("dynamic UTI: \(target.hasDynamicResolvedIdentifier)")
          printTypeInfo(for: utype, includeIdentifier: false)
        } else {
          print("resolved UTI: <none>")
        }

        printDefaultApp(
          bundleIdentifier: details.bundleIdentifier,
          appURL: details.appURL
        )
      }
    }
  }
}
