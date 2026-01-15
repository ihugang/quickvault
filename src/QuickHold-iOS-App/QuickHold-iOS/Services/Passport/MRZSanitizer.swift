//
//  MRZSanitizer.swift
//  QuickHold-iOS
//
//  Created by Hu Gang on 2026/1/13.
//


final class MRZSanitizer {
    /// 标准化：去空格/奇怪符号；替换常见 OCR 误差；补齐/截断到目标长度
    static func normalizeLine(_ raw: String, targetLength: Int) -> String {
        // 1) 去空格
        var s = raw.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "‹", with: "<") // 有些OCR会用‹
            .replacingOccurrences(of: "«", with: "<")

        // 2) 只保留 A-Z 0-9 <，其他当成 <
        s = s.map { ch in
            if (ch >= "A" && ch <= "Z") || (ch >= "0" && ch <= "9") || ch == "<" {
                return ch
            }
            return "<"
        }.reduce("") { $0 + String($1) }

        // 3) 常见纠错（只在“数字域/校验位域”更严谨，这里先做通用轻纠错）
        // 注意：过度纠错会把名字里 O 误改成 0，所以后续“字段级纠错”更重要
        // 这里不做全局替换，只做有限替换：把易错符号统一为 <
        s = s.replacingOccurrences(of: "|", with: "<")

        // 4) 补齐或截断
        if s.count < targetLength {
            s += String(repeating: "<", count: targetLength - s.count)
        } else if s.count > targetLength {
            s = String(s.prefix(targetLength))
        }
        return s
    }
}
