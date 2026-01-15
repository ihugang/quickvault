//
//  CardTemplate.swift
//  QuickHold
//

import Foundation

// MARK: - Field Definition

/// Defines a single field in a card template
public struct FieldDefinition: Sendable {
  public let key: String
  public let label: String
  public let required: Bool
  public let multiline: Bool

  public init(key: String, label: String, required: Bool = true, multiline: Bool = false) {
    self.key = key
    self.label = label
    self.required = required
    self.multiline = multiline
  }
}

// MARK: - Card Type

public enum CardType: String, CaseIterable, Sendable, Identifiable {
  case general
  case address
  case invoice
  case businessLicense
  case idCard
  case passport
  case driversLicense
  case residencePermit
  case socialSecurityCard
  case bankCard

  public var displayName: String {
    switch self {
    case .general: return "通用文本 / General Text"
    case .address: return "地址 / Address"
    case .invoice: return "发票 / Invoice"
    case .businessLicense: return "营业执照 / Business License"
    case .idCard: return "身份证 / ID Card"
    case .passport: return "护照 / Passport"
    case .driversLicense: return "驾照 / Driver's License"
    case .residencePermit: return "居留卡 / Residence Permit"
    case .socialSecurityCard: return "社保卡 / Social Security Card"
    case .bankCard: return "银行卡 / Bank Card"
    }
  }

  public var id: String {
    rawValue
  }
  
  public var group: CardGroup {
    switch self {
    case .general, .address, .idCard, .passport, .driversLicense, 
         .residencePermit, .socialSecurityCard, .bankCard:
      return .personal
    case .invoice, .businessLicense:
      return .company
    }
  }
}

// MARK: - Card Group

public enum CardGroup: String, CaseIterable {
  case personal
  case company

  public var displayName: String {
    switch self {
    case .personal: return "个人"
    case .company: return "公司"
    }
  }
}

// MARK: - Address Template

public struct AddressTemplate {
  public static let type: CardType = .address

  public static let fields: [FieldDefinition] = [
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
  public static func formatForCopy(fieldValues: [String: String]) -> String {
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

public struct InvoiceTemplate {
  public static let type: CardType = .invoice

  public static let fields: [FieldDefinition] = [
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
  public static func formatForCopy(fieldValues: [String: String]) -> String {
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

public struct GeneralTextTemplate {
  public static let type: CardType = .general

  public static let fields: [FieldDefinition] = [
    FieldDefinition(key: "content", label: "内容", required: true, multiline: true)
  ]

  /// Formats general text for copying - returns content directly without labels
  /// - Parameter fieldValues: Dictionary of field keys to values
  /// - Returns: Raw content string
  public static func formatForCopy(fieldValues: [String: String]) -> String {
    return fieldValues["content"] ?? ""
  }
}

// MARK: - Business License Template

public struct BusinessLicenseTemplate {
  public static let type: CardType = .businessLicense

  public static let fields: [FieldDefinition] = [
    FieldDefinition(key: "companyName", label: "企业名称", required: true),
    FieldDefinition(key: "creditCode", label: "统一社会信用代码", required: true),
    FieldDefinition(key: "legalRepresentative", label: "法定代表人", required: true),
    FieldDefinition(key: "registeredCapital", label: "注册资本", required: true),
    FieldDefinition(key: "address", label: "住所", required: true),
    FieldDefinition(key: "establishedDate", label: "成立日期", required: true),
    FieldDefinition(key: "businessScope", label: "经营范围", required: false, multiline: true),
  ]

  public static func formatForCopy(fieldValues: [String: String]) -> String {
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

public struct IdCardTemplate {
  public static let type: CardType = .idCard

  public static let fields: [FieldDefinition] = [
    FieldDefinition(key: "name", label: "姓名", required: true),
    FieldDefinition(key: "gender", label: "性别", required: true),
    FieldDefinition(key: "nationality", label: "民族", required: true),
    FieldDefinition(key: "birthDate", label: "出生日期", required: true),
    FieldDefinition(key: "idNumber", label: "身份证号", required: true),
    FieldDefinition(key: "address", label: "住址", required: true),
    FieldDefinition(key: "issuingAuthority", label: "签发机关", required: false),
    FieldDefinition(key: "validPeriod", label: "有效期", required: false),
  ]

  public static func formatForCopy(fieldValues: [String: String]) -> String {
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

// MARK: - Passport Template

public struct PassportTemplate {
  public static let type: CardType = .passport

  public static let fields: [FieldDefinition] = [
    FieldDefinition(key: "name", label: "姓名 / Name", required: true),
    FieldDefinition(key: "passportNumber", label: "护照号 / Passport No.", required: true),
    FieldDefinition(key: "nationality", label: "国籍 / Nationality", required: true),
    FieldDefinition(key: "gender", label: "性别 / Gender", required: true),
    FieldDefinition(key: "birthDate", label: "出生日期 / Date of Birth", required: true),
    FieldDefinition(key: "birthPlace", label: "出生地 / Place of Birth", required: false),
    FieldDefinition(key: "issueDate", label: "签发日期 / Issue Date", required: false),
    FieldDefinition(key: "expiryDate", label: "有效期至 / Expiry Date", required: false),
    FieldDefinition(key: "issuer", label: "签发机关 / Issuing Authority", required: false),
  ]

  public static func formatForCopy(fieldValues: [String: String]) -> String {
    let name = fieldValues["name"] ?? ""
    let passportNumber = fieldValues["passportNumber"] ?? ""
    let nationality = fieldValues["nationality"] ?? ""
    let gender = fieldValues["gender"] ?? ""
    let birthDate = fieldValues["birthDate"] ?? ""
    let birthPlace = fieldValues["birthPlace"] ?? ""
    let issueDate = fieldValues["issueDate"] ?? ""
    let expiryDate = fieldValues["expiryDate"] ?? ""
    let issuer = fieldValues["issuer"] ?? ""

    var result = """
      姓名：\(name)
      护照号：\(passportNumber)
      国籍：\(nationality)
      性别：\(gender)
      出生日期：\(birthDate)
      """

    if !birthPlace.isEmpty {
      result += "\n出生地：\(birthPlace)"
    }
    if !issueDate.isEmpty {
      result += "\n签发日期：\(issueDate)"
    }
    if !expiryDate.isEmpty {
      result += "\n有效期至：\(expiryDate)"
    }
    if !issuer.isEmpty {
      result += "\n签发机关：\(issuer)"
    }

    return result
  }
}

// MARK: - Driver's License Template

public struct DriversLicenseTemplate {
  public static let type: CardType = .driversLicense

  public static let fields: [FieldDefinition] = [
    FieldDefinition(key: "name", label: "姓名 / Name", required: true),
    FieldDefinition(key: "licenseNumber", label: "证号 / License No.", required: true),
    FieldDefinition(key: "gender", label: "性别 / Gender", required: true),
    FieldDefinition(key: "nationality", label: "国籍 / Nationality", required: false),
    FieldDefinition(key: "birthDate", label: "出生日期 / Date of Birth", required: true),
    FieldDefinition(key: "address", label: "住址 / Address", required: false),
    FieldDefinition(key: "issueDate", label: "初次领证日期 / Issue Date", required: false),
    FieldDefinition(key: "validFrom", label: "有效起始日期 / Valid From", required: false),
    FieldDefinition(key: "validUntil", label: "有效期限 / Valid Until", required: false),
    FieldDefinition(key: "licenseClass", label: "准驾车型 / License Class", required: false),
  ]

  public static func formatForCopy(fieldValues: [String: String]) -> String {
    let name = fieldValues["name"] ?? ""
    let licenseNumber = fieldValues["licenseNumber"] ?? ""
    let gender = fieldValues["gender"] ?? ""
    let nationality = fieldValues["nationality"] ?? ""
    let birthDate = fieldValues["birthDate"] ?? ""
    let address = fieldValues["address"] ?? ""
    let issueDate = fieldValues["issueDate"] ?? ""
    let validFrom = fieldValues["validFrom"] ?? ""
    let validUntil = fieldValues["validUntil"] ?? ""
    let licenseClass = fieldValues["licenseClass"] ?? ""

    var result = """
      姓名：\(name)
      证号：\(licenseNumber)
      性别：\(gender)
      出生日期：\(birthDate)
      """

    if !nationality.isEmpty {
      result += "\n国籍：\(nationality)"
    }
    if !address.isEmpty {
      result += "\n住址：\(address)"
    }
    if !issueDate.isEmpty {
      result += "\n初次领证日期：\(issueDate)"
    }
    if !validFrom.isEmpty {
      result += "\n有效起始：\(validFrom)"
    }
    if !validUntil.isEmpty {
      result += "\n有效期限：\(validUntil)"
    }
    if !licenseClass.isEmpty {
      result += "\n准驾车型：\(licenseClass)"
    }

    return result
  }
}

// MARK: - Residence Permit Template

public struct ResidencePermitTemplate {
  public static let type: CardType = .residencePermit

  public static let fields: [FieldDefinition] = [
    FieldDefinition(key: "name", label: "姓名 / Name", required: true),
    FieldDefinition(key: "permitNumber", label: "证件号码 / Permit No.", required: true),
    FieldDefinition(key: "gender", label: "性别 / Gender", required: true),
    FieldDefinition(key: "nationality", label: "国籍 / Nationality", required: true),
    FieldDefinition(key: "birthDate", label: "出生日期 / Date of Birth", required: true),
    FieldDefinition(key: "issueDate", label: "签发日期 / Issue Date", required: false),
    FieldDefinition(key: "expiryDate", label: "有效期至 / Expiry Date", required: false),
    FieldDefinition(key: "permitType", label: "居留事由 / Permit Type", required: false),
  ]

  public static func formatForCopy(fieldValues: [String: String]) -> String {
    let name = fieldValues["name"] ?? ""
    let permitNumber = fieldValues["permitNumber"] ?? ""
    let gender = fieldValues["gender"] ?? ""
    let nationality = fieldValues["nationality"] ?? ""
    let birthDate = fieldValues["birthDate"] ?? ""
    let issueDate = fieldValues["issueDate"] ?? ""
    let expiryDate = fieldValues["expiryDate"] ?? ""
    let permitType = fieldValues["permitType"] ?? ""

    var result = """
      姓名：\(name)
      证件号码：\(permitNumber)
      性别：\(gender)
      国籍：\(nationality)
      出生日期：\(birthDate)
      """

    if !issueDate.isEmpty {
      result += "\n签发日期：\(issueDate)"
    }
    if !expiryDate.isEmpty {
      result += "\n有效期至：\(expiryDate)"
    }
    if !permitType.isEmpty {
      result += "\n居留事由：\(permitType)"
    }

    return result
  }
}

// MARK: - Social Security Card Template

public struct SocialSecurityCardTemplate {
  public static let type: CardType = .socialSecurityCard

  public static let fields: [FieldDefinition] = [
    FieldDefinition(key: "name", label: "姓名 / Name", required: true),
    FieldDefinition(key: "cardNumber", label: "社保卡号 / Card No.", required: true),
    FieldDefinition(key: "idNumber", label: "社会保障号码 / ID No.", required: true),
    FieldDefinition(key: "issueDate", label: "发卡日期 / Issue Date", required: false),
    FieldDefinition(key: "bankName", label: "发卡银行 / Issuing Bank", required: false),
  ]

  public static func formatForCopy(fieldValues: [String: String]) -> String {
    let name = fieldValues["name"] ?? ""
    let cardNumber = fieldValues["cardNumber"] ?? ""
    let idNumber = fieldValues["idNumber"] ?? ""
    let issueDate = fieldValues["issueDate"] ?? ""
    let bankName = fieldValues["bankName"] ?? ""

    var result = """
      姓名：\(name)
      社保卡号：\(cardNumber)
      社会保障号码：\(idNumber)
      """

    if !issueDate.isEmpty {
      result += "\n发卡日期：\(issueDate)"
    }
    if !bankName.isEmpty {
      result += "\n发卡银行：\(bankName)"
    }

    return result
  }
}

// MARK: - Bank Card Template

public struct BankCardTemplate {
  public static let type: CardType = .bankCard

  public static let fields: [FieldDefinition] = [
    FieldDefinition(key: "cardNumber", label: "卡号 / Card No.", required: true),
    FieldDefinition(key: "cardholderName", label: "持卡人 / Cardholder", required: true),
    FieldDefinition(key: "bankName", label: "开户行 / Bank", required: true),
    FieldDefinition(key: "expiryDate", label: "有效期 / Expiry Date", required: false),
    FieldDefinition(key: "cvv", label: "CVV", required: false),
    FieldDefinition(key: "notes", label: "备注 / Notes", required: false, multiline: true),
  ]

  public static func formatForCopy(fieldValues: [String: String]) -> String {
    let cardNumber = fieldValues["cardNumber"] ?? ""
    let cardholderName = fieldValues["cardholderName"] ?? ""
    let bankName = fieldValues["bankName"] ?? ""
    let expiryDate = fieldValues["expiryDate"] ?? ""
    let cvv = fieldValues["cvv"] ?? ""
    let notes = fieldValues["notes"] ?? ""

    var result = """
      持卡人：\(cardholderName)
      卡号：\(cardNumber)
      开户行：\(bankName)
      """

    if !expiryDate.isEmpty {
      result += "\n有效期：\(expiryDate)"
    }
    if !cvv.isEmpty {
      result += "\nCVV：\(cvv)"
    }
    if !notes.isEmpty {
      result += "\n备注：\(notes)"
    }

    return result
  }
}

// MARK: - Template Helper

public struct CardTemplateHelper {
  /// Get field definitions for a card type
  public static func fields(for type: CardType) -> [FieldDefinition] {
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
    case .passport:
      return PassportTemplate.fields
    case .driversLicense:
      return DriversLicenseTemplate.fields
    case .residencePermit:
      return ResidencePermitTemplate.fields
    case .socialSecurityCard:
      return SocialSecurityCardTemplate.fields
    case .bankCard:
      return BankCardTemplate.fields
    }
  }

  /// Format field values for copying
  public static func formatForCopy(type: CardType, fieldValues: [String: String]) -> String {
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
    case .passport:
      return PassportTemplate.formatForCopy(fieldValues: fieldValues)
    case .driversLicense:
      return DriversLicenseTemplate.formatForCopy(fieldValues: fieldValues)
    case .residencePermit:
      return ResidencePermitTemplate.formatForCopy(fieldValues: fieldValues)
    case .socialSecurityCard:
      return SocialSecurityCardTemplate.formatForCopy(fieldValues: fieldValues)
    case .bankCard:
      return BankCardTemplate.formatForCopy(fieldValues: fieldValues)
    }
  }
}
