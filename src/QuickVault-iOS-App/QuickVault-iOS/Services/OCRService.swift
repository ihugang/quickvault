//
//  OCRService.swift
//  QuickVault
//
//  OCR service for extracting text from ID cards, passports, and business licenses
//

import Foundation
import Vision
import UIKit

// MARK: - OCR Result Types

/// 身份证 OCR 识别结果
struct IDCardOCRResult {
    var name: String?
    var gender: String?
    var nationality: String?
    var birthDate: String?
    var idNumber: String?
    var address: String?
    var issuer: String?
    var validPeriod: String?
    var isFrontSide: Bool = true
}

/// 护照 OCR 识别结果
struct PassportOCRResult {
    var name: String?
    var nationality: String?
    var birthDate: String?
    var gender: String?
    var passportNumber: String?
    var issueDate: String?
    var expiryDate: String?
    var issuer: String?
}

/// 营业执照 OCR 识别结果
struct BusinessLicenseOCRResult {
    var companyName: String?
    var creditCode: String?
    var legalRepresentative: String?
    var registeredCapital: String?
    var address: String?
    var establishedDate: String?
    var businessScope: String?
}

// MARK: - OCR Service Protocol

protocol OCRService {
    func recognizeIDCard(image: UIImage) async throws -> IDCardOCRResult
    func recognizePassport(image: UIImage) async throws -> PassportOCRResult
    func recognizeBusinessLicense(image: UIImage) async throws -> BusinessLicenseOCRResult
}

// MARK: - OCR Service Implementation

final class OCRServiceImpl: OCRService {
    
    static let shared = OCRServiceImpl()
    
    private init() {}
    
    // MARK: - ID Card Recognition
    
    func recognizeIDCard(image: UIImage) async throws -> IDCardOCRResult {
        let recognizedTexts = try await performOCR(on: image)
        return parseIDCardTexts(recognizedTexts)
    }
    
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
            
            // 住址
            if trimmed.contains("住址") {
                result.address = extractValueAfterLabel(trimmed, label: "住址")
                // 地址可能跨多行
                if result.address == nil || result.address?.isEmpty == true {
                    var addressParts: [String] = []
                    for i in (index + 1)..<min(index + 4, texts.count) {
                        let part = texts[i].trimmingCharacters(in: .whitespacesAndNewlines)
                        if !part.contains("公民身份") && !part.isEmpty {
                            addressParts.append(part)
                        } else {
                            break
                        }
                    }
                    if !addressParts.isEmpty {
                        result.address = addressParts.joined()
                    }
                }
            }
            
            // 签发机关 (背面)
            if trimmed.contains("签发机关") {
                result.issuer = extractValueAfterLabel(trimmed, label: "签发机关")
                    ?? (index + 1 < texts.count ? texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines) : nil)
            }
            
            // 有效期限 (背面)
            if trimmed.contains("有效期") {
                // 格式: YYYY.MM.DD-YYYY.MM.DD 或 YYYY.MM.DD-长期
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
    
    func recognizePassport(image: UIImage) async throws -> PassportOCRResult {
        let recognizedTexts = try await performOCR(on: image)
        return parsePassportTexts(recognizedTexts)
    }
    
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
    
    // MARK: - Business License Recognition
    
    func recognizeBusinessLicense(image: UIImage) async throws -> BusinessLicenseOCRResult {
        let recognizedTexts = try await performOCR(on: image)
        return parseBusinessLicenseTexts(recognizedTexts)
    }
    
    private func parseBusinessLicenseTexts(_ texts: [String]) -> BusinessLicenseOCRResult {
        var result = BusinessLicenseOCRResult()
        
        for (index, text) in texts.enumerated() {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 统一社会信用代码 - 18位
            if let codeMatch = trimmed.range(of: #"[0-9A-Z]{18}"#, options: .regularExpression) {
                let code = String(trimmed[codeMatch])
                // 验证是否符合统一社会信用代码格式
                if isValidCreditCode(code) {
                    result.creditCode = code
                }
            }
            
            // 企业名称/名称
            if trimmed.contains("名称") || trimmed.contains("企业名称") {
                result.companyName = extractValueAfterLabel(trimmed, label: "名称")
                    ?? extractValueAfterLabel(trimmed, label: "企业名称")
                    ?? (index + 1 < texts.count ? texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines) : nil)
            }
            
            // 法定代表人
            if trimmed.contains("法定代表人") || trimmed.contains("负责人") {
                result.legalRepresentative = extractValueAfterLabel(trimmed, label: "法定代表人")
                    ?? extractValueAfterLabel(trimmed, label: "负责人")
                    ?? (index + 1 < texts.count ? texts[index + 1].trimmingCharacters(in: .whitespacesAndNewlines) : nil)
            }
            
            // 注册资本
            if trimmed.contains("注册资本") || trimmed.contains("注册资金") {
                result.registeredCapital = extractValueAfterLabel(trimmed, label: "注册资本")
                    ?? extractValueAfterLabel(trimmed, label: "注册资金")
                // 提取金额
                if let capitalMatch = trimmed.range(of: #"\d+(\.\d+)?万?[元人民币]?"#, options: .regularExpression) {
                    result.registeredCapital = String(trimmed[capitalMatch])
                }
            }
            
            // 住所/经营场所
            if trimmed.contains("住所") || trimmed.contains("经营场所") {
                result.address = extractValueAfterLabel(trimmed, label: "住所")
                    ?? extractValueAfterLabel(trimmed, label: "经营场所")
                // 地址可能跨多行
                if result.address == nil || result.address?.isEmpty == true {
                    var addressParts: [String] = []
                    for i in (index + 1)..<min(index + 3, texts.count) {
                        let part = texts[i].trimmingCharacters(in: .whitespacesAndNewlines)
                        if !part.contains("成立日期") && !part.contains("经营范围") && !part.isEmpty {
                            addressParts.append(part)
                        } else {
                            break
                        }
                    }
                    if !addressParts.isEmpty {
                        result.address = addressParts.joined()
                    }
                }
            }
            
            // 成立日期
            if trimmed.contains("成立日期") {
                if let dateMatch = trimmed.range(of: #"\d{4}年\d{1,2}月\d{1,2}日"#, options: .regularExpression) {
                    result.establishedDate = String(trimmed[dateMatch])
                }
            }
            
            // 经营范围
            if trimmed.contains("经营范围") {
                result.businessScope = extractValueAfterLabel(trimmed, label: "经营范围")
                // 经营范围通常很长，可能跨多行
                if result.businessScope == nil || result.businessScope?.isEmpty == true {
                    var scopeParts: [String] = []
                    for i in (index + 1)..<min(index + 5, texts.count) {
                        let part = texts[i].trimmingCharacters(in: .whitespacesAndNewlines)
                        scopeParts.append(part)
                    }
                    if !scopeParts.isEmpty {
                        result.businessScope = scopeParts.joined()
                    }
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
