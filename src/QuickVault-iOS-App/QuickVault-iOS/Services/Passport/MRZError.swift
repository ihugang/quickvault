//
//  MRZError.swift
//  QuickVault-iOS
//
//  Created by Hu Gang on 2026/1/13.
//


import Foundation

enum MRZError: Error {
    case invalidFormat
    case checksumFailed
}

struct MRZParsed: Codable {
    let documentType: String?
    let issuingCountry: String?
    let surname: String?
    let givenNames: String?
    let passportNumber: String?
    let nationality: String?
    let birthDateYYMMDD: String?
    let sex: String?
    let expiryDateYYMMDD: String?
    let personalNumber: String? // optional
    let checksumsValid: Bool
    let rawLine1: String
    let rawLine2: String
}

final class MRZChecksum {
    // ICAO: A=10 ... Z=35, 0-9 as 0-9, < as 0
    static func value(of ch: Character) -> Int? {
        if ch == "<" { return 0 }
        if let d = ch.wholeNumberValue { return d }
        let u = ch.uppercased()
        guard let scalar = u.unicodeScalars.first else { return nil }
        let v = Int(scalar.value)
        // 'A' = 65
        if v >= 65 && v <= 90 { return v - 55 } // 65-55=10
        return nil
    }

    static func checksum(of field: String) -> Int? {
        let weights = [7, 3, 1]
        var sum = 0
        for (i, ch) in field.enumerated() {
            guard let v = value(of: ch) else { return nil }
            sum += v * weights[i % 3]
        }
        return sum % 10
    }

    static func isValid(field: String, checkDigit: Character) -> Bool {
        guard let expected = checksum(of: field),
              let provided = checkDigit.wholeNumberValue else { return false }
        return expected == provided
    }
}