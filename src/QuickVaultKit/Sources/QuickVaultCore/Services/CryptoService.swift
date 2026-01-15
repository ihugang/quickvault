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

private let cryptoLogger = Logger(subsystem: AppConstants.Logger.subsystem, category: AppConstants.Logger.Category.crypto)

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
  func initializeKey(password: String, salt: Data?) throws
  func clearKey()  // 清除加密密钥 / Clear encryption key
  func hashPassword(_ password: String) -> String
}

public final class CryptoServiceImpl: CryptoService, @unchecked Sendable {
  /// Shared singleton instance / 共享单例实例
  public static let shared = CryptoServiceImpl()
  
  private var encryptionKey: SymmetricKey?
  private let keychainService: KeychainService

  private let saltKey = "crypto.salt"
  private let keyKey = "crypto.key"

  public init(keychainService: KeychainService = KeychainServiceImpl()) {
    self.keychainService = keychainService
  }

  // MARK: - Key Management

  public func initializeKey(password: String, salt: Data? = nil) throws {
    cryptoLogger.info("[CryptoService] initializeKey called")
    let saltData: Data

    if let existingSalt = salt {
      cryptoLogger.debug("[CryptoService] Using provided salt")
      saltData = existingSalt
    } else if keychainService.exists(key: saltKey) {
      cryptoLogger.debug("[CryptoService] Loading salt from keychain")
      saltData = try keychainService.load(key: saltKey)
    } else {
      cryptoLogger.debug("[CryptoService] Generating new salt")
      saltData = generateSalt()
      try keychainService.save(key: saltKey, data: saltData)
    }

    encryptionKey = try deriveKey(from: password, salt: saltData)
    cryptoLogger.info("[CryptoService] Encryption key initialized successfully")
  }

  public func deriveKey(from password: String, salt: Data) throws -> SymmetricKey {
    guard let passwordData = password.data(using: .utf8) else {
      throw CryptoError.keyDerivationFailed
    }

    // Use PBKDF2 with configured iterations
    let derivedKey = try PBKDF2.deriveKey(
      password: passwordData,
      salt: salt,
      iterations: AppConstants.Crypto.pbkdf2Iterations,
      keyLength: AppConstants.Crypto.keySize
    )

    return SymmetricKey(data: derivedKey)
  }

  public func generateSalt() -> Data {
    var salt = Data(count: AppConstants.Crypto.saltSize)
    _ = salt.withUnsafeMutableBytes { bytes in
      SecRandomCopyBytes(kSecRandomDefault, AppConstants.Crypto.saltSize, bytes.baseAddress!)
    }
    return salt
  }
  
  public func getSalt() throws -> Data {
    guard keychainService.exists(key: saltKey) else {
      throw CryptoError.keyNotAvailable
    }
    return try keychainService.load(key: saltKey)
  }
  
  /// 清除加密密钥（用于登出或清除所有数据）
  /// Clear encryption key (for logout or clearing all data)
  public func clearKey() {
    encryptionKey = nil
    cryptoLogger.info("[CryptoService] Encryption key cleared")
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
