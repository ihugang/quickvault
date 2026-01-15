//
//  OCRFieldMapper.swift
//  QuickHold
//
//  Intelligent field mapping from OCR results to card templates
//

import Foundation
import QuickHoldCore

// MARK: - Field Mapping Service

/// OCR字段映射服务
final class OCRFieldMapper {
    
    static let shared = OCRFieldMapper()
    
    private init() {}
    
    // MARK: - Document Type to Card Type Mapping
    
    /// 将文档类型映射到卡片类型
    func mapDocumentTypeToCardType(_ documentType: DocumentType) -> CardType {
        switch documentType {
        case .idCard:
            return .idCard
        case .passport:
            return .passport
        case .driversLicense:
            return .driversLicense
        case .businessLicense:
            return .businessLicense
        case .residencePermit:
            return .residencePermit
        case .socialSecurityCard:
            return .socialSecurityCard
        case .bankCard:
            return .bankCard
        case .invoice:
            return .invoice
        case .unknown:
            return .general
        }
    }
    
    // MARK: - OCR Result to Card Fields
    
    /// 将OCR结果转换为卡片字段
    func mapToCardFields(_ ocrResult: any OCRResult) -> (cardType: CardType, fields: [String: String]) {
        let cardType = mapDocumentTypeToCardType(ocrResult.documentType)
        let fields = ocrResult.toCardFields()
        
        // 应用后处理优化
        let optimizedFields = postProcessFields(fields, for: cardType)
        
        return (cardType, optimizedFields)
    }
    
    // MARK: - Field Post-Processing
    
    /// 后处理字段，进行格式化和验证
    private func postProcessFields(_ fields: [String: String], for cardType: CardType) -> [String: String] {
        var processed = fields
        
        // 标准化日期格式
        processed = normalizeDateFields(processed)
        
        // 清理空白字符
        processed = trimFields(processed)
        
        // 验证并修正特定字段
        switch cardType {
        case .idCard:
            processed = validateIDCardFields(processed)
        case .passport:
            processed = validatePassportFields(processed)
        case .driversLicense:
            processed = validateDriversLicenseFields(processed)
        case .businessLicense:
            processed = validateBusinessLicenseFields(processed)
        default:
            break
        }
        
        return processed
    }
    
    // MARK: - Field Normalization
    
    /// 标准化日期字段
    private func normalizeDateFields(_ fields: [String: String]) -> [String: String] {
        var normalized = fields
        
        let dateKeys = ["birthDate", "issueDate", "expiryDate", "validFrom", "validUntil", "establishedDate"]
        
        for key in dateKeys {
            if let dateValue = normalized[key] {
                // 将 "YYYY年MM月DD日" 格式转换为 "YYYY-MM-DD"
                let standardized = dateValue
                    .replacingOccurrences(of: "年", with: "-")
                    .replacingOccurrences(of: "月", with: "-")
                    .replacingOccurrences(of: "日", with: "")
                
                normalized[key] = standardized
            }
        }
        
        return normalized
    }
    
    /// 清理字段中的空白字符
    private func trimFields(_ fields: [String: String]) -> [String: String] {
        var trimmed: [String: String] = [:]
        for (key, value) in fields {
            let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty {
                trimmed[key] = cleaned
            }
        }
        return trimmed
    }
    
    // MARK: - Field Validation
    
    /// 验证身份证字段
    private func validateIDCardFields(_ fields: [String: String]) -> [String: String] {
        var validated = fields
        
        // 验证身份证号格式
        if let idNumber = validated["idNumber"] {
            let cleaned = idNumber.filter { $0.isNumber || $0 == "X" || $0 == "x" }
            if cleaned.count == 18 {
                validated["idNumber"] = cleaned.uppercased()
            }
        }
        
        // 标准化性别
        if let gender = validated["gender"] {
            if gender.contains("男") || gender.lowercased().contains("m") {
                validated["gender"] = "男"
            } else if gender.contains("女") || gender.lowercased().contains("f") {
                validated["gender"] = "女"
            }
        }
        
        return validated
    }
    
    /// 验证护照字段
    private func validatePassportFields(_ fields: [String: String]) -> [String: String] {
        var validated = fields
        
        // 护照号码大写
        if let passportNumber = validated["passportNumber"] {
            validated["passportNumber"] = passportNumber.uppercased()
        }
        
        // 标准化性别
        if let gender = validated["gender"] {
            if gender.contains("男") || gender.lowercased().contains("m") {
                validated["gender"] = "男"
            } else if gender.contains("女") || gender.lowercased().contains("f") {
                validated["gender"] = "女"
            }
        }
        
        return validated
    }
    
    /// 验证驾照字段
    private func validateDriversLicenseFields(_ fields: [String: String]) -> [String: String] {
        var validated = fields
        
        // 标准化准驾车型
        if let licenseClass = validated["licenseClass"] {
            validated["licenseClass"] = licenseClass.uppercased()
        }
        
        return validated
    }
    
    /// 验证营业执照字段
    private func validateBusinessLicenseFields(_ fields: [String: String]) -> [String: String] {
        var validated = fields
        
        // 统一社会信用代码大写
        if let creditCode = validated["creditCode"] {
            validated["creditCode"] = creditCode.uppercased()
        }
        
        return validated
    }
    
    // MARK: - Auto-Fill Suggestions
    
    /// 生成自动填充建议
    /// - Parameter ocrResult: OCR识别结果
    /// - Returns: 字段填充建议，包含置信度
    func generateAutoFillSuggestions(_ ocrResult: any OCRResult) -> [String: (value: String, confidence: Double)] {
        let fields = ocrResult.toCardFields()
        var suggestions: [String: (String, Double)] = [:]
        
        for (key, value) in fields {
            // 基础置信度来自OCR结果
            var confidence = ocrResult.confidence
            
            // 根据字段类型和内容调整置信度
            confidence = adjustConfidence(for: key, value: value, baseConfidence: confidence)
            
            suggestions[key] = (value, confidence)
        }
        
        return suggestions
    }
    
    /// 根据字段类型和内容调整置信度
    private func adjustConfidence(for key: String, value: String, baseConfidence: Double) -> Double {
        var confidence = baseConfidence
        
        // 关键字段如果格式正确，提高置信度
        switch key {
        case "idNumber":
            if value.count == 18 && value.range(of: #"^\d{17}[\dXx]$"#, options: .regularExpression) != nil {
                confidence = min(confidence + 0.2, 1.0)
            }
            
        case "passportNumber":
            if value.count >= 8 && value.count <= 9 && value.first?.isLetter == true {
                confidence = min(confidence + 0.15, 1.0)
            }
            
        case "creditCode":
            if value.count == 18 {
                confidence = min(confidence + 0.15, 1.0)
            }
            
        case "birthDate", "issueDate", "expiryDate":
            // 日期格式检查
            if value.range(of: #"\d{4}[-年]\d{1,2}[-月]\d{1,2}"#, options: .regularExpression) != nil {
                confidence = min(confidence + 0.1, 1.0)
            }
            
        default:
            break
        }
        
        // 如果值为空或太短，降低置信度
        if value.isEmpty {
            confidence = 0.0
        } else if value.count < 2 {
            confidence = max(confidence - 0.2, 0.0)
        }
        
        return confidence
    }
    
    // MARK: - Merge Fields
    
    /// 合并多个OCR结果（例如正反面）
    func mergeOCRResults(_ results: [any OCRResult]) -> (cardType: CardType, fields: [String: String]) {
        guard !results.isEmpty else {
            return (.general, [:])
        }
        
        // 使用第一个结果的文档类型
        let primaryResult = results[0]
        let cardType = mapDocumentTypeToCardType(primaryResult.documentType)
        
        // 合并所有字段，后面的结果覆盖前面的
        var mergedFields: [String: String] = [:]
        for result in results {
            let fields = result.toCardFields()
            for (key, value) in fields {
                if !value.isEmpty {
                    mergedFields[key] = value
                }
            }
        }
        
        // 应用后处理
        let optimizedFields = postProcessFields(mergedFields, for: cardType)
        
        return (cardType, optimizedFields)
    }
}
