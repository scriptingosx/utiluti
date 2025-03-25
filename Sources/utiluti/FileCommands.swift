//
//  FileCommands.swift
//  utiluti
//
//  Created by Armin on 25/03/2025.
//

import Foundation

import Foundation
import ArgumentParser
import UniformTypeIdentifiers
import AppKit // for NSWorkspace

struct FileCommands: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "file",
    abstract: "commands to manage specific files",
    subcommands: [ GetUTI.self ]
  )
  
  struct GetUTI: ParsableCommand {
    static let configuration
    = CommandConfiguration(abstract: "get the uniform type identifier of a file")
    
    @Argument(help:ArgumentHelp("file path", valueName: "path"))
    var path: String
    
    func run() {
      let url = URL(fileURLWithPath: path)
      let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier
      print(typeIdentifier ?? "<unknown>")
    }
  }
}
    
