//
//  MRZTD3Parser.swift
//  QuickVault-iOS
//
//  Created by Hu Gang on 2026/1/13.
//


final class MRZTD3Parser {
    /// 输入两行 MRZ（允许包含空格/错误字符），返回解析结果（含 checksum 校验）
    func parse(line1 raw1: String, line2 raw2: String) throws -> MRZParsed {
        let l1 = MRZSanitizer.normalizeLine(raw1, targetLength: 44)
        let l2 = MRZSanitizer.normalizeLine(raw2, targetLength: 44)

        guard l1.count == 44, l2.count == 44 else { throw MRZError.invalidFormat }

        let docType = String(l1.prefix(2)) // "P<"
        let issuingCountry = String(l1.dropFirst(2).prefix(3))

        let namesPart = String(l1.dropFirst(5))
        let (surname, given) = splitName(namesPart)

        // line2 fixed positions (TD3)
        let passportNumberField = substr(l2, 0, 9)
        let passportNumberCD    = charAt(l2, 9)

        let nationality         = substr(l2, 10, 3)
        let birthField          = substr(l2, 13, 6)
        let birthCD             = charAt(l2, 19)

        let sex                 = String(charAt(l2, 20))
        let expiryField         = substr(l2, 21, 6)
        let expiryCD            = charAt(l2, 27)

        let personalNumberField = substr(l2, 28, 14)
        let personalNumberCD    = charAt(l2, 42)

        let finalCD             = charAt(l2, 43)

        // 校验：护照号、出生、到期、个人号(可选) + final checksum（组合字段）
        let passportOK = MRZChecksum.isValid(field: passportNumberField, checkDigit: passportNumberCD)
        let birthOK    = MRZChecksum.isValid(field: birthField, checkDigit: birthCD)
        let expiryOK   = MRZChecksum.isValid(field: expiryField, checkDigit: expiryCD)

        // personal number 有些国家不用，但校验位仍在（若全是<也视为可选）
        let personalAllFillers = personalNumberField.allSatisfy { $0 == "<" }
        let personalOK = personalAllFillers ? true : MRZChecksum.isValid(field: personalNumberField, checkDigit: personalNumberCD)

        // final checksum: passportNumber(9)+CD + birth(6)+CD + expiry(6)+CD + personal(14)+CD
        let composite = passportNumberField + String(passportNumberCD)
                      + birthField + String(birthCD)
                      + expiryField + String(expiryCD)
                      + personalNumberField + String(personalNumberCD)
        let finalOK = MRZChecksum.isValid(field: composite, checkDigit: finalCD)

        let allOK = passportOK && birthOK && expiryOK && personalOK && finalOK

        return MRZParsed(
            documentType: docType,
            issuingCountry: issuingCountry,
            surname: surname,
            givenNames: given,
            passportNumber: passportNumberField.replacingOccurrences(of: "<", with: ""),
            nationality: nationality,
            birthDateYYMMDD: birthField,
            sex: sex,
            expiryDateYYMMDD: expiryField,
            personalNumber: personalAllFillers ? nil : personalNumberField.replacingOccurrences(of: "<", with: ""),
            checksumsValid: allOK,
            rawLine1: l1,
            rawLine2: l2
        )
    }

    private func splitName(_ s: String) -> (String?, String?) {
        // "ERIKSSON<<ANNA<MARIA<<<<<<<<"
        let parts = s.split(separator: "<", omittingEmptySubsequences: false)
        // 更可靠：用 "<<"
        if let range = s.range(of: "<<") {
            let sur = s[..<range.lowerBound].replacingOccurrences(of: "<", with: " ").trimmingCharacters(in: .whitespaces)
            let giv = s[range.upperBound...].replacingOccurrences(of: "<", with: " ").trimmingCharacters(in: .whitespaces)
            return (sur.isEmpty ? nil : sur, giv.isEmpty ? nil : giv)
        }
        let cleaned = s.replacingOccurrences(of: "<", with: " ").trimmingCharacters(in: .whitespaces)
        return (cleaned.isEmpty ? nil : cleaned, nil)
    }

    private func substr(_ s: String, _ start: Int, _ len: Int) -> String {
        let a = s.index(s.startIndex, offsetBy: start)
        let b = s.index(a, offsetBy: len)
        return String(s[a..<b])
    }

    private func charAt(_ s: String, _ idx: Int) -> Character {
        s[s.index(s.startIndex, offsetBy: idx)]
    }
}