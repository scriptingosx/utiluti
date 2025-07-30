//
//  GetIdentifier.swift
//  utiluti
//
//  Created by Armin Briegel on 2022-11-10.
//

import Foundation
import ArgumentParser
import UniformTypeIdentifiers

struct GetUTI: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-uti",
    abstract: "Get the type identifier (UTI) for a file extension"
  )

  @Argument(help: "file extension")
  var fileExtension: String
  
  @Flag(help: "show dynamic identifiers")
  var showDynamic = false
  
  func run() async {
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
