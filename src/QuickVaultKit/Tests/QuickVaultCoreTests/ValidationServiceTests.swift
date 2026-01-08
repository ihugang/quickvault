//
//  ValidationServiceTests.swift
//  QuickVault Tests
//

import XCTest

@testable import QuickVault

final class ValidationServiceTests: XCTestCase {
  var validationService: ValidationService!

  override func setUp() {
    validationService = ValidationServiceImpl()
  }

  override func tearDown() {
    validationService = nil
  }

  // MARK: - Property 8: Phone Number Validation
  // Feature: quick-vault-macos, Property 8: Phone Number Validation

  func testValidChineseMobileNumbers() {
    // Valid Chinese mobile numbers (11 digits starting with 1)
    let validNumbers = [
      "13800138000",
      "13900139000",
      "15012345678",
      "18612345678",
      "17712345678",
    ]

    for number in validNumbers {
      XCTAssertTrue(
        validationService.validatePhoneNumber(number),
        "Should accept valid mobile number: \(number)")
    }
  }

  func testValidChineseLandlineNumbers() {
    // Valid Chinese landline numbers
    let validNumbers = [
      "010-12345678",  // Beijing
      "021-87654321",  // Shanghai
      "0755-12345678",  // Shenzhen
      "028-1234567",  // Chengdu (7 digits)
    ]

    for number in validNumbers {
      XCTAssertTrue(
        validationService.validatePhoneNumber(number),
        "Should accept valid landline number: \(number)")
    }
  }

  func testPhoneNumberWithSpaces() {
    // Should accept numbers with spaces
    XCTAssertTrue(validationService.validatePhoneNumber("138 0013 8000"))
    XCTAssertTrue(validationService.validatePhoneNumber("010 1234 5678"))
  }

  func testInvalidPhoneNumbers() {
    // Invalid phone numbers
    let invalidNumbers = [
      "12345",  // Too short
      "123",  // Too short
      "23800138000",  // Doesn't start with 1 (mobile)
      "00012345678",  // Invalid area code
      "abcdefghijk",  // Letters
      "",  // Empty
      "138001380001",  // Too long
    ]

    for number in invalidNumbers {
      XCTAssertFalse(
        validationService.validatePhoneNumber(number),
        "Should reject invalid phone number: \(number)")
    }
  }

  // MARK: - Property 11: Tax ID Validation
  // Feature: quick-vault-macos, Property 11: Tax ID Validation

  func testValidTaxIDs() {
    // Valid 18-character unified social credit codes
    let validTaxIDs = [
      "91110000MA01A1B2C3",
      "91310000MA02B3C4D5",
      "123456789012345678",
      "ABCDEFGHIJKLMNOPQR",
      "91110000600037341L",  // Real format example
    ]

    for taxID in validTaxIDs {
      XCTAssertTrue(
        validationService.validateTaxID(taxID),
        "Should accept valid tax ID: \(taxID)")
    }
  }

  func testTaxIDWithSeparators() {
    // Should accept tax IDs with separators
    XCTAssertTrue(validationService.validateTaxID("911100-00MA01A1B2C-3"))
    XCTAssertTrue(validationService.validateTaxID("91110000 MA01A1B2C3"))
  }

  func testInvalidTaxIDs() {
    // Invalid tax IDs
    let invalidTaxIDs = [
      "12345",  // Too short
      "1234567890123456789",  // Too long (19 chars)
      "91110000MA01A1B2",  // Too short (17 chars)
      "911100-00MA01A1B2C",  // Only 17 after removing separator
      "",  // Empty
      "91110000MA01A1B2C*",  // Special character
    ]

    for taxID in invalidTaxIDs {
      XCTAssertFalse(
        validationService.validateTaxID(taxID),
        "Should reject invalid tax ID: \(taxID)")
    }
  }

  // MARK: - Property 39: Required Field Validation
  // Feature: quick-vault-macos, Property 39: Required Field Validation

  func testRequiredFieldValidation() {
    // Valid non-empty field
    XCTAssertNoThrow(try validationService.validateRequiredField("Some value", fieldName: "Test"))
    XCTAssertNoThrow(
      try validationService.validateRequiredField("  Valid  ", fieldName: "Test"))
  }

  func testRequiredFieldEmpty() {
    // Empty field should throw
    XCTAssertThrowsError(try validationService.validateRequiredField("", fieldName: "姓名")) {
      error in
      guard let validationError = error as? ValidationError,
        case .requiredFieldEmpty(let fieldName) = validationError
      else {
        XCTFail("Expected ValidationError.requiredFieldEmpty")
        return
      }
      XCTAssertEqual(fieldName, "姓名")
    }
  }

  func testRequiredFieldWhitespaceOnly() {
    // Whitespace-only field should throw
    XCTAssertThrowsError(
      try validationService.validateRequiredField("   ", fieldName: "姓名")
    ) { error in
      XCTAssertTrue(error is ValidationError)
    }

    XCTAssertThrowsError(
      try validationService.validateRequiredField("\n\t", fieldName: "姓名")
    ) { error in
      XCTAssertTrue(error is ValidationError)
    }
  }

  // MARK: - Property 40: Password Minimum Length
  // Feature: quick-vault-macos, Property 40: Password Minimum Length

  func testPasswordMinimumLength() {
    // Valid passwords (8+ characters)
    XCTAssertNoThrow(try validationService.validatePasswordLength("12345678"))
    XCTAssertNoThrow(try validationService.validatePasswordLength("password123"))
    XCTAssertNoThrow(try validationService.validatePasswordLength("LongPassword!"))
  }

  func testPasswordTooShort() {
    // Passwords shorter than 8 characters should throw
    let shortPasswords = [
      "",
      "1",
      "12",
      "1234567",  // 7 characters
      "abc",
    ]

    for password in shortPasswords {
      XCTAssertThrowsError(try validationService.validatePasswordLength(password)) { error in
        guard let validationError = error as? ValidationError,
          case .passwordTooShort = validationError
        else {
          XCTFail("Expected ValidationError.passwordTooShort for password: \(password)")
          return
        }
      }
    }
  }

  // MARK: - Card Field Validation Integration Tests

  func testValidateAddressFields() {
    // Valid address fields
    let validFields: [String: String] = [
      "recipient": "张三",
      "phone": "13800138000",
      "province": "北京市",
      "city": "海淀区",
      "district": "中关村",
      "address": "科技大厦101室",
    ]

    XCTAssertNoThrow(
      try validationService.validateCardFields(validFields, for: AddressTemplate.fields))
  }

  func testValidateAddressWithOptionalFields() {
    // Address with optional fields filled
    let fields: [String: String] = [
      "recipient": "李四",
      "phone": "010-12345678",
      "province": "上海市",
      "city": "浦东新区",
      "district": "陆家嘴",
      "address": "金融大厦202室",
      "postalCode": "100080",
      "notes": "请在工作日送达",
    ]

    XCTAssertNoThrow(
      try validationService.validateCardFields(fields, for: AddressTemplate.fields))
  }

  func testValidateAddressMissingRequiredField() {
    // Missing required field (recipient)
    let invalidFields: [String: String] = [
      "phone": "13800138000",
      "province": "北京市",
      "city": "海淀区",
      "district": "中关村",
      "address": "科技大厦101室",
    ]

    XCTAssertThrowsError(
      try validationService.validateCardFields(invalidFields, for: AddressTemplate.fields)
    ) { error in
      guard let validationError = error as? ValidationError,
        case .requiredFieldEmpty = validationError
      else {
        XCTFail("Expected ValidationError.requiredFieldEmpty")
        return
      }
    }
  }

  func testValidateAddressInvalidPhone() {
    // Invalid phone number
    let invalidFields: [String: String] = [
      "recipient": "张三",
      "phone": "123",  // Invalid
      "province": "北京市",
      "city": "海淀区",
      "district": "中关村",
      "address": "科技大厦101室",
    ]

    XCTAssertThrowsError(
      try validationService.validateCardFields(invalidFields, for: AddressTemplate.fields)
    ) { error in
      guard let validationError = error as? ValidationError,
        case .invalidPhoneNumber = validationError
      else {
        XCTFail("Expected ValidationError.invalidPhoneNumber")
        return
      }
    }
  }

  func testValidateInvoiceFields() {
    // Valid invoice fields
    let validFields: [String: String] = [
      "companyName": "北京科技有限公司",
      "taxId": "91110000MA01A1B2C3",
      "address": "北京市朝阳区建国路1号",
      "phone": "010-12345678",
      "bankName": "中国工商银行北京分行",
      "bankAccount": "1234567890123456789",
    ]

    XCTAssertNoThrow(
      try validationService.validateCardFields(validFields, for: InvoiceTemplate.fields))
  }

  func testValidateInvoiceInvalidTaxID() {
    // Invalid tax ID
    let invalidFields: [String: String] = [
      "companyName": "北京科技有限公司",
      "taxId": "12345",  // Invalid - too short
      "address": "北京市朝阳区建国路1号",
      "phone": "010-12345678",
      "bankName": "中国工商银行北京分行",
      "bankAccount": "1234567890123456789",
    ]

    XCTAssertThrowsError(
      try validationService.validateCardFields(invalidFields, for: InvoiceTemplate.fields)
    ) { error in
      guard let validationError = error as? ValidationError,
        case .invalidTaxID = validationError
      else {
        XCTFail("Expected ValidationError.invalidTaxID")
        return
      }
    }
  }

  func testValidateGeneralTextField() {
    // General text - only content is required
    let validFields: [String: String] = [
      "content": "这是一段测试文本"
    ]

    XCTAssertNoThrow(
      try validationService.validateCardFields(validFields, for: GeneralTextTemplate.fields))
  }

  func testValidateGeneralTextEmpty() {
    // Empty content should fail
    let invalidFields: [String: String] = [:]

    XCTAssertThrowsError(
      try validationService.validateCardFields(invalidFields, for: GeneralTextTemplate.fields)
    ) { error in
      XCTAssertTrue(error is ValidationError)
    }
  }
}
