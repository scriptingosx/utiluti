// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ArgumentParser

@main
struct UtilUTI: ParsableCommand {
  static let subCommands: [ParsableCommand.Type] = {
    if #available(macOS 11.0, *) {
      return [URLCommands.self, TypeCommands.self, GetUTI.self]
    } else {
      return [URLCommands.self, TypeCommands.self]
    }
  }()
  
  static let configuration = CommandConfiguration(
    commandName: "utiluti",
    abstract: "Read and set default URL scheme and file type handlers.",
    version: "1.0",
    subcommands: subCommands
  )
}
