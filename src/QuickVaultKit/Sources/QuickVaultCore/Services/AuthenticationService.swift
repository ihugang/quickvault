import Combine
import CoreData
import CryptoKit
import Foundation
import LocalAuthentication
import os.log

private let authLogger = Logger(subsystem: "com.quickvault", category: "AuthService")

// MARK: - Authentication Errors / 认证错误

public enum AuthenticationError: LocalizedError {
  case biometricNotAvailable  // 生物识别不可用
  case biometricFailed  // 生物识别失败
  case biometricPasswordNotStored  // 生物识别密码未存储，需要先用密码登录
  case passwordIncorrect  // 密码错误
  case passwordTooShort  // 密码太短
  case noPasswordSet  // 未设置密码
  case rateLimited(remainingSeconds: Int)  // 速率限制
  case keychainError(String)  // 钥匙串错误

  public var localizationKey: String {
    switch self {
    case .biometricNotAvailable:
      return "auth.error.biometric.unavailable"
    case .biometricFailed:
      return "auth.error.biometric.failed"
    case .biometricPasswordNotStored:
      return "auth.error.biometric.password.not.stored"
    case .passwordIncorrect:
      return "auth.error.password.incorrect"
    case .passwordTooShort:
      return "auth.error.password.too.short"
    case .noPasswordSet:
      return "auth.error.no.password"
    case .rateLimited:
      return "auth.error.rate.limited"
    case .keychainError:
      return "auth.error.keychain"
    }
  }
  
  public var errorDescription: String? {
    let languageCode = UserDefaults.standard.string(forKey: "app_language") ?? "en"
    if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
       let bundle = Bundle(path: path) {
      switch self {
      case .rateLimited(let seconds):
        let format = bundle.localizedString(forKey: localizationKey, value: nil, table: nil)
        return String(format: format, seconds)
      case .keychainError(let message):
        let format = bundle.localizedString(forKey: localizationKey, value: nil, table: nil)
        return String(format: format, message)
      default:
        return bundle.localizedString(forKey: localizationKey, value: nil, table: nil)
      }
    }
    // Fallback to English
    switch self {
    case .biometricNotAvailable:
      return "Touch ID is not available"
    case .biometricFailed:
      return "Touch ID authentication failed"
    case .biometricPasswordNotStored:
      return "Please login with password first to enable Touch ID"
    case .passwordIncorrect:
      return "Incorrect password"
    case .passwordTooShort:
      return "Password must be at least 8 characters"
    case .noPasswordSet:
      return "No master password set"
    case .rateLimited(let seconds):
      return "Too many failed attempts. Please wait \(seconds) seconds"
    case .keychainError(let message):
      return "Keychain error: \(message)"
    }
  }
}

// MARK: - Authentication State / 认证状态

public enum AuthenticationState {
  case locked  // 锁定
  case unlocked  // 解锁
  case setupRequired  // 需要设置
}

// MARK: - Authentication Service Protocol / 认证服务协议

public protocol AuthenticationService {
  var isLocked: Bool { get }
  var authenticationState: AuthenticationState { get }
  var authenticationStatePublisher: AnyPublisher<AuthenticationState, Never> { get }

  func setupMasterPassword(_ password: String) async throws
  func authenticateWithPassword(_ password: String) async throws
  func authenticateWithBiometric() async throws
  func changePassword(oldPassword: String, newPassword: String) async throws
  func clearAllData(password: String) async throws  // 清除所有数据 / Clear all data
  func lock()
  func isBiometricAvailable() -> Bool
  func enableBiometric(_ enabled: Bool) throws
  func isBiometricEnabled() -> Bool
}

// MARK: - Authentication Service Implementation / 认证服务实现

public class AuthenticationServiceImpl: AuthenticationService {

  // MARK: - Properties

  private let keychainService: KeychainService
  private let persistenceController: PersistenceController
  private var cryptoService: CryptoService {
    CryptoServiceImpl.shared
  }

  private let masterPasswordKey = "com.quickvault.masterPassword"
  private let biometricPasswordKey = "com.quickvault.biometricPassword"
  private let biometricEnabledKey = "com.quickvault.biometricEnabled"
  private let failedAttemptsKey = "com.quickvault.failedAttempts"
  private let lastFailedAttemptKey = "com.quickvault.lastFailedAttempt"

  private let maxFailedAttempts = 3
  private let rateLimitDuration: TimeInterval = 30  // 30 seconds

  private let stateSubject = CurrentValueSubject<AuthenticationState, Never>(.locked)

  public var isLocked: Bool {
    authenticationState == .locked
  }

  public var authenticationState: AuthenticationState {
    stateSubject.value
  }

  public var authenticationStatePublisher: AnyPublisher<AuthenticationState, Never> {
    stateSubject.eraseToAnyPublisher()
  }

  // MARK: - Initialization

  public init(keychainService: KeychainService, persistenceController: PersistenceController, cryptoService: CryptoService? = nil) {
    self.keychainService = keychainService
    self.persistenceController = persistenceController

    // Check if master password exists
    if keychainService.exists(key: masterPasswordKey) {
      stateSubject.send(.locked)
    } else {
      stateSubject.send(.setupRequired)
    }
  }

  // MARK: - Setup

  public func setupMasterPassword(_ password: String) async throws {
    authLogger.info("[AuthService] setupMasterPassword called")
    guard password.count >= 8 else {
      authLogger.warning("[AuthService] Password too short")
      throw AuthenticationError.passwordTooShort
    }

    // Hash the password before storing
    let passwordHash = cryptoService.hashPassword(password)
    guard let passwordData = passwordHash.data(using: .utf8) else {
      throw AuthenticationError.keychainError("Failed to encode password hash")
    }

    do {
      try keychainService.save(key: masterPasswordKey, data: passwordData)
      authLogger.info("[AuthService] Master password saved to keychain")
      
      // Initialize encryption key with the password
      try cryptoService.initializeKey(password: password, salt: nil)
      authLogger.info("[AuthService] Encryption key initialized")
      
      // Store password for biometric authentication (if enabled later)
      storeBiometricPassword(password)
      authLogger.info("[AuthService] Biometric password stored")
      
      stateSubject.send(.unlocked)
    } catch {
      authLogger.error("[AuthService] Setup failed: \(error.localizedDescription)")
      throw AuthenticationError.keychainError(error.localizedDescription)
    }
  }

  // MARK: - Authentication

  public func authenticateWithPassword(_ password: String) async throws {
    authLogger.info("[AuthService] authenticateWithPassword called")
    // Check rate limiting
    try checkRateLimit()

    guard keychainService.exists(key: masterPasswordKey) else {
      throw AuthenticationError.noPasswordSet
    }

    do {
      let storedHashData = try keychainService.load(key: masterPasswordKey)
      guard let storedHash = String(data: storedHashData, encoding: .utf8) else {
        throw AuthenticationError.keychainError("Failed to decode stored password hash")
      }

      let passwordHash = cryptoService.hashPassword(password)

      if passwordHash == storedHash {
        // Success - initialize encryption key and reset failed attempts
        try cryptoService.initializeKey(password: password, salt: nil)
        resetFailedAttempts()
        // Store password for biometric authentication
        storeBiometricPassword(password)
        stateSubject.send(.unlocked)
      } else {
        // Failed - increment failed attempts
        incrementFailedAttempts()
        throw AuthenticationError.passwordIncorrect
      }
    } catch let error as AuthenticationError {
      throw error
    } catch {
      throw AuthenticationError.keychainError(error.localizedDescription)
    }
  }

  public func authenticateWithBiometric() async throws {
    authLogger.info("[AuthService] authenticateWithBiometric called")
    authLogger.debug("[AuthService] isBiometricEnabled: \(self.isBiometricEnabled())")
    
    guard isBiometricEnabled() else {
      authLogger.warning("[AuthService] Biometric not enabled")
      throw AuthenticationError.biometricNotAvailable
    }

    let context = LAContext()
    var error: NSError?

    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
      authLogger.error("[AuthService] Cannot evaluate biometric policy: \(error?.localizedDescription ?? "unknown")")
      throw AuthenticationError.biometricNotAvailable
    }

    do {
      let reason = "Authenticate to unlock QuickVault / 认证以解锁随取"
      let success = try await context.evaluatePolicy(
        .deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)

      if success {
        authLogger.info("[AuthService] Biometric authentication succeeded")
        // Load the stored password and initialize encryption key
        let biometricKeyExists = keychainService.exists(key: biometricPasswordKey)
        authLogger.debug("[AuthService] Biometric password key exists: \(biometricKeyExists)")
        
        guard let passwordData = try? keychainService.load(key: biometricPasswordKey),
              let password = String(data: passwordData, encoding: .utf8) else {
          authLogger.error("[AuthService] Failed to load biometric password from keychain")
          // Password not stored - user needs to authenticate with password first
          // This can happen if biometric was enabled before password was stored
          throw AuthenticationError.biometricPasswordNotStored
        }
        authLogger.debug("[AuthService] Biometric password loaded, initializing key...")
        try cryptoService.initializeKey(password: password, salt: nil)
        authLogger.info("[AuthService] Encryption key initialized via biometric")
        stateSubject.send(.unlocked)
      } else {
        authLogger.warning("[AuthService] Biometric authentication returned false")
        throw AuthenticationError.biometricFailed
      }
    } catch let authError as AuthenticationError {
      authLogger.error("[AuthService] Auth error: \(authError.localizedDescription)")
      throw authError
    } catch {
      authLogger.error("[AuthService] Biometric failed with error: \(error.localizedDescription)")
      throw AuthenticationError.biometricFailed
    }
  }

  // MARK: - Password Management

  public func changePassword(oldPassword: String, newPassword: String) async throws {
    // Verify old password first
    guard keychainService.exists(key: masterPasswordKey) else {
      throw AuthenticationError.noPasswordSet
    }

    let storedHashData = try keychainService.load(key: masterPasswordKey)
    guard let storedHash = String(data: storedHashData, encoding: .utf8) else {
      throw AuthenticationError.keychainError("Failed to decode stored password hash")
    }

    let oldPasswordHash = cryptoService.hashPassword(oldPassword)

    guard oldPasswordHash == storedHash else {
      throw AuthenticationError.passwordIncorrect
    }

    // Validate new password
    guard newPassword.count >= 8 else {
      throw AuthenticationError.passwordTooShort
    }

    // CRITICAL: Re-encrypt all data with new password
    // This must be done before changing the password in keychain
    try await reencryptAllData(oldPassword: oldPassword, newPassword: newPassword)
    
    // CRITICAL: Update the encryption key in CryptoService to use new password
    // 重要：更新 CryptoService 中的加密密钥以使用新密码
    try cryptoService.initializeKey(password: newPassword, salt: nil)
    authLogger.info("[AuthService] Updated encryption key with new password")

    // Save new password
    let newPasswordHash = cryptoService.hashPassword(newPassword)
    guard let newPasswordData = newPasswordHash.data(using: .utf8) else {
      throw AuthenticationError.keychainError("Failed to encode new password hash")
    }
    try keychainService.save(key: masterPasswordKey, data: newPasswordData)
    
    // Update stored password for biometric authentication
    storeBiometricPassword(newPassword)
  }
  
  /// 清除所有数据（包括 CoreData 和文件系统中的文件）
  /// Clear all data (including CoreData and files in filesystem)
  /// ⚠️ 此操作不可逆！/ This operation is irreversible!
  public func clearAllData(password: String) async throws {
    // Verify password first
    guard keychainService.exists(key: masterPasswordKey) else {
      throw AuthenticationError.noPasswordSet
    }
    
    let storedHashData = try keychainService.load(key: masterPasswordKey)
    guard let storedHash = String(data: storedHashData, encoding: .utf8) else {
      throw AuthenticationError.keychainError("Failed to decode stored password hash")
    }
    
    let passwordHash = cryptoService.hashPassword(password)
    guard passwordHash == storedHash else {
      throw AuthenticationError.passwordIncorrect
    }
    
    authLogger.warning("[AuthService] ⚠️ Starting to clear ALL data...")
    
    let context = persistenceController.container.viewContext
    
    try await context.perform {
      // 1. Delete all files from filesystem
      let itemRequest = Item.fetchRequest()
      let items = try context.fetch(itemRequest)
      
      let fileStorageManager = FileStorageManager(cryptoService: self.cryptoService, storageLocation: .local)
      
      for item in items {
        if let fileSet = item.files {
          for case let fileContent as FileContent in fileSet {
            if let relativePath = fileContent.fileURL {
              try? fileStorageManager.deleteFile(relativePath: relativePath)
            }
          }
        }
      }
      
      // 2. Delete all CoreData entities
      let deleteRequest = NSBatchDeleteRequest(fetchRequest: Item.fetchRequest())
      try context.execute(deleteRequest)
      try context.save()
      
      authLogger.info("[AuthService] Deleted all items from CoreData")
    }
    
    // 3. Delete all keychain data
    try? keychainService.delete(key: masterPasswordKey)
    try? keychainService.delete(key: biometricPasswordKey)
    try? keychainService.delete(key: "crypto.salt")
    
    // 4. Clear encryption key from CryptoService
    cryptoService.clearKey()
    
    // 5. Clear UserDefaults
    UserDefaults.standard.removeObject(forKey: biometricEnabledKey)
    UserDefaults.standard.removeObject(forKey: failedAttemptsKey)
    UserDefaults.standard.removeObject(forKey: lastFailedAttemptKey)
    
    authLogger.warning("[AuthService] ✅ All data cleared successfully")
    
    // 6. Update state to setupRequired
    stateSubject.send(.setupRequired)
  }
  
  /// Re-encrypt all encrypted data with new password
  /// 使用新密码重新加密所有数据
  private func reencryptAllData(oldPassword: String, newPassword: String) async throws {
    authLogger.info("[AuthService] Starting data re-encryption...")
    
    // Get salt for key derivation
    let saltData = try cryptoService.getSalt()
    
    // Create crypto services with old and new keys
    let oldKey = try cryptoService.deriveKey(from: oldPassword, salt: saltData)
    let newKey = try cryptoService.deriveKey(from: newPassword, salt: saltData)
    
    // Re-encrypt all Items in CoreData
    let context = persistenceController.container.viewContext
    
    try await context.perform {
      // Fetch all items
      let itemRequest = Item.fetchRequest()
      let items = try context.fetch(itemRequest)
      
      authLogger.info("[AuthService] Re-encrypting \(items.count) items...")
      
      for item in items {
        // Re-encrypt TextContent
        if let textContent = item.textContent,
           let encryptedData = textContent.encryptedContent {
          // Decrypt with old key
          let decryptedData = try self.decryptData(encryptedData, using: oldKey)
          // Encrypt with new key
          let reencryptedData = try self.encryptData(decryptedData, using: newKey)
          textContent.encryptedContent = reencryptedData
        }
        
        // Re-encrypt ImageContent
        if let imageSet = item.images {
          for case let imageContent as ImageContent in imageSet {
            if let encryptedData = imageContent.encryptedData {
              let decryptedData = try self.decryptData(encryptedData, using: oldKey)
              let reencryptedData = try self.encryptData(decryptedData, using: newKey)
              imageContent.encryptedData = reencryptedData
            }
            if let thumbnailData = imageContent.thumbnailData {
              let decryptedData = try self.decryptData(thumbnailData, using: oldKey)
              let reencryptedData = try self.encryptData(decryptedData, using: newKey)
              imageContent.thumbnailData = reencryptedData
            }
          }
        }
        
        // Re-encrypt FileContent (files are stored in filesystem)
        if let fileSet = item.files {
          for case let fileContent as FileContent in fileSet {
            // Files are stored encrypted in filesystem
            // Each file is encrypted with AES-GCM using current password
            if let relativePath = fileContent.fileURL {
              // Create temporary FileStorageManager instances
              // oldStorageManager uses old password's key
              // newStorageManager uses new password's key
              let fileStorageManager = FileStorageManager(cryptoService: self.cryptoService, storageLocation: .local)
              let fullURL = try fileStorageManager.getFileURL(relativePath: relativePath)
              
              // Read encrypted file data directly from disk
              let encryptedFileData = try Data(contentsOf: fullURL)
              
              // Decrypt with old key, then re-encrypt with new key
              let decryptedFileData = try self.decryptData(encryptedFileData, using: oldKey)
              let reencryptedFileData = try self.encryptData(decryptedFileData, using: newKey)
              
              // Write back encrypted file
              try reencryptedFileData.write(to: fullURL, options: .atomic)
            }
            
            // Re-encrypt thumbnail (stored in CoreData)
            if let thumbnailData = fileContent.thumbnailData {
              let decryptedData = try self.decryptData(thumbnailData, using: oldKey)
              let reencryptedData = try self.encryptData(decryptedData, using: newKey)
              fileContent.thumbnailData = reencryptedData
            }
          }
        }
      }
      
      // Save all changes
      try context.save()
      authLogger.info("[AuthService] Successfully re-encrypted all data")
    }
  }
  
  /// Decrypt data using specific key (helper for re-encryption)
  private func decryptData(_ data: Data, using key: SymmetricKey) throws -> Data {
    let sealedBox = try AES.GCM.SealedBox(combined: data)
    return try AES.GCM.open(sealedBox, using: key)
  }
  
  /// Encrypt data using specific key (helper for re-encryption)
  private func encryptData(_ data: Data, using key: SymmetricKey) throws -> Data {
    let sealedBox = try AES.GCM.seal(data, using: key)
    guard let combined = sealedBox.combined else {
      throw AuthenticationError.keychainError("Encryption failed")
    }
    return combined
  }

  // MARK: - Lock Management

  public func lock() {
    cryptoService.clearKey()
    stateSubject.send(.locked)
    authLogger.info("[AuthService] App locked and encryption key cleared")
  }

  // MARK: - Biometric Management

  public func isBiometricAvailable() -> Bool {
    let context = LAContext()
    var error: NSError?
    return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
  }

  public func enableBiometric(_ enabled: Bool) throws {
    UserDefaults.standard.set(enabled, forKey: biometricEnabledKey)
    
    // If disabling biometric, remove the stored password
    if !enabled {
      try? keychainService.delete(key: biometricPasswordKey)
    }
  }
  
  /// Store password for biometric authentication (called after successful password auth)
  /// Always store the password so it's available when biometric is enabled later
  private func storeBiometricPassword(_ password: String) {
    authLogger.debug("[AuthService] storeBiometricPassword called")
    guard let passwordData = password.data(using: .utf8) else {
      authLogger.error("[AuthService] Failed to encode password for biometric storage")
      return
    }
    do {
      try keychainService.save(key: biometricPasswordKey, data: passwordData)
      authLogger.info("[AuthService] Biometric password stored successfully")
    } catch {
      authLogger.error("[AuthService] Failed to store biometric password: \(error.localizedDescription)")
    }
  }

  public func isBiometricEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: biometricEnabledKey)
  }

  // MARK: - Rate Limiting

  private func checkRateLimit() throws {
    let failedAttempts = UserDefaults.standard.integer(forKey: failedAttemptsKey)

    guard failedAttempts >= maxFailedAttempts else {
      return
    }

    let lastFailedAttempt = UserDefaults.standard.double(forKey: lastFailedAttemptKey)
    let timeSinceLastAttempt = Date().timeIntervalSince1970 - lastFailedAttempt

    if timeSinceLastAttempt < rateLimitDuration {
      let remainingSeconds = Int(rateLimitDuration - timeSinceLastAttempt)
      throw AuthenticationError.rateLimited(remainingSeconds: remainingSeconds)
    } else {
      // Rate limit expired, reset counter
      resetFailedAttempts()
    }
  }

  private func incrementFailedAttempts() {
    let currentAttempts = UserDefaults.standard.integer(forKey: failedAttemptsKey)
    UserDefaults.standard.set(currentAttempts + 1, forKey: failedAttemptsKey)
    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastFailedAttemptKey)
  }

  private func resetFailedAttempts() {
    UserDefaults.standard.set(0, forKey: failedAttemptsKey)
    UserDefaults.standard.set(0, forKey: lastFailedAttemptKey)
  }
}
