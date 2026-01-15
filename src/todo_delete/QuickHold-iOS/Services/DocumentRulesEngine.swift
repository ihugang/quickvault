//
//  DocumentRulesEngine.swift
//  QuickHold
//
//  Rule engine for processing document recognition rules based on country/region
//

import Foundation

// MARK: - Rule Models

/// 文档规则配置
struct DocumentRulesConfig: Codable {
    let schemaVersion: String
    let updatedAt: String
    let defaultPolicy: DefaultPolicy
    let documentTypes: [String: DocumentTypeRule]
    let countries: [String: CountryRule]
    
    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case updatedAt = "updated_at"
        case defaultPolicy = "default_policy"
        case documentTypes = "document_types"
        case countries
    }
}

struct DefaultPolicy: Codable {
    let purpose: String
    let minCollection: Bool
    let frontRequiredByDefault: Bool
    let backRequiredByDefault: Bool
    let notes: [String]
    
    enum CodingKeys: String, CodingKey {
        case purpose
        case minCollection = "min_collection"
        case frontRequiredByDefault = "front_required_by_default"
        case backRequiredByDefault = "back_required_by_default"
        case notes
    }
}

struct DocumentTypeRule: Codable {
    let labels: [String: String]
    let pages: [String]
    let uploadFields: [String: UploadField]
    
    enum CodingKeys: String, CodingKey {
        case labels
        case pages
        case uploadFields = "upload_fields"
    }
}

struct UploadField: Codable {
    let labels: [String: String]
}

struct CountryRule: Codable {
    let name: [String: String]
    let documents: [String: CountryDocumentRule]
}

struct CountryDocumentRule: Codable {
    let frontRequired: Bool?
    let backRequired: Bool?
    let backOptional: Bool?
    let backReason: [String]?
    let dataPageRequired: Bool?
    let uiHints: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case frontRequired = "front_required"
        case backRequired = "back_required"
        case backOptional = "back_optional"
        case backReason = "back_reason"
        case dataPageRequired = "data_page_required"
        case uiHints = "ui_hints"
    }
}

// MARK: - Document Upload Guidance

/// 上传指导信息
struct UploadGuidance {
    let documentType: String
    let countryCode: String
    let frontRequired: Bool
    let backRequired: Bool
    let backOptional: Bool
    let hint: String?
    let pages: [String]
    
    var shouldRequestFront: Bool { frontRequired }
    var shouldRequestBack: Bool { backRequired || backOptional }
}

// MARK: - Rules Engine

final class DocumentRulesEngine {
    
    static let shared = DocumentRulesEngine()
    
    private var config: DocumentRulesConfig?
    
    private init() {
        loadRules()
    }
    
    /// 加载规则配置
    private func loadRules() {
        guard let url = Bundle.main.url(forResource: "idpassport_rules", withExtension: "json") else {
            print("⚠️ idpassport_rules.json not found in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            config = try decoder.decode(DocumentRulesConfig.self, from: data)
            print("✅ Document rules loaded successfully")
        } catch {
            print("❌ Failed to load document rules: \(error)")
        }
    }
    
    /// 获取上传指导信息
    /// - Parameters:
    ///   - documentType: 文档类型 (如 "national_id", "passport", "drivers_license")
    ///   - countryCode: 国家/地区代码 (如 "CN", "HK", "US")
    /// - Returns: 上传指导信息
    func getUploadGuidance(for documentType: String, countryCode: String) -> UploadGuidance? {
        guard let config = config else { return nil }
        
        // 获取文档类型规则
        guard let docTypeRule = config.documentTypes[documentType] else {
            return nil
        }
        
        // 获取国家规则
        let countryRule = config.countries[countryCode]
        let countryDocRule = countryRule?.documents[documentType]
        
        // 构建上传指导
        let frontRequired = countryDocRule?.frontRequired ?? config.defaultPolicy.frontRequiredByDefault
        let backRequired = countryDocRule?.backRequired ?? config.defaultPolicy.backRequiredByDefault
        let backOptional = countryDocRule?.backOptional ?? false
        
        let hint: String?
        if let uiHints = countryDocRule?.uiHints {
            // 优先使用中文提示
            hint = uiHints["zh"] ?? uiHints["en"]
        } else {
            hint = nil
        }
        
        return UploadGuidance(
            documentType: documentType,
            countryCode: countryCode,
            frontRequired: frontRequired,
            backRequired: backRequired,
            backOptional: backOptional,
            hint: hint,
            pages: docTypeRule.pages
        )
    }
    
    /// 获取文档类型的本地化名称
    func getDocumentTypeName(for documentType: String, locale: String = "zh") -> String? {
        guard let config = config else { return nil }
        return config.documentTypes[documentType]?.labels[locale]
    }
    
    /// 获取国家/地区名称
    func getCountryName(for countryCode: String, locale: String = "zh") -> String? {
        guard let config = config else { return nil }
        return config.countries[countryCode]?.name[locale]
    }
    
    /// 检查是否需要正反面照片
    func requiresBothSides(documentType: String, countryCode: String) -> Bool {
        guard let guidance = getUploadGuidance(for: documentType, countryCode: countryCode) else {
            return false
        }
        return guidance.frontRequired && guidance.backRequired
    }
    
    /// 获取支持的国家/地区列表
    func getSupportedCountries() -> [(code: String, name: String)] {
        guard let config = config else { return [] }
        return config.countries.map { (code: $0.key, name: $0.value.name["zh"] ?? $0.key) }
            .sorted { $0.name < $1.name }
    }
    
    /// 获取支持的文档类型列表
    func getSupportedDocumentTypes() -> [(type: String, name: String)] {
        guard let config = config else { return [] }
        return config.documentTypes.map { (type: $0.key, name: $0.value.labels["zh"] ?? $0.key) }
            .sorted { $0.name < $1.name }
    }
}
