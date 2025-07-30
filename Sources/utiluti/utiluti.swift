// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ArgumentParser

@main
struct UtilUTI: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "utiluti",
    abstract: "Read and set default URL scheme and file type handlers.",
    version: "1.3",
    subcommands: [
      URLCommands.self,
      TypeCommands.self,
      GetUTI.self,
      AppCommands.self,
      FileCommands.self,
      ManageCommand.self
    ]
  )
}
