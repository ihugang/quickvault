//
//  KeychainServiceTests.swift
//  QuickHold Tests
//

import XCTest

@testable import QuickHold

final class KeychainServiceTests: XCTestCase {
  var keychainService: KeychainService!
  let testKey = "test.key.quickhold"

  override func setUpWithError() throws {
    keychainService = KeychainServiceImpl(service: "com.QuickHold.test")
    // Clean up any existing test data
    try? keychainService.delete(key: testKey)
  }

  override func tearDownWithError() throws {
    // Clean up test data
    try? keychainService.delete(key: testKey)
    keychainService = nil
  }

  func testSaveAndLoad() throws {
    // Given
    let testData = "Test Data 测试数据".data(using: .utf8)!

    // When
    try keychainService.save(key: testKey, data: testData)
    let loadedData = try keychainService.load(key: testKey)

    // Then
    XCTAssertEqual(testData, loadedData)
  }

  func testExists() throws {
    // Given
    let testData = "Test Data".data(using: .utf8)!

    // When - before save
    XCTAssertFalse(keychainService.exists(key: testKey))

    // When - after save
    try keychainService.save(key: testKey, data: testData)

    // Then
    XCTAssertTrue(keychainService.exists(key: testKey))
  }

  func testDelete() throws {
    // Given
    let testData = "Test Data".data(using: .utf8)!
    try keychainService.save(key: testKey, data: testData)
    XCTAssertTrue(keychainService.exists(key: testKey))

    // When
    try keychainService.delete(key: testKey)

    // Then
    XCTAssertFalse(keychainService.exists(key: testKey))
  }

  func testLoadNonExistentKey() throws {
    // When/Then
    XCTAssertThrowsError(try keychainService.load(key: "nonexistent.key")) { error in
      XCTAssertTrue(error is KeychainError)
      if case KeychainError.itemNotFound = error {
        // Expected error
      } else {
        XCTFail("Expected KeychainError.itemNotFound")
      }
    }
  }

  func testOverwriteExistingKey() throws {
    // Given
    let firstData = "First Data".data(using: .utf8)!
    let secondData = "Second Data".data(using: .utf8)!

    // When
    try keychainService.save(key: testKey, data: firstData)
    try keychainService.save(key: testKey, data: secondData)
    let loadedData = try keychainService.load(key: testKey)

    // Then
    XCTAssertEqual(secondData, loadedData)
    XCTAssertNotEqual(firstData, loadedData)
  }
}
