//
//  LaunchServicesPreferences.swift
//  utiluti
//

import Foundation

struct LaunchServicesPreferences {
  static let relativePath = "Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"
  static let handlersKey = "LSHandlers"

  private struct Cache {
    var dictionaries = [String: [String:Any]]()
    var handlers = [String: [LaunchServicesHandlerEntry]]()
  }

  private static let cache = LockedValue(Cache())

  private let fileURL: URL

  init() {
    self.fileURL = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(Self.relativePath, isDirectory: false)
  }

  /**
   Read the current per-user Launch Services handler overrides.
   */
  var handlers: [LaunchServicesHandlerEntry] {
    if let cachedHandlers = Self.cache.withLock({ $0.handlers[cacheKey] }) {
      return cachedHandlers
    }

    let rawHandlers = dictionary[Self.handlersKey] as? [[String:Any]] ?? []
    let handlers = rawHandlers.map(LaunchServicesHandlerEntry.init(storage:))
    Self.cache.withLock { $0.handlers[cacheKey] = handlers }
    return handlers
  }

  /**
   Look for an extension-specific override such as
   `LSHandlerContentTag = go` and return the preferred bundle identifier.
   */
  func preferredBundleIdentifier(forExtension fileExtension: String) -> String? {
    Self.preferredBundleIdentifier(forExtension: fileExtension, in: handlers)
  }

  /**
   Look for a content-type override such as
   `LSHandlerContentType = public.plain-text`.
   */
  func preferredBundleIdentifier(forTypeIdentifier utidentifier: String) -> String? {
    Self.preferredBundleIdentifier(forTypeIdentifier: utidentifier, in: handlers)
  }

  @discardableResult
  /**
   Write or replace the user's extension-specific editor override while leaving
   unrelated Launch Services handler entries untouched.
   */
  func setDefaultEditor(bundleIdentifier: String, forExtension fileExtension: String) -> Bool {
    let updatedHandlers = Self.upsertingExtensionHandler(
      bundleIdentifier: bundleIdentifier,
      forExtension: fileExtension,
      in: handlers
    )

    var updatedDictionary = dictionary
    updatedDictionary[Self.handlersKey] = updatedHandlers.map(\.propertyListRepresentation)

    do {
      try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(),
        withIntermediateDirectories: true,
        attributes: nil
      )
      let plistData = try PropertyListSerialization.data(
        fromPropertyList: updatedDictionary,
        format: .xml,
        options: 0
      )
      try plistData.write(to: fileURL, options: .atomic)
      Self.cache.withLock { cache in
        cache.dictionaries[cacheKey] = updatedDictionary
        cache.handlers[cacheKey] = updatedHandlers
      }
      return true
    } catch {
      return false
    }
  }

  /**
   Replace any existing override for the same extension with a single
   normalized `public.filename-extension` handler entry.
   */
  private static func upsertingExtensionHandler(
    bundleIdentifier: String,
    forExtension fileExtension: String,
    in handlers: [LaunchServicesHandlerEntry]
  ) -> [LaunchServicesHandlerEntry] {
    let normalizedExtension = TypeTarget.normalizeExtension(fileExtension)
    let remainingHandlers = handlers.filter { !$0.matches(fileExtension: normalizedExtension) }

    var updatedHandlers = remainingHandlers
    updatedHandlers.append(
      .extensionEditorOverride(bundleIdentifier: bundleIdentifier, fileExtension: normalizedExtension)
    )

    return updatedHandlers
  }

  private static func preferredBundleIdentifier(
    forExtension fileExtension: String,
    in handlers: [LaunchServicesHandlerEntry]
  ) -> String? {
    let normalizedExtension = TypeTarget.normalizeExtension(fileExtension)
    return handlers.last(where: { $0.matches(fileExtension: normalizedExtension) })?.preferredBundleIdentifier
  }

  private static func preferredBundleIdentifier(
    forTypeIdentifier utidentifier: String,
    in handlers: [LaunchServicesHandlerEntry]
  ) -> String? {
    handlers.last(where: { $0.matches(typeIdentifier: utidentifier) })?.preferredBundleIdentifier
  }

  /**
   Load the Launch Services secure plist directly because the `LSHandlers`
   array is the source of truth for the per-user overrides we need to read
   and update.
   */
  private var dictionary: [String:Any] {
    if let cachedDictionary = Self.cache.withLock({ $0.dictionaries[cacheKey] }) {
      return cachedDictionary
    }

    guard let data = try? Data(contentsOf: fileURL),
          let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
          let dictionary = plist as? [String:Any]
    else {
      Self.cache.withLock { $0.dictionaries[cacheKey] = [:] }
      return [:]
    }

    Self.cache.withLock { $0.dictionaries[cacheKey] = dictionary }

    return dictionary
  }

  private var cacheKey: String {
    fileURL.path
  }
}
