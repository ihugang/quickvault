import Foundation
import CoreGraphics

enum DocumentType: String {
    case cnResidentIDFront
    case passportMRZ
    case unknown
}

struct ExtractedField: Codable, Hashable {
    let key: String            // e.g. "name", "id_number"
    let label: String          // e.g. "姓名"
    let value: String
    let confidence: Float      // 0~1 (粗略)
}

struct DocumentExtractionResult: Codable {
    let docType: DocumentType
    let fields: [ExtractedField]
    let rawText: String
}