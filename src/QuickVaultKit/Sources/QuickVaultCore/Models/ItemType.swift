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
    case .text: return LocalizationKeys.Items.ItemType.text
    case .image: return LocalizationKeys.Items.ItemType.image
    case .file: return LocalizationKeys.Items.ItemType.file
    }
  }

  public var icon: String {
    switch self {
    case .text: return AppConstants.SystemIcon.textDocument
    case .image: return AppConstants.SystemIcon.image
    case .file: return AppConstants.SystemIcon.file
    }
  }

  public var id: String {
    rawValue
  }
}
