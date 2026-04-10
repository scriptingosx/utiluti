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
    let normalizedExtension = TypeTarget.normalizeExtension(fileExtension)

    guard let utype = UTType(filenameExtension: normalizedExtension) else {
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
