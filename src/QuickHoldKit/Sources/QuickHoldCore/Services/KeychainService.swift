//
//  KeychainService.swift
//  QuickHold
//

import Foundation
import Security
import os.log

private let keychainLogger = Logger(subsystem: "com.codans.quickhold", category: "KeychainService")

public enum KeychainError: LocalizedError {
  case saveFailed(OSStatus)
  case loadFailed(OSStatus)
  case deleteFailed(OSStatus)
  case unexpectedData
  case itemNotFound

  public var errorDescription: String? {
    switch self {
    case .saveFailed(let status):
      return "保存到钥匙串失败 / Failed to save to Keychain: \(status)"
    case .loadFailed(let status):
      return "从钥匙串加载失败 / Failed to load from Keychain: \(status)"
    case .deleteFailed(let status):
      return "从钥匙串删除失败 / Failed to delete from Keychain: \(status)"
    case .unexpectedData:
      return "钥匙串数据格式错误 / Unexpected Keychain data format"
    case .itemNotFound:
      return "钥匙串项目未找到 / Keychain item not found"
    }
  }
}

public protocol KeychainService {
  func save(key: String, data: Data, synchronizable: Bool) throws
  func load(key: String) throws -> Data
  func delete(key: String) throws
  func exists(key: String) -> Bool
}

public class KeychainServiceImpl: KeychainService {
  private let service: String

  public init(service: String = "com.codans.quickhold.app") {
    self.service = service
    keychainLogger.info("🔑 [Keychain] KeychainService initialized with service: \(service)")
  }

  public func save(key: String, data: Data, synchronizable: Bool = false) throws {
    keychainLogger.info("💾 [Keychain] ========== SAVE START ==========")
    keychainLogger.info("📊 [Keychain] Key: \(key)")
    keychainLogger.info("📊 [Keychain] Data size: \(data.count) bytes")
    keychainLogger.info("📊 [Keychain] Synchronizable (iCloud): \(synchronizable)")

    // Delete existing item if present
    keychainLogger.info("🗑️ [Keychain] Deleting existing item if present...")
    try? delete(key: key)

    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
    ]

    // Enable iCloud Keychain sync if requested
    if synchronizable {
      keychainLogger.info("☁️ [Keychain] Enabling iCloud Keychain sync for this item")
      query[kSecAttrSynchronizable as String] = true
    } else {
      keychainLogger.info("📱 [Keychain] Item will be stored LOCALLY only (not synced to iCloud)")
    }

    keychainLogger.info("📝 [Keychain] Calling SecItemAdd...")
    let status = SecItemAdd(query as CFDictionary, nil)

    guard status == errSecSuccess else {
      keychainLogger.error("❌ [Keychain] SecItemAdd FAILED with status: \(status)")
      keychainLogger.error("💡 [Keychain] Common status codes:")
      keychainLogger.error("   -25299 = errSecDuplicateItem (item already exists)")
      keychainLogger.error("   -25300 = errSecItemNotFound")
      keychainLogger.error("   -34018 = iOS keychain access error (check entitlements)")
      keychainLogger.error("❌ [Keychain] ========== SAVE FAILED ==========")
      throw KeychainError.saveFailed(status)
    }

    keychainLogger.info("✅ [Keychain] Item saved successfully!")
    keychainLogger.info("✅ [Keychain] ========== SAVE SUCCESS ==========")
  }

  public func load(key: String) throws -> Data {
    keychainLogger.info("📥 [Keychain] ========== LOAD START ==========")
    keychainLogger.info("📊 [Keychain] Key: \(key)")

    // First try to load synchronizable item (for iCloud synced data)
    keychainLogger.info("🔍 [Keychain] Searching for item (kSecAttrSynchronizableAny)...")
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
    ]

    var result: AnyObject?
    keychainLogger.info("📝 [Keychain] Calling SecItemCopyMatching...")
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess else {
      if status == errSecItemNotFound {
        keychainLogger.warning("⚠️ [Keychain] Item not found (status: -25300)")
        keychainLogger.warning("💡 [Keychain] This could mean:")
        keychainLogger.warning("   - Item was never saved")
        keychainLogger.warning("   - Item was deleted")
        keychainLogger.warning("   - iCloud Keychain sync hasn't completed yet")
        keychainLogger.error("❌ [Keychain] ========== LOAD - ITEM NOT FOUND ==========")
        throw KeychainError.itemNotFound
      }
      keychainLogger.error("❌ [Keychain] SecItemCopyMatching FAILED with status: \(status)")
      keychainLogger.error("❌ [Keychain] ========== LOAD FAILED ==========")
      throw KeychainError.loadFailed(status)
    }

    guard let data = result as? Data else {
      keychainLogger.error("❌ [Keychain] Result is not Data type (unexpected)")
      keychainLogger.error("❌ [Keychain] ========== LOAD - UNEXPECTED DATA ==========")
      throw KeychainError.unexpectedData
    }

    keychainLogger.info("✅ [Keychain] Item loaded successfully!")
    keychainLogger.info("📊 [Keychain] Data size: \(data.count) bytes")
    keychainLogger.info("✅ [Keychain] ========== LOAD SUCCESS ==========")
    return data
  }

  public func delete(key: String) throws {
    keychainLogger.info("🗑️ [Keychain] ========== DELETE START ==========")
    keychainLogger.info("📊 [Keychain] Key: \(key)")

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
    ]

    keychainLogger.info("📝 [Keychain] Calling SecItemDelete...")
    let status = SecItemDelete(query as CFDictionary)

    guard status == errSecSuccess || status == errSecItemNotFound else {
      keychainLogger.error("❌ [Keychain] SecItemDelete FAILED with status: \(status)")
      keychainLogger.error("❌ [Keychain] ========== DELETE FAILED ==========")
      throw KeychainError.deleteFailed(status)
    }

    if status == errSecItemNotFound {
      keychainLogger.info("ℹ️ [Keychain] Item was not found (already deleted or never existed)")
    } else {
      keychainLogger.info("✅ [Keychain] Item deleted successfully!")
    }
    keychainLogger.info("✅ [Keychain] ========== DELETE SUCCESS ==========")
  }

  public func exists(key: String) -> Bool {
    keychainLogger.debug("🔍 [Keychain] EXISTS check for key: \(key)")

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecReturnData as String: false,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
    ]

    let status = SecItemCopyMatching(query as CFDictionary, nil)
    let exists = status == errSecSuccess

    keychainLogger.debug("📊 [Keychain] EXISTS result for '\(key)': \(exists) (status: \(status))")
    return exists
  }
}
