//
//  main.swift
//  utiluti
//
//  Created by Armin Briegel on 2022-11-08.
//

import Foundation
import ArgumentParser

struct UtilUTI: ParsableCommand {
  static var subCommands: [ParsableCommand.Type] = {
    if #available(macOS 11.0, *) {
      return [URLCommands.self, TypeCommands.self, GetUTI.self]
    } else {
      return [URLCommands.self, TypeCommands.self]
    }
  }()
  
  static var configuration = CommandConfiguration(
    commandName: "utiluti",
    abstract: "Read and set default URL scheme and file type handlers.",
    subcommands: subCommands)
}

UtilUTI.main()
