//
//  ItemType.swift
//  QuickHold
//

import Foundation

// MARK: - Item Type

public enum ItemType: String, CaseIterable, Sendable, Identifiable {
  case text
  case image
  case file

  public var localizationKey: String {
    switch self {
    case .text: return "items.type.text"
    case .image: return "items.type.image"
    case .file: return "items.type.file"
    }
  }

  public var icon: String {
    switch self {
    case .text: return "doc.text"
    case .image: return "photo"
    case .file: return "folder.fill"
    }
  }

  public var id: String {
    rawValue
  }
}
