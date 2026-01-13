//
//  OCRService.swift
//  QuickVault
//
//  Enhanced OCR service with intelligent document type detection and structured parsing
//

import Foundation
import Vision
import UIKit

// MARK: - Document Type

/// 文档类型枚举
enum DocumentType: String, CaseIterable {
    case idCard = "id_card"
    case passport = "passport"
    case driversLicense = "drivers_license"
    case businessLicense = "business_license"
    case residencePermit = "residence_permit"
    case socialSecurityCard = "social_security_card"
    case bankCard = "bank_card"
    case invoice = "invoice"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .idCard: return "身份证 / ID Card"
        case .passport: return "护照 / Passport"
        case .driversLicense: return "驾照 / Driver's License"
        case .businessLicense: return "营业执照 / Business License"
        case .residencePermit: return "居留卡 / Residence Permit"
        case .socialSecurityCard: return "社保卡 / Social Security Card"
        case .bankCard: return "银行卡 / Bank Card"
        case .invoice: return "发票 / Invoice"
        case .unknown: return "未知 / Unknown"
        }
    }
}

// MARK: - OCR Result Protocol

/// 统一的 OCR 结果协议
protocol OCRResult {
    var documentType: DocumentType { get }
    var confidence: Double { get set }
    var rawTexts: [String] { get set }
    
    /// 转换为卡片字段字典
    func toCardFields() -> [String: String]
}

// MARK: - Concrete OCR Results

/// 身份证 OCR 识别结果
struct IDCardOCRResult: OCRResult {
    let documentType: DocumentType = .idCard
    var confidence: Double = 0.0
    var rawTexts: [String] = []
    
    var name: String?
    var gender: String?
    var nationality: String?
    var birthDate: String?
    var idNumber: String?
    var address: String?
    var issuer: String?
    var validPeriod: String?
    var isFrontSide: Bool = true
    
    func toCardFields() -> [String: String] {
        var fields: [String: String] = [:]
        if let name = name { fields["name"] = name }
        if let gender = gender { fields["gender"] = gender }
        if let nationality = nationality { fields["nationality"] = nationality }
        if let birthDate = birthDate { fields["birthDate"] = birthDate }
        if let idNumber = idNumber { fields["idNumber"] = idNumber }
        if let address = address { fields["address"] = address }
        if let issuer = issuer { fields["issuingAuthority"] = issuer }
        if let validPeriod = validPeriod { fields["validPeriod"] = validPeriod }
        return fields
    }
}

/// 护照 OCR 识别结果
struct PassportOCRResult: OCRResult {
    let documentType: DocumentType = .passport
    var confidence: Double = 0.0
    var rawTexts: [String] = []
    
    var name: String?
    var nationality: String?
    var birthDate: String?
    var birthPlace: String?
    var gender: String?
    var passportNumber: String?
    var issueDate: String?
    var expiryDate: String?
    var issuer: String?
    
    func toCardFields() -> [String: String] {
        var fields: [String: String] = [:]
        if let name = name { fields["name"] = name }
        if let nationality = nationality { fields["nationality"] = nationality }
        if let birthDate = birthDate { fields["birthDate"] = birthDate }
        if let birthPlace = birthPlace { fields["birthPlace"] = birthPlace }
        if let gender = gender { fields["gender"] = gender }
        if let passportNumber = passportNumber { fields["passportNumber"] = passportNumber }
        if let issueDate = issueDate { fields["issueDate"] = issueDate }
        if let expiryDate = expiryDate { fields["expiryDate"] = expiryDate }
        if let issuer = issuer { fields["issuer"] = issuer }
        return fields
    }
}

/// 驾照 OCR 识别结果
struct DriversLicenseOCRResult: OCRResult {
    let documentType: DocumentType = .driversLicense
    var confidence: Double = 0.0
    var rawTexts: [String] = []
    
    var name: String?
    var gender: String?
    var nationality: String?
    var birthDate: String?
    var licenseNumber: String?
    var address: String?
    var issueDate: String?
    var validFrom: String?
    var validUntil: String?
    var licenseClass: String?
    
    func toCardFields() -> [String: String] {
        var fields: [String: String] = [:]
        if let name = name { fields["name"] = name }
        if let gender = gender { fields["gender"] = gender }
        if let nationality = nationality { fields["nationality"] = nationality }
        if let birthDate = birthDate { fields["birthDate"] = birthDate }
        if let licenseNumber = licenseNumber { fields["licenseNumber"] = licenseNumber }
        if let address = address { fields["address"] = address }
        if let issueDate = issueDate { fields["issueDate"] = issueDate }
        if let validFrom = validFrom { fields["validFrom"] = validFrom }
        if let validUntil = validUntil { fields["validUntil"] = validUntil }
        if let licenseClass = licenseClass { fields["licenseClass"] = licenseClass }
        return fields
    }
}

/// 营业执照 OCR 识别结果
struct BusinessLicenseOCRResult: OCRResult {
    let documentType: DocumentType = .businessLicense
    var confidence: Double = 0.0
    var rawTexts: [String] = []
    
    var companyName: String?
    var companyType: String?
    var creditCode: String?
    var legalRepresentative: String?
    var registeredCapital: String?
    var address: String?
    var establishedDate: String?
    var businessTerm: String?
    var businessScope: String?
    
    func toCardFields() -> [String: String] {
        var fields: [String: String] = [:]
        if let companyName = companyName { fields["companyName"] = companyName }
        if let creditCode = creditCode { fields["creditCode"] = creditCode }
        if let legalRepresentative = legalRepresentative { fields["legalRepresentative"] = legalRepresentative }
        if let registeredCapital = registeredCapital { fields["registeredCapital"] = registeredCapital }
        if let address = address { fields["address"] = address }
        if let establishedDate = establishedDate { fields["establishedDate"] = establishedDate }
        if let businessScope = businessScope { fields["businessScope"] = businessScope }
        return fields
    }
}

// MARK: - OCR Service Protocol

protocol OCRService {
    /// 自动检测文档类型并识别
    func recognizeDocument(image: UIImage) async throws -> any OCRResult
    
    /// 识别指定类型的文档
    func recognizeDocument(image: UIImage, expectedType: DocumentType) async throws -> any OCRResult
    
    /// 仅检测文档类型
    func detectDocumentType(image: UIImage) async throws -> DocumentType
}

// MARK: - Document Type Detection

/// 文档类型检测器
struct DocumentTypeDetector {
    
    /// 基于关键词检测文档类型
    static func detect(from texts: [String]) -> (type: DocumentType, confidence: Double) {
        let fullText = texts.joined(separator: "\n").lowercased()
        
        // 定义各类文档的关键词和权重
        let patterns: [(DocumentType, [String: Double])] = [
            (.idCard, [
                "公民身份": 0.9,
                "居民身份证": 0.9,
                "签发机关": 0.7,
                "民族": 0.6,
                "身份证": 0.5
            ]),
            (.passport, [
                "passport": 0.9,
                "护照": 0.9,
                "p<": 0.8,
                "mrz": 0.7,
                "nationality": 0.6
            ]),
            (.driversLicense, [
                "驾驶证": 0.9,
                "driver": 0.8,
                "license": 0.7,
                "准驾车型": 0.8,
                "有效期限": 0.4,
                "初次领证日期": 0.7
            ]),
            (.businessLicense, [
                "营业执照": 0.9,
                "统一社会信用代码": 0.9,
                "法定代表人": 0.8,
                "注册资本": 0.7,
                "经营范围": 0.6,
                "登记机关": 0.6
            ]),
            (.residencePermit, [
                "居留": 0.8,
                "residence": 0.8,
                "permit": 0.7,
                "签证": 0.6
            ]),
            (.socialSecurityCard, [
                "社会保障": 0.9,
                "社保卡": 0.9,
                "social security": 0.8
            ]),
            (.bankCard, [
                "银联": 0.8,
                "unionpay": 0.8,
                "valid thru": 0.7,
                "信用卡": 0.7,
                "储蓄卡": 0.7
            ]),
            (.invoice, [
                "发票": 0.9,
                "invoice": 0.8,
                "税号": 0.7,
                "价税合计": 0.8
            ])
        ]
        
        var scores: [DocumentType: Double] = [:]
        
        for (docType, keywords) in patterns {
            var score = 0.0
            for (keyword, weight) in keywords {
                if fullText.contains(keyword) {
                    score += weight
                }
            }
            scores[docType] = score
        }
        
        // 找到得分最高的类型
        if let (type, score) = scores.max(by: { $0.value < $1.value }), score > 0.5 {
            let confidence = min(score / 3.0, 1.0) // 归一化置信度
            return (type, confidence)
        }
        
        return (.unknown, 0.0)
    }
}

// MARK: - OCR Service Implementation

final class OCRServiceImpl: OCRService {
    
    static let shared = OCRServiceImpl()
    
    private init() {}
    
    // MARK: - Public API
    
    /// 自动检测文档类型并识别
    func recognizeDocument(image: UIImage) async throws -> any OCRResult {
        let recognizedTexts = try await performOCR(on: image)
        let (detectedType, confidence) = DocumentTypeDetector.detect(from: recognizedTexts)
        
        return try await recognizeDocument(image: image, expectedType: detectedType, 
                                          preExtractedTexts: recognizedTexts, 
                                          detectedConfidence: confidence)
    }
    
    /// 识别指定类型的文档
    func recognizeDocument(image: UIImage, expectedType: DocumentType) async throws -> any OCRResult {
        let recognizedTexts = try await performOCR(on: image)
        return try await recognizeDocument(image: image, expectedType: expectedType, 
                                          preExtractedTexts: recognizedTexts, 
                                          detectedConfidence: 0.9)
    }
    
    /// 仅检测文档类型
    func detectDocumentType(image: UIImage) async throws -> DocumentType {
        let recognizedTexts = try await performOCR(on: image)
        let (detectedType, _) = DocumentTypeDetector.detect(from: recognizedTexts)
        return detectedType
    }
    
    // MARK: - Internal Recognition
    
    private func recognizeDocument(image: UIImage, expectedType: DocumentType, 
                                   preExtractedTexts: [String], 
                                   detectedConfidence: Double) async throws -> any OCRResult {
        switch expectedType {
        case .idCard:
            var result = parseIDCardTexts(preExtractedTexts)
            result.confidence = detectedConfidence
            result.rawTexts = preExtractedTexts
            return result
            
        case .passport:
            var result = parsePassportTexts(preExtractedTexts)
            result.confidence = detectedConfidence
            result.rawTexts = preExtractedTexts
            return result
            
        case .driversLicense:
            var result = parseDriversLicenseTexts(preExtractedTexts)
            result.confidence = detectedConfidence
            result.rawTexts = preExtractedTexts
            return result
            
        case .businessLicense:
            var result = parseBusinessLicenseTexts(preExtractedTexts)
            result.confidence = detectedConfidence
            result.rawTexts = preExtractedTexts
            return result
            
        case .residencePermit, .socialSecurityCard, .bankCard, .invoice, .unknown:
            // 对于暂未实现的类型，返回基本的 ID Card 结果
            var result = IDCardOCRResult()
            result.confidence = 0.0
            result.rawTexts = preExtractedTexts
            return result
        }
    }
    
    // MARK: - ID Card Recognition
    
    private func parseIDCardTexts(_ texts: [String]) -> IDCardOCRResult {
        var result = IDCardOCRResult()
        
        let fullText = texts.joined(separator: "\n")
        
        // 判断是正面还是背面
        if fullText.contains("签发机关") || fullText.contains("有效期") {
            result.isFrontSide = false
        }
        
        for (index, text) in texts.enumerated() {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 姓名 - 通常在"姓名"后面
            if trimmed.contains("姓名") {
                result.name = extractValueAfterLabel(trimmed, label: "姓名")
                    ?? (index + 1 < texts.count ? texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines) : nil)
            }
            
            // 性别 - 可能在同一行或下一行
            if trimmed.contains("性别") {
                // 尝试从同一行提取
                if let genderValue = extractValueAfterLabel(trimmed, label: "性别") {
                    if genderValue.contains("男") {
                        result.gender = "男"
                    } else if genderValue.contains("女") {
                        result.gender = "女"
                    } else {
                        result.gender = genderValue
                    }
                } else if trimmed.contains("男") {
                    result.gender = "男"
                } else if trimmed.contains("女") {
                    result.gender = "女"
                } else if index + 1 < texts.count {
                    // 尝试从下一行提取
                    let nextLine = texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if nextLine == "男" || nextLine.hasPrefix("男") {
                        result.gender = "男"
                    } else if nextLine == "女" || nextLine.hasPrefix("女") {
                        result.gender = "女"
                    }
                }
            }
            
            // 单独出现的性别（有时 OCR 会把性别单独识别为一行）
            if result.gender == nil && (trimmed == "男" || trimmed == "女") {
                result.gender = trimmed
            }
            
            // 民族
            if trimmed.contains("民族") {
                result.nationality = extractValueAfterLabel(trimmed, label: "民族")
            }
            
            // 出生日期 - 格式: YYYY年MM月DD日
            if let birthMatch = trimmed.range(of: #"\d{4}年\d{1,2}月\d{1,2}日"#, options: .regularExpression) {
                result.birthDate = String(trimmed[birthMatch])
            }
            
            // 身份证号 - 18位数字或17位数字+X
            if let idMatch = trimmed.range(of: #"\d{17}[\dXx]"#, options: .regularExpression) {
                result.idNumber = String(trimmed[idMatch]).uppercased()
            }
            
            // 住址 - 收集"住址"后的 1-3 行内容
            if trimmed.contains("住址") && result.address == nil {
                var addressParts: [String] = []
                
                // 先尝试从同一行提取"住址"后面的内容
                if let addressValue = extractValueAfterLabel(trimmed, label: "住址"), !addressValue.isEmpty {
                    addressParts.append(addressValue)
                }
                
                // 继续收集后续 1-3 行作为地址
                for i in (index + 1)..<min(index + 4, texts.count) {
                    let part = texts[i].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // 遇到这些内容时停止收集
                    if part.isEmpty ||
                       part.contains("公民身份") || 
                       part.contains("身份证") ||
                       part.range(of: #"\d{17}[\dXx]"#, options: .regularExpression) != nil ||
                       part.range(of: #"\d{4}年\d{1,2}月\d{1,2}日"#, options: .regularExpression) != nil {
                        break
                    }
                    
                    // 收集地址行
                    addressParts.append(part)
                }
                
                if !addressParts.isEmpty {
                    result.address = addressParts.joined()
                }
            }
            
            // 签发机关 (背面)
            if trimmed.contains("签发机关") {
                if let issuerValue = extractValueAfterLabel(trimmed, label: "签发机关"), !issuerValue.isEmpty {
                    result.issuer = issuerValue
                } else if index + 1 < texts.count {
                    let nextLine = texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                    // 签发机关通常是公安局
                    if nextLine.contains("公安") || nextLine.contains("派出所") || nextLine.count > 3 {
                        result.issuer = nextLine
                    }
                }
            }
            
            // 有效期限 (背面) - 支持多种格式
            if trimmed.contains("有效期") && result.validPeriod == nil {
                // 格式1: YYYY.MM.DD-YYYY.MM.DD
                if let validMatch = trimmed.range(of: #"\d{4}\.\d{2}\.\d{2}[-－]\d{4}\.\d{2}\.\d{2}"#, options: .regularExpression) {
                    result.validPeriod = String(trimmed[validMatch])
                }
                // 格式2: YYYY.MM.DD-长期
                else if let validMatch = trimmed.range(of: #"\d{4}\.\d{2}\.\d{2}[-－]长期"#, options: .regularExpression) {
                    result.validPeriod = String(trimmed[validMatch])
                }
                // 格式3: 从下一行获取
                else if index + 1 < texts.count {
                    let nextLine = texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if let validMatch = nextLine.range(of: #"\d{4}\.\d{2}\.\d{2}[-－]\d{4}\.\d{2}\.\d{2}"#, options: .regularExpression) {
                        result.validPeriod = String(nextLine[validMatch])
                    } else if let validMatch = nextLine.range(of: #"\d{4}\.\d{2}\.\d{2}[-－]长期"#, options: .regularExpression) {
                        result.validPeriod = String(nextLine[validMatch])
                    } else if nextLine.contains("长期") {
                        // 尝试组合当前行和下一行
                        let combined = trimmed + nextLine
                        if let validMatch = combined.range(of: #"\d{4}\.\d{2}\.\d{2}[-－]长期"#, options: .regularExpression) {
                            result.validPeriod = String(combined[validMatch])
                        }
                    }
                }
            }
            
            // 单独出现的有效期格式（有时OCR会把日期单独识别）
            if result.validPeriod == nil {
                if let validMatch = trimmed.range(of: #"\d{4}\.\d{2}\.\d{2}[-－]\d{4}\.\d{2}\.\d{2}"#, options: .regularExpression) {
                    result.validPeriod = String(trimmed[validMatch])
                } else if let validMatch = trimmed.range(of: #"\d{4}\.\d{2}\.\d{2}[-－]长期"#, options: .regularExpression) {
                    result.validPeriod = String(trimmed[validMatch])
                }
            }
        }
        
        return result
    }
    
    // MARK: - Passport Recognition
    
    private func parsePassportTexts(_ texts: [String]) -> PassportOCRResult {
        var result = PassportOCRResult()
        
        for text in texts {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 护照号码 - 通常以字母开头，后跟数字
            if let passportMatch = trimmed.range(of: #"[A-Z][A-Z0-9]{7,8}"#, options: .regularExpression) {
                let potentialNumber = String(trimmed[passportMatch])
                // 排除常见的非护照号码
                if !["PASSPORT", "REPUBLIC", "PEOPLES"].contains(potentialNumber) {
                    result.passportNumber = potentialNumber
                }
            }
            
            // MRZ 行解析 (机读区)
            if trimmed.hasPrefix("P<") || trimmed.count == 44 {
                parseMRZ(trimmed, result: &result)
            }
            
            // 日期格式: DD MMM YYYY 或 YYYY-MM-DD
            if let dateMatch = trimmed.range(of: #"\d{2}\s+[A-Z]{3}\s+\d{4}"#, options: .regularExpression) {
                let dateStr = String(trimmed[dateMatch])
                // 根据上下文判断是出生日期还是有效期
                if result.birthDate == nil {
                    result.birthDate = dateStr
                } else if result.expiryDate == nil {
                    result.expiryDate = dateStr
                }
            }
            
            // 性别
            if trimmed.contains("M/男") || trimmed == "M" || trimmed == "男" {
                result.gender = "男"
            } else if trimmed.contains("F/女") || trimmed == "F" || trimmed == "女" {
                result.gender = "女"
            }
            
            // 国籍
            if trimmed.contains("CHN") || trimmed.contains("CHINESE") || trimmed.contains("中国") {
                result.nationality = "中国"
            }
        }
        
        return result
    }
    
    private func parseMRZ(_ mrz: String, result: inout PassportOCRResult) {
        // MRZ 第一行格式: P<CHNLAST<<FIRST<MIDDLE<<<<<<<<<<<<<<<<<<
        // MRZ 第二行格式: PASSPORT#<CHECK<NATIONALITY<BIRTHDATE<CHECK<SEX<EXPIRY<CHECK<<<<<<<<<CHECK
        
        let cleaned = mrz.replacingOccurrences(of: " ", with: "")
        
        if cleaned.hasPrefix("P<") {
            // 第一行 - 提取姓名
            let namePart = String(cleaned.dropFirst(5)) // 跳过 P<CHN
            let names = namePart.split(separator: "<").map { String($0) }.filter { !$0.isEmpty }
            if names.count >= 2 {
                result.name = names.joined(separator: " ")
            } else if names.count == 1 {
                result.name = names[0]
            }
        } else if cleaned.count >= 44 {
            // 第二行 - 提取护照号、出生日期、有效期等
            // 位置: 0-8 护照号, 13-18 出生日期(YYMMDD), 21 性别, 22-27 有效期(YYMMDD)
            if result.passportNumber == nil {
                let passportNum = String(cleaned.prefix(9)).replacingOccurrences(of: "<", with: "")
                if !passportNum.isEmpty {
                    result.passportNumber = passportNum
                }
            }
        }
    }
    
    // MARK: - Driver's License Recognition
    
    private func parseDriversLicenseTexts(_ texts: [String]) -> DriversLicenseOCRResult {
        var result = DriversLicenseOCRResult()
        
        for (index, text) in texts.enumerated() {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 姓名
            if trimmed.contains("姓名") {
                result.name = extractValueAfterLabel(trimmed, label: "姓名")
                    ?? (index + 1 < texts.count ? texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines) : nil)
            }
            
            // 性别
            if trimmed.contains("性别") {
                if let genderValue = extractValueAfterLabel(trimmed, label: "性别") {
                    if genderValue.contains("男") {
                        result.gender = "男"
                    } else if genderValue.contains("女") {
                        result.gender = "女"
                    }
                } else if trimmed.contains("男") {
                    result.gender = "男"
                } else if trimmed.contains("女") {
                    result.gender = "女"
                }
            }
            
            // 国籍
            if trimmed.contains("国籍") {
                result.nationality = extractValueAfterLabel(trimmed, label: "国籍")
            }
            
            // 出生日期 - 支持多种格式
            if let birthMatch = trimmed.range(of: #"\d{4}年\d{1,2}月\d{1,2}日"#, options: .regularExpression) {
                result.birthDate = String(trimmed[birthMatch])
            } else if let birthMatch = trimmed.range(of: #"\d{4}-\d{2}-\d{2}"#, options: .regularExpression) {
                result.birthDate = String(trimmed[birthMatch])
            }
            
            // 驾照号码 - 通常12位或18位
            if result.licenseNumber == nil {
                if let licenseMatch = trimmed.range(of: #"\d{12}|\d{18}"#, options: .regularExpression) {
                    let number = String(trimmed[licenseMatch])
                    // 排除身份证号（18位）和日期（8位）
                    if number.count == 12 || (number.count == 18 && !trimmed.contains("身份证")) {
                        result.licenseNumber = number
                    }
                }
            }
            
            // 住址
            if trimmed.contains("住址") && result.address == nil {
                var addressParts: [String] = []
                if let addressValue = extractValueAfterLabel(trimmed, label: "住址"), !addressValue.isEmpty {
                    addressParts.append(addressValue)
                }
                for i in (index + 1)..<min(index + 3, texts.count) {
                    let part = texts[i].trimmingCharacters(in: .whitespacesAndNewlines)
                    if part.isEmpty || part.contains("初次领证") || part.contains("有效期") {
                        break
                    }
                    addressParts.append(part)
                }
                if !addressParts.isEmpty {
                    result.address = addressParts.joined()
                }
            }
            
            // 初次领证日期
            if trimmed.contains("初次领证") {
                if let dateMatch = trimmed.range(of: #"\d{4}年\d{1,2}月\d{1,2}日"#, options: .regularExpression) {
                    result.issueDate = String(trimmed[dateMatch])
                } else if let dateMatch = trimmed.range(of: #"\d{4}-\d{2}-\d{2}"#, options: .regularExpression) {
                    result.issueDate = String(trimmed[dateMatch])
                }
            }
            
            // 有效期限
            if trimmed.contains("有效期限") || trimmed.contains("有效期") {
                // 格式: YYYY-MM-DD至YYYY-MM-DD 或 YYYY年MM月DD日至YYYY年MM月DD日
                if let validMatch = trimmed.range(of: #"\d{4}[-年]\d{2}[-月]\d{2}[日]?至\d{4}[-年]\d{2}[-月]\d{2}[日]?"#, options: .regularExpression) {
                    let validPeriod = String(trimmed[validMatch])
                    let dates = validPeriod.split(separator: "至").map { String($0) }
                    if dates.count == 2 {
                        result.validFrom = dates[0]
                        result.validUntil = dates[1]
                    }
                }
            }
            
            // 准驾车型
            if trimmed.contains("准驾车型") {
                result.licenseClass = extractValueAfterLabel(trimmed, label: "准驾车型")
                // 常见车型: C1, C2, B2, A1, A2 等
                if result.licenseClass == nil {
                    if let classMatch = trimmed.range(of: #"[A-D][1-3]"#, options: .regularExpression) {
                        result.licenseClass = String(trimmed[classMatch])
                    }
                }
            }
        }
        
        return result
    }
    
    // MARK: - Business License Recognition
    
    private func parseBusinessLicenseTexts(_ texts: [String]) -> BusinessLicenseOCRResult {
        var result = BusinessLicenseOCRResult()
        
        // 合并所有文本用于某些字段的提取
        let fullText = texts.joined(separator: "\n")
        
        for (index, text) in texts.enumerated() {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 统一社会信用代码 - 18位
            if result.creditCode == nil {
                if let codeMatch = trimmed.range(of: #"[0-9A-Z]{18}"#, options: .regularExpression) {
                    let code = String(trimmed[codeMatch])
                    if isValidCreditCode(code) {
                        result.creditCode = code
                    }
                }
            }
            
            // 企业名称 - OCR 可能把"名"和"称"分开识别
            // 格式1: "名称 XXX公司" 或 "企业名称 XXX公司"
            // 格式2: "名" 在一行，"称 XXX公司" 在下一行
            // 格式3: 直接包含公司名称的行（以"公司"、"有限"等结尾）
            if result.companyName == nil {
                if trimmed.contains("名称") || trimmed.contains("企业名称") {
                    result.companyName = extractValueAfterLabel(trimmed, label: "名称")
                        ?? extractValueAfterLabel(trimmed, label: "企业名称")
                } else if trimmed == "名" && index + 1 < texts.count {
                    // "名" 单独一行，下一行是 "称 XXX公司"
                    let nextLine = texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if nextLine.hasPrefix("称") {
                        let name = String(nextLine.dropFirst()).trimmingCharacters(in: .whitespaces)
                        if !name.isEmpty {
                            result.companyName = name
                        }
                    }
                } else if trimmed.hasPrefix("称 ") {
                    // "称 XXX公司" 格式（带空格）
                    let name = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty && (name.contains("公司") || name.contains("企业") || name.contains("有限")) {
                        result.companyName = name
                    }
                } else if trimmed.hasPrefix("称") && trimmed.count > 1 {
                    // "称XXX公司" 格式（不带空格）
                    let name = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty && (name.contains("公司") || name.contains("企业") || name.contains("有限")) {
                        result.companyName = name
                    }
                }
            }
            
            // 类型
            if result.companyType == nil && trimmed.contains("类型") {
                result.companyType = extractValueAfterLabel(trimmed, label: "类型")
            }
            
            // 法定代表人 - 可能分行
            if result.legalRepresentative == nil {
                if trimmed.contains("法定代表人") || trimmed.contains("负责人") {
                    result.legalRepresentative = extractValueAfterLabel(trimmed, label: "法定代表人")
                        ?? extractValueAfterLabel(trimmed, label: "负责人")
                    // 如果同一行没有值，取下一行
                    if (result.legalRepresentative == nil || result.legalRepresentative?.isEmpty == true) && index + 1 < texts.count {
                        let nextLine = texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                        // 排除其他标签
                        if !nextLine.contains("经营范围") && !nextLine.contains("注册资本") && !nextLine.isEmpty {
                            result.legalRepresentative = nextLine
                        }
                    }
                }
            }
            
            // 注册资本 - 可能是中文大写金额如"壹佰万元整"
            if result.registeredCapital == nil && (trimmed.contains("注册资本") || trimmed.contains("注册资金")) {
                result.registeredCapital = extractValueAfterLabel(trimmed, label: "注册资本")
                    ?? extractValueAfterLabel(trimmed, label: "注册资金")
                // 提取数字金额
                if result.registeredCapital == nil {
                    if let capitalMatch = trimmed.range(of: #"\d+(\.\d+)?万?[元人民币]?"#, options: .regularExpression) {
                        result.registeredCapital = String(trimmed[capitalMatch])
                    }
                }
                // 提取中文大写金额
                if result.registeredCapital == nil {
                    if let capitalMatch = trimmed.range(of: #"[零壹贰叁肆伍陆柒捌玖拾佰仟万亿]+[元人民币整]+"#, options: .regularExpression) {
                        result.registeredCapital = String(trimmed[capitalMatch])
                    }
                }
            }
            
            // 住所/经营场所 - 可能跨多行
            if result.address == nil && (trimmed.contains("住所") || trimmed.contains("经营场所")) {
                result.address = extractValueAfterLabel(trimmed, label: "住所")
                    ?? extractValueAfterLabel(trimmed, label: "经营场所")
                // 地址可能跨多行，收集后续行直到遇到其他标签
                var addressParts: [String] = []
                if let addr = result.address, !addr.isEmpty {
                    addressParts.append(addr)
                }
                for i in (index + 1)..<min(index + 4, texts.count) {
                    let part = texts[i].trimmingCharacters(in: .whitespacesAndNewlines)
                    // 遇到其他标签停止
                    if part.contains("登记机关") || part.contains("成立日期") || part.contains("经营范围") ||
                       part.contains("营业期限") || part.isEmpty || part.range(of: #"^\d{4}$"#, options: .regularExpression) != nil {
                        break
                    }
                    addressParts.append(part)
                }
                if !addressParts.isEmpty {
                    result.address = addressParts.joined()
                }
            }
            
            // 成立日期
            if result.establishedDate == nil && trimmed.contains("成立日期") {
                if let dateMatch = trimmed.range(of: #"\d{4}年\d{1,2}月\d{1,2}日"#, options: .regularExpression) {
                    result.establishedDate = String(trimmed[dateMatch])
                }
            }
            
            // 营业期限 - 格式如 "2001年04月20日 至长期" 或 "2001年04月20日 至 2031年04月20日"
            if result.businessTerm == nil && trimmed.contains("营业期限") {
                // 尝试从当前行和后续行提取
                var termParts: [String] = []
                for i in index..<min(index + 3, texts.count) {
                    let part = texts[i].trimmingCharacters(in: .whitespacesAndNewlines)
                    if let match = part.range(of: #"\d{4}年\d{1,2}月\d{1,2}日"#, options: .regularExpression) {
                        termParts.append(String(part[match]))
                    }
                    if part.contains("长期") || part.contains("至长期") {
                        termParts.append("长期")
                        break
                    }
                }
                if termParts.count >= 2 {
                    result.businessTerm = termParts[0] + " 至 " + termParts[1]
                } else if termParts.count == 1 {
                    result.businessTerm = termParts[0]
                }
            }
            
            // 经营范围 - 通常很长，可能跨多行
            if result.businessScope == nil && trimmed.contains("经营范围") {
                result.businessScope = extractValueAfterLabel(trimmed, label: "经营范围")
                // 收集后续行
                var scopeParts: [String] = []
                if let scope = result.businessScope, !scope.isEmpty {
                    scopeParts.append(scope)
                }
                for i in (index + 1)..<min(index + 6, texts.count) {
                    let part = texts[i].trimmingCharacters(in: .whitespacesAndNewlines)
                    // 遇到其他标签停止
                    if part.contains("注册资本") || part.contains("成立日期") || part.contains("住所") ||
                       part.contains("营业期限") || part.contains("登记机关") {
                        break
                    }
                    scopeParts.append(part)
                }
                if !scopeParts.isEmpty {
                    result.businessScope = scopeParts.joined()
                }
            }
        }
        
        return result
    }
    
    private func isValidCreditCode(_ code: String) -> Bool {
        // 统一社会信用代码校验
        // 第1位: 登记管理部门代码 (1-9, A, N, Y)
        // 第2位: 机构类别代码
        // 第3-8位: 登记管理机关行政区划码
        // 第9-17位: 主体标识码
        // 第18位: 校验码
        guard code.count == 18 else { return false }
        let validChars = CharacterSet(charactersIn: "0123456789ABCDEFGHJKLMNPQRTUWXY")
        return code.unicodeScalars.allSatisfy { validChars.contains($0) }
    }
    
    // MARK: - Core OCR
    
    private func performOCR(on image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let recognizedTexts = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                continuation.resume(returning: recognizedTexts)
            }
            
            // 配置识别参数
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractValueAfterLabel(_ text: String, label: String) -> String? {
        guard let range = text.range(of: label) else { return nil }
        var value = String(text[range.upperBound...])
        // 移除常见分隔符
        value = value.trimmingCharacters(in: CharacterSet(charactersIn: "：: "))
        return value.isEmpty ? nil : value
    }
}

// MARK: - OCR Errors

enum OCRError: LocalizedError {
    case invalidImage
    case recognitionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image / 无效的图片"
        case .recognitionFailed(let message):
            return "OCR recognition failed: \(message) / OCR 识别失败：\(message)"
        }
    }
}
