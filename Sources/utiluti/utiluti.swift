// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ArgumentParser

@main
struct UtilUTI: AsyncParsableCommand {
  static let subCommands: [ParsableCommand.Type] = [URLCommands.self, TypeCommands.self, GetUTI.self, AppCommands.self, FileCommands.self]
  
  static let configuration = CommandConfiguration(
    commandName: "utiluti",
    abstract: "Read and set default URL scheme and file type handlers.",
    version: "1.1dev",
    subcommands: subCommands
  )
}
