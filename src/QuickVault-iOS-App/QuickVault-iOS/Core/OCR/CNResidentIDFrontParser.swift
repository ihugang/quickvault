
import Foundation
import CoreGraphics

final class CNResidentIDFrontParser {
    struct Parsed {
        var name: String?
        var gender: String?
        var ethnicity: String?
        var birthDate: String?
        var address: String?
        var idNumber: String?
    }

    func parse(from lines: [OCRLine]) -> DocumentExtractionResult {
        let raw = lines.map(\.text).joined(separator: "\n")
        var p = Parsed()

        // 1) 先用关键词直接从同一行提取
        p.name = extractValue(after: "姓名", in: lines)
        p.gender = extractValue(after: "性别", in: lines)
        p.ethnicity = extractValue(after: "民族", in: lines)
        p.birthDate = extractValue(after: "出生", in: lines) ?? extractValue(after: "出生日期", in: lines)
        p.idNumber = extractIDNumber(in: lines)

        // 2) 住址：通常以“住址”开头，后续可能多行
        p.address = extractMultilineAddress(in: lines)

        // 3) 组装输出（做脱敏可在这里做）
        var fields: [ExtractedField] = []
        func add(_ key: String, _ label: String, _ value: String?, conf: Float = 0.9) {
            guard let v = value, !v.isEmpty else { return }
            fields.append(.init(key: key, label: label, value: v, confidence: conf))
        }

        add("name", "姓名", p.name)
        add("gender", "性别", p.gender)
        add("ethnicity", "民族", p.ethnicity)
        add("birth_date", "出生日期", normalizeDate(p.birthDate))
        add("address", "住址", p.address, conf: 0.75)
        add("id_number", "公民身份号码", p.idNumber, conf: 0.95)

        let docType: DocumentType = fields.isEmpty ? .unknown : .cnResidentIDFront
        return .init(docType: docType, fields: fields, rawText: raw)
    }

    // MARK: - Helpers

    private func extractValue(after keyword: String, in lines: [OCRLine]) -> String? {
        // 寻找包含关键词的行：如 “姓名 张三”
        for l in lines {
            let t = l.text.replacingOccurrences(of: "：", with: " ")
            if t.contains(keyword) {
                // keyword 后面的内容
                if let range = t.range(of: keyword) {
                    let tail = t[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    if !tail.isEmpty { return tail }
                }
            }
        }
        return nil
    }

    private func extractIDNumber(in lines: [OCRLine]) -> String? {
        // 18位：17数字+1校验(数字或X)
        // 15位老号也兼容
        let patterns = [
            #"\b\d{17}[\dXx]\b"#,
            #"\b\d{15}\b"#
        ]
        for l in lines {
            for p in patterns {
                if let m = l.text.range(of: p, options: .regularExpression) {
                    return String(l.text[m]).uppercased()
                }
            }
        }
        // 有些OCR会拆开：尝试拼接所有数字再找
        let digits = lines.map(\.text).joined().replacingOccurrences(of: " ", with: "")
        if let m = digits.range(of: #"\d{17}[\dXx]"#, options: .regularExpression) {
            return String(digits[m]).uppercased()
        }
        return nil
    }

    private func extractMultilineAddress(in lines: [OCRLine]) -> String? {
        // 找到包含“住址”的行作为起点
        guard let anchor = lines.first(where: { $0.text.contains("住址") || $0.text.contains("住") && $0.text.contains("址") }) else {
            return nil
        }

        // 住址值：同一行 keyword 后
        var addressParts: [String] = []
        if let sameLine = extractValue(after: "住址", in: [anchor]), !sameLine.isEmpty {
            addressParts.append(sameLine)
        }

        // 依据空间：取“住址”行附近、且在其下方、x位置相近的连续行
        // Vision boundingBox: (x,y,w,h) 0~1，y越大越靠上
        let anchorBox = anchor.boundingBox
        let xMin = anchorBox.minX - 0.05
        let xMax = anchorBox.minX + 0.25

        // 按 y 从上到下排序
        let sorted = lines.sorted { $0.boundingBox.midY > $1.boundingBox.midY }

        // 收集在 anchor 之后、并且在其下方的几行（最多3行），直到遇到“公民身份号码/号码”等关键词
        var started = false
        var extraCount = 0

        for l in sorted {
            if l.text == anchor.text { started = true; continue }
            if !started { continue }

            if l.text.contains("公民身份号码") || l.text.contains("身份号码") || l.text.contains("号码") {
                break
            }

            // 在 anchor 下方
            if l.boundingBox.midY < anchorBox.midY - 0.01 {
                // x位置相近
                if l.boundingBox.minX >= xMin && l.boundingBox.minX <= xMax {
                    let cleaned = l.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if cleaned.count >= 2 {
                        addressParts.append(cleaned)
                        extraCount += 1
                        if extraCount >= 3 { break }
                    }
                }
            }
        }

        let joined = addressParts.joined()
            .replacingOccurrences(of: "住址", with: "")
            .replacingOccurrences(of: "：", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return joined.isEmpty ? nil : joined
    }

    private func normalizeDate(_ s: String?) -> String? {
        guard var s = s else { return nil }
        s = s.replacingOccurrences(of: "年", with: "-")
             .replacingOccurrences(of: "月", with: "-")
             .replacingOccurrences(of: "日", with: "")
             .replacingOccurrences(of: " ", with: "")
        // 可能是 1990-01-02 或 19900102
        if s.range(of: #"^\d{8}$"#, options: .regularExpression) != nil {
            let y = s.prefix(4)
            let m = s.dropFirst(4).prefix(2)
            let d = s.dropFirst(6).prefix(2)
            return "\(y)-\(m)-\(d)"
        }
        return s
    }
}