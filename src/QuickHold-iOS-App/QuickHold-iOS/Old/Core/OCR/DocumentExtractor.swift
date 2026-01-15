import UIKit

final class DocumentExtractor {
    private let ocr = VisionOCR()
    private let cnID = CNResidentIDFrontParser()
    private let mrz = PassportMRZParser()

    func extract(from image: UIImage) async throws -> DocumentExtractionResult {
        let lines = try await ocr.recognizeLines(from: image)

        // 粗判断：有没有 MRZ / 有没有“公民身份号码”
        let allText = lines.map(\.text).joined(separator: "\n")

        if allText.contains("公民身份号码") || allText.contains("居民身份证") || allText.contains("姓名") && allText.contains("住址") {
            return cnID.parse(from: lines)
        }

        if allText.contains("P<") || allText.contains("P‹") {
            let r = mrz.parse(from: lines)
            if r.docType != .unknown { return r }
        }

        return .init(docType: .unknown, fields: [], rawText: allText)
    }
}
