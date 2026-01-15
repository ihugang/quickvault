import Vision
import UIKit
import ImageIO

/// MRZ专用Vision OCR识别器 - 针对护照底部MRZ区域优化
final class MRZVisionOCR {

    /// 主入口：返回尽量稳定的两行 MRZ（line1, line2）
    func recognizeMRZLines(from uiImage: UIImage) async throws -> (String, String)? {
        guard let cgImage = uiImage.cgImage else { return nil }

        // 先尝试通过文本框定位精确的两条MRZ
        let detectedStrips = try? await detectMRZStrips(in: cgImage, orientation: uiImage.cgImageOrientation)

        // 如果检测失败，则回退到经验ROI
        let mrzROI: CGRect
        let line1Strip: CGRect
        let line2Strip: CGRect

        if let (detectedLine1, detectedLine2) = detectedStrips {
            line1Strip = detectedLine1
            line2Strip = detectedLine2
            // 以检测到的两条的并集作为总区域，便于调试打印
            let minY = min(line1Strip.minY, line2Strip.minY)
            let maxY = max(line1Strip.maxY, line2Strip.maxY)
            mrzROI = CGRect(x: 0.05, y: minY, width: 0.90, height: maxY - minY)
            print("  🎯 [MRZ ROI] 使用检测到的两行区域")
        } else {
            // 关键：先取"底部区域"作为 MRZ 大致 ROI（经验值：底部 18%）
            // Vision 的 ROI 是 normalized，坐标原点在左下角
            mrzROI = CGRect(x: 0.05, y: 0.00, width: 0.90, height: 0.18)

            // MRZ两行从上到下（在Vision坐标系中从高到低）：
            // Line1（姓名行）- 在上方，y值更大
            // Line2（数据行）- 在下方，y值更小
            // 每行高度约占总MRZ区域的44%，中间留12%间隙严格分离
            line1Strip = CGRect(x: mrzROI.minX, y: mrzROI.minY + mrzROI.height * 0.56,
                                width: mrzROI.width, height: mrzROI.height * 0.44)
            line2Strip = CGRect(x: mrzROI.minX, y: mrzROI.minY,
                                width: mrzROI.width, height: mrzROI.height * 0.44)
            print("  🎯 [MRZ ROI] 使用默认底部区域")
        }

        print("  🔍 [MRZ ROI] 总区域: y=\(mrzROI.minY), h=\(mrzROI.height)")
        print("  🔍 [MRZ ROI] Line1区域: y=\(line1Strip.minY), h=\(line1Strip.height)")
        print("  🔍 [MRZ ROI] Line2区域: y=\(line2Strip.minY), h=\(line2Strip.height)")

        // 识别两条
        let l1Candidates = try await recognize(in: cgImage, orientation: uiImage.cgImageOrientation, roi: line1Strip)
        let l2Candidates = try await recognize(in: cgImage, orientation: uiImage.cgImageOrientation, roi: line2Strip)

        print("  📝 [MRZ识别] Line1候选: \(l1Candidates)")
        print("  📝 [MRZ识别] Line2候选: \(l2Candidates)")

        // 从候选里挑"最像 MRZ"的一条（长度、字符集、<密度）
          // 部分设备会把 "P<" 识别成 "PO" / "P0"，因此只要求以 "P" 开头，内部做宽松匹配
          guard let line1 = pickBestMRZLine(from: l1Candidates, expectedPrefix: "P"),
              let line2 = pickBestMRZLine(from: l2Candidates, expectedPrefix: nil) else {
            print("  ⚠️ [MRZ识别] 未能选出有效的MRZ行")
            return nil
        }

        print("  ✅ [MRZ选择] Line1: \(line1)")
        print("  ✅ [MRZ选择] Line2: \(line2)")

        return (line1, line2)
    }

    // MARK: - Vision Recognize

    private func recognize(in cgImage: CGImage,
                           orientation: CGImagePropertyOrientation,
                           roi: CGRect) async throws -> [String] {

        try await withCheckedThrowingContinuation { cont in
            let req = VNRecognizeTextRequest { request, error in
                if let error { cont.resume(throwing: error); return }
                let obs = (request.results as? [VNRecognizedTextObservation]) ?? []

                // 取所有候选，去除空格并转大写
                var strings: [String] = []
                for observation in obs {
                    // 每个观察取前3个候选
                    for candidate in observation.topCandidates(3) {
                        let text = candidate.string.uppercased().replacingOccurrences(of: " ", with: "")
                        if !text.isEmpty {
                            strings.append(text)
                        }
                    }
                }

                cont.resume(returning: strings)
            }

            // MRZ 专用参数
            req.recognitionLevel = .fast
            req.usesLanguageCorrection = false
            req.recognitionLanguages = ["en-US"]
            req.minimumTextHeight = 0.015  // 降低最小文本高度，确保能识别到MRZ
            req.regionOfInterest = roi

            let handler = VNImageRequestHandler(cgImage: cgImage,
                                                orientation: orientation,
                                                options: [:])
            do {
                try handler.perform([req])
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    /// 通过文本框定位MRZ两行，返回两个严格分离的区域（上行、下行）
    private func detectMRZStrips(in cgImage: CGImage,
                                 orientation: CGImagePropertyOrientation) async throws -> (CGRect, CGRect)? {

        return try await withCheckedThrowingContinuation { cont in
            let req = VNRecognizeTextRequest { request, error in
                if let error { cont.resume(throwing: error); return }
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []

                // 筛选底部的宽文本框，尽量匹配MRZ两行
                let candidates = observations
                    .map { $0.boundingBox } // normalized, origin at lower-left
                    .filter { box in
                        // 只看底部 35% 区域
                        box.minY < 0.35 &&
                        // 宽度足够大
                        box.width > 0.45 &&
                        // 高度不宜太高
                        box.height < 0.15
                    }

                // 按 y 从小到大排序（下->上）
                let sorted = candidates.sorted { $0.minY < $1.minY }

                guard sorted.count >= 2 else {
                    print("  ⚠️ [MRZ检测] 底部文本框不足两条，回退默认ROI")
                    cont.resume(returning: nil)
                    return
                }

                let line2Box = sorted[0] // 下方
                // 选择与line2在y方向间隔最大的另一个作为line1
                let line1Box = sorted.dropFirst().max(by: { lhs, rhs in lhs.minY < rhs.minY }) ?? sorted[1]

                // 给每行加一点padding，避免裁切
                func pad(_ box: CGRect, by factor: CGFloat = 0.08) -> CGRect {
                    let dx = box.width * factor
                    let dy = box.height * factor
                    var padded = box.insetBy(dx: -dx, dy: -dy)
                    // Clamp to [0,1]
                    padded.origin.x = max(0, padded.origin.x)
                    padded.origin.y = max(0, padded.origin.y)
                    padded.size.width = min(1 - padded.origin.x, padded.size.width)
                    padded.size.height = min(1 - padded.origin.y, padded.size.height)
                    return padded
                }

                let paddedLine1 = pad(line1Box)
                let paddedLine2 = pad(line2Box)

                print("  🎯 [MRZ检测] 自动定位两条MRZ：Line1 y=\(paddedLine1.minY) h=\(paddedLine1.height), Line2 y=\(paddedLine2.minY) h=\(paddedLine2.height)")

                cont.resume(returning: (paddedLine1, paddedLine2))
            }

            req.recognitionLevel = .fast
            req.usesLanguageCorrection = false
            req.recognitionLanguages = ["en-US"]
            req.minimumTextHeight = 0.01
            req.regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1) // 全局检测

            let handler = VNImageRequestHandler(cgImage: cgImage,
                                                orientation: orientation,
                                                options: [:])
            do {
                try handler.perform([req])
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    // MARK: - Pick best line

    private func pickBestMRZLine(from candidates: [String], expectedPrefix: String?) -> String? {
        guard !candidates.isEmpty else { return nil }
        
        // 清洗：只保留 A-Z0-9<
        func sanitize(_ s: String) -> String {
            let u = s.uppercased()
            return String(u.map { ch in
                if ("A"..."Z").contains(String(ch)) || ("0"..."9").contains(String(ch)) || ch == "<" {
                    return ch
                }
                return "<"
            })
        }

        let sanitized = candidates.map { sanitize($0) }

        // 优先尝试前缀匹配，若全部不匹配再放宽（"P<" 常被识别为 "PO"/"P0"，这里认为以"P"开头即视为可能的第一行）
        var pool = sanitized
        if let prefix = expectedPrefix {
            let withPrefix = sanitized.filter { line in
                if line.hasPrefix(prefix) { return true }
                // 针对护照行，将 P< 误识别为 PO / P0 的情况放行
                if prefix == "P" && (line.hasPrefix("PO") || line.hasPrefix("P0")) { return true }
                return false
            }
            if !withPrefix.isEmpty {
                pool = withPrefix
            } else {
                print("    ⚠️ 未找到符合前缀 \(prefix) 的候选，放宽前缀要求")
            }
        }

        let scored = pool.map { line -> (String, Int) in
            let hasPrefix = expectedPrefix == nil ? true : line.hasPrefix(expectedPrefix!)
            // MRZ 通常 44 字符（TD3），允许少量误差
            let lenScore = max(0, 100 - abs(line.count - 44) * 6)
            let ltCount = line.filter { $0 == "<" }.count
            let charsetOK = line.allSatisfy { $0 == "<" || $0.isNumber || ($0 >= "A" && $0 <= "Z") }
            // 对以P开头的护照行加分，对P0/PO也给一定加分
            var mrzLike = (line.hasPrefix("P<") ? 40 : 0) + (charsetOK ? 10 : 0) + min(ltCount, 20)
            if line.hasPrefix("PO") || line.hasPrefix("P0") { mrzLike += 25 }
            if expectedPrefix != nil && !hasPrefix {
                mrzLike -= 20 // 没有前缀的惩罚，但仍允许作为降级候选
            }
            let totalScore = lenScore + mrzLike
            print("    📊 候选: \(line.prefix(24))... | 长度:\(line.count) | 分数:\(totalScore) | 前缀匹配:\(hasPrefix)")
            return (line, totalScore)
        }
        
        let best = scored.sorted(by: { $0.1 > $1.1 }).first
        
        // 要求至少有一定分数才认为是有效的MRZ行（降级情况下略放宽）
        if let best = best, best.1 >= 45 {
            return best.0
        }
        
        print("    ⚠️ 所有候选分数都太低或被过滤")
        return nil
    }
}

// MARK: - UIImage orientation helper
extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
