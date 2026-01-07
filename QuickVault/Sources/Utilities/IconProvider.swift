//
//  IconProvider.swift
//  QuickVault
//

import AppKit

enum IconProvider {

  // MARK: - Menu Bar Icons

  /// Menu bar icon for unlocked state
  /// 解锁状态的菜单栏图标
  static var menuBarUnlocked: NSImage {
    // Try to load custom icon first
    if let customIcon = NSImage(named: "MenuBarIcon") {
      return customIcon
    }

    // Fallback to SF Symbol
    let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
    if let sfSymbol = NSImage(
      systemSymbolName: "lock.open.fill", accessibilityDescription: "Unlocked")?
      .withSymbolConfiguration(config)
    {
      return sfSymbol
    }

    // Ultimate fallback
    return NSImage(size: NSSize(width: 18, height: 18))
  }

  /// Menu bar icon for locked state
  /// 锁定状态的菜单栏图标
  static var menuBarLocked: NSImage {
    // Try to load custom icon first
    if let customIcon = NSImage(named: "MenuBarIconLocked") {
      return customIcon
    }

    // Fallback to SF Symbol
    let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
    if let sfSymbol = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: "Locked")?
      .withSymbolConfiguration(config)
    {
      return sfSymbol
    }

    // Ultimate fallback
    return NSImage(size: NSSize(width: 18, height: 18))
  }

  // MARK: - App Icon

  /// Main application icon
  /// 主应用程序图标
  static var appIcon: NSImage {
    if let icon = NSImage(named: "AppIcon") {
      return icon
    }
    return NSImage(size: NSSize(width: 512, height: 512))
  }

  // MARK: - Card Type Icons

  /// Icon for address card type
  /// 地址卡片类型图标
  static func cardIcon(for type: String) -> NSImage {
    let symbolName: String
    switch type {
    case "address":
      symbolName = "location.fill"
    case "invoice":
      symbolName = "doc.text.fill"
    case "general":
      symbolName = "note.text"
    default:
      symbolName = "doc"
    }

    let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
    if let sfSymbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: type)?
      .withSymbolConfiguration(config)
    {
      return sfSymbol
    }

    return NSImage(size: NSSize(width: 16, height: 16))
  }

  // MARK: - Action Icons

  /// Copy icon
  /// 复制图标
  static var copyIcon: NSImage {
    let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
    if let sfSymbol = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Copy")?
      .withSymbolConfiguration(config)
    {
      return sfSymbol
    }
    return NSImage(size: NSSize(width: 16, height: 16))
  }

  /// Settings icon
  /// 设置图标
  static var settingsIcon: NSImage {
    let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
    if let sfSymbol = NSImage(
      systemSymbolName: "gearshape.fill", accessibilityDescription: "Settings")?
      .withSymbolConfiguration(config)
    {
      return sfSymbol
    }
    return NSImage(size: NSSize(width: 16, height: 16))
  }

  /// Dashboard icon
  /// 仪表板图标
  static var dashboardIcon: NSImage {
    let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
    if let sfSymbol = NSImage(
      systemSymbolName: "square.grid.2x2", accessibilityDescription: "Dashboard")?
      .withSymbolConfiguration(config)
    {
      return sfSymbol
    }
    return NSImage(size: NSSize(width: 16, height: 16))
  }

  /// Pin icon
  /// 置顶图标
  static var pinIcon: NSImage {
    let config = NSImage.SymbolConfiguration(pointSize: 10, weight: .regular)
    if let sfSymbol = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: "Pinned")?
      .withSymbolConfiguration(config)
    {
      return sfSymbol
    }
    return NSImage(size: NSSize(width: 12, height: 12))
  }

  /// Attachment icon
  /// 附件图标
  static var attachmentIcon: NSImage {
    let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
    if let sfSymbol = NSImage(
      systemSymbolName: "paperclip", accessibilityDescription: "Attachment")?
      .withSymbolConfiguration(config)
    {
      return sfSymbol
    }
    return NSImage(size: NSSize(width: 16, height: 16))
  }
}
