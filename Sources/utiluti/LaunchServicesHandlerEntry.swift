//
//  LaunchServicesHandlerEntry.swift
//  utiluti
//

import Foundation

struct LaunchServicesHandlerEntry {
  private enum Key {
    static let contentType = "LSHandlerContentType"
    static let contentTag = "LSHandlerContentTag"
    static let contentTagClass = "LSHandlerContentTagClass"
    static let preferredVersions = "LSHandlerPreferredVersions"
    static let roleAll = "LSHandlerRoleAll"
    static let roleEditor = "LSHandlerRoleEditor"
    static let roleViewer = "LSHandlerRoleViewer"
    static let roleShell = "LSHandlerRoleShell"
  }

  static let filenameExtensionTagClass = "public.filename-extension"

  private let storage: [String:Any]

  init(storage: [String:Any]) {
    self.storage = storage
  }

  var propertyListRepresentation: [String:Any] {
    storage
  }

  var preferredBundleIdentifier: String? {
    storage[Key.roleAll] as? String
      ?? storage[Key.roleEditor] as? String
      ?? storage[Key.roleViewer] as? String
      ?? storage[Key.roleShell] as? String
  }

  func matches(typeIdentifier: String) -> Bool {
    (storage[Key.contentType] as? String) == typeIdentifier
  }

  func matches(fileExtension normalizedExtension: String) -> Bool {
    guard let tagClass = storage[Key.contentTagClass] as? String,
          tagClass == Self.filenameExtensionTagClass,
          let tag = storage[Key.contentTag] as? String
    else { return false }

    return TypeTarget.normalizeExtension(tag) == normalizedExtension
  }

  static func extensionEditorOverride(bundleIdentifier: String, fileExtension: String) -> Self {
    let normalizedExtension = TypeTarget.normalizeExtension(fileExtension)

    return Self(storage: [
      Key.contentTag: normalizedExtension,
      Key.contentTagClass: filenameExtensionTagClass,
      Key.preferredVersions: [
        Key.roleEditor: "-"
      ],
      Key.roleEditor: bundleIdentifier
    ])
  }
}
