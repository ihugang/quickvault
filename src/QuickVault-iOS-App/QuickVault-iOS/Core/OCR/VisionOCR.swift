import Vision
import UIKit

struct OCRLine {
    let text: String
    let confidence: Float
    /// normalized (0~1), origin at bottom-left (Vision convention)
    let boundingBox: CGRect
}

final class VisionOCR {
    func recognizeLines(from uiImage: UIImage) async throws -> [OCRLine] {
        guard let cgImage = uiImage.cgImage else { return [] }

        return try await withCheckedThrowingContinuation { cont in
            let request = VNRecognizeTextRequest { req, err in
                if let err = err { cont.resume(throwing: err); return }

                let obs = (req.results as? [VNRecognizedTextObservation]) ?? []
                var lines: [OCRLine] = []
                lines.reserveCapacity(obs.count)

                for o in obs {
                    guard let top = o.topCandidates(1).first else { continue }
                    lines.append(.init(
                        text: top.string.trimmingCharacters(in: .whitespacesAndNewlines),
                        confidence: top.confidence,
                        boundingBox: o.boundingBox
                    ))
                }

                // 过滤空行
                lines = lines.filter { !$0.text.isEmpty }
                cont.resume(returning: lines)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["zh-Hans", "en-US"]
            request.minimumTextHeight = 0.02  // 视图片大小调整

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do { try handler.perform([request]) }
            catch { cont.resume(throwing: error) }
        }
    }
}