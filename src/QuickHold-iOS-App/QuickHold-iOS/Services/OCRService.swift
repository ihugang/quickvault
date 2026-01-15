//
//  OCRService.swift
//  QuickHold
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
    var issuePlace: String?
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
        if let issuePlace = issuePlace { fields["issuePlace"] = issuePlace }
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

// MARK: - OCR Text Observation

/// OCR识别的文本及其位置信息
struct OCRTextObservation {
    let text: String
    let boundingBox: CGRect  // 归一化坐标 (0-1)
    
    /// 判断另一个观察结果是否在当前观察结果的下方
    func isBelow(_ other: OCRTextObservation, tolerance: CGFloat = 0.02) -> Bool {
        return self.boundingBox.origin.y < other.boundingBox.origin.y - tolerance
    }
    
    /// 判断另一个观察结果是否在当前观察结果的右侧
    func isRightOf(_ other: OCRTextObservation, tolerance: CGFloat = 0.02) -> Bool {
        return self.boundingBox.origin.x > other.boundingBox.origin.x + tolerance
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
    
    private let mrzCorrector = MRZAutoCorrector() // MRZ自动矫正器
    
    private init() {}
    
    // MARK: - Public API
    
    /// 自动检测文档类型并识别
    func recognizeDocument(image: UIImage) async throws -> any OCRResult {
        print("🔍 [OCR] 开始识别文档...")
        
        let observations = try await performOCR(on: image)
        let recognizedTexts = observations.map { $0.text }
        print("📝 [OCR] Vision 识别到 \(recognizedTexts.count) 行文本:")
        for (index, text) in recognizedTexts.enumerated() {
            print("  [\(index)] \(text)")
        }
        
        let (detectedType, confidence) = DocumentTypeDetector.detect(from: recognizedTexts)
        print("🎯 [OCR] 检测到文档类型: \(detectedType), 置信度: \(String(format: "%.2f", confidence))")
        
        return try await recognizeDocument(image: image, expectedType: detectedType, 
                                           preExtractedObservations: observations,
                                           detectedConfidence: confidence)
    }
    
    /// 识别指定类型的文档
    func recognizeDocument(image: UIImage, expectedType: DocumentType) async throws -> any OCRResult {
        print("🔍 [OCR] 使用指定类型识别: \(expectedType)")
        
        let observations = try await performOCR(on: image)
        let recognizedTexts = observations.map { $0.text }
        print("📝 [OCR] Vision 识别到 \(recognizedTexts.count) 行文本:")
        for (index, text) in recognizedTexts.enumerated() {
            print("  [\(index)] \(text)")
        }
        
        return try await recognizeDocument(image: image, expectedType: expectedType, 
                                           preExtractedObservations: observations,
                                           detectedConfidence: 0.9)
    }
    
    /// 仅检测文档类型
    func detectDocumentType(image: UIImage) async throws -> DocumentType {
        let observations = try await performOCR(on: image)
        let recognizedTexts = observations.map { $0.text }
        let (detectedType, _) = DocumentTypeDetector.detect(from: recognizedTexts)
        return detectedType
    }
    
    // MARK: - Internal Recognition
    
    /// 辅助函数：判断是否为标签行（如 "签发日期/Date of issue"）而非双语值（如 "浙江/ZHEJIANG"）
    private func isLabelLine(_ text: String) -> Bool {
        // 标签行通常包含这些关键词
        let labelKeywords = [
            "date", "place", "authority", "signature", "expiry", "birth", 
            "nationality", "sex", "type", "code", "number", "name",
            "日期", "地点", "机关", "签发", "签名", "有效期", "出生", 
            "国籍", "性别", "类型", "代码", "号码", "姓名"
        ]
        
        let lower = text.lowercased()
        
        // 如果包含任何标签关键词，认为是标签行
        for keyword in labelKeywords {
            if lower.contains(keyword) {
                return true
            }
        }
        
        // 如果包含 "/"，检查是否符合标签行模式
        if text.contains("/") {
            let parts = text.components(separatedBy: "/")
            if parts.count == 2 {
                let part1 = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let part2 = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // 先排除日期格式（如 "10 1月" / " JAN 2025"）
                let datePattern1 = #"^\d{1,2}\s+\d{1,2}?月?$"#  // "10 1月"
                let datePattern2 = #"^\s*[A-Z]{3}\s+\d{4}$"#   // " JAN 2025"
                if part1.range(of: datePattern1, options: .regularExpression) != nil ||
                   part2.range(of: datePattern2, options: .regularExpression) != nil {
                    return false  // 是日期值，不是标签
                }
                
                // 如果两边都是多个单词（如 "Date of issue"），很可能是标签
                if part1.contains(" ") || part2.contains(" ") {
                    return true
                }
                
                // 如果两边都是单个大写单词（如 "PLACE/地点"），也可能是标签
                // 但如果是 "浙江/ZHEJIANG" 或 "14 3月/MAR 2023"，则是值
                // 检查是否两边都只包含字母且都是大写（省份代码模式）
                let isProvincePattern = part2.allSatisfy { $0.isLetter && $0.isUppercase } &&
                                       part1.allSatisfy { $0.isLetter || $0 == " " }
                if isProvincePattern && !part1.contains(" ") {
                    // "浙江/ZHEJIANG" 这种是值，不是标签
                    return false
                }
            }
        }
        
        return false
    }
    
    private func recognizeDocument(image: UIImage, expectedType: DocumentType, 
                                   preExtractedObservations: [OCRTextObservation], 
                                   detectedConfidence: Double) async throws -> any OCRResult {
        print("⚙️ [OCR] 开始解析为: \(expectedType)")
        
        let preExtractedTexts = preExtractedObservations.map { $0.text }
        
        switch expectedType {
        case .idCard:
            print("🪪 [OCR] 解析身份证...")
            var result = parseIDCardTexts(preExtractedTexts)
            result.confidence = detectedConfidence
            result.rawTexts = preExtractedTexts
            print("✅ [OCR] 身份证解析完成: 姓名=\(result.name ?? "nil"), 身份证号=\(result.idNumber ?? "nil")")
            return result
            
        case .passport:
            print("📘 [OCR] 解析护照...")
            
            // 优先使用MRZ专用识别器
            print("  🎯 [MRZ] 尝试使用MRZ专用识别器...")
            let mrzOCR = MRZVisionOCR()
            if let (rawLine1, rawLine2) = try? await mrzOCR.recognizeMRZLines(from: image) {
                print("  ✅ [MRZ] 专用识别器成功获取MRZ行")
                print("      Line1: \(rawLine1)")
                print("      Line2: \(rawLine2)")
                // 部分护照印刷为“PO”/“P0”，矫正为标准“P<”
                func normalizeMRZLine(_ line: String) -> String {
                    var s = line
                    if s.hasPrefix("PO") || s.hasPrefix("P0") { // replace second char with '<'
                        var chars = Array(s)
                        chars[1] = "<"
                        s = String(chars)
                    }
                    return s
                }
                let line1 = normalizeMRZLine(rawLine1)
                let line2 = normalizeMRZLine(rawLine2)
                
                // 使用MRZ自动矫正器解析
                do {
                    let parsed = try mrzCorrector.parseWithAutoCorrection(line1: line1, line2: line2)
                    print("  ✅ [MRZ矫正] 解析成功, 校验通过: \(parsed.checksumsValid)")
                    
                    // 构建PassportOCRResult
                    var result = PassportOCRResult()
                    result.confidence = parsed.checksumsValid ? 0.95 : 0.70
                    result.rawTexts = preExtractedTexts
                    
                    // 姓名：优先组合中英双语（如果有中文）
                    let englishName = [parsed.surname, parsed.givenNames].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
                    let chineseName = extractChineseNameFromObservations(from: preExtractedObservations)
                    if let cn = chineseName, !cn.isEmpty {
                        if !englishName.isEmpty {
                            result.name = "\(cn) \(englishName)"
                        } else {
                            result.name = cn
                        }
                    } else if !englishName.isEmpty {
                        result.name = englishName
                    }
                    result.passportNumber = parsed.passportNumber
                    result.nationality = parsed.nationality
                    result.gender = parsed.sex == "M" ? "男" : (parsed.sex == "F" ? "女" : nil)
                    
                    // 先格式化出生日期（作为基准）
                    result.birthDate = formatMRZDate(parsed.birthDateYYMMDD, referenceYear: nil, isBirthDate: true)
                    
                    // 使用出生年份作为参考格式化有效期（有效期必定晚于出生日期）
                    let birthYear = extractYearFromDate(result.birthDate)
                    result.expiryDate = formatMRZDate(parsed.expiryDateYYMMDD, referenceYear: birthYear, isBirthDate: false)
                    
                    // 补充提取MRZ中不包含的字段（签发日期、签发机关等）
                    print("  🔍 [MRZ补充] 从全图文本提取额外字段...")
                    let supplementaryFields = extractSupplementaryPassportFields(from: preExtractedObservations)
                    if let issueDate = supplementaryFields.issueDate {
                        result.issueDate = issueDate
                        print("    ✓ 提取签发日期: \(issueDate)")
                    }
                    if let issuePlace = supplementaryFields.issuePlace {
                        result.issuePlace = issuePlace
                        print("    ✓ 提取签发地点: \(issuePlace)")
                    }
                    if let issuer = supplementaryFields.issuer {
                        result.issuer = issuer
                        print("    ✓ 提取签发机关: \(issuer)")
                    }
                    
                    if !parsed.checksumsValid {
                        print("  ⚠️ [MRZ矫正] 校验和未通过，建议用户确认")
                    }
                    
                    print("✅ [OCR] 护照解析完成(MRZ专用): 姓名=\(result.name ?? "nil"), 护照号=\(result.passportNumber ?? "nil"), 国籍=\(result.nationality ?? "nil"), 签发日期=\(result.issueDate ?? "nil")")
                    return result
                } catch {
                    print("  ❌ [MRZ矫正] 解析失败: \(error)，降级到全图OCR")
                }
            } else {
                print("  ⚠️ [MRZ] 专用识别器未获取到MRZ行，降级到全图OCR")
            }
            
            // 降级：使用全图OCR解析
            var result = parsePassportTexts(preExtractedTexts)
            result.confidence = detectedConfidence
            result.rawTexts = preExtractedTexts
            print("✅ [OCR] 护照解析完成: 姓名=\(result.name ?? "nil"), 护照号=\(result.passportNumber ?? "nil"), 国籍=\(result.nationality ?? "nil")")
            return result
            
        case .driversLicense:
            print("🚗 [OCR] 解析驾驶证...")
            var result = parseDriversLicenseTexts(preExtractedTexts)
            result.confidence = detectedConfidence
            result.rawTexts = preExtractedTexts
            print("✅ [OCR] 驾驶证解析完成: 姓名=\(result.name ?? "nil"), 证号=\(result.licenseNumber ?? "nil")")
            return result
            
        case .businessLicense:
            print("🏢 [OCR] 解析营业执照...")
            var result = parseBusinessLicenseTexts(preExtractedTexts)
            result.confidence = detectedConfidence
            result.rawTexts = preExtractedTexts
            print("✅ [OCR] 营业执照解析完成: 公司名=\(result.companyName ?? "nil"), 统一社会信用代码=\(result.creditCode ?? "nil")")
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
        print("  🔎 [护照解析] 开始解析 \(texts.count) 行文本")
        var result = PassportOCRResult()
        
        // 收集MRZ行用于后续矫正
        var mrzLine1: String?
        var mrzLine2: String?
        
        for (index, text) in texts.enumerated() {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = trimmed.lowercased()
            
            // 姓名识别 - 支持多种格式（防止重复）
            // "姓名/Name"这种标签只处理一次
            if (lower.contains("surname") || (lower.contains("姓") && !lower.contains("签名"))) && result.name == nil {
                print("    ℹ️ [护照] 第\(index)行发现姓氏标签: \(trimmed)")
                // 下一行可能是姓名
                if index + 1 < texts.count {
                    let nextLine = texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !nextLine.isEmpty && !nextLine.contains(":") && !nextLine.contains("/") && nextLine.count < 50 {
                        result.name = nextLine
                        print("    ✓ [护照] 提取姓名: \(nextLine)")
                    }
                }
            }
            
            // 护照号码 - 更灵活的匹配
            if lower.contains("passport") && lower.contains("no") {
                if let value = extractValueAfterLabel(trimmed, label: "Passport No") ?? extractValueAfterLabel(trimmed, label: "No.") {
                    let cleaned = value.replacingOccurrences(of: " ", with: "")
                    // 有效的护照号应该至少有5个字符
                    if cleaned.count >= 5 {
                        result.passportNumber = cleaned
                        print("    ✓ [护照] 从标签提取护照号: \(cleaned)")
                    }
                }
            }
            
            // 直接匹配护照号码格式 (通常是字母+数字组合，8-9位)
            if result.passportNumber == nil {
                if let passportMatch = trimmed.range(of: #"[A-Z]{1,2}[0-9]{7,8}"#, options: .regularExpression) {
                    let potentialNumber = String(trimmed[passportMatch])
                    // 排除常见的非护照号码关键词
                    if !["PASSPORT", "REPUBLIC", "PEOPLES", "PASSPORT"].contains(potentialNumber) {
                        result.passportNumber = potentialNumber
                        print("    ✓ [护照] 正则匹配护照号: \(potentialNumber)")
                    }
                }
            }
            
            // 国籍识别
            if lower.contains("nationality") || lower.contains("国籍") {
                print("    ℹ️ [护照] 第\(index)行发现国籍标签: \(trimmed)")
                // 检查接下来的几行，找到包含国籍的行
                for i in (index + 1)..<min(index + 4, texts.count) {
                    let nextLine = texts[i].trimmingCharacters(in: .whitespacesAndNewlines)
                    let lowerNext = nextLine.lowercased()
                    
                    // 明确包含国籍关键词
                    if nextLine.contains("中国") || nextLine.contains("CHINESE") || 
                       (nextLine.contains("CHN") && !nextLine.contains("P<CHN")) {
                        result.nationality = nextLine
                        print("    ✓ [护照] 从第\(i)行提取国籍: \(nextLine)")
                        break
                    }
                    // 排除性别行（包含M/F或男/女）
                    if lowerNext.contains("/m") || lowerNext.contains("/f") || 
                       lowerNext.contains("男") || lowerNext.contains("女") ||
                       lowerNext.contains("sex") {
                        continue
                    }
                    // 如果是短文本且不包含斜杠标签格式，可能是国籍
                    if nextLine.count <= 20 && !nextLine.contains("/") && nextLine.count > 2 {
                        // 进一步检查是否看起来像国籍（字母或汉字组合）
                        let hasOnlyLettersOrChinese = nextLine.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted.subtracting(CharacterSet.whitespaces)) == nil
                        if hasOnlyLettersOrChinese {
                            result.nationality = nextLine
                            print("    ✓ [护照] 从第\(i)行提取国籍: \(nextLine)")
                            break
                        }
                    }
                }
            }
            
            // 常见国籍识别
            if trimmed.contains("CHN") || trimmed.contains("CHINESE") || trimmed.contains("中国") || trimmed.contains("CHINA") {
                if result.nationality == nil {
                    result.nationality = "中国"
                    print("    ✓ [护照] 关键词匹配国籍: 中国")
                }
            }
            
            // 性别识别
            if lower.contains("sex") || lower.contains("性别") {
                print("    ℹ️ [护照] 第\(index)行发现性别标签: \(trimmed)")
                // 先检查当前行
                if trimmed.contains("M") || trimmed.contains("MALE") || trimmed.contains("男") {
                    result.gender = "男"
                    print("    ✓ [护照] 识别性别: 男")
                } else if trimmed.contains("F") || trimmed.contains("FEMALE") || trimmed.contains("女") {
                    result.gender = "女"
                    print("    ✓ [护照] 识别性别: 女")
                }
                // 如果当前行没找到，检查下一行
                else if index + 1 < texts.count {
                    let nextLine = texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if nextLine.contains("M") || nextLine.contains("MALE") || nextLine.contains("男") {
                        result.gender = "男"
                        print("    ✓ [护照] 从第\(index+1)行识别性别: 男")
                    } else if nextLine.contains("F") || nextLine.contains("FEMALE") || nextLine.contains("女") {
                        result.gender = "女"
                        print("    ✓ [护照] 从第\(index+1)行识别性别: 女")
                    }
                }
            }
            
            // 出生日期识别 - 多种格式
            if lower.contains("date of birth") || (lower.contains("birth") && !lower.contains("place")) || lower.contains("出生日期") {
                print("    ℹ️ [护照] 第\(index)行发现出生日期标签: \(trimmed)")
                // 检查当前行和下一行
                for i in index..<min(index + 2, texts.count) {
                    let line = texts[i].trimmingCharacters(in: .whitespacesAndNewlines)
                    // DD MMM YYYY 格式 (如 "18 FEB 1975")
                    if let dateMatch = line.range(of: #"\d{1,2}\s+[A-Z]{3}\s+\d{4}"#, options: .regularExpression) {
                        result.birthDate = String(line[dateMatch])
                        print("    ✓ [护照] 正则匹配出生日期(DD MMM YYYY): \(result.birthDate ?? "")")
                        break
                    }
                    // YYYY-MM-DD 或 YYYY年MM月DD日 格式
                    else if let dateMatch = line.range(of: #"\d{4}[-/年]\d{1,2}[-/月]\d{1,2}"#, options: .regularExpression) {
                        result.birthDate = String(line[dateMatch])
                        print("    ✓ [护照] 正则匹配出生日期(YYYY-MM-DD): \(result.birthDate ?? "")")
                        break
                    }
                }
            }
            
            // 有效期识别
            if lower.contains("date of expiry") || lower.contains("expiry") || lower.contains("有效期") {
                print("    ℹ️ [护照] 第\(index)行发现有效期标签: \(trimmed)")
                // 检查当前行和下一行
                for i in index..<min(index + 2, texts.count) {
                    let line = texts[i].trimmingCharacters(in: .whitespacesAndNewlines)
                    // DD 月/MMM YYYY 格式 (如 "04 8月/AUG 2026")
                    if let dateMatch = line.range(of: #"\d{1,2}\s+\d{1,2}?月?/[A-Z]{3}\s+\d{4}"#, options: .regularExpression) {
                        result.expiryDate = String(line[dateMatch])
                        print("    ✓ [护照] 正则匹配有效期(混合格式): \(result.expiryDate ?? "")")
                        break
                    }
                    // DD MMM YYYY 格式
                    else if let dateMatch = line.range(of: #"\d{1,2}\s+[A-Z]{3}\s+\d{4}"#, options: .regularExpression) {
                        result.expiryDate = String(line[dateMatch])
                        print("    ✓ [护照] 正则匹配有效期(DD MMM YYYY): \(result.expiryDate ?? "")")
                        break
                    }
                    // YYYY-MM-DD 格式
                    else if let dateMatch = line.range(of: #"\d{4}[-/年]\d{1,2}[-/月]\d{1,2}"#, options: .regularExpression) {
                        result.expiryDate = String(line[dateMatch])
                        print("    ✓ [护照] 正则匹配有效期(YYYY-MM-DD): \(result.expiryDate ?? "")")
                        break
                    }
                }
            }

            // 签发日期识别(Date of Issue) - 容错OCR错误(bf/of)
            if lower.contains("date of issue") || lower.contains("date bf issue") || lower.contains("issue date") || lower.contains("发日期") || lower.contains("签发日期") {
                print("    ℹ️ [护照] 第\(index)行发现签发日期标签: \(trimmed)")
                for i in index..<min(index + 2, texts.count) {
                    let line = texts[i].trimmingCharacters(in: .whitespacesAndNewlines)
                    // DD 月/MMM YYYY 混合格式
                    if let dateMatch = line.range(of: #"\d{1,2}\s+\d{1,2}?月?/[A-Z]{3}\s+\d{4}"#, options: .regularExpression) {
                        result.issueDate = String(line[dateMatch])
                        print("    ✓ [护照] 正则匹配签发日期(混合格式): \(result.issueDate ?? "")")
                        break
                    }
                    // DD MMM YYYY
                    else if let dateMatch = line.range(of: #"\d{1,2}\s+[A-Z]{3}\s+\d{4}"#, options: .regularExpression) {
                        result.issueDate = String(line[dateMatch])
                        print("    ✓ [护照] 正则匹配签发日期(DD MMM YYYY): \(result.issueDate ?? "")")
                        break
                    }
                    // YYYY-MM-DD
                    else if let dateMatch = line.range(of: #"\d{4}[-/年]\d{1,2}[-/月]\d{1,2}"#, options: .regularExpression) {
                        result.issueDate = String(line[dateMatch])
                        print("    ✓ [护照] 正则匹配签发日期(YYYY-MM-DD): \(result.issueDate ?? "")")
                        break
                    }
                }
            }

            // 签发机关 / Authority (容错OCR拼写错误)
            if lower.contains("authority") || lower.contains("authoriy") || lower.contains("签发机关") || lower.contains("exit & entry") {
                print("    ℹ️ [护照] 第\(index)行发现签发机关标签: \(trimmed)")
                // 尝试多种拼写变体
                if let value = extractValueAfterLabel(trimmed, label: "Authority") 
                    ?? extractValueAfterLabel(trimmed, label: "Authoriy")
                    ?? extractValueAfterLabel(trimmed, label: "签发机关") {
                    result.issuer = value
                    print("    ✓ [护照] 从标签提取签发机关: \(value)")
                } else if index + 1 < texts.count {
                    let nextLine = texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                    // 常见的签发机关文本
                    if nextLine.lowercased().contains("exit") || nextLine.contains("公安") || nextLine.count > 4 {
                        result.issuer = nextLine
                        print("    ✓ [护照] 从下一行提取签发机关: \(nextLine)")
                    }
                }
            }
            
            // 识别并收集MRZ行（移除所有空格和特殊字符后检查）
            let cleaned = trimmed.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "<", with: "<")
            
            // MRZ第一行：P< 开头，长度约44字符（容忍度35+）
            if cleaned.hasPrefix("P<") && cleaned.count >= 35 {
                print("    🔤 [护照] 第\(index)行识别为MRZ第一行(姓名行)")
                print("        原始: \(trimmed)")
                print("        清理后: \(cleaned)")
                mrzLine1 = trimmed
            }
            // MRZ第二行：长度30+字符，包含护照号开头（如E72340946）
            else if cleaned.count >= 30 && mrzLine2 == nil {
                let hasDigits = cleaned.rangeOfCharacter(from: .decimalDigits) != nil
                let hasLetters = cleaned.rangeOfCharacter(from: .letters) != nil
                // MRZ第二行通常以护照号开头（如E72340946）
                let startsWithPassport = cleaned.range(of: #"^[A-Z][0-9]{8}"#, options: .regularExpression) != nil
                
                if (hasDigits && hasLetters) && (startsWithPassport || mrzLine1 != nil) {
                    print("    🔤 [护照] 第\(index)行识别为MRZ第二行(数据行)")
                    print("        原始: \(trimmed)")
                    print("        清理后: \(cleaned)")
                    mrzLine2 = trimmed
                }
            }
            // 打印长文本行用于调试
            else if cleaned.count >= 25 && cleaned.count < 30 {
                print("    🔍 [调试] 第\(index)行中等长度文本(\(cleaned.count)字符): \(trimmed)")
            }
        }
        
        // 使用MRZ矫正器解析
        if let line1 = mrzLine1, let line2 = mrzLine2 {
            print("  🔧 [MRZ矫正] 使用自动矫正器解析MRZ...")
            do {
                let parsed = try mrzCorrector.parseWithAutoCorrection(line1: line1, line2: line2)
                print("  ✅ [MRZ矫正] 解析成功, 校验通过: \(parsed.checksumsValid)")
                
                // 使用MRZ解析的高质量数据（优先级高）
                if result.name == nil || parsed.checksumsValid {
                    let fullName = [parsed.surname, parsed.givenNames].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
                    if !fullName.isEmpty {
                        result.name = fullName
                        print("    ✓ [MRZ矫正] 提取姓名: \(fullName)")
                    }
                }
                
                if result.passportNumber == nil || parsed.checksumsValid {
                    result.passportNumber = parsed.passportNumber
                    print("    ✓ [MRZ矫正] 提取护照号: \(parsed.passportNumber ?? "nil")")
                }
                
                if result.nationality == nil || parsed.checksumsValid {
                    result.nationality = parsed.nationality
                    print("    ✓ [MRZ矫正] 提取国籍: \(parsed.nationality ?? "nil")")
                }
                
                if result.birthDate == nil || parsed.checksumsValid {
                    result.birthDate = parsed.birthDateYYMMDD
                    print("    ✓ [MRZ矫正] 提取出生日期: \(parsed.birthDateYYMMDD ?? "nil")")
                }
                
                if result.expiryDate == nil || parsed.checksumsValid {
                    result.expiryDate = parsed.expiryDateYYMMDD
                    print("    ✓ [MRZ矫正] 提取有效期: \(parsed.expiryDateYYMMDD ?? "nil")")
                }
                
                if result.gender == nil || parsed.checksumsValid {
                    result.gender = parsed.sex == "M" ? "男" : (parsed.sex == "F" ? "女" : nil)
                    print("    ✓ [MRZ矫正] 提取性别: \(result.gender ?? "nil")")
                }
                
                if !parsed.checksumsValid {
                    print("    ⚠️ [MRZ矫正] 校验和未通过，建议用户确认或重新拍照")
                }
                
            } catch {
                print("  ❌ [MRZ矫正] 解析失败: \(error)")
                // 降级使用传统方法
                if let line1 = mrzLine1 {
                    parseMRZ(line1, result: &result)
                }
                if let line2 = mrzLine2 {
                    parseMRZ(line2, result: &result)
                }
            }
        } else if mrzLine1 != nil || mrzLine2 != nil {
            // 只有部分MRZ行，使用传统方法
            print("  ⚠️ [MRZ] 只识别到部分MRZ行，使用传统解析")
            if let line = mrzLine1 {
                parseMRZ(line, result: &result)
            }
            if let line = mrzLine2 {
                parseMRZ(line, result: &result)
            }
        }
        
        print("  ✅ [护照解析] 完成 - 姓名:\(result.name ?? "nil"), 护照号:\(result.passportNumber ?? "nil"), 国籍:\(result.nationality ?? "nil")")
        return result
    }
    
    private func parseMRZ(_ mrz: String, result: inout PassportOCRResult) {
        // MRZ 第一行格式: P<CHNLAST<<FIRST<MIDDLE<<<<<<<<<<<<<<<<<<
        // MRZ 第二行格式: PASSPORT#<CHECK<NATIONALITY<BIRTHDATE<CHECK<SEX<EXPIRY<CHECK<<<<<<<<<CHECK
        
        print("      🔍 [MRZ] 解析MRZ行: \(mrz)")
        
        let cleaned = mrz.replacingOccurrences(of: " ", with: "")
        
        if cleaned.hasPrefix("P<") {
            print("      📋 [MRZ] 识别为第一行(姓名行)")
            // 第一行 - 提取姓名
            let namePart = String(cleaned.dropFirst(5)) // 跳过 P<CHN
            let names = namePart.split(separator: "<").map { String($0) }.filter { !$0.isEmpty }
            print("      🔤 [MRZ] 提取到姓名组件: \(names)")
            
            if names.count >= 2 && result.name == nil {
                result.name = names.joined(separator: " ")
                print("      ✓ [MRZ] 提取姓名: \(result.name ?? "")")
            } else if names.count == 1 && result.name == nil {
                result.name = names[0]
                print("      ✓ [MRZ] 提取姓名(单段): \(result.name ?? "")")
            }
        } else if cleaned.count >= 44 {
            print("      📋 [MRZ] 识别为第二行(数据行), 长度: \(cleaned.count)")
            // 第二行 - 提取护照号、出生日期、有效期等
            // 位置: 0-8 护照号, 13-18 出生日期(YYMMDD), 21 性别, 22-27 有效期(YYMMDD)
            if result.passportNumber == nil {
                let passportNum = String(cleaned.prefix(9)).replacingOccurrences(of: "<", with: "")
                if !passportNum.isEmpty {
                    result.passportNumber = passportNum
                    print("      ✓ [MRZ] 提取护照号: \(passportNum)")
                }
            }
            
            // 提取日期 (YYMMDD格式)
            if cleaned.count >= 20 && result.birthDate == nil {
                let birthStr = String(cleaned.dropFirst(13).prefix(6))
                if let _ = Int(birthStr) {
                    result.birthDate = formatYYMMDD(birthStr)
                    print("      ✓ [MRZ] 提取出生日期: \(birthStr) -> \(result.birthDate ?? "")")
                }
            }
            
            if cleaned.count >= 28 && result.expiryDate == nil {
                let expiryStr = String(cleaned.dropFirst(21).prefix(6))
                if let _ = Int(expiryStr) {
                    result.expiryDate = formatYYMMDD(expiryStr)
                    print("      ✓ [MRZ] 提取有效期: \(expiryStr) -> \(result.expiryDate ?? "")")
                }
            }
            
            // 性别 (位置21)
            if cleaned.count >= 21 && result.gender == nil {
                let sex = String(cleaned.dropFirst(20).prefix(1))
                if sex == "M" {
                    result.gender = "男"
                    print("      ✓ [MRZ] 提取性别: M -> 男")
                } else if sex == "F" {
                    result.gender = "女"
                    print("      ✓ [MRZ] 提取性别: F -> 女")
                }
            }
        } else {
            print("      ⚠️ [MRZ] MRZ行长度不足(\(cleaned.count)字符)，跳过")
        }
    }
    
    // 格式化 YYMMDD 为更易读的格式
    private func formatYYMMDD(_ yymmdd: String) -> String {
        guard yymmdd.count == 6, let _ = Int(yymmdd) else { return yymmdd }
        
        let yy = String(yymmdd.prefix(2))
        let mm = String(yymmdd.dropFirst(2).prefix(2))
        let dd = String(yymmdd.dropFirst(4).prefix(2))
        
        // 简单判断世纪
        let yearPrefix = Int(yy)! <= 30 ? "20" : "19"
        return "\(yearPrefix)\(yy)-\(mm)-\(dd)"
    }
    
    // MARK: - Driver's License Recognition
    
    private func parseDriversLicenseTexts(_ texts: [String]) -> DriversLicenseOCRResult {
        var result = DriversLicenseOCRResult()
        
        for (index, text) in texts.enumerated() {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 姓名 - 优先从主页提取（避免副页OCR错误）
            if (trimmed.contains("姓名") || trimmed.contains("糕名")) && result.name == nil {
                // 提取标签后的值
                var extractedName = extractValueAfterLabel(trimmed, label: "姓名")
                    ?? extractValueAfterLabel(trimmed, label: "糕名")
                
                // 如果没有提取到，检查下一行
                if extractedName == nil && index + 1 < texts.count {
                    let nextLine = texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                    // 确保下一行不是其他标签
                    if !nextLine.contains("性别") && !nextLine.contains("国籍") && !nextLine.isEmpty {
                        extractedName = nextLine
                    }
                }
                
                // 只有在主页（非副页）时才设置姓名
                if let name = extractedName, !trimmed.contains("副页") {
                    result.name = name
                }
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
            
            // 出生日期 - 必须明确包含"出生"标签，避免误取有效期
            if trimmed.contains("出生") && result.birthDate == nil {
                if let birthMatch = trimmed.range(of: #"\d{4}年\d{1,2}月\d{1,2}日"#, options: .regularExpression) {
                    result.birthDate = String(trimmed[birthMatch])
                } else if let birthMatch = trimmed.range(of: #"\d{4}-\d{2}-\d{2}"#, options: .regularExpression) {
                    result.birthDate = String(trimmed[birthMatch])
                }
            }
            
            // 驾照号码 - 通常12位数字或18位（可能以X结尾）
            if result.licenseNumber == nil {
                // 方式1: 当前行包含"证号"标签，尝试在同行或下一行提取
                if trimmed.contains("证号") && !trimmed.contains("副页") {
                    var licenseNumber: String?
                    
                    // 先尝试从同行提取
                    if let licenseMatch = trimmed.range(of: #"\d{17}[0-9Xx]|\d{12}|\d{18}"#, options: .regularExpression) {
                        licenseNumber = String(trimmed[licenseMatch])
                    }
                    // 如果同行没有，检查下一行
                    else if index + 1 < texts.count {
                        let nextLine = texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                        if let licenseMatch = nextLine.range(of: #"\d{17}[0-9Xx]|\d{12}|\d{18}"#, options: .regularExpression) {
                            licenseNumber = String(nextLine[licenseMatch])
                        }
                    }
                    
                    if let number = licenseNumber, !trimmed.contains("身份证") {
                        result.licenseNumber = number
                    }
                }
                // 方式2: 直接匹配18位数字+X格式（驾照特征）
                else if let licenseMatch = trimmed.range(of: #"\d{17}[0-9Xx]"#, options: .regularExpression) {
                    let number = String(trimmed[licenseMatch])
                    // 确保不是在副页或身份证相关的行
                    if !trimmed.contains("副页") && !trimmed.contains("身份证") {
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
                    // 停止条件：遇到其他标签或空行
                    if part.isEmpty || part.contains("初次领证") || part.contains("有效期") || part.contains("出生") {
                        break
                    }
                    // 过滤纯英文标签（如 "Avidns"、"Address" 等）
                    if !part.allSatisfy({ $0.isASCII && $0.isLetter }) {
                        addressParts.append(part)
                    }
                }
                if !addressParts.isEmpty {
                    // 清理地址中混入的英文标签
                    let cleanedAddress = addressParts.joined()
                        .replacingOccurrences(of: #"[A-Za-z]{3,}"#, with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleanedAddress.isEmpty {
                        result.address = cleanedAddress
                    }
                }
            }
            
            // 初次领证日期
            if (trimmed.contains("初次领证") || trimmed.contains("初次领証")) && result.issueDate == nil {
                var issueDate: String?
                
                // 尝试从同行提取完整日期
                if let dateMatch = trimmed.range(of: #"\d{4}年\d{1,2}月\d{1,2}日"#, options: .regularExpression) {
                    issueDate = String(trimmed[dateMatch])
                } else if let dateMatch = trimmed.range(of: #"\d{4}-\d{2}-\d{2}"#, options: .regularExpression) {
                    issueDate = String(trimmed[dateMatch])
                }
                // 尝试从同行提取不完整日期（如 "2000-03-"）
                else if let dateMatch = trimmed.range(of: #"\d{4}-\d{2}-?"#, options: .regularExpression) {
                    issueDate = String(trimmed[dateMatch]).replacingOccurrences(of: "-$", with: "", options: .regularExpression)
                }
                
                // 如果同行没有，检查下一行
                if issueDate == nil && index + 1 < texts.count {
                    let nextLine = texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if let dateMatch = nextLine.range(of: #"\d{4}年\d{1,2}月\d{1,2}日"#, options: .regularExpression) {
                        issueDate = String(nextLine[dateMatch])
                    } else if let dateMatch = nextLine.range(of: #"\d{4}-\d{2}-\d{2}"#, options: .regularExpression) {
                        issueDate = String(nextLine[dateMatch])
                    } else if let dateMatch = nextLine.range(of: #"\d{4}-\d{2}-?"#, options: .regularExpression) {
                        issueDate = String(nextLine[dateMatch]).replacingOccurrences(of: "-$", with: "", options: .regularExpression)
                    }
                }
                
                result.issueDate = issueDate
            }
            
            // 有效期限
            if (trimmed.contains("有效期限") || trimmed.contains("有效期")) && result.validFrom == nil && result.validUntil == nil {
                var validFrom: String?
                var validUntil: String?
                
                // 格式1: 同行包含完整期限 "YYYY-MM-DD至YYYY-MM-DD"
                if let validMatch = trimmed.range(of: #"\d{4}[-年]\d{2}[-月]\d{2}[日]?至\d{4}[-年]\d{2}[-月]\d{2}[日]?"#, options: .regularExpression) {
                    let validPeriod = String(trimmed[validMatch])
                    let dates = validPeriod.split(separator: "至").map { String($0) }
                    if dates.count == 2 {
                        validFrom = dates[0]
                        validUntil = dates[1]
                    }
                }
                // 格式2: 标签和日期分离，需要从后续行提取
                else {
                    // 检查接下来的2-3行
                    for i in (index + 1)..<min(index + 4, texts.count) {
                        let line = texts[i].trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // 提取validFrom（第一个日期）
                        if validFrom == nil {
                            if let dateMatch = line.range(of: #"\d{4}-\d{2}-\d{2}"#, options: .regularExpression) {
                                validFrom = String(line[dateMatch])
                                continue
                            }
                        }
                        
                        // 提取validUntil（"至"后的日期）
                        if line.contains("至") {
                            if let dateMatch = line.range(of: #"\d{4}-\d{2}-\d{2}"#, options: .regularExpression) {
                                validUntil = String(line[dateMatch])
                                break
                            }
                        }
                    }
                }
                
                result.validFrom = validFrom
                result.validUntil = validUntil
            }
            
            // 准驾车型
            if trimmed.contains("准驾车型") && result.licenseClass == nil {
                var licenseClass: String?
                
                // 尝试从同行提取
                licenseClass = extractValueAfterLabel(trimmed, label: "准驾车型")
                
                // 如果没有提取到，尝试正则匹配常见车型
                if licenseClass == nil {
                    if let classMatch = trimmed.range(of: #"[A-D][1-3]"#, options: .regularExpression) {
                        licenseClass = String(trimmed[classMatch])
                    }
                }
                
                // 如果同行没有，检查下一行
                if licenseClass == nil && index + 1 < texts.count {
                    let nextLine = texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                    // 匹配常见车型格式
                    if let classMatch = nextLine.range(of: #"[A-D][1-3]"#, options: .regularExpression) {
                        licenseClass = String(nextLine[classMatch])
                    }
                }
                
                result.licenseClass = licenseClass
            }
        }
        
        return result
    }
    
    // MARK: - Business License Recognition
    
    private func parseBusinessLicenseTexts(_ texts: [String]) -> BusinessLicenseOCRResult {
        var result = BusinessLicenseOCRResult()
        
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
    
    private func performOCR(on image: UIImage) async throws -> [OCRTextObservation] {
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
                
                // 按照y坐标排序（从上到下），y接近时按x坐标排序（从左到右）
                // Vision坐标系原点在左下角，y值越大越靠上
                let sortedObservations = observations.sorted { obs1, obs2 in
                    let y1 = obs1.boundingBox.origin.y
                    let y2 = obs2.boundingBox.origin.y
                    let height = max(obs1.boundingBox.height, obs2.boundingBox.height)
                    
                    // 如果y坐标差异小于高度的一半，认为在同一行，按x坐标排序
                    if abs(y1 - y2) < height * 0.5 {
                        return obs1.boundingBox.origin.x < obs2.boundingBox.origin.x
                    }
                    // 否则按y坐标降序（从上到下）
                    return y1 > y2
                }
                
                let textObservations = sortedObservations.compactMap { observation -> OCRTextObservation? in
                    guard let text = observation.topCandidates(1).first?.string else { return nil }
                    return OCRTextObservation(text: text, boundingBox: observation.boundingBox)
                }
                
                continuation.resume(returning: textObservations)
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
    
    /// 提取MRZ中不包含的护照补充字段（签发日期、签发地点、签发机关等）
    private func extractSupplementaryPassportFields(from observations: [OCRTextObservation]) -> (issueDate: String?, issuePlace: String?, issuer: String?) {
        var issueDate: String?
        var issuePlace: String?
        var issuer: String?
        
        print("  📊 [补充字段] 开始从\(observations.count)个观察结果中提取")
        
        for (index, obs) in observations.enumerated() {
            let trimmed = obs.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = trimmed.lowercased()
            
            // 签发日期（容错OCR错误：bf/of, dato/date, isste/issue）
            if issueDate == nil && (lower.contains("date of issue") || lower.contains("date bf issue") || 
                                     lower.contains("dato") || lower.contains("isste") ||
                                     lower.contains("issue date") || lower.contains("发日期") || lower.contains("签发日期")) {
                print("  🔍 [补充字段] 找到签发日期标签[\(index)]: \(trimmed) (y=\(obs.boundingBox.origin.y))")
                // 查找空间上位于当前标签下方的文本
                var foundBelow = false
                for (nextIdx, nextObs) in observations[(index+1)...].enumerated() {
                    let actualIdx = index + 1 + nextIdx
                    if nextObs.isBelow(obs) {
                        foundBelow = true
                        let nextLine = nextObs.text.trimmingCharacters(in: .whitespacesAndNewlines)
                        let nextLower = nextLine.lowercased()
                        print("    → 找到下方文本[\(actualIdx)]: \(nextLine) (y=\(nextObs.boundingBox.origin.y))")
                        
                        // 先尝试匹配日期格式（优先级最高）
                        // 混合格式：14 3月/MAR 2023
                        if let dateMatch = nextLine.range(of: #"\d{1,2}\s+\d{1,2}?月?/[A-Z]{3}\s+\d{4}"#, options: .regularExpression) {
                            issueDate = String(nextLine[dateMatch])
                            print("    ✅ 提取签发日期(混合): \(issueDate!)")
                            break
                        }
                        // DD MMM YYYY
                        else if let dateMatch = nextLine.range(of: #"\d{1,2}\s+[A-Z]{3}\s+\d{4}"#, options: .regularExpression) {
                            issueDate = String(nextLine[dateMatch])
                            print("    ✅ 提取签发日期(标准): \(issueDate!)")
                            break
                        }
                        // YYYY-MM-DD
                        else if let dateMatch = nextLine.range(of: #"\d{4}[-/年]\d{1,2}[-/月]\d{1,2}"#, options: .regularExpression) {
                            issueDate = String(nextLine[dateMatch])
                            print("    ✅ 提取签发日期(YYYY-MM-DD): \(issueDate!)")
                            break
                        }
                        // 如果不是日期格式，检查是否是标签行
                        else if isLabelLine(nextLine) {
                            print("    ⚠️ 下方是标签行，跳过")
                            // 继续查找下一个
                        }
                        // 检查是否是其他字段的标签（如遇到"签发地点"等，停止查找）
                        else if nextLower.contains("place of issue") || nextLower.contains("签发地点") ||
                                nextLower.contains("authority") || nextLower.contains("issuing") {
                            print("    ⚠️ 遇到其他字段标签，停止查找")
                            break
                        }
                        else {
                            print("    ⚠️ 下方文本无法匹配日期格式，继续查找: \(nextLine)")
                            // 继续查找下一个位于下方的文本
                        }
                    }
                }
                if !foundBelow {
                    print("    ❌ 未找到位于下方的文本")
                }
            }
            
            // 签发地点（排除出生地点）
            if issuePlace == nil && !lower.contains("birth") && !lower.contains("bitth") && !lower.contains("出生") &&
               (lower.contains("place of issue") || lower.contains("place of issuc") || lower.contains("签发地点")) {
                print("  🔍 [补充字段] 找到签发地点标签[\(index)]: \(trimmed) (y=\(obs.boundingBox.origin.y))")
                // 查找空间上位于当前标签下方的文本
                var foundBelow = false
                for (nextIdx, nextObs) in observations[(index+1)...].enumerated() {
                    let actualIdx = index + 1 + nextIdx
                    if nextObs.isBelow(obs) {
                        foundBelow = true
                        let nextLine = nextObs.text.trimmingCharacters(in: .whitespacesAndNewlines)
                        let nextLower = nextLine.lowercased()
                        print("    → 找到下方文本[\(actualIdx)]: \(nextLine) (y=\(nextObs.boundingBox.origin.y))")
                        
                        // 检查是否是其他字段的标签行
                        if isLabelLine(nextLine) && (nextLower.contains("authority") || 
                                                      nextLower.contains("signature") ||
                                                      nextLower.contains("expiry") ||
                                                      nextLower.contains("date of issue") ||
                                                      nextLower.contains("签发日期")) {
                            print("    ⚠️ 下方是其他字段标签行，停止查找")
                            break
                        }
                        // 排除出生地（可能在签发地点之前出现）
                        else if nextLower.contains("birth") || nextLower.contains("出生") {
                            print("    ⚠️ 这是出生地点，继续查找签发地点")
                            // 继续查找下一个
                        }
                        else if nextLine.count > 1 && nextLine.count < 50 {
                            issuePlace = nextLine
                            print("    ✅ 提取签发地点: \(issuePlace!)")
                            break
                        } else {
                            print("    ⚠️ 下方文本长度不符合(\(nextLine.count))，继续查找")
                            // 继续查找下一个
                        }
                    }
                }
                if !foundBelow {
                    print("    ❌ 未找到位于下方的文本")
                }
            }
            
            // 签发机关（容错OCR拼写错误：authoriy/authority）
            if issuer == nil && (lower.contains("authority") || lower.contains("authoriy") || 
                                  lower.contains("签发机关")) {
                // 查找空间上位于当前标签下方的文本
                for nextObs in observations[(index+1)...] {
                    if nextObs.isBelow(obs) {
                        let nextLine = nextObs.text.trimmingCharacters(in: .whitespacesAndNewlines)
                        let nextLower = nextLine.lowercased()
                        // 下一行不能是其他标签行
                        if !nextLine.contains("/") &&
                           !nextLower.contains("signature") &&
                           nextLine.count > 4 {
                            issuer = nextLine
                        }
                        break  // 只检查第一个位于下方的文本
                    }
                }
            }
        }
        
        return (issueDate, issuePlace, issuer)
    }
    
    private func extractValueAfterLabel(_ text: String, label: String) -> String? {
        // 对于双语标签（如"姓名/Name"），需要匹配斜杠后的英文部分
        let searchLabel: String
        if let slashIndex = text.firstIndex(of: "/") {
            // 检查斜杠后是否有英文标签
            let afterSlash = String(text[text.index(after: slashIndex)...])
            if afterSlash.lowercased().contains(label.lowercased()) {
                searchLabel = label
            } else {
                searchLabel = label
            }
        } else {
            searchLabel = label
        }
        
        guard let range = text.range(of: searchLabel, options: .caseInsensitive) else { return nil }
        var value = String(text[range.upperBound...])
        // 移除常见分隔符
        value = value.trimmingCharacters(in: CharacterSet(charactersIn: "：: "))
        
        // 如果值仍然包含标签文本（如"/Date of birth"），说明没有实际值
        if value.hasPrefix("/") || value.contains(label) {
            return nil
        }
        
        return value.isEmpty ? nil : value
    }
}

// MARK: - OCR Errors

// MARK: - Helpers

extension OCRServiceImpl {
    /// 提取可能的中文姓名（2-4个连续中文字符），优先取“姓名/Name”标签下的下一行
    fileprivate func extractChineseName(from texts: [String]) -> String? {
        // 已弃用：此方法存在空间定位问题（取idx+1可能是右侧而非下方文本）
        // 改用 extractChineseNameFromObservations 基于坐标的方法
        // 兜底：扫描所有行，找 2-4 位的纯中文（排除常见误识别）
        for line in texts {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = trimmed.lowercased()
            // 排除护照头部的常见文本
            if lower.contains("协助") || lower.contains("民共和国") || 
               lower.contains("republic") || lower.contains("china") ||
               lower.contains("passport") {
                continue
            }
            if containsChinese(trimmed) && trimmed.count >= 2 && trimmed.count <= 8 {
                return trimmed
            }
        }
        return nil
    }
    
    /// 从OCR观察结果中提取中文姓名（基于空间坐标）
    fileprivate func extractChineseNameFromObservations(from observations: [OCRTextObservation]) -> String? {
        // 找到"姓名/Name"标签
        for (idx, obs) in observations.enumerated() {
            let trimmed = obs.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = trimmed.lowercased()
            if (trimmed.contains("姓名") || lower.contains("name")) && 
               (trimmed.contains("/") || trimmed.contains(":")) {
                // 查找空间上位于标签下方的文本
                for nextObs in observations[(idx+1)...] {
                    if nextObs.isBelow(obs) {
                        let nextText = nextObs.text.trimmingCharacters(in: .whitespacesAndNewlines)
                        let nextLower = nextText.lowercased()
                        // 排除护照号（如EP0390865）、英文姓名、性别、其他标签
                        let isPureAlphanumeric = nextText.allSatisfy({ $0.isLetter || $0.isNumber })
                        let isEnglishName = nextText.allSatisfy({ $0.isLetter || $0.isWhitespace || $0 == "," })
                        if nextLower.contains("passport") || nextLower.contains("/sex") ||
                           nextLower.contains("/m") || nextLower.contains("/f") ||
                           isPureAlphanumeric || isEnglishName {
                            continue
                        }
                        if containsChinese(nextText) && nextText.count >= 2 && nextText.count <= 8 {
                            return nextText
                        }
                    }
                }
            }
        }
        // 兜底：扫描所有观察结果，找纯中文姓名
        for obs in observations {
            let trimmed = obs.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = trimmed.lowercased()
            if lower.contains("协助") || lower.contains("民共和国") || 
               lower.contains("republic") || lower.contains("china") ||
               lower.contains("passport") || trimmed.contains("/") {
                continue
            }
            if containsChinese(trimmed) && trimmed.count >= 2 && trimmed.count <= 8 {
                return trimmed
            }
        }
        return nil
    }

    /// 将 YYMMDD 转为 yyyyMMdd，简单世纪推断：若年份 > 当前年份%100 则归为 1900，否则 2000
    fileprivate func formatMRZDate(_ yymmdd: String?, referenceYear: Int?, isBirthDate: Bool) -> String? {
        guard let yymmdd, yymmdd.count == 6 else { return yymmdd }
        let yyString = String(yymmdd.prefix(2))
        let mmString = String(yymmdd.dropFirst(2).prefix(2))
        let ddString = String(yymmdd.suffix(2))
        guard let yy = Int(yyString) else { return yymmdd }
        
        let century: Int
        if isBirthDate {
            // 出生日期：使用当前年份判断
            let currentYY = Calendar.current.component(.year, from: Date()) % 100
            // 出生年份不可能在未来，如果yy<=当前yy认为是本世纪，否则是上世纪
            century = (yy <= currentYY + 5) ? 2000 : 1900
        } else {
            // 有效期日期：使用出生年份作为参考
            if let refYear = referenceYear {
                let refYY = refYear % 100
                // 有效期年份必定 >= 出生年份
                // 如果yy < refYY，说明跨世纪了（如出生1975 yy=75，有效期2033 yy=33）
                century = (yy >= refYY) ? (refYear / 100) * 100 : ((refYear / 100) + 1) * 100
            } else {
                // 没有参考年份时，使用当前年份+20年作为阈值
                let currentYY = Calendar.current.component(.year, from: Date()) % 100
                century = (yy <= currentYY + 20) ? 2000 : 1900
            }
        }
        
        let yyyy = century + yy
        return String(format: "%04d%@%@", yyyy, mmString, ddString)
    }
    
    fileprivate func extractYearFromDate(_ dateString: String?) -> Int? {
        guard let dateString else { return nil }
        // 尝试提取4位年份
        if let match = dateString.range(of: #"\d{4}"#, options: .regularExpression) {
            return Int(String(dateString[match]))
        }
        return nil
    }

    fileprivate func containsChinese(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if scalar.value >= 0x4E00 && scalar.value <= 0x9FFF {
                return true
            }
        }
        return false
    }
}

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
