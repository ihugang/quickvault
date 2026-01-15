//
//  ValidationService.swift
//  QuickHold
//

import Foundation

// MARK: - Validation Errors

public enum ValidationError: LocalizedError {
  case invalidPhoneNumber  // 无效的电话号码
  case invalidTaxID  // 无效的税号
  case requiredFieldEmpty(fieldName: String)  // 必填字段为空
  case passwordTooShort  // 密码太短
  case invalidFieldValue(fieldName: String, reason: String)  // 无效的字段值

  public var errorDescription: String? {
    switch self {
    case .invalidPhoneNumber:
      return "无效的电话号码格式 / Invalid phone number format"
    case .invalidTaxID:
      return "无效的税号格式 / Invalid tax ID format"
    case .requiredFieldEmpty(let fieldName):
      return "\(fieldName) 不能为空 / \(fieldName) cannot be empty"
    case .passwordTooShort:
      return "密码至少需要 8 个字符 / Password must be at least 8 characters"
    case .invalidFieldValue(let fieldName, let reason):
      return "\(fieldName) 无效: \(reason) / \(fieldName) invalid: \(reason)"
    }
  }
}

// MARK: - Validation Service Protocol

public protocol ValidationService {
  /// Validate Chinese phone number (mobile or landline)
  /// 验证中国电话号码(手机或座机)
  func validatePhoneNumber(_ phone: String) -> Bool

  /// Validate Chinese unified social credit code (税号)
  /// 验证中国统一社会信用代码(税号)
  func validateTaxID(_ taxID: String) -> Bool

  /// Validate required field is not empty
  /// 验证必填字段不为空
  func validateRequiredField(_ value: String, fieldName: String) throws

  /// Validate password minimum length (8 characters)
  /// 验证密码最小长度(8个字符)
  func validatePasswordLength(_ password: String) throws

  /// Validate all fields for a card type
  /// 验证卡片类型的所有字段
  func validateCardFields(_ fields: [String: String], for template: [FieldDefinition]) throws
}

// MARK: - Validation Service Implementation

public class ValidationServiceImpl: ValidationService {

  public init() {}

  // MARK: - Phone Number Validation

  /// Validates Chinese phone numbers
  /// Supports:
  /// - Mobile: 11 digits starting with 1 (e.g., 13800138000)
  /// - Landline: 3-4 digit area code + 7-8 digit number (e.g., 010-12345678)
  public func validatePhoneNumber(_ phone: String) -> Bool {
    // Remove common separators
    let cleaned = phone.replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: "-", with: "")
      .replacingOccurrences(of: "(", with: "")
      .replacingOccurrences(of: ")", with: "")

    // Mobile pattern: 11 digits starting with 1
    let mobilePattern = "^1\\d{10}$"
    if let mobileRegex = try? NSRegularExpression(pattern: mobilePattern),
      mobileRegex.firstMatch(
        in: cleaned,
        range: NSRange(cleaned.startIndex..., in: cleaned)) != nil
    {
      return true
    }

    // Landline pattern: 0 + 2-3 digit area code (10-999) + 7-8 digit number
    // Examples: 010-12345678, 0755-1234567
    // Total length: 11-12 digits (0 + 2-3 area code + 7-8 number)
    let landlinePattern = "^0[1-9]\\d{1,2}\\d{7,8}$"
    if let landlineRegex = try? NSRegularExpression(pattern: landlinePattern),
      landlineRegex.firstMatch(
        in: cleaned,
        range: NSRange(cleaned.startIndex..., in: cleaned)) != nil
    {
      return true
    }

    return false
  }

  // MARK: - Tax ID Validation

  /// Validates Chinese Unified Social Credit Code (统一社会信用代码)
  /// Must be 18 characters (alphanumeric)
  /// Format: XXXXXX-XXXXXXXXX-X or XXXXXXXXXXXXXXXXXX
  public func validateTaxID(_ taxID: String) -> Bool {
    // Remove common separators
    let cleaned = taxID.replacingOccurrences(of: "-", with: "")
      .replacingOccurrences(of: " ", with: "")

    // Must be exactly 18 alphanumeric characters
    guard cleaned.count == 18 else {
      return false
    }

    // Check if all characters are alphanumeric
    let alphanumericPattern = "^[A-Z0-9]{18}$"
    guard let regex = try? NSRegularExpression(pattern: alphanumericPattern),
      regex.firstMatch(
        in: cleaned.uppercased(),
        range: NSRange(cleaned.startIndex..., in: cleaned)) != nil
    else {
      return false
    }

    return true
  }

  // MARK: - Required Field Validation

  public func validateRequiredField(_ value: String, fieldName: String) throws {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      throw ValidationError.requiredFieldEmpty(fieldName: fieldName)
    }
  }

  // MARK: - Password Validation

  public func validatePasswordLength(_ password: String) throws {
    if password.count < 8 {
      throw ValidationError.passwordTooShort
    }
  }

  // MARK: - Card Field Validation

  public func validateCardFields(_ fields: [String: String], for template: [FieldDefinition]) throws {
    for fieldDef in template {
      let value = fields[fieldDef.key] ?? ""

      // Check required fields
      if fieldDef.required {
        try validateRequiredField(value, fieldName: fieldDef.label)
      }

      // Skip validation for empty optional fields
      if value.isEmpty && !fieldDef.required {
        continue
      }

      // Field-specific validation
      switch fieldDef.key {
      case "phone":
        if !validatePhoneNumber(value) {
          throw ValidationError.invalidPhoneNumber
        }

      case "taxId":
        if !validateTaxID(value) {
          throw ValidationError.invalidTaxID
        }

      default:
        // No specific validation for other fields
        break
      }
    }
  }
}
