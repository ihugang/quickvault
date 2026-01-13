final class PassportMRZParser {
    /// 输入OCR raw lines，尝试找两行 MRZ（长度通常 44）
    func parse(from lines: [OCRLine]) -> DocumentExtractionResult {
        let raw = lines.map(\.text).joined(separator: "\n")

        let candidates = lines
            .map { $0.text.replacingOccurrences(of: " ", with: "") }
            .filter { $0.count >= 30 } // 先粗过滤

        // 常见 MRZ 以 P< 开头
        guard let line1 = candidates.first(where: { $0.hasPrefix("P<") || $0.hasPrefix("P‹") }) else {
            return .init(docType: .unknown, fields: [], rawText: raw)
        }

        // 找第二行：通常紧挨着（这里简化为找下一条最长的）
        let line2 = candidates
            .filter { $0 != line1 }
            .sorted { $0.count > $1.count }
            .first

        guard let l2 = line2 else {
            return .init(docType: .unknown, fields: [], rawText: raw)
        }

        // 简化解析：国家码、姓名、护照号、出生日期、到期日
        let (issuingCountry, surnameGiven) = parseLine1(line1)
        let (passportNumber, nationality, birthDate, expiryDate, sex) = parseLine2(l2)

        var fields: [ExtractedField] = []
        func add(_ key: String, _ label: String, _ value: String?) {
            guard let v = value, !v.isEmpty else { return }
            fields.append(.init(key: key, label: label, value: v, confidence: 0.85))
        }

        add("issuing_country", "签发国家", issuingCountry)
        add("name", "姓名（MRZ）", surnameGiven)
        add("passport_number", "护照号码", passportNumber)
        add("nationality", "国籍", nationality)
        add("birth_date", "出生日期", birthDate)
        add("expiry_date", "有效期至", expiryDate)
        add("sex", "性别", sex)

        let docType: DocumentType = fields.isEmpty ? .unknown : .passportMRZ
        return .init(docType: docType, fields: fields, rawText: raw)
    }

    private func parseLine1(_ s: String) -> (String?, String?) {
        // P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<
        // 1-2: P<, 3-5: country
        let country = s.count >= 5 ? String(s.dropFirst(2).prefix(3)) : nil

        // 姓名分隔：<<
        if let range = s.range(of: "<<") {
            let namePart = s[range.upperBound...]
            let cleaned = namePart.replacingOccurrences(of: "<", with: " ").trimmingCharacters(in: .whitespaces)
            return (country, cleaned.isEmpty ? nil : cleaned)
        }
        return (country, nil)
    }

    private func parseLine2(_ s: String) -> (String?, String?, String?, String?, String?) {
        // L898902C36UTO7408122F1204159ZE184226B<<<<<10
        // 护照号：前9位（通常）
        let passportNumber = s.count >= 9 ? String(s.prefix(9)).replacingOccurrences(of: "<", with: "") : nil
        let nationality = s.count >= 13 ? String(s.dropFirst(10).prefix(3)) : nil

        // 出生日期：YYMMDD (位置因格式略有差异，这里用常见位置：第14~19)
        let birth = s.count >= 19 ? String(s.dropFirst(13).prefix(6)) : nil
        let sex = s.count >= 21 ? String(s.dropFirst(20).prefix(1)) : nil
        let exp = s.count >= 27 ? String(s.dropFirst(21).prefix(6)) : nil

        return (
            passportNumber,
            nationality,
            formatYYMMDD(birth),
            formatYYMMDD(exp),
            sex
        )
    }

    private func formatYYMMDD(_ yymmdd: String?) -> String? {
        guard let s = yymmdd, s.count == 6, s.range(of: #"^\d{6}$"#, options: .regularExpression) != nil else {
            return nil
        }
        let yy = s.prefix(2)
        let mm = s.dropFirst(2).prefix(2)
        let dd = s.dropFirst(4).prefix(2)
        return "\(yy)-\(mm)-\(dd)" // 你也可以结合当前年份推断 19xx/20xx
    }
}