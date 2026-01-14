//
//  ItemType.swift
//  QuickVault
//

import Foundation

// MARK: - Item Type

public enum ItemType: String, CaseIterable, Sendable, Identifiable {
  case text
  case image

  public var displayName: String {
    switch self {
    case .text: return "文本 / Text"
    case .image: return "图片 / Image"
    }
  }

  public var icon: String {
    switch self {
    case .text: return "doc.text"
    case .image: return "photo"
    }
  }

  public var id: String {
    rawValue
  }
}
