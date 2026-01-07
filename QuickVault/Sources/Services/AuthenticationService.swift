import Combine
import Foundation
import LocalAuthentication

// MARK: - Authentication Errors / 认证错误

enum AuthenticationError: LocalizedError {
  case biometricNotAvailable  // 生物识别不可用
  case biometricFailed  // 生物识别失败
  case passwordIncorrect  // 密码错误
  case passwordTooShort  // 密码太短
  case noPasswordSet  // 未设置密码
  case rateLimited(remainingSeconds: Int)  // 速率限制
  case keychainError(String)  // 钥匙串错误

  var errorDescription: String? {
    switch self {
    case .biometricNotAvailable:
      return "Touch ID is not available / 触控 ID 不可用"
    case .biometricFailed:
      return "Touch ID authentication failed / 触控 ID 认证失败"
    case .passwordIncorrect:
      return "Incorrect password / 密码错误"
    case .passwordTooShort:
      return "Password must be at least 8 characters / 密码必须至少 8 个字符"
    case .noPasswordSet:
      return "No master password set / 未设置主密码"
    case .rateLimited(let seconds):
      return "Too many failed attempts. Please wait \(seconds) seconds / 失败次数过多，请等待 \(seconds) 秒"
    case .keychainError(let message):
      return "Keychain error: \(message) / 钥匙串错误：\(message)"
    }
  }
}

// MARK: - Authentication State / 认证状态

enum AuthenticationState {
  case locked  // 锁定
  case unlocked  // 解锁
  case setupRequired  // 需要设置
}

// MARK: - Authentication Service Protocol / 认证服务协议

protocol AuthenticationService {
  var isLocked: Bool { get }
  var authenticationState: AuthenticationState { get }
  var authenticationStatePublisher: AnyPublisher<AuthenticationState, Never> { get }

  func setupMasterPassword(_ password: String) async throws
  func authenticateWithPassword(_ password: String) async throws
  func authenticateWithBiometric() async throws
  func changePassword(oldPassword: String, newPassword: String) async throws
  func lock()
  func isBiometricAvailable() -> Bool
  func enableBiometric(_ enabled: Bool) throws
  func isBiometricEnabled() -> Bool
}

// MARK: - Authentication Service Implementation / 认证服务实现

class AuthenticationServiceImpl: AuthenticationService {

  // MARK: - Properties

  private let keychainService: KeychainService
  private let cryptoService: CryptoService

  private let masterPasswordKey = "com.quickvault.masterPassword"
  private let biometricEnabledKey = "com.quickvault.biometricEnabled"
  private let failedAttemptsKey = "com.quickvault.failedAttempts"
  private let lastFailedAttemptKey = "com.quickvault.lastFailedAttempt"

  private let maxFailedAttempts = 3
  private let rateLimitDuration: TimeInterval = 30  // 30 seconds

  private let stateSubject = CurrentValueSubject<AuthenticationState, Never>(.locked)

  var isLocked: Bool {
    authenticationState == .locked
  }

  var authenticationState: AuthenticationState {
    stateSubject.value
  }

  var authenticationStatePublisher: AnyPublisher<AuthenticationState, Never> {
    stateSubject.eraseToAnyPublisher()
  }

  // MARK: - Initialization

  init(keychainService: KeychainService, cryptoService: CryptoService) {
    self.keychainService = keychainService
    self.cryptoService = cryptoService

    // Check if master password exists
    if keychainService.exists(forKey: masterPasswordKey) {
      stateSubject.send(.locked)
    } else {
      stateSubject.send(.setupRequired)
    }
  }

  // MARK: - Setup

  func setupMasterPassword(_ password: String) async throws {
    guard password.count >= 8 else {
      throw AuthenticationError.passwordTooShort
    }

    // Hash the password before storing
    let passwordHash = cryptoService.hashPassword(password)

    do {
      try keychainService.save(passwordHash, forKey: masterPasswordKey)
      stateSubject.send(.unlocked)
    } catch {
      throw AuthenticationError.keychainError(error.localizedDescription)
    }
  }

  // MARK: - Authentication

  func authenticateWithPassword(_ password: String) async throws {
    // Check rate limiting
    try checkRateLimit()

    guard keychainService.exists(forKey: masterPasswordKey) else {
      throw AuthenticationError.noPasswordSet
    }

    do {
      let storedHash = try keychainService.load(forKey: masterPasswordKey)
      let passwordHash = cryptoService.hashPassword(password)

      if passwordHash == storedHash {
        // Success - reset failed attempts
        resetFailedAttempts()
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

  func authenticateWithBiometric() async throws {
    guard isBiometricEnabled() else {
      throw AuthenticationError.biometricNotAvailable
    }

    let context = LAContext()
    var error: NSError?

    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
      throw AuthenticationError.biometricNotAvailable
    }

    do {
      let reason = "Authenticate to unlock QuickVault / 认证以解锁随取"
      let success = try await context.evaluatePolicy(
        .deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)

      if success {
        stateSubject.send(.unlocked)
      } else {
        throw AuthenticationError.biometricFailed
      }
    } catch {
      throw AuthenticationError.biometricFailed
    }
  }

  // MARK: - Password Management

  func changePassword(oldPassword: String, newPassword: String) async throws {
    // Verify old password first
    guard keychainService.exists(forKey: masterPasswordKey) else {
      throw AuthenticationError.noPasswordSet
    }

    let storedHash = try keychainService.load(forKey: masterPasswordKey)
    let oldPasswordHash = cryptoService.hashPassword(oldPassword)

    guard oldPasswordHash == storedHash else {
      throw AuthenticationError.passwordIncorrect
    }

    // Validate new password
    guard newPassword.count >= 8 else {
      throw AuthenticationError.passwordTooShort
    }

    // Save new password
    let newPasswordHash = cryptoService.hashPassword(newPassword)
    try keychainService.save(newPasswordHash, forKey: masterPasswordKey)
  }

  // MARK: - Lock Management

  func lock() {
    stateSubject.send(.locked)
  }

  // MARK: - Biometric Management

  func isBiometricAvailable() -> Bool {
    let context = LAContext()
    var error: NSError?
    return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
  }

  func enableBiometric(_ enabled: Bool) throws {
    UserDefaults.standard.set(enabled, forKey: biometricEnabledKey)
  }

  func isBiometricEnabled() -> Bool {
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
