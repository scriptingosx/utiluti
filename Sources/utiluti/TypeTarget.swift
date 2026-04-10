//
//  TypeTarget.swift
//  utiluti
//

import Foundation
import UniformTypeIdentifiers

enum TypeTarget: Equatable {
  case uti(String)
  case fileExtension(String)

  init(value: String, isFileExtension: Bool) {
    if isFileExtension {
      self = .fileExtension(Self.normalizeExtension(value))
    } else {
      self = .uti(value)
    }
  }

  init(managedKey: String) {
    if managedKey.hasPrefix("extension:") {
      let value = String(managedKey.dropFirst("extension:".count))
      self = .fileExtension(Self.normalizeExtension(value))
    } else {
      self = .uti(managedKey)
    }
  }

  static func normalizeExtension(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.hasPrefix(".") {
      return String(trimmed.dropFirst()).lowercased()
    } else {
      return trimmed.lowercased()
    }
  }

  var displayValue: String {
    switch self {
    case .uti(let identifier):
      return identifier
    case .fileExtension(let fileExtension):
      return "extension:\(fileExtension)"
    }
  }

  /**
   Resolve the target to the best available UTI string. For extension input
   this is only advisory; the caller can still fall back to the extension
   path when Launch Services rejects the resolved type.
   */
  var resolvedIdentifier: String? {
    resolvedType?.identifier
  }

  var hasDynamicResolvedIdentifier: Bool {
    resolvedIdentifier?.hasPrefix("dyn.") ?? false
  }

  /**
   The preferred UTI-based route for this target. Explicit UTIs always use
   their original identifier, while extension input uses the resolved UTI
   when one exists.
   */
  var preferredTypeIdentifier: String? {
    switch self {
    case .uti(let identifier):
      return identifier
    case .fileExtension:
      return resolvedIdentifier
    }
  }

  var resolvedType: UTType? {
    switch self {
    case .uti(let identifier):
      return UTType(identifier)
    case .fileExtension(let fileExtension):
      return UTType(filenameExtension: fileExtension)
    }
  }
}
