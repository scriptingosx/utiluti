//
//  GetIdentifier.swift
//  utiluti
//
//  Created by Armin Briegel on 2022-11-10.
//

import Foundation
import ArgumentParser
import UniformTypeIdentifiers

@available(macOS 11.0, *)
struct GetUTI: ParsableCommand {
  static let configuration
  = CommandConfiguration(abstract: "Get the type identifier (UTI) for a file extension")
  
  @Argument(help: "file extension")
  var fileExtension: String
  
  @Flag(help: "show dynamic identifiers")
  var showDynamic = false
  
  func run() {
    guard let utype = UTType(filenameExtension: fileExtension) else {
      Self.exit(withError: ExitCode(3))
    }
    
    if utype.identifier.hasPrefix("dyn.") {
      if showDynamic {
        print(utype.identifier)
      }
    } else {
      print(utype.identifier)
    }
  }
}
