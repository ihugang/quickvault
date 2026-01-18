//
//  CryptoService.swift
//  QuickHold
//

// Import CommonCrypto for PBKDF2
import CommonCrypto
import CryptoKit
import Foundation
import os.log
import Security

private let cryptoLogger = Logger(subsystem: "com.codans.quickhold", category: "CryptoService")

public enum CryptoError: LocalizedError {
  case encryptionFailed
  case decryptionFailed
  case keyDerivationFailed
  case keyNotAvailable
  case invalidData

  public var errorDescription: String? {
    switch self {
    case .encryptionFailed:
      return "加密失败 / Encryption failed"
    case .decryptionFailed:
      return "解密失败 / Decryption failed"
    case .keyDerivationFailed:
      return "密钥派生失败 / Key derivation failed"
    case .keyNotAvailable:
      return "加密密钥不可用 / Encryption key not available"
    case .invalidData:
      return "无效的数据格式 / Invalid data format"
    }
  }
}

public protocol CryptoService {
  func encrypt(_ data: String) throws -> Data
  func decrypt(_ data: Data) throws -> String
  func encryptFile(_ data: Data) throws -> Data
  func decryptFile(_ data: Data) throws -> Data
  func deriveKey(from password: String, salt: Data) throws -> SymmetricKey
  func generateSalt() -> Data
  func getSalt() throws -> Data
  func initializeKey(password: String, salt: Data?, allowSaltGeneration: Bool) throws
  func hasSalt() -> Bool
  func clearKey()  // 清除加密密钥 / Clear encryption key
  func hashPassword(_ password: String) -> String
}

public final class CryptoServiceImpl: CryptoService, @unchecked Sendable {
  /// Shared singleton instance / 共享单例实例
  public static let shared = CryptoServiceImpl()
  
  private var encryptionKey: SymmetricKey?
  private let keychainService: KeychainService

  private let saltKey = QuickHoldConstants.KeychainKeys.cryptoSalt
  private let keyKey = "crypto.key"

  public init(keychainService: KeychainService = KeychainServiceImpl()) {
    self.keychainService = keychainService
  }

  // MARK: - Key Management

  public func initializeKey(
    password: String,
    salt: Data? = nil,
    allowSaltGeneration: Bool = true
  ) throws {
    cryptoLogger.info("🔐 [CryptoService] initializeKey called - allowSaltGeneration: \(allowSaltGeneration)")
    let saltData: Data

    if let existingSalt = salt {
      cryptoLogger.info("📥 [CryptoService] Using provided salt (length: \(existingSalt.count) bytes)")
      saltData = existingSalt
    } else if keychainService.exists(key: saltKey) {
      cryptoLogger.info("🔑 [CryptoService] Loading salt from keychain")
      saltData = try keychainService.load(key: saltKey)
      cryptoLogger.info("✅ [CryptoService] Salt loaded successfully (length: \(saltData.count) bytes)")

      // Log salt hash for debugging (first 8 bytes as hex)
      let saltPrefix = saltData.prefix(8).map { String(format: "%02x", $0) }.joined()
      cryptoLogger.info("🔍 [CryptoService] Salt prefix (first 8 bytes): \(saltPrefix)")

      // Migration: Re-save salt with iCloud sync enabled for existing users
      // 迁移：为已有用户重新保存盐值并启用 iCloud 同步
      cryptoLogger.info("🔄 [CryptoService] Checking if salt migration needed...")
      try migrateSaltToSynchronizable(saltData)
    } else if allowSaltGeneration {
      cryptoLogger.warning("⚠️ [CryptoService] Salt not found in keychain, generating new salt")
      saltData = generateSalt()
      cryptoLogger.info("🆕 [CryptoService] New salt generated (length: \(saltData.count) bytes)")

      // Log salt hash for debugging (first 8 bytes as hex)
      let saltPrefix = saltData.prefix(8).map { String(format: "%02x", $0) }.joined()
      cryptoLogger.info("🔍 [CryptoService] Salt prefix (first 8 bytes): \(saltPrefix)")

      // Enable iCloud Keychain sync for salt to support multi-device scenarios
      // 启用 iCloud Keychain 同步以支持多设备场景
      cryptoLogger.info("☁️ [CryptoService] Saving salt to iCloud Keychain (synchronizable: true)")
      try keychainService.save(key: saltKey, data: saltData, synchronizable: true)
      cryptoLogger.info("✅ [CryptoService] Salt saved to iCloud Keychain successfully")
    } else {
      cryptoLogger.error("❌ [CryptoService] Salt not available and generation disabled - throwing keyNotAvailable")
      throw CryptoError.keyNotAvailable
    }

    cryptoLogger.info("🔑 [CryptoService] Deriving encryption key from password...")
    encryptionKey = try deriveKey(from: password, salt: saltData)
    cryptoLogger.info("✅ [CryptoService] Encryption key initialized successfully")
  }

  /// Migrate existing salt to synchronizable keychain item
  /// 将现有盐值迁移到可同步的 Keychain 项
  private func migrateSaltToSynchronizable(_ salt: Data) throws {
    cryptoLogger.info("🔄 [CryptoService] Starting salt migration to synchronizable keychain item")
    cryptoLogger.debug("📊 [CryptoService] Salt to migrate: \(salt.count) bytes")

    // Delete old non-synchronizable item and save as synchronizable
    // 删除旧的不可同步项并保存为可同步项
    cryptoLogger.info("🗑️ [CryptoService] Deleting old non-synchronizable salt")
    try keychainService.delete(key: saltKey)

    cryptoLogger.info("💾 [CryptoService] Saving salt with synchronizable: true")
    try keychainService.save(key: saltKey, data: salt, synchronizable: true)

    cryptoLogger.info("✅ [CryptoService] Salt migration completed successfully")
  }

  public func deriveKey(from password: String, salt: Data) throws -> SymmetricKey {
    guard let passwordData = password.data(using: .utf8) else {
      throw CryptoError.keyDerivationFailed
    }

    // Use PBKDF2 with 100,000 iterations
    let derivedKey = try PBKDF2.deriveKey(
      password: passwordData,
      salt: salt,
      iterations: 100_000,
      keyLength: 32  // 256 bits for AES-256
    )

    return SymmetricKey(data: derivedKey)
  }

  public func generateSalt() -> Data {
    cryptoLogger.info("🎲 [CryptoService] Generating new random salt (32 bytes)...")
    var salt = Data(count: 32)
    let result = salt.withUnsafeMutableBytes { bytes in
      SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
    }
    if result == errSecSuccess {
      cryptoLogger.info("✅ [CryptoService] Random salt generated successfully")
    } else {
      cryptoLogger.error("❌ [CryptoService] Failed to generate random salt, status: \(result)")
    }
    return salt
  }
  
  public func getSalt() throws -> Data {
    cryptoLogger.debug("🔍 [CryptoService] getSalt() called")
    guard keychainService.exists(key: saltKey) else {
      cryptoLogger.warning("⚠️ [CryptoService] Salt not found in keychain")
      throw CryptoError.keyNotAvailable
    }
    let salt = try keychainService.load(key: saltKey)
    cryptoLogger.info("✅ [CryptoService] Salt retrieved successfully (length: \(salt.count) bytes)")
    return salt
  }

  public func hasSalt() -> Bool {
    let exists = keychainService.exists(key: saltKey)
    cryptoLogger.debug("🔍 [CryptoService] hasSalt() = \(exists)")
    return exists
  }
  
  /// 清除加密密钥（用于登出或清除所有数据）
  /// Clear encryption key (for logout or clearing all data)
  public func clearKey() {
    cryptoLogger.info("🗑️ [CryptoService] Clearing encryption key from memory")
    encryptionKey = nil
    cryptoLogger.info("✅ [CryptoService] Encryption key cleared successfully")
  }

  // MARK: - String Encryption/Decryption

  public func encrypt(_ data: String) throws -> Data {
    guard let key = encryptionKey else {
      cryptoLogger.error("[CryptoService] encrypt failed: encryptionKey is nil")
      throw CryptoError.keyNotAvailable
    }
    cryptoLogger.debug("[CryptoService] Encrypting data")

    guard let dataToEncrypt = data.data(using: .utf8) else {
      throw CryptoError.encryptionFailed
    }

    do {
      let sealedBox = try AES.GCM.seal(dataToEncrypt, using: key)
      guard let combined = sealedBox.combined else {
        throw CryptoError.encryptionFailed
      }
      return combined
    } catch {
      throw CryptoError.encryptionFailed
    }
  }

  public func decrypt(_ data: Data) throws -> String {
    guard let key = encryptionKey else {
      throw CryptoError.keyNotAvailable
    }

    do {
      let sealedBox = try AES.GCM.SealedBox(combined: data)
      let decryptedData = try AES.GCM.open(sealedBox, using: key)

      guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
        throw CryptoError.decryptionFailed
      }

      return decryptedString
    } catch {
      throw CryptoError.decryptionFailed
    }
  }

  // MARK: - File Encryption/Decryption

  public func encryptFile(_ data: Data) throws -> Data {
    guard let key = encryptionKey else {
      throw CryptoError.keyNotAvailable
    }

    do {
      let sealedBox = try AES.GCM.seal(data, using: key)
      guard let combined = sealedBox.combined else {
        throw CryptoError.encryptionFailed
      }
      return combined
    } catch {
      throw CryptoError.encryptionFailed
    }
  }

  public func decryptFile(_ data: Data) throws -> Data {
    guard let key = encryptionKey else {
      throw CryptoError.keyNotAvailable
    }

    do {
      let sealedBox = try AES.GCM.SealedBox(combined: data)
      let decryptedData = try AES.GCM.open(sealedBox, using: key)
      return decryptedData
    } catch {
      throw CryptoError.decryptionFailed
    }
  }

  // MARK: - Password Hashing

  public func hashPassword(_ password: String) -> String {
    guard let passwordData = password.data(using: .utf8) else {
      return ""
    }

    let hash = SHA256.hash(data: passwordData)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
  }
}

// MARK: - PBKDF2 Helper

private struct PBKDF2 {
  static func deriveKey(password: Data, salt: Data, iterations: Int, keyLength: Int) throws -> Data
  {
    var derivedKeyData = Data(count: keyLength)
    let derivationStatus = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
      salt.withUnsafeBytes { saltBytes in
        password.withUnsafeBytes { passwordBytes in
          CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
            password.count,
            saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
            salt.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
            UInt32(iterations),
            derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
            keyLength
          )
        }
      }
    }

    guard derivationStatus == kCCSuccess else {
      throw CryptoError.keyDerivationFailed
    }

    return derivedKeyData
  }
}
