//
//  FileTypeProbe.swift
//  utiluti
//

import Foundation

enum FileTypeProbe {
  /**
   Some file-association APIs only answer accurately for a concrete file URL,
   so create a short-lived empty probe file and remove it immediately after.
   */
  static func withTemporaryFileURL<T>(forExtension fileExtension: String, perform body: (URL) -> T) -> T {
    let normalizedExtension = TypeTarget.normalizeExtension(fileExtension)
    let tempDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("utiluti-\(UUID().uuidString)", isDirectory: true)
    let baseFileURL = tempDirectory.appendingPathComponent("utiluti-probe")
    let fileURL = normalizedExtension.isEmpty ? baseFileURL : baseFileURL.appendingPathExtension(normalizedExtension)

    try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    FileManager.default.createFile(atPath: fileURL.path, contents: Data())
    defer { try? FileManager.default.removeItem(at: tempDirectory) }

    return body(fileURL)
  }
}
