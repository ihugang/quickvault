//
//  KeychainService.swift
//  QuickHold
//

import Foundation
import Security

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
  }

  public func save(key: String, data: Data, synchronizable: Bool = false) throws {
    // Delete existing item if present
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
      query[kSecAttrSynchronizable as String] = true
    }

    let status = SecItemAdd(query as CFDictionary, nil)

    guard status == errSecSuccess else {
      throw KeychainError.saveFailed(status)
    }
  }

  public func load(key: String) throws -> Data {
    // First try to load synchronizable item (for iCloud synced data)
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
    ]

    var result: AnyObject?
    var status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess else {
      if status == errSecItemNotFound {
        throw KeychainError.itemNotFound
      }
      throw KeychainError.loadFailed(status)
    }

    guard let data = result as? Data else {
      throw KeychainError.unexpectedData
    }

    return data
  }

  public func delete(key: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
    ]

    let status = SecItemDelete(query as CFDictionary)

    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.deleteFailed(status)
    }
  }

  public func exists(key: String) -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecReturnData as String: false,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
    ]

    let status = SecItemCopyMatching(query as CFDictionary, nil)
    return status == errSecSuccess
  }
}
