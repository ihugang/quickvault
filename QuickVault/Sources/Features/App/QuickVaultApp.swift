//
//  QuickVaultApp.swift
//  QuickVault
//
//  Created on 2026-01-07.
//

import SwiftUI

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
  func applicationDidFinishLaunching(_ notification: Notification) {
    // Hide dock icon - menu bar app only
    NSApp.setActivationPolicy(.accessory)
  }
}
