//
//  AppCommands.swift
//  utiluti
//
//  Created by Armin on 20/03/2025.
//

import Foundation
import ArgumentParser
import AppKit // for NSWorkspace

struct AppCommands: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app",
        abstract: "list uniform types identifiers and url schemes associated with an app",
        subcommands: [ Types.self ]
    )
    
    struct Types: ParsableCommand {
        static let configuration
        = CommandConfiguration(abstract: "List the uniform type identifiers this app can open")
        
        @Argument(help:ArgumentHelp("the app identifier", valueName: "app-identifier"))
        var appID: String
        
        @Flag(name: .shortAndLong,
              help: "show more information")
        var verbose: Bool = false
        
        func run() {
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
                    let name = docType["CFBundleTypeName"] as? String,
                    let role = docType["CFBundleTypeRole"] as? String,
                    let types = docType["LSItemContentTypes"] as? [String]
                else { continue }
                for type in types {
                    if verbose {
                        print("\(type) - \(name) (\(role))")
                    } else {
                        print(type)
                    }
                }
            }
        }
    }
}
