//
//  TypeCommands.swift
//  utiluti
//
//  Created by Armin Briegel on 2022-11-10.
//

import Foundation
import ArgumentParser

struct TypeCommands: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "type",
    abstract: "Manipulate default file type handlers",
    subcommands: [Get.self, List.self, Set.self],
    defaultSubcommand: Get.self
  )
  
  struct UTIdentifier: ParsableArguments {
    @Argument(help: "universal type identifier, e.g. 'public.html'") var utidentifier: String
  }
  
  
  struct Get: ParsableCommand {
    static var configuration
    = CommandConfiguration(abstract: "Get the path to the default application.")
   
    @OptionGroup var args: UTIdentifier
    
    func run() {
      let appURL = LSKit.defaultAppURL(forTypeIdentifier: args.utidentifier)
      print(appURL?.path ?? "no default app found")
    }
  }
  
  struct List: ParsableCommand {
    static var configuration
    = CommandConfiguration(abstract: "List all applications that can handle this type identifier.")

    @OptionGroup var args: UTIdentifier
    
    func run() {
      let appURLs = LSKit.appURLs(forTypeIdentifier: args.utidentifier)
      
      for appURL in appURLs {
        print(appURL.path)
      }
    }
  }
  
  struct Set: ParsableCommand {
    static var configuration
    = CommandConfiguration(abstract: "Set the default app for this type identifier.")

    @OptionGroup var args: UTIdentifier
    @Argument var identifier: String
    
    func run() {
      let result = LSKit.setDefaultApp(identifier: identifier, forTypeIdentifier: args.utidentifier)
      
      if result == 0 {
        print("set \(identifier) for \(args.utidentifier)")
      } else {
        print("cannot set default app for \(args.utidentifier) (error \(result))")
      }
    }
  }
}
