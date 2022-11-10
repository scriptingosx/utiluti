//
//  URLScheme.swift
//  utiluti
//
//  Created by Armin Briegel on 2022-11-10.
//

import Foundation
import ArgumentParser

struct URLCommands: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "url",
        abstract: "Manipulate default URL scheme handlers",
        subcommands: [ Get.self, List.self, Set.self],
        defaultSubcommand: Get.self)
    
    struct URLScheme: ParsableArguments {
        @Argument(help: "the url scheme, e.g. 'http' or 'mailto'") var value: String
    }
    
    struct Get: ParsableCommand {
        static var configuration
        = CommandConfiguration(abstract: "Get the path to the default application.")
        
        @OptionGroup var scheme: URLScheme
        
        func run() {
            let appURL = LSKit.defaultAppURL(forScheme: scheme.value)
            print(appURL?.path ?? "no default app found")
        }
    }
    
    struct List: ParsableCommand {
        static var configuration
        = CommandConfiguration(abstract: "List all applications that can handle this URL scheme.")
        
        @OptionGroup var scheme: URLScheme
        
        func run() {
            let appURLs = LSKit.appURLs(forScheme: scheme.value)
            
            for appURL in appURLs {
                print(appURL.path)
            }
        }
    }
    
    struct Set: ParsableCommand {
        static var configuration
        = CommandConfiguration(abstract: "Set the default app for this URL scheme.")
        
        @OptionGroup var scheme: URLScheme
        @Argument(help: "bundle identifier for the app") var identifier: String
        
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
