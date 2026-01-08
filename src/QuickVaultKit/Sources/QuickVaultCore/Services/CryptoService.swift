//
//  CryptoService.swift
//  QuickVault
//

// Import CommonCrypto for PBKDF2
import CommonCrypto
import CryptoKit
import Foundation

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
  func initializeKey(password: String, salt: Data?) throws
  func hashPassword(_ password: String) -> String
}

public class CryptoServiceImpl: CryptoService {
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
    let saltData: Data

    if let existingSalt = salt {
      saltData = existingSalt
    } else if keychainService.exists(key: saltKey) {
      saltData = try keychainService.load(key: saltKey)
    } else {
      saltData = generateSalt()
      try keychainService.save(key: saltKey, data: saltData)
    }

    encryptionKey = try deriveKey(from: password, salt: saltData)
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
    var salt = Data(count: 32)
    _ = salt.withUnsafeMutableBytes { bytes in
      SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
    }
    return salt
  }

  // MARK: - String Encryption/Decryption

  public func encrypt(_ data: String) throws -> Data {
    guard let key = encryptionKey else {
      throw CryptoError.keyNotAvailable
    }

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
