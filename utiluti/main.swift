//
//  main.swift
//  utiluti
//
//  Created by Armin Briegel on 2022-11-08.
//

import Foundation
import ArgumentParser

struct UtilUTI: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "utiluti",
    abstract: "Read and set default URL scheme and file type handlers.",
    subcommands: [URLCommands.self, TypeCommands.self])
}

UtilUTI.main()
