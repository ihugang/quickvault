//
//  MRZAutoCorrector.swift
//  QuickHold-iOS
//
//  Created by Hu Gang on 2026/1/13.
//


final class MRZAutoCorrector {
    private let parser = MRZTD3Parser()

    /// 输入原始两行（可能有 OCR 错误），返回“尽量校验通过”的结果
    func parseWithAutoCorrection(line1: String, line2: String) throws -> MRZParsed {
        // 先标准化
        let l1 = MRZSanitizer.normalizeLine(line1, targetLength: 44)
        var l2 = MRZSanitizer.normalizeLine(line2, targetLength: 44)

        // 先尝试直接解析
        if let ok = try? parser.parse(line1: l1, line2: l2), ok.checksumsValid {
            return ok
        }

        // 只针对 line2 的数字域做纠错（护照号、出生、到期、校验位）
        // 常见映射：O->0, I->1, Z->2, S->5, B->8, G->6
        let digitFix: [Character: Character] = [
            "O": "0", "Q": "0",
            "I": "1", "L": "1",
            "Z": "2",
            "S": "5",
            "B": "8",
            "G": "6"
        ]

        // 需要为“数字域”建立索引集合（TD3 固定位置）
        // passportNumber: 0..8, CD:9, birth:13..18, CD:19, expiry:21..26, CD:27, personal:28..41, CD:42, finalCD:43
        let numericPositions: [Int] =
            Array(0...9) + Array(13...19) + Array(21...27) + Array(28...43)

        // 先做一次“强制数字化”替换（只在这些位置）
        l2 = applyMap(l2, positions: numericPositions, map: digitFix)

        // 再尝试解析
        if let ok = try? parser.parse(line1: l1, line2: l2), ok.checksumsValid {
            return ok
        }

        // 进一步：如果仍失败，做“单字符搜索修正”
        // 思路：在失败的字段中，逐位尝试把疑似字母改为数字候选，直到 checksum 通过
        let attemptLimit = 200
        var attempts = 0

        // 对护照号/出生/到期分别尝试修正
        let fieldsToFix: [(range: Range<Int>, cdIndex: Int)] = [
            (0..<9, 9),
            (13..<19, 19),
            (21..<27, 27)
        ]

        for f in fieldsToFix {
            if attempts >= attemptLimit { break }
            let (newL2, fixed) = tryFixChecksum(line2: l2, fieldRange: f.range, cdIndex: f.cdIndex, map: digitFix, maxTries: attemptLimit - attempts)
            l2 = newL2
            attempts += fixed
        }

        // 最终尝试
        if let ok = try? parser.parse(line1: l1, line2: l2) {
            return ok // 即便 checksumsValid=false 也返回，交给上层做提示/重拍
        }
        throw MRZError.checksumFailed
    }

    // MARK: - Helpers

    private func applyMap(_ s: String, positions: [Int], map: [Character: Character]) -> String {
        var chars = Array(s)
        for i in positions where i < chars.count {
            if let repl = map[chars[i]] {
                chars[i] = repl
            }
        }
        return String(chars)
    }

    private func tryFixChecksum(
        line2: String,
        fieldRange: Range<Int>,
        cdIndex: Int,
        map: [Character: Character],
        maxTries: Int
    ) -> (String, Int) {
        var chars = Array(line2)
        let original = chars

        func fieldString(_ c: [Character]) -> String {
            String(c[fieldRange])
        }

        var tries = 0
        // 当前校验是否通过
        if MRZChecksum.isValid(field: fieldString(chars), checkDigit: chars[cdIndex]) {
            return (line2, tries)
        }

        // 逐位尝试替换
        for i in fieldRange {
            if tries >= maxTries { break }

            // 如果该位是字母且可映射为数字，尝试替换
            if let repl = map[chars[i]] {
                let old = chars[i]
                chars[i] = repl
                tries += 1

                if MRZChecksum.isValid(field: fieldString(chars), checkDigit: chars[cdIndex]) {
                    return (String(chars), tries)
                }
                // 不通过则回滚
                chars[i] = old
            }
        }

        // 再尝试：如果校验位本身被识别成字母（如 O），也试图修正校验位为数字
        if let repl = map[chars[cdIndex]] {
            let old = chars[cdIndex]
            chars[cdIndex] = repl
            tries += 1
            if MRZChecksum.isValid(field: fieldString(chars), checkDigit: chars[cdIndex]) {
                return (String(chars), tries)
            }
            chars[cdIndex] = old
        }

        // 失败：恢复原样
        return (String(original), tries)
    }
}
