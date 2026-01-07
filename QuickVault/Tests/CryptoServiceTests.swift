//
//  CryptoServiceTests.swift
//  QuickVault Tests
//

import XCTest

@testable import QuickVault

final class CryptoServiceTests: XCTestCase {
  var cryptoService: CryptoServiceImpl!
  let testPassword = "TestPassword123!"

  override func setUpWithError() throws {
    let keychainService = KeychainServiceImpl(service: "com.quickvault.test.crypto")
    cryptoService = CryptoServiceImpl(keychainService: keychainService)

    let salt = cryptoService.generateSalt()
    try cryptoService.initializeKey(password: testPassword, salt: salt)
  }

  override func tearDownWithError() throws {
    cryptoService = nil
  }

  // MARK: - Property 21: Field Encryption Round Trip
  // Feature: quick-vault-macos, Property 21: Field Encryption Round Trip

  func testEncryptionRoundTrip() throws {
    // Test with various strings
    let testStrings = [
      "Simple text",
      "中文测试",
      "Emoji 😀🎉",
      "Multi\nLine\nText",
      "Special chars: !@#$%^&*()",
      "",
    ]

    for originalString in testStrings {
      // When
      let encrypted = try cryptoService.encrypt(originalString)
      let decrypted = try cryptoService.decrypt(encrypted)

      // Then
      XCTAssertEqual(originalString, decrypted, "Round trip failed for: \(originalString)")
      XCTAssertNotEqual(originalString.data(using: .utf8), encrypted, "Data should be encrypted")
    }
  }

  // MARK: - Property 22: Key Derivation Determinism
  // Feature: quick-vault-macos, Property 22: Key Derivation Determinism

  func testKeyDerivationDeterminism() throws {
    // Given
    let password = "TestPassword"
    let salt = cryptoService.generateSalt()

    // When
    let key1 = try cryptoService.deriveKey(from: password, salt: salt)
    let key2 = try cryptoService.deriveKey(from: password, salt: salt)

    // Then
    XCTAssertEqual(
      key1.withUnsafeBytes { Data($0) },
      key2.withUnsafeBytes { Data($0) },
      "Same password and salt should produce identical keys")
  }

  // MARK: - Property 41: Attachment File Encryption
  // Feature: quick-vault-macos, Property 41: Attachment File Encryption

  func testFileEncryptionRoundTrip() throws {
    // Given - create test file data
    let testData = Data("Test file content 测试文件内容".utf8)

    // When
    let encrypted = try cryptoService.encryptFile(testData)
    let decrypted = try cryptoService.decryptFile(encrypted)

    // Then
    XCTAssertEqual(testData, decrypted, "File round trip should preserve data")
    XCTAssertNotEqual(testData, encrypted, "File data should be encrypted")
  }

  func testEncryptionWithoutKey() throws {
    // Given
    let uninitializedService = CryptoServiceImpl(
      keychainService: KeychainServiceImpl(service: "com.quickvault.test.nokey")
    )

    // When/Then
    XCTAssertThrowsError(try uninitializedService.encrypt("test")) { error in
      XCTAssertTrue(error is CryptoError)
      if case CryptoError.keyNotAvailable = error {
        // Expected
      } else {
        XCTFail("Expected CryptoError.keyNotAvailable")
      }
    }
  }

  func testSaltGeneration() {
    // When
    let salt1 = cryptoService.generateSalt()
    let salt2 = cryptoService.generateSalt()

    // Then
    XCTAssertEqual(salt1.count, 32, "Salt should be 32 bytes")
    XCTAssertEqual(salt2.count, 32, "Salt should be 32 bytes")
    XCTAssertNotEqual(salt1, salt2, "Each salt should be unique")
  }

  func testDifferentPasswordsProduceDifferentKeys() throws {
    // Given
    let salt = cryptoService.generateSalt()

    // When
    let key1 = try cryptoService.deriveKey(from: "password1", salt: salt)
    let key2 = try cryptoService.deriveKey(from: "password2", salt: salt)

    // Then
    XCTAssertNotEqual(
      key1.withUnsafeBytes { Data($0) },
      key2.withUnsafeBytes { Data($0) },
      "Different passwords should produce different keys")
  }

  func testDifferentSaltsProduceDifferentKeys() throws {
    // Given
    let password = "TestPassword"
    let salt1 = cryptoService.generateSalt()
    let salt2 = cryptoService.generateSalt()

    // When
    let key1 = try cryptoService.deriveKey(from: password, salt: salt1)
    let key2 = try cryptoService.deriveKey(from: password, salt: salt2)

    // Then
    XCTAssertNotEqual(
      key1.withUnsafeBytes { Data($0) },
      key2.withUnsafeBytes { Data($0) },
      "Different salts should produce different keys")
  }
}
