import Combine
import CoreData
import CryptoKit
import Foundation
import LocalAuthentication
import os.log

private let authLogger = Logger(subsystem: "com.codans.quickhold", category: "AuthService")

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
  case passwordMismatchWithExistingData  // 密码与现有数据不匹配（多设备场景）
  case waitingForSync  // 等待 iCloud 同步

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
    case .passwordMismatchWithExistingData:
      return "auth.error.password.mismatch.existing.data"
    case .waitingForSync:
      return "auth.error.waiting.for.sync"
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
    case .passwordMismatchWithExistingData:
      return "Password does not match existing data from other devices. Please use the same password you set on your first device."
    case .waitingForSync:
      return "Waiting for iCloud sync... Please try again in a few moments."
    }
  }
}

// MARK: - Authentication State / 认证状态

public enum AuthenticationState {
  case initializing  // 初始化中（检查 iCloud 状态）
  case locked  // 锁定
  case unlocked  // 解锁
  case setupRequired  // 需要设置
  case waitingForCloudSync  // 等待 iCloud 同步（检测到云端有数据，等待 salt 同步）
}

// MARK: - Authentication Service Protocol / 认证服务协议

public protocol AuthenticationService {
  var isLocked: Bool { get }
  var authenticationState: AuthenticationState { get }
  var authenticationStatePublisher: AnyPublisher<AuthenticationState, Never> { get }

  func checkInitialState() async  // 检查初始状态（应在 App 启动时调用）
  func setupMasterPassword(_ password: String) async throws
  func authenticateWithPassword(_ password: String) async throws
  func authenticateWithBiometric() async throws
  func changePassword(oldPassword: String, newPassword: String) async throws
  func clearAllData(password: String) async throws  // 清除所有数据 / Clear all data
  func lock()
  func isBiometricAvailable() -> Bool
  func enableBiometric(_ enabled: Bool) throws
  func isBiometricEnabled() -> Bool
  func hasExistingCloudData() async -> Bool  // 检查是否有现有 iCloud 数据
  func validatePasswordWithExistingData(_ password: String) async -> Bool  // 验证密码是否能解密现有数据
}

// MARK: - Authentication Service Implementation / 认证服务实现

public class AuthenticationServiceImpl: AuthenticationService, @unchecked Sendable {

  // MARK: - Properties

  private let keychainService: KeychainService
  private let persistenceController: PersistenceController
  private var cryptoService: CryptoService {
    CryptoServiceImpl.shared
  }

  private let masterPasswordKey = QuickHoldConstants.KeychainKeys.masterPassword
  private let biometricPasswordKey = QuickHoldConstants.KeychainKeys.biometricPassword
  private let biometricEnabledKey = QuickHoldConstants.UserDefaultsKeys.biometricEnabled
  private let failedAttemptsKey = QuickHoldConstants.UserDefaultsKeys.failedAttempts
  private let lastFailedAttemptKey = QuickHoldConstants.UserDefaultsKeys.lastFailedAttempt

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

    authLogger.info("🔐 [AuthService] ========== AuthenticationService INIT ==========")

    // Check if master password and salt exist
    let hasPassword = keychainService.exists(key: masterPasswordKey)
    let hasSalt = keychainService.exists(key: QuickHoldConstants.KeychainKeys.cryptoSalt)

    authLogger.info("📊 [AuthService] hasPassword: \(hasPassword), hasSalt: \(hasSalt)")

    if hasPassword && hasSalt {
      // Both password and salt exist - normal initialized state
      authLogger.info("✅ [AuthService] Credentials found, setting state to .locked")
      stateSubject.send(.locked)
    } else if hasPassword && !hasSalt {
      // Password exists but salt missing - likely corrupted state or app update issue
      // Clear all Keychain data for clean re-initialization
      authLogger.warning("⚠️ [AuthService] INCONSISTENT STATE: Password exists but salt missing")
      authLogger.warning("💡 [AuthService] This could be due to:")
      authLogger.warning("   - App reinstall without iCloud Keychain restore")
      authLogger.warning("   - Keychain corruption")
      authLogger.warning("   - Incomplete initialization")
      authLogger.warning("🗑️ [AuthService] Clearing all Keychain data for fresh start")

      try? keychainService.delete(key: masterPasswordKey)
      try? keychainService.delete(key: biometricPasswordKey)
      try? keychainService.delete(key: QuickHoldConstants.KeychainKeys.cryptoSalt)
      stateSubject.send(.setupRequired)
    } else if !hasPassword && hasSalt {
      // Salt exists but password missing - unusual but possible in multi-device scenario
      // User needs to set up password (will use existing salt from iCloud)
      authLogger.warning("⚠️ [AuthService] Salt exists but password missing (multi-device scenario?)")
      authLogger.info("🔄 [AuthService] Setting state to .locked (will prompt for login)")
      stateSubject.send(.locked)
    } else {
      // Neither password nor salt exist - need to check iCloud for existing data
      // Don't immediately show setup screen, wait for checkInitialState() to be called
      authLogger.info("🔍 [AuthService] No local credentials found")
      authLogger.info("⏳ [AuthService] Setting state to .initializing (need to check iCloud status)")
      authLogger.info("💡 [AuthService] App should call checkInitialState() to determine next step")
      stateSubject.send(.initializing)
    }

    let stateDescription: String
    switch self.authenticationState {
    case .initializing:
      stateDescription = "initializing"
    case .locked:
      stateDescription = "locked"
    case .unlocked:
      stateDescription = "unlocked"
    case .setupRequired:
      stateDescription = "setupRequired"
    case .waitingForCloudSync:
      stateDescription = "waitingForCloudSync"
    }
    authLogger.info("📊 [AuthService] Initial state: \(stateDescription)")
    authLogger.info("✅ [AuthService] ========== AuthenticationService INIT COMPLETE ==========")
  }

  // MARK: - Initial State Check

  /// Check initial authentication state by querying iCloud data
  /// 检查初始认证状态（通过查询 iCloud 数据）
  /// Should be called on app launch after init
  /// 应该在 init 之后、App 启动时调用
  public func checkInitialState() async {
    authLogger.info("🔍 [AuthService] ========== checkInitialState START ==========")

    // Only check if we're in initializing state
    guard authenticationState == .initializing else {
      let currentState: String
      switch authenticationState {
      case .initializing: currentState = "initializing"
      case .locked: currentState = "locked"
      case .unlocked: currentState = "unlocked"
      case .setupRequired: currentState = "setupRequired"
      case .waitingForCloudSync: currentState = "waitingForCloudSync"
      }
      authLogger.info("ℹ️ [AuthService] State is not .initializing (current: \(currentState)), skipping check")
      authLogger.info("✅ [AuthService] ========== checkInitialState SKIPPED ==========")
      return
    }

    authLogger.info("☁️ [AuthService] Checking for existing data in iCloud CloudKit...")
    let hasCloudData = await hasExistingCloudData()
    authLogger.info("📊 [AuthService] hasCloudData: \(hasCloudData)")

    if hasCloudData {
      // Cloud data exists - this is a secondary device
      authLogger.info("🔍 [AuthService] MULTI-DEVICE SCENARIO: Found existing data in CloudKit")
      authLogger.info("💡 [AuthService] This device should sync with primary device")

      // Check if salt has already synced from iCloud Keychain
      let hasSalt = cryptoService.hasSalt()
      authLogger.info("🔑 [AuthService] Checking if salt has synced from iCloud Keychain...")
      authLogger.info("📊 [AuthService] hasSalt: \(hasSalt)")

      if hasSalt {
        // Salt already synced - user can login
        authLogger.info("✅ [AuthService] Salt already synced from iCloud Keychain")
        authLogger.info("🔓 [AuthService] Setting state to .locked (user can login with their password)")
        stateSubject.send(.locked)
      } else {
        // Salt not yet synced - need to wait
        authLogger.info("⏳ [AuthService] Salt not yet synced from iCloud Keychain")
        authLogger.info("⏱️ [AuthService] Setting state to .waitingForCloudSync")
        authLogger.info("💡 [AuthService] User should see a waiting screen")
        stateSubject.send(.waitingForCloudSync)

        // Attempt to wait for salt sync in background
        authLogger.info("🔄 [AuthService] Starting background task to wait for salt sync...")
        Task {
          do {
            try await waitForSaltSyncIfNeeded()
            authLogger.info("🎉 [AuthService] Salt synced successfully in background!")
            authLogger.info("🔓 [AuthService] Updating state to .locked")
            stateSubject.send(.locked)
          } catch {
            authLogger.error("❌ [AuthService] Salt sync timeout in background: \(error.localizedDescription)")
            authLogger.warning("⚠️ [AuthService] User may need to wait longer or check iCloud settings")
            // Keep state as .waitingForCloudSync, let user retry
          }
        }
      }
    } else {
      // No cloud data - this is the primary/first device
      authLogger.info("🆕 [AuthService] FIRST DEVICE SCENARIO: No existing data in CloudKit")
      authLogger.info("💡 [AuthService] This is the first device or a fresh start")
      authLogger.info("📝 [AuthService] Setting state to .setupRequired (user should set up password)")
      stateSubject.send(.setupRequired)
    }

    authLogger.info("✅ [AuthService] ========== checkInitialState COMPLETE ==========")
  }

  // MARK: - Setup

  public func setupMasterPassword(_ password: String) async throws {
    authLogger.info("🔐 [AuthService] ========== setupMasterPassword START ==========")
    authLogger.info("📊 [AuthService] Password length: \(password.count) characters")

    guard password.count >= 8 else {
      authLogger.warning("⚠️ [AuthService] Password too short (minimum 8 characters required)")
      throw AuthenticationError.passwordTooShort
    }

    // Check if there's existing data from other devices
    authLogger.info("☁️ [AuthService] Checking for existing CloudKit data...")
    let hasExistingData = await hasExistingCloudData()
    authLogger.info("📊 [AuthService] hasExistingCloudData = \(hasExistingData)")

    if hasExistingData {
      authLogger.info("🔍 [AuthService] MULTI-DEVICE SCENARIO: Detected existing data from other devices")

      // Wait for iCloud Keychain to deliver the existing salt to avoid generating a new one
      authLogger.info("⏳ [AuthService] Waiting for iCloud Keychain to sync salt from primary device...")
      try await waitForSaltSyncIfNeeded()
      authLogger.info("✅ [AuthService] Salt sync check completed")

      // Validate password against existing data
      authLogger.info("🔑 [AuthService] Validating password against existing encrypted data...")
      let isValid = await validatePasswordWithExistingData(password)
      if !isValid {
        authLogger.error("❌ [AuthService] Password validation FAILED - password does not match existing data")
        throw AuthenticationError.passwordMismatchWithExistingData
      }
      authLogger.info("✅ [AuthService] Password validated successfully against existing data")
    } else {
      authLogger.info("🆕 [AuthService] FIRST DEVICE SCENARIO: No existing data, setting up as primary device")
    }

    // Hash the password before storing
    authLogger.info("🔐 [AuthService] Hashing password with SHA-256...")
    let passwordHash = cryptoService.hashPassword(password)
    authLogger.debug("📊 [AuthService] Password hash length: \(passwordHash.count) characters")

    guard let passwordData = passwordHash.data(using: .utf8) else {
      authLogger.error("❌ [AuthService] Failed to encode password hash to UTF-8")
      throw AuthenticationError.keychainError("Failed to encode password hash")
    }

    do {
      // Password hash should NOT be synced to iCloud for security reasons
      // 密码哈希不应同步到 iCloud（安全考虑）
      authLogger.info("💾 [AuthService] Saving password hash to LOCAL keychain (synchronizable: false)")
      try keychainService.save(key: masterPasswordKey, data: passwordData, synchronizable: false)
      authLogger.info("✅ [AuthService] Master password hash saved to keychain")

      // Initialize encryption key with the password
      authLogger.info("🔑 [AuthService] Initializing encryption key (allowSaltGeneration: \(!hasExistingData))...")
      try cryptoService.initializeKey(
        password: password,
        salt: nil,
        allowSaltGeneration: !hasExistingData
      )
      authLogger.info("✅ [AuthService] Encryption key initialized successfully")

      // Store password for biometric authentication (if enabled later)
      authLogger.info("👆 [AuthService] Storing password for biometric authentication...")
      storeBiometricPassword(password)
      authLogger.info("✅ [AuthService] Biometric password stored")

      authLogger.info("🔓 [AuthService] Updating state to .unlocked")
      stateSubject.send(.unlocked)

      authLogger.info("✅ [AuthService] ========== setupMasterPassword SUCCESS ==========")
    } catch {
      authLogger.error("❌ [AuthService] Setup FAILED: \(error.localizedDescription)")
      authLogger.error("❌ [AuthService] ========== setupMasterPassword FAILED ==========")
      throw AuthenticationError.keychainError(error.localizedDescription)
    }
  }

  // MARK: - Authentication

  public func authenticateWithPassword(_ password: String) async throws {
    authLogger.info("🔐 [AuthService] ========== authenticateWithPassword START ==========")

    // Check rate limiting
    authLogger.info("🛡️ [AuthService] Checking rate limit...")
    try checkRateLimit()
    authLogger.info("✅ [AuthService] Rate limit check passed")

    authLogger.info("🔍 [AuthService] Checking if master password exists in keychain...")
    let hasStoredPassword = keychainService.exists(key: masterPasswordKey)
    authLogger.info("📊 [AuthService] hasStoredPassword: \(hasStoredPassword)")

    // Multi-device scenario: no stored password but has salt
    if !hasStoredPassword {
      authLogger.info("🌐 [AuthService] MULTI-DEVICE SCENARIO: No stored password, validating with existing data...")

      // Validate password by trying to decrypt existing data
      let isValid = await validatePasswordWithExistingData(password)

      if isValid {
        authLogger.info("🎉 [AuthService] Password validated successfully with existing data!")

        // Store the password hash for future use
        authLogger.info("💾 [AuthService] Storing password hash to keychain...")
        let passwordHash = cryptoService.hashPassword(password)
        try keychainService.save(key: masterPasswordKey, data: passwordHash.data(using: .utf8)!, synchronizable: false)
        authLogger.info("✅ [AuthService] Password hash stored successfully")

        // Initialize encryption key
        authLogger.info("🔑 [AuthService] Initializing encryption key...")
        try cryptoService.initializeKey(
          password: password,
          salt: nil,
          allowSaltGeneration: false
        )

        // Reset failed attempts
        authLogger.info("🔄 [AuthService] Resetting failed login attempts counter...")
        resetFailedAttempts()

        // Store password for biometric authentication
        authLogger.info("👆 [AuthService] Storing password for biometric authentication...")
        storeBiometricPassword(password)

        authLogger.info("🔓 [AuthService] Updating state to .unlocked")
        stateSubject.send(.unlocked)

        authLogger.info("✅ [AuthService] ========== authenticateWithPassword SUCCESS (MULTI-DEVICE) ==========")
        return
      } else {
        authLogger.warning("⚠️ [AuthService] Password validation FAILED with existing data")
        incrementFailedAttempts()
        authLogger.error("❌ [AuthService] ========== authenticateWithPassword FAILED - INCORRECT PASSWORD ==========")
        throw AuthenticationError.passwordIncorrect
      }
    }

    do {
      authLogger.info("📥 [AuthService] Loading stored password hash from keychain...")
      let storedHashData = try keychainService.load(key: masterPasswordKey)

      guard let storedHash = String(data: storedHashData, encoding: .utf8) else {
        authLogger.error("❌ [AuthService] Failed to decode stored password hash from UTF-8")
        throw AuthenticationError.keychainError("Failed to decode stored password hash")
      }
      authLogger.info("✅ [AuthService] Stored password hash loaded successfully")

      authLogger.info("🔐 [AuthService] Hashing provided password...")
      let passwordHash = cryptoService.hashPassword(password)

      authLogger.info("🔍 [AuthService] Comparing password hashes...")
      if passwordHash == storedHash {
        authLogger.info("🎉 [AuthService] Password hash MATCH! Authentication successful")

        // Success - initialize encryption key and reset failed attempts
        authLogger.info("⏳ [AuthService] Waiting for salt sync if needed...")
        try await waitForSaltSyncIfNeeded()

        authLogger.info("🔑 [AuthService] Initializing encryption key...")
        try cryptoService.initializeKey(
          password: password,
          salt: nil,
          allowSaltGeneration: false
        )

        authLogger.info("🔄 [AuthService] Resetting failed login attempts counter...")
        resetFailedAttempts()

        // Store password for biometric authentication
        authLogger.info("👆 [AuthService] Storing password for biometric authentication...")
        storeBiometricPassword(password)

        authLogger.info("🔓 [AuthService] Updating state to .unlocked")
        stateSubject.send(.unlocked)

        authLogger.info("✅ [AuthService] ========== authenticateWithPassword SUCCESS ==========")
      } else {
        authLogger.warning("⚠️ [AuthService] Password hash MISMATCH! Authentication failed")
        // Failed - increment failed attempts
        incrementFailedAttempts()
        authLogger.error("❌ [AuthService] ========== authenticateWithPassword FAILED - INCORRECT PASSWORD ==========")
        throw AuthenticationError.passwordIncorrect
      }
    } catch let error as AuthenticationError {
      authLogger.error("❌ [AuthService] AuthenticationError: \(error.localizedDescription)")
      throw error
    } catch let cryptoError as CryptoError {
      if case .keyNotAvailable = cryptoError {
        authLogger.error("❌ [AuthService] CryptoError: Salt not available, waiting for iCloud sync")
        throw AuthenticationError.waitingForSync
      }
      authLogger.error("❌ [AuthService] CryptoError: \(cryptoError.localizedDescription)")
      throw AuthenticationError.keychainError(cryptoError.localizedDescription)
    } catch {
      authLogger.error("❌ [AuthService] Unexpected error: \(error.localizedDescription)")
      throw AuthenticationError.keychainError(error.localizedDescription)
    }
  }

  public func authenticateWithBiometric() async throws {
    authLogger.info("👆 [AuthService] ========== authenticateWithBiometric START ==========")
    authLogger.info("📊 [AuthService] isBiometricEnabled: \(self.isBiometricEnabled())")

    guard isBiometricEnabled() else {
      authLogger.warning("⚠️ [AuthService] Biometric authentication not enabled by user")
      authLogger.error("❌ [AuthService] ========== authenticateWithBiometric - NOT ENABLED ==========")
      throw AuthenticationError.biometricNotAvailable
    }
    authLogger.info("✅ [AuthService] Biometric authentication is enabled")

    authLogger.info("📱 [AuthService] Creating LAContext for biometric evaluation...")
    let context = LAContext()
    var error: NSError?

    authLogger.info("🔍 [AuthService] Checking if device supports biometric authentication...")
    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
      authLogger.error("❌ [AuthService] Device cannot evaluate biometric policy: \(error?.localizedDescription ?? "unknown")")
      authLogger.error("❌ [AuthService] ========== authenticateWithBiometric - DEVICE NOT SUPPORTED ==========")
      throw AuthenticationError.biometricNotAvailable
    }
    authLogger.info("✅ [AuthService] Device supports biometric authentication")

    do {
      let reason = "Authenticate to unlock QuickHold / 认证以解锁随取"
      authLogger.info("👆 [AuthService] Requesting biometric authentication from user...")
      authLogger.debug("📊 [AuthService] Reason: \(reason)")

      let success = try await context.evaluatePolicy(
        .deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)

      if success {
        authLogger.info("🎉 [AuthService] Biometric authentication succeeded!")

        // Load the stored password and initialize encryption key
        authLogger.info("🔍 [AuthService] Checking if biometric password exists in keychain...")
        let biometricKeyExists = keychainService.exists(key: biometricPasswordKey)
        authLogger.info("📊 [AuthService] Biometric password key exists: \(biometricKeyExists)")

        guard let passwordData = try? keychainService.load(key: biometricPasswordKey),
              let password = String(data: passwordData, encoding: .utf8) else {
          authLogger.error("❌ [AuthService] Failed to load biometric password from keychain")
          authLogger.error("💡 [AuthService] User needs to authenticate with password first to enable biometric")
          authLogger.error("❌ [AuthService] ========== authenticateWithBiometric - PASSWORD NOT STORED ==========")
          // Password not stored - user needs to authenticate with password first
          // This can happen if biometric was enabled before password was stored
          throw AuthenticationError.biometricPasswordNotStored
        }
        authLogger.info("✅ [AuthService] Biometric password loaded from keychain")

        authLogger.info("⏳ [AuthService] Waiting for salt sync if needed...")
        try await waitForSaltSyncIfNeeded()

        authLogger.info("🔑 [AuthService] Initializing encryption key with biometric password...")
        try cryptoService.initializeKey(
          password: password,
          salt: nil,
          allowSaltGeneration: false
        )
        authLogger.info("✅ [AuthService] Encryption key initialized via biometric authentication")

        authLogger.info("🔓 [AuthService] Updating state to .unlocked")
        stateSubject.send(.unlocked)

        authLogger.info("✅ [AuthService] ========== authenticateWithBiometric SUCCESS ==========")
      } else {
        authLogger.warning("⚠️ [AuthService] Biometric authentication returned false (user cancelled?)")
        authLogger.error("❌ [AuthService] ========== authenticateWithBiometric FAILED - USER CANCELLED ==========")
        throw AuthenticationError.biometricFailed
      }
    } catch let authError as AuthenticationError {
      authLogger.error("❌ [AuthService] AuthenticationError: \(authError.localizedDescription)")
      throw authError
    } catch let cryptoError as CryptoError {
      if case .keyNotAvailable = cryptoError {
        authLogger.error("❌ [AuthService] CryptoError: Salt not available during biometric auth")
        authLogger.error("💡 [AuthService] Waiting for iCloud Keychain sync...")
        throw AuthenticationError.waitingForSync
      }
      authLogger.error("❌ [AuthService] CryptoError: \(cryptoError.localizedDescription)")
      throw AuthenticationError.keychainError(cryptoError.localizedDescription)
    } catch {
      authLogger.error("❌ [AuthService] Biometric authentication failed with error: \(error.localizedDescription)")
      authLogger.error("❌ [AuthService] ========== authenticateWithBiometric ERROR ==========")
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
    try cryptoService.initializeKey(
      password: newPassword,
      salt: nil,
      allowSaltGeneration: false
    )
    authLogger.info("[AuthService] Updated encryption key with new password")

    // Save new password
    let newPasswordHash = cryptoService.hashPassword(newPassword)
    guard let newPasswordData = newPasswordHash.data(using: .utf8) else {
      throw AuthenticationError.keychainError("Failed to encode new password hash")
    }
    // Password hash should NOT be synced to iCloud for security reasons
    // 密码哈希不应同步到 iCloud（安全考虑）
    try keychainService.save(key: masterPasswordKey, data: newPasswordData, synchronizable: false)
    
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

    try await context.perform { [cryptoService] in
      // 1. Delete all files from filesystem
      let itemRequest = Item.fetchRequest()
      let items = try context.fetch(itemRequest)

      let fileStorageManager = FileStorageManager(cryptoService: cryptoService, storageLocation: .local)
      
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
    try? keychainService.delete(key: QuickHoldConstants.KeychainKeys.cryptoSalt)
    
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
    
    try await context.perform { [weak self] in
      guard let self = self else { return }
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
      // Biometric password should NOT be synced to iCloud for security reasons
      // 生物识别密码不应同步到 iCloud（安全考虑）
      try keychainService.save(key: biometricPasswordKey, data: passwordData, synchronizable: false)
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

  // MARK: - iCloud Keychain Sync Helpers

  /// Wait for iCloud Keychain to deliver the shared salt before generating a new one
  private func waitForSaltSyncIfNeeded() async throws {
    authLogger.info("⏳ [AuthService] ========== waitForSaltSyncIfNeeded START ==========")

    authLogger.info("🔍 [AuthService] Checking if salt already exists locally...")
    if cryptoService.hasSalt() {
      authLogger.info("✅ [AuthService] Salt already exists in local keychain, no wait needed")
      authLogger.info("✅ [AuthService] ========== waitForSaltSyncIfNeeded - IMMEDIATE RETURN ==========")
      return
    }

    authLogger.warning("⚠️ [AuthService] Salt NOT found locally, waiting for iCloud Keychain sync...")
    let delays: [UInt64] = [1, 2, 3, 4]
    var attempt = 0

    for delay in delays {
      attempt += 1
      authLogger.info("⏱️ [AuthService] Attempt \(attempt)/\(delays.count): Waiting \(delay) second(s)...")
      try? await Task.sleep(nanoseconds: delay * 1_000_000_000)

      authLogger.info("🔍 [AuthService] Checking if salt has synced...")
      if cryptoService.hasSalt() {
        authLogger.info("🎉 [AuthService] SUCCESS! Salt received from iCloud Keychain after \(attempt) attempt(s)")
        authLogger.info("✅ [AuthService] ========== waitForSaltSyncIfNeeded SUCCESS ==========")
        return
      }
      authLogger.warning("⚠️ [AuthService] Salt still not available after attempt \(attempt)")
    }

    authLogger.error("❌ [AuthService] TIMEOUT: Failed to receive salt after \(delays.count) attempts (total ~10 seconds)")
    authLogger.error("💡 [AuthService] Possible reasons:")
    authLogger.error("   - iCloud Keychain is disabled on this device")
    authLogger.error("   - Primary device hasn't synced salt to iCloud yet")
    authLogger.error("   - Network connectivity issues")
    authLogger.error("   - User signed out of iCloud")
    authLogger.error("❌ [AuthService] ========== waitForSaltSyncIfNeeded TIMEOUT ==========")
    throw AuthenticationError.waitingForSync
  }

  // MARK: - Multi-Device Support / 多设备支持

  /// Check if there is existing data in iCloud
  /// 检查 iCloud 中是否有现有数据
  public func hasExistingCloudData() async -> Bool {
    authLogger.info("☁️ [AuthService] Checking for existing CloudKit data via PersistenceController...")
    let hasData = await persistenceController.hasExistingData()
    authLogger.info("📊 [AuthService] CloudKit data check result: \(hasData)")
    return hasData
  }

  /// Validate if the password can decrypt existing data
  /// 验证密码是否能解密现有数据
  public func validatePasswordWithExistingData(_ password: String) async -> Bool {
    authLogger.info("🔍 [AuthService] ========== validatePasswordWithExistingData START ==========")

    // Check if there's any encrypted data to validate against
    authLogger.info("📊 [AuthService] Checking if there's existing data to validate against...")
    let hasData = await hasExistingCloudData()
    guard hasData else {
      authLogger.info("ℹ️ [AuthService] No existing data found, skipping validation (returning true)")
      authLogger.info("✅ [AuthService] ========== validatePasswordWithExistingData - NO DATA ==========")
      return true  // No data means password is valid
    }

    // Try to initialize crypto service with the password
    do {
      authLogger.info("🔑 [AuthService] Attempting to initialize crypto key with provided password...")
      try cryptoService.initializeKey(
        password: password,
        salt: nil,
        allowSaltGeneration: false
      )
      authLogger.info("✅ [AuthService] Crypto key initialized successfully")

      // Try to fetch and decrypt a sample item
      authLogger.info("📥 [AuthService] Fetching sample item from CoreData...")
      let context = persistenceController.viewContext
      let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Item")
      fetchRequest.fetchLimit = 1

      guard let items = try? context.fetch(fetchRequest) as? [NSManagedObject],
            let item = items.first else {
        authLogger.warning("⚠️ [AuthService] No items found in CoreData to validate against")
        authLogger.info("✅ [AuthService] ========== validatePasswordWithExistingData - NO ITEMS ==========")
        return true
      }

      authLogger.info("📊 [AuthService] Found item to validate, attempting to decrypt...")

      // Try to decrypt text content if available
      if let textContentSet = item.value(forKey: "textContent") as? NSSet,
         let textContent = textContentSet.allObjects.first as? NSManagedObject,
         let encryptedData = textContent.value(forKey: "encryptedContent") as? Data {
        authLogger.info("🔐 [AuthService] Found text content, attempting decryption (data length: \(encryptedData.count) bytes)...")
        do {
          _ = try cryptoService.decrypt(encryptedData)
          authLogger.info("🎉 [AuthService] Decryption SUCCESS! Password is valid")
          authLogger.info("✅ [AuthService] ========== validatePasswordWithExistingData SUCCESS ==========")
          return true
        } catch {
          authLogger.error("❌ [AuthService] Decryption FAILED: \(error.localizedDescription)")
          authLogger.error("💡 [AuthService] This means the password does not match the one used on the primary device")
          authLogger.error("❌ [AuthService] ========== validatePasswordWithExistingData FAILED ==========")
          return false
        }
      }

      // If no text content, try image content
      if let imageContentSet = item.value(forKey: "images") as? NSSet,
         let imageContent = imageContentSet.allObjects.first as? NSManagedObject,
         let encryptedData = imageContent.value(forKey: "encryptedData") as? Data {
        authLogger.info("🖼️ [AuthService] Found image content, attempting decryption (data length: \(encryptedData.count) bytes)...")
        do {
          _ = try cryptoService.decryptFile(encryptedData)
          authLogger.info("🎉 [AuthService] Image decryption SUCCESS! Password is valid")
          authLogger.info("✅ [AuthService] ========== validatePasswordWithExistingData SUCCESS ==========")
          return true
        } catch {
          authLogger.error("❌ [AuthService] Image decryption FAILED: \(error.localizedDescription)")
          authLogger.error("💡 [AuthService] This means the password does not match the one used on the primary device")
          authLogger.error("❌ [AuthService] ========== validatePasswordWithExistingData FAILED ==========")
          return false
        }
      }

      authLogger.warning("⚠️ [AuthService] No encrypted content found to validate (item has no text/image content)")
      authLogger.info("✅ [AuthService] ========== validatePasswordWithExistingData - NO CONTENT ==========")
      return true

    } catch CryptoError.keyNotAvailable {
      authLogger.error("❌ [AuthService] Salt not available while validating password")
      authLogger.error("💡 [AuthService] This likely means iCloud Keychain sync hasn't completed")
      authLogger.error("❌ [AuthService] ========== validatePasswordWithExistingData - SALT ERROR ==========")
      return false
    } catch {
      authLogger.error("❌ [AuthService] Password validation failed with error: \(error.localizedDescription)")
      authLogger.error("❌ [AuthService] ========== validatePasswordWithExistingData ERROR ==========")
      return false
    }
  }
}
