//
//  QuickVaultApp.swift
//  QuickVault
//
//  Created on 2026-01-07.
//

import AppKit
import SwiftUI
import QuickHoldCore

@main
struct QuickVaultApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    Settings {
      EmptyView()
    }
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {
  private var menuBarManager: MenuBarManager?

  func applicationDidFinishLaunching(_ notification: Notification) {
    print("QuickVault did finish launching")
    // Hide dock icon - menu bar app only
    NSApp.setActivationPolicy(.accessory)
    let keychainService = KeychainServiceImpl()
    let cryptoService = CryptoServiceImpl(keychainService: keychainService)
    let authService = AuthenticationServiceImpl(
      keychainService: keychainService,
      persistenceController: PersistenceController.shared,
      cryptoService: cryptoService
    )
    let cardService = CardServiceImpl(
      persistenceController: PersistenceController.shared,
      cryptoService: cryptoService
    )

    menuBarManager = MenuBarManager(authService: authService, cardService: cardService)

    // 报告设备信息到云端
    Task { @MainActor in
      await DeviceReportService.shared.reportDeviceIfNeeded()
    }
  }
}
