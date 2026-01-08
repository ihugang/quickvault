//
//  LocalizationManager.swift
//  QuickVault
//
//  Manages app localization with dynamic language switching / 管理应用本地化和动态语言切换
//

import Foundation
import SwiftUI

// MARK: - Supported Languages

enum AppLanguage: String, CaseIterable, Identifiable {
  case english = "en"
  case simplifiedChinese = "zh-Hans"
  case spanish = "es"
  case french = "fr"
  case german = "de"
  case italian = "it"
  case portuguesePortugal = "pt-PT"
  case portugueseBrazil = "pt-BR"
  case dutch = "nl"
  case polish = "pl"
  case russian = "ru"
  case swedish = "sv"
  case danish = "da"
  case norwegian = "no"
  case finnish = "fi"
  case czech = "cs"
  case hungarian = "hu"
  case romanian = "ro"
  case greek = "el"
  case ukrainian = "uk"
  case japanese = "ja"
  case arabic = "ar"
  
  var id: String { rawValue }
  
  var displayName: String {
    switch self {
    case .english: return "English"
    case .simplifiedChinese: return "简体中文"
    case .spanish: return "Español"
    case .french: return "Français"
    case .german: return "Deutsch"
    case .italian: return "Italiano"
    case .portuguesePortugal: return "Português (Portugal)"
    case .portugueseBrazil: return "Português (Brasil)"
    case .dutch: return "Nederlands"
    case .polish: return "Polski"
    case .russian: return "Русский"
    case .swedish: return "Svenska"
    case .danish: return "Dansk"
    case .norwegian: return "Norsk"
    case .finnish: return "Suomi"
    case .czech: return "Čeština"
    case .hungarian: return "Magyar"
    case .romanian: return "Română"
    case .greek: return "Ελληνικά"
    case .ukrainian: return "Українська"
    case .japanese: return "日本語"
    case .arabic: return "العربية"
    }
  }
  
  var isRTL: Bool {
    self == .arabic
  }
}

// MARK: - Localization Manager

@MainActor
class LocalizationManager: ObservableObject {
  static let shared = LocalizationManager()
  
  private let languageKey = "app_language"
  
  @Published var currentLanguage: AppLanguage {
    didSet {
      UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
      updateLayoutDirection()
    }
  }
  
  @Published var layoutDirection: LayoutDirection = .leftToRight
  
  private var bundle: Bundle?
  
  private init() {
    if let savedLanguage = UserDefaults.standard.string(forKey: languageKey),
       let language = AppLanguage(rawValue: savedLanguage) {
      self.currentLanguage = language
    } else {
      // Default to system language or English
      let preferredLanguage = Locale.preferredLanguages.first ?? "en"
      if let language = AppLanguage.allCases.first(where: { preferredLanguage.hasPrefix($0.rawValue) }) {
        self.currentLanguage = language
      } else {
        self.currentLanguage = .english
      }
    }
    updateBundle()
    updateLayoutDirection()
  }
  
  func setLanguage(_ language: AppLanguage) {
    currentLanguage = language
    updateBundle()
  }
  
  private func updateBundle() {
    if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
       let bundle = Bundle(path: path) {
      self.bundle = bundle
    } else {
      // Fallback to main bundle
      self.bundle = Bundle.main
    }
  }
  
  private func updateLayoutDirection() {
    layoutDirection = currentLanguage.isRTL ? .rightToLeft : .leftToRight
  }
  
  nonisolated func localizedString(_ key: String) -> String {
    let languageCode = UserDefaults.standard.string(forKey: "app_language") ?? "en"
    if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
       let bundle = Bundle(path: path) {
      return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
    return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
  }
  
  nonisolated func localizedString(_ key: String, _ arguments: CVarArg...) -> String {
    let format = localizedString(key)
    return String(format: format, arguments: arguments)
  }
}

// MARK: - String Extension for Localization

extension String {
  var localized: String {
    LocalizationManager.shared.localizedString(self)
  }
  
  func localized(_ arguments: CVarArg...) -> String {
    let format = LocalizationManager.shared.localizedString(self)
    return String(format: format, arguments: arguments)
  }
}

// MARK: - View Modifier for RTL Support

struct LocalizedViewModifier: ViewModifier {
  @ObservedObject var localizationManager = LocalizationManager.shared
  
  func body(content: Content) -> some View {
    content
      .environment(\.layoutDirection, localizationManager.layoutDirection)
  }
}

extension View {
  func localized() -> some View {
    modifier(LocalizedViewModifier())
  }
}
