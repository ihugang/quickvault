//
//  URL+Extensions.swift
//  QuickVault
//
//  URL 扩展工具
//

import Foundation

extension URL {
    /// 解析 URL 查询参数
    var queryParameters: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return [:]
        }

        var parameters: [String: String] = [:]
        for item in queryItems {
            parameters[item.name] = item.value
        }
        return parameters
    }
}
