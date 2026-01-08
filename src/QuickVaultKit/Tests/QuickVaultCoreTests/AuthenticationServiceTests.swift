import XCTest

@testable import QuickVault

final class AuthenticationServiceTests: XCTestCase {

  var authService: AuthenticationServiceImpl!
  var keychainService: KeychainService!
  var cryptoService: CryptoService!

  override func setUp() {
    super.setUp()
    keychainService = KeychainServiceImpl()
    cryptoService = CryptoServiceImpl(keychainService: keychainService)
    authService = AuthenticationServiceImpl(
      keychainService: keychainService,
      cryptoService: cryptoService
    )

    // Clean up any existing test data
    try? keychainService.delete(key: "com.quickvault.masterPassword")
  }

  override func tearDown() {
    // Clean up test data
    try? keychainService.delete(key: "com.quickvault.masterPassword")
    UserDefaults.standard.removeObject(forKey: "com.quickvault.biometricEnabled")
    UserDefaults.standard.removeObject(forKey: "com.quickvault.failedAttempts")
    UserDefaults.standard.removeObject(forKey: "com.quickvault.lastFailedAttempt")
    super.tearDown()
  }

  // MARK: - Setup Tests

  func testSetupMasterPassword() async throws {
    // Test that master password can be set up
    let password = "testPassword123"

    try await authService.setupMasterPassword(password)

    XCTAssertEqual(authService.authenticationState, .unlocked)
    XCTAssertTrue(keychainService.exists(key: "com.quickvault.masterPassword"))
  }

  func testSetupMasterPasswordTooShort() async {
    // Test that short passwords are rejected
    let shortPassword = "short"

    do {
      try await authService.setupMasterPassword(shortPassword)
      XCTFail("Should have thrown passwordTooShort error")
    } catch AuthenticationError.passwordTooShort {
      // Expected
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testInitialStateSetupRequired() {
    // Test that initial state is setupRequired when no password exists
    let freshAuthService = AuthenticationServiceImpl(
      keychainService: keychainService,
      cryptoService: cryptoService
    )

    XCTAssertEqual(freshAuthService.authenticationState, .setupRequired)
  }

  func testInitialStateLocked() async throws {
    // Test that initial state is locked when password exists
    try await authService.setupMasterPassword("testPassword123")

    // Create new instance to simulate app restart
    let newAuthService = AuthenticationServiceImpl(
      keychainService: keychainService,
      cryptoService: cryptoService
    )

    XCTAssertEqual(newAuthService.authenticationState, .locked)
  }

  // MARK: - Authentication Tests

  func testAuthenticateWithCorrectPassword() async throws {
    // Setup password
    let password = "testPassword123"
    try await authService.setupMasterPassword(password)

    // Lock the system
    authService.lock()
    XCTAssertEqual(authService.authenticationState, .locked)

    // Authenticate with correct password
    try await authService.authenticateWithPassword(password)

    XCTAssertEqual(authService.authenticationState, .unlocked)
    XCTAssertFalse(authService.isLocked)
  }

  func testAuthenticateWithIncorrectPassword() async throws {
    // Setup password
    let password = "testPassword123"
    try await authService.setupMasterPassword(password)

    // Lock the system
    authService.lock()

    // Authenticate with incorrect password
    do {
      try await authService.authenticateWithPassword("wrongPassword")
      XCTFail("Should have thrown passwordIncorrect error")
    } catch AuthenticationError.passwordIncorrect {
      // Expected
      XCTAssertEqual(authService.authenticationState, .locked)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  // MARK: - Password Change Tests

  func testChangePassword() async throws {
    // Setup initial password
    let oldPassword = "oldPassword123"
    try await authService.setupMasterPassword(oldPassword)

    // Change password
    let newPassword = "newPassword456"
    try await authService.changePassword(oldPassword: oldPassword, newPassword: newPassword)

    // Lock and try to authenticate with new password
    authService.lock()
    try await authService.authenticateWithPassword(newPassword)

    XCTAssertEqual(authService.authenticationState, .unlocked)
  }

  func testChangePasswordWithIncorrectOldPassword() async throws {
    // Setup initial password
    let oldPassword = "oldPassword123"
    try await authService.setupMasterPassword(oldPassword)

    // Try to change password with incorrect old password
    do {
      try await authService.changePassword(
        oldPassword: "wrongPassword", newPassword: "newPassword456")
      XCTFail("Should have thrown passwordIncorrect error")
    } catch AuthenticationError.passwordIncorrect {
      // Expected
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testChangePasswordTooShort() async throws {
    // Setup initial password
    let oldPassword = "oldPassword123"
    try await authService.setupMasterPassword(oldPassword)

    // Try to change to a short password
    do {
      try await authService.changePassword(oldPassword: oldPassword, newPassword: "short")
      XCTFail("Should have thrown passwordTooShort error")
    } catch AuthenticationError.passwordTooShort {
      // Expected
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  // MARK: - Lock Tests

  func testLock() async throws {
    // Setup and unlock
    try await authService.setupMasterPassword("testPassword123")
    XCTAssertEqual(authService.authenticationState, .unlocked)

    // Lock
    authService.lock()

    XCTAssertEqual(authService.authenticationState, .locked)
    XCTAssertTrue(authService.isLocked)
  }

  // MARK: - Rate Limiting Tests

  func testRateLimitingAfterThreeFailedAttempts() async throws {
    // Setup password
    let password = "testPassword123"
    try await authService.setupMasterPassword(password)
    authService.lock()

    // Make 3 failed attempts
    for _ in 0..<3 {
      do {
        try await authService.authenticateWithPassword("wrongPassword")
      } catch {
        // Expected to fail
      }
    }

    // Fourth attempt should be rate limited
    do {
      try await authService.authenticateWithPassword("wrongPassword")
      XCTFail("Should have thrown rateLimited error")
    } catch AuthenticationError.rateLimited(let remainingSeconds) {
      // Expected
      XCTAssertGreaterThan(remainingSeconds, 0)
      XCTAssertLessThanOrEqual(remainingSeconds, 30)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testRateLimitingResetsAfterSuccessfulAuth() async throws {
    // Setup password
    let password = "testPassword123"
    try await authService.setupMasterPassword(password)
    authService.lock()

    // Make 2 failed attempts
    for _ in 0..<2 {
      do {
        try await authService.authenticateWithPassword("wrongPassword")
      } catch {
        // Expected to fail
      }
    }

    // Successful authentication should reset counter
    try await authService.authenticateWithPassword(password)
    authService.lock()

    // Should be able to make failed attempts again without immediate rate limiting
    do {
      try await authService.authenticateWithPassword("wrongPassword")
    } catch AuthenticationError.passwordIncorrect {
      // Expected - not rate limited
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  // MARK: - Biometric Tests

  func testBiometricAvailability() {
    // This test just checks that the method doesn't crash
    // Actual availability depends on hardware
    let isAvailable = authService.isBiometricAvailable()

    // On CI or machines without Touch ID, this will be false
    // On machines with Touch ID, this will be true
    XCTAssertNotNil(isAvailable)
  }

  func testEnableBiometric() throws {
    // Test enabling biometric
    try authService.enableBiometric(true)
    XCTAssertTrue(authService.isBiometricEnabled())

    // Test disabling biometric
    try authService.enableBiometric(false)
    XCTAssertFalse(authService.isBiometricEnabled())
  }

  // MARK: - State Publisher Tests

  func testAuthenticationStatePublisher() async throws {
    let expectation = XCTestExpectation(description: "State changes published")
    var receivedStates: [AuthenticationState] = []

    let cancellable = authService.authenticationStatePublisher
      .sink { state in
        receivedStates.append(state)
        if receivedStates.count == 3 {
          expectation.fulfill()
        }
      }

    // Setup password (setupRequired -> unlocked)
    try await authService.setupMasterPassword("testPassword123")

    // Lock (unlocked -> locked)
    authService.lock()

    await fulfillment(of: [expectation], timeout: 1.0)

    XCTAssertEqual(receivedStates.count, 3)
    XCTAssertEqual(receivedStates[0], .setupRequired)
    XCTAssertEqual(receivedStates[1], .unlocked)
    XCTAssertEqual(receivedStates[2], .locked)

    cancellable.cancel()
  }
}
