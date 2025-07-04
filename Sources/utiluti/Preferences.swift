//
//  File.swift
//  
//
//  Created by Armin Briegel on 2024-03-20.
//

import Foundation

struct Preferences {
  init?(suiteName: String) {
    self.suiteName = suiteName
    guard let ud = UserDefaults(suiteName: suiteName) else { return nil }
    self.userDefaults = ud
  }
  
  let suiteName: String
  let userDefaults: UserDefaults
  
  
  var allKeys: [String] {
    userDefaults.dictionaryRepresentation().map { $0.key }
  }

  func dictionaryRepresentation(forKeys keys: [String]) -> [String:Any] {
    var dict = [String:Any]()
    for key in keys {
      if let value = userDefaults.object(forKey: key) {
        dict[key] = value
      }
    }
    return dict
  }

  var networkGlobalKeys: [String] {
    keylist(kCFPreferencesAnyApplication, kCFPreferencesAnyUser, kCFPreferencesAnyHost)
  }
  
  var systemGlobalKeys: [String] {
    keylist(kCFPreferencesAnyApplication, kCFPreferencesAnyUser, kCFPreferencesCurrentHost)
  }
  
  var hostGlobalKeys: [String] {
    keylist(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
  }
  
  var userGlobalKeys: [String] {
    keylist(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
  }
  
  var globalKeys: [String] {
    var globalKeys = Set(userGlobalKeys)
    globalKeys.formUnion(systemGlobalKeys)
    globalKeys.formUnion(networkGlobalKeys)
    globalKeys.formUnion(hostGlobalKeys)
    return Array(globalKeys)
  }

  var nonGlobalKeys: [String] {
    var nonGlobalKeys = Set(userKeys)
    nonGlobalKeys.formUnion(hostKeys)
    nonGlobalKeys.formUnion(systemKeys)
    nonGlobalKeys.formUnion(networkKeys)
    return Array(nonGlobalKeys)
  }

  var managedKeys: [String] {
    allKeys
      .filter { userDefaults.objectIsForced(forKey: $0) }
      .filter { $0 != "_manualProfile" }
      .filter { $0 != "PayloadUUID" }
  }
  
  var userKeys: [String] {
    keylist(suiteName as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
  }
  
  var networkKeys: [String] {
    keylist(suiteName as CFString, kCFPreferencesAnyUser, kCFPreferencesAnyHost)
  }
  
  var systemKeys: [String] {
    keylist(suiteName as CFString, kCFPreferencesAnyUser, kCFPreferencesCurrentHost)
  }
  
  var hostKeys: [String] {
    keylist(suiteName as CFString, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
  }
  
  var volatileKeys: [String] {
    let vDomains = userDefaults.volatileDomainNames
    var volatileKeys = Set<String>()
    for domain in vDomains {
      let dict = userDefaults.volatileDomain(forName: domain)
      let keys = dict.map {$0.key}
      volatileKeys.formUnion(keys)
    }
    return Array(volatileKeys)
  }
  
  // MARK: functions
  
  func keylist(_ applicationID: CFString, _ userName: CFString, _ hostName: CFString) -> [String] {
    CFPreferencesCopyKeyList(applicationID, userName, hostName) as? [String] ?? []
  }
  
  func isManaged(_ key: String) -> Bool {
    userDefaults.objectIsForced(forKey: key)
  }
  
  func level(for key: String) -> String? {
    if !allKeys.contains(where: {$0 == key}) {
      return nil
    }
    if isManaged(key) {
      return "managed"
    }
    if hostKeys.contains(where: {$0 == key}) {
      return "host"
    }
    if hostGlobalKeys.contains(where: {$0 == key}) {
      return "global/host"
    }
    if userKeys.contains(where: {$0 == key}) {
      return "user"
    }
    if userGlobalKeys.contains(where: {$0 == key}) {
      return "global/user"
    }
    if systemKeys.contains(where: {$0 == key}) {
      return "system"
    }
    if systemGlobalKeys.contains(where: {$0 == key}) {
      return "global/system"
    }
    if networkKeys.contains(where: {$0 == key}) {
      return "network"
    }
    if networkGlobalKeys.contains(where: {$0 == key}) {
      return "global/network"
    }
    if volatileKeys.contains(where: {$0 == key}) {
      return "volatile"
    }
    
    return nil
  }
}
