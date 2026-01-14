//
//  AIEnhancedOCRService.swift
//  QuickVault
//
//  AI增强的OCR服务 - 后端集成
//

import Foundation
import UIKit

// MARK: - API Models

/// AI-OCR API 请求模型
struct AIOCRRequest: Codable {
    let documentType: String
    let rawTexts: [String]
    let imageUrl: String?
    let clientVersion: String
    let locale: String
    
    enum CodingKeys: String, CodingKey {
        case documentType
        case rawTexts
        case imageUrl
        case clientVersion
        case locale
    }
}

/// AI-OCR API 响应模型
struct AIOCRResponse: Codable {
    let success: Bool
    let data: AIOCRData?
    let error: AIOCRError?
    let meta: AIOCRMeta?
}

/// AI-OCR 数据模型
struct AIOCRData: Codable {
    let documentType: String
    let confidence: Double
    let fields: [String: AIOCRField]
    let warnings: [String]?
    let processingTime: Int?
}

/// AI-OCR 字段模型
struct AIOCRField: Codable {
    let value: String
    let confidence: Double
    let corrected: Bool?
    let originalValue: String?
}

/// AI-OCR 错误模型
struct AIOCRError: Codable {
    let code: String
    let message: String
    let details: [String: AnyCodable]?
}

/// AI-OCR 元数据模型
struct AIOCRMeta: Codable {
    let requestId: String
    let timestamp: String
    let modelUsed: String?
    let promptVersion: String?
}

/// 支持任意类型的Codable包装
struct AnyCodable: Codable {
    let value: Any
    
    init<T>(_ value: T) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "无法解码值")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "无法编码值")
            throw EncodingError.invalidValue(value, context)
        }
    }
}

// MARK: - AI Enhanced OCR Service

/// AI增强的OCR服务
@MainActor
class AIEnhancedOCRService {
    
    // MARK: - Configuration
    
    struct Configuration {
        let baseURL: String
        let apiKey: String
        let timeout: TimeInterval
        let enableFallback: Bool  // 是否启用本地fallback
        let maxRetries: Int
        
        static let `default` = Configuration(
            baseURL: "https://api.quickvault.app",  // 替换为实际后端URL
            apiKey: ProcessInfo.processInfo.environment["QUICKVAULT_API_KEY"] ?? "",
            timeout: 10.0,
            enableFallback: true,
            maxRetries: 2
        )
    }
    
    // MARK: - Properties
    
    private let config: Configuration
    private let localOCRService: OCRServiceImpl  // 本地OCR服务作为fallback
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    // 性能统计
    private var requestCount: Int = 0
    private var successCount: Int = 0
    private var fallbackCount: Int = 0
    
    // MARK: - Initialization
    
    init(configuration: Configuration = .default, localService: OCRServiceImpl) {
        self.config = configuration
        self.localOCRService = localService
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.timeoutIntervalForResource = configuration.timeout * 2
        self.session = URLSession(configuration: sessionConfig)
        
        print("🤖 [AI-OCR] 服务初始化完成")
        print("   - 后端URL: \(configuration.baseURL)")
        print("   - Fallback: \(configuration.enableFallback ? "启用" : "禁用")")
    }
    
    // MARK: - Public Methods
    
    /// 识别文档（AI增强模式）
    /// - Parameters:
    ///   - image: 待识别的图片
    ///   - documentType: 证件类型
    /// - Returns: OCR识别结果
    func recognizeDocument(image: UIImage, documentType: DocumentType) async throws -> any OCRResult {
        requestCount += 1
        print("🤖 [AI-OCR] 开始识别（请求 #\(requestCount)）: \(documentType.rawValue)")
        
        do {
            // Step 1: 本地Vision OCR提取文本
            print("📱 [AI-OCR] Step 1: 本地Vision OCR...")
            let localTexts = try await performLocalVisionOCR(image: image)
            print("📱 [AI-OCR] Vision识别到 \(localTexts.count) 行文本")
            
            // Step 2: 调用后端AI解析
            print("☁️ [AI-OCR] Step 2: 后端AI解析...")
            let startTime = Date()
            let aiResult = try await callBackendAPI(
                documentType: documentType,
                rawTexts: localTexts
            )
            let duration = Date().timeIntervalSince(startTime)
            print("☁️ [AI-OCR] AI解析完成，耗时: \(Int(duration * 1000))ms, 置信度: \(aiResult.confidence)")
            
            // Step 3: 转换为本地OCR结果格式
            let ocrResult = try convertToOCRResult(aiData: aiResult, documentType: documentType)
            
            successCount += 1
            printStatistics()
            
            return ocrResult
            
        } catch {
            print("❌ [AI-OCR] AI识别失败: \(error.localizedDescription)")
            
            // Fallback to local OCR
            if config.enableFallback {
                fallbackCount += 1
                print("🔄 [AI-OCR] 切换到本地OCR (Fallback #\(fallbackCount))")
                return try await localOCRService.recognizeDocument(image: image)
            } else {
                throw error
            }
        }
    }
    
    /// 批量识别文档
    func batchRecognize(documents: [(image: UIImage, type: DocumentType)]) async throws -> [any OCRResult] {
        print("🤖 [AI-OCR] 批量识别: \(documents.count) 个文档")
        
        // 并发处理，限制并发数为3
        let results = try await withThrowingTaskGroup(of: (Int, any OCRResult).self) { group in
            var results: [Int: any OCRResult] = [:]
            
            for (index, doc) in documents.enumerated() {
                group.addTask {
                    let result = try await self.recognizeDocument(image: doc.image, documentType: doc.type)
                    return (index, result)
                }
            }
            
            for try await (index, result) in group {
                results[index] = result
            }
            
            return results.sorted(by: { $0.key < $1.key }).map { $0.value }
        }
        
        print("🤖 [AI-OCR] 批量识别完成: \(results.count)/\(documents.count)")
        return results
    }
    
    // MARK: - Private Methods
    
    /// 本地Vision OCR提取文本
    private func performLocalVisionOCR(image: UIImage) async throws -> [String] {
        // 复用本地OCR服务的Vision识别能力
        return try await withCheckedThrowingContinuation { continuation in
            let recognizer = MRZVisionOCR()
            recognizer.recognizeText(in: image) { texts, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: texts)
                }
            }
        }
    }
    
    /// 调用后端API
    private func callBackendAPI(documentType: DocumentType, rawTexts: [String]) async throws -> AIOCRData {
        let endpoint = "/api/v1/ocr/analyze"
        let url = URL(string: config.baseURL + endpoint)!
        
        // 构建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(getCurrentVersion(), forHTTPHeaderField: "X-Client-Version")
        request.setValue("iOS", forHTTPHeaderField: "X-Client-Platform")
        
        // 请求体
        let requestBody = AIOCRRequest(
            documentType: documentType.rawValue,
            rawTexts: rawTexts,
            imageUrl: nil,  // 不上传图片，仅发送OCR文本
            clientVersion: getCurrentVersion(),
            locale: Locale.current.identifier
        )
        request.httpBody = try encoder.encode(requestBody)
        
        // 发送请求（带重试）
        var lastError: Error?
        for attempt in 1...config.maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw OCRError.networkError
                }
                
                print("☁️ [AI-OCR] HTTP状态码: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    let errorResponse = try? decoder.decode(AIOCRResponse.self, from: data)
                    let errorMessage = errorResponse?.error?.message ?? "未知错误"
                    throw OCRError.apiError(message: errorMessage)
                }
                
                let response = try decoder.decode(AIOCRResponse.self, from: data)
                
                guard response.success, let data = response.data else {
                    let errorMessage = response.error?.message ?? "API返回失败"
                    throw OCRError.apiError(message: errorMessage)
                }
                
                return data
                
            } catch {
                lastError = error
                if attempt < config.maxRetries {
                    print("⚠️ [AI-OCR] 请求失败，重试 \(attempt)/\(config.maxRetries)...")
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000) // 指数退避
                }
            }
        }
        
        throw lastError ?? OCRError.networkError
    }
    
    /// 转换AI响应为本地OCR结果格式
    private func convertToOCRResult(aiData: AIOCRData, documentType: DocumentType) throws -> any OCRResult {
        var result: any OCRResult
        
        switch documentType {
        case .idCard:
            var idResult = IDCardOCRResult()
            idResult.confidence = aiData.confidence
            idResult.name = aiData.fields["name"]?.value
            idResult.idNumber = aiData.fields["idNumber"]?.value
            idResult.gender = aiData.fields["gender"]?.value
            idResult.nationality = aiData.fields["nationality"]?.value
            idResult.birthDate = aiData.fields["birthDate"]?.value
            idResult.address = aiData.fields["address"]?.value
            idResult.issuingAuthority = aiData.fields["issuingAuthority"]?.value
            idResult.validFrom = aiData.fields["validFrom"]?.value
            idResult.validUntil = aiData.fields["validUntil"]?.value
            result = idResult
            
        case .driversLicense:
            var dlResult = DriversLicenseOCRResult()
            dlResult.confidence = aiData.confidence
            dlResult.name = aiData.fields["name"]?.value
            dlResult.licenseNumber = aiData.fields["licenseNumber"]?.value
            dlResult.gender = aiData.fields["gender"]?.value
            dlResult.nationality = aiData.fields["nationality"]?.value
            dlResult.birthDate = aiData.fields["birthDate"]?.value
            dlResult.address = aiData.fields["address"]?.value
            dlResult.issueDate = aiData.fields["issueDate"]?.value
            dlResult.validFrom = aiData.fields["validFrom"]?.value
            dlResult.validUntil = aiData.fields["validUntil"]?.value
            dlResult.licenseClass = aiData.fields["licenseClass"]?.value
            result = dlResult
            
        case .passport:
            var ppResult = PassportOCRResult()
            ppResult.confidence = aiData.confidence
            ppResult.name = aiData.fields["name"]?.value
            ppResult.passportNumber = aiData.fields["passportNumber"]?.value
            ppResult.nationality = aiData.fields["nationality"]?.value
            ppResult.birthDate = aiData.fields["birthDate"]?.value
            ppResult.birthPlace = aiData.fields["birthPlace"]?.value
            ppResult.gender = aiData.fields["gender"]?.value
            ppResult.issueDate = aiData.fields["issueDate"]?.value
            ppResult.expiryDate = aiData.fields["expiryDate"]?.value
            ppResult.issuePlace = aiData.fields["issuePlace"]?.value
            result = ppResult
            
        default:
            throw OCRError.unsupportedDocumentType
        }
        
        // 输出识别到的字段和置信度
        print("✅ [AI-OCR] 字段识别结果:")
        for (key, field) in aiData.fields {
            let correctionFlag = field.corrected == true ? " ✏️" : ""
            print("   - \(key): \(field.value) (置信度: \(String(format: "%.2f", field.confidence)))\(correctionFlag)")
        }
        
        if let warnings = aiData.warnings, !warnings.isEmpty {
            print("⚠️ [AI-OCR] 警告信息:")
            for warning in warnings {
                print("   - \(warning)")
            }
        }
        
        return result
    }
    
    /// 获取当前版本号
    private func getCurrentVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version).\(build)"
    }
    
    /// 打印统计信息
    private func printStatistics() {
        let successRate = requestCount > 0 ? Double(successCount) / Double(requestCount) * 100 : 0
        let fallbackRate = requestCount > 0 ? Double(fallbackCount) / Double(requestCount) * 100 : 0
        print("📊 [AI-OCR] 统计: 总请求=\(requestCount), 成功率=\(String(format: "%.1f", successRate))%, Fallback率=\(String(format: "%.1f", fallbackRate))%")
    }
    
    // MARK: - Health Check
    
    /// 健康检查
    func healthCheck() async throws -> Bool {
        let endpoint = "/api/v1/health"
        let url = URL(string: config.baseURL + endpoint)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String {
                return status == "healthy"
            }
            
            return false
        } catch {
            return false
        }
    }
}

// MARK: - Error Types

enum OCRError: LocalizedError {
    case networkError
    case apiError(message: String)
    case unsupportedDocumentType
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "网络连接失败"
        case .apiError(let message):
            return "API错误: \(message)"
        case .unsupportedDocumentType:
            return "不支持的证件类型"
        case .parseError:
            return "解析错误"
        }
    }
}
