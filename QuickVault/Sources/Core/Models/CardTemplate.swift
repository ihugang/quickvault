//
//  CardTemplate.swift
//  QuickVault
//

import Foundation

// MARK: - Field Definition

/// Defines a single field in a card template
struct FieldDefinition {
  let key: String
  let label: String
  let required: Bool
  let multiline: Bool

  init(key: String, label: String, required: Bool = true, multiline: Bool = false) {
    self.key = key
    self.label = label
    self.required = required
    self.multiline = multiline
  }
}

// MARK: - Card Type

enum CardType: String, CaseIterable {
  case general
  case address
  case invoice
  case businessLicense
  case idCard

  var displayName: String {
    switch self {
    case .general: return "通用文本"
    case .address: return "地址"
    case .invoice: return "发票"
    case .businessLicense: return "营业执照"
    case .idCard: return "身份证"
    }
  }
}

// MARK: - Card Group

enum CardGroup: String, CaseIterable {
  case personal
  case company

  var displayName: String {
    switch self {
    case .personal: return "个人"
    case .company: return "公司"
    }
  }
}

// MARK: - Address Template

struct AddressTemplate {
  static let type: CardType = .address

  static let fields: [FieldDefinition] = [
    FieldDefinition(key: "recipient", label: "收件人", required: true),
    FieldDefinition(key: "phone", label: "手机号", required: true),
    FieldDefinition(key: "province", label: "省", required: true),
    FieldDefinition(key: "city", label: "市", required: true),
    FieldDefinition(key: "district", label: "区", required: true),
    FieldDefinition(key: "address", label: "详细地址", required: true),
    FieldDefinition(key: "postalCode", label: "邮编", required: false),
    FieldDefinition(key: "notes", label: "备注", required: false, multiline: true),
  ]

  /// Formats address fields for copying to clipboard
  /// - Parameter fieldValues: Dictionary of field keys to values
  /// - Returns: Formatted string with labels
  static func formatForCopy(fieldValues: [String: String]) -> String {
    let recipient = fieldValues["recipient"] ?? ""
    let phone = fieldValues["phone"] ?? ""
    let province = fieldValues["province"] ?? ""
    let city = fieldValues["city"] ?? ""
    let district = fieldValues["district"] ?? ""
    let address = fieldValues["address"] ?? ""
    let postalCode = fieldValues["postalCode"] ?? ""
    let notes = fieldValues["notes"] ?? ""

    var result = """
      收件人：\(recipient)
      手机号：\(phone)
      地址：\(province)\(city)\(district)\(address)
      """

    if !postalCode.isEmpty {
      result += "\n邮编：\(postalCode)"
    }

    if !notes.isEmpty {
      result += "\n备注：\(notes)"
    }

    return result
  }
}

// MARK: - Invoice Template

struct InvoiceTemplate {
  static let type: CardType = .invoice

  static let fields: [FieldDefinition] = [
    FieldDefinition(key: "companyName", label: "公司名称", required: true),
    FieldDefinition(key: "taxId", label: "税号", required: true),
    FieldDefinition(key: "address", label: "地址", required: true),
    FieldDefinition(key: "phone", label: "电话", required: true),
    FieldDefinition(key: "bankName", label: "开户行", required: true),
    FieldDefinition(key: "bankAccount", label: "银行账号", required: true),
    FieldDefinition(key: "notes", label: "备注", required: false, multiline: true),
  ]

  /// Formats invoice fields for copying to clipboard
  /// - Parameter fieldValues: Dictionary of field keys to values
  /// - Returns: Formatted string with labels
  static func formatForCopy(fieldValues: [String: String]) -> String {
    let companyName = fieldValues["companyName"] ?? ""
    let taxId = fieldValues["taxId"] ?? ""
    let address = fieldValues["address"] ?? ""
    let phone = fieldValues["phone"] ?? ""
    let bankName = fieldValues["bankName"] ?? ""
    let bankAccount = fieldValues["bankAccount"] ?? ""
    let notes = fieldValues["notes"] ?? ""

    var result = """
      公司名称：\(companyName)
      税号：\(taxId)
      地址：\(address)
      电话：\(phone)
      开户行：\(bankName)
      账号：\(bankAccount)
      """

    if !notes.isEmpty {
      result += "\n备注：\(notes)"
    }

    return result
  }
}

// MARK: - General Text Template

struct GeneralTextTemplate {
  static let type: CardType = .general

  static let fields: [FieldDefinition] = [
    FieldDefinition(key: "content", label: "内容", required: true, multiline: true)
  ]

  /// Formats general text for copying - returns content directly without labels
  /// - Parameter fieldValues: Dictionary of field keys to values
  /// - Returns: Raw content string
  static func formatForCopy(fieldValues: [String: String]) -> String {
    return fieldValues["content"] ?? ""
  }
}

// MARK: - Business License Template

struct BusinessLicenseTemplate {
  static let type: CardType = .businessLicense

  static let fields: [FieldDefinition] = [
    FieldDefinition(key: "companyName", label: "企业名称", required: true),
    FieldDefinition(key: "creditCode", label: "统一社会信用代码", required: true),
    FieldDefinition(key: "legalRepresentative", label: "法定代表人", required: true),
    FieldDefinition(key: "registeredCapital", label: "注册资本", required: true),
    FieldDefinition(key: "address", label: "住所", required: true),
    FieldDefinition(key: "establishedDate", label: "成立日期", required: true),
    FieldDefinition(key: "businessScope", label: "经营范围", required: false, multiline: true),
  ]

  static func formatForCopy(fieldValues: [String: String]) -> String {
    let companyName = fieldValues["companyName"] ?? ""
    let creditCode = fieldValues["creditCode"] ?? ""
    let legalRepresentative = fieldValues["legalRepresentative"] ?? ""
    let registeredCapital = fieldValues["registeredCapital"] ?? ""
    let address = fieldValues["address"] ?? ""
    let establishedDate = fieldValues["establishedDate"] ?? ""
    let businessScope = fieldValues["businessScope"] ?? ""

    var result = """
      企业名称：\(companyName)
      统一社会信用代码：\(creditCode)
      法定代表人：\(legalRepresentative)
      注册资本：\(registeredCapital)
      住所：\(address)
      成立日期：\(establishedDate)
      """

    if !businessScope.isEmpty {
      result += "\n经营范围：\(businessScope)"
    }

    return result
  }
}

// MARK: - ID Card Template

struct IdCardTemplate {
  static let type: CardType = .idCard

  static let fields: [FieldDefinition] = [
    FieldDefinition(key: "name", label: "姓名", required: true),
    FieldDefinition(key: "gender", label: "性别", required: true),
    FieldDefinition(key: "nationality", label: "民族", required: true),
    FieldDefinition(key: "birthDate", label: "出生日期", required: true),
    FieldDefinition(key: "idNumber", label: "身份证号", required: true),
    FieldDefinition(key: "address", label: "住址", required: true),
    FieldDefinition(key: "issuingAuthority", label: "签发机关", required: false),
    FieldDefinition(key: "validPeriod", label: "有效期", required: false),
  ]

  static func formatForCopy(fieldValues: [String: String]) -> String {
    let name = fieldValues["name"] ?? ""
    let gender = fieldValues["gender"] ?? ""
    let nationality = fieldValues["nationality"] ?? ""
    let birthDate = fieldValues["birthDate"] ?? ""
    let idNumber = fieldValues["idNumber"] ?? ""
    let address = fieldValues["address"] ?? ""
    let issuingAuthority = fieldValues["issuingAuthority"] ?? ""
    let validPeriod = fieldValues["validPeriod"] ?? ""

    var result = """
      姓名：\(name)
      性别：\(gender)
      民族：\(nationality)
      出生日期：\(birthDate)
      身份证号：\(idNumber)
      住址：\(address)
      """

    if !issuingAuthority.isEmpty {
      result += "\n签发机关：\(issuingAuthority)"
    }
    if !validPeriod.isEmpty {
      result += "\n有效期：\(validPeriod)"
    }

    return result
  }
}

// MARK: - Template Helper

struct CardTemplateHelper {
  /// Get field definitions for a card type
  static func fields(for type: CardType) -> [FieldDefinition] {
    switch type {
    case .general:
      return GeneralTextTemplate.fields
    case .address:
      return AddressTemplate.fields
    case .invoice:
      return InvoiceTemplate.fields
    case .businessLicense:
      return BusinessLicenseTemplate.fields
    case .idCard:
      return IdCardTemplate.fields
    }
  }

  /// Format field values for copying
  static func formatForCopy(type: CardType, fieldValues: [String: String]) -> String {
    switch type {
    case .general:
      return GeneralTextTemplate.formatForCopy(fieldValues: fieldValues)
    case .address:
      return AddressTemplate.formatForCopy(fieldValues: fieldValues)
    case .invoice:
      return InvoiceTemplate.formatForCopy(fieldValues: fieldValues)
    case .businessLicense:
      return BusinessLicenseTemplate.formatForCopy(fieldValues: fieldValues)
    case .idCard:
      return IdCardTemplate.formatForCopy(fieldValues: fieldValues)
    }
  }
}
