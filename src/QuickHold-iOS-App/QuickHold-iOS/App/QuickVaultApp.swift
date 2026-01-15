//
//  QuickHoldSimpleApp.swift
//  QuickHold
//
//  简化版应用入口
//

import SwiftUI
import QuickHoldCore

@main
struct QuickHoldSimpleApp: App {
    
    // MARK: - Core Services
    
    private let persistenceController = PersistenceController.shared
    private let keychainService = KeychainServiceImpl()
    
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var autoLockManager: AutoLockManager
    
    // MARK: - Initialization
    
    init() {
        let keychainService = KeychainServiceImpl()
        let cryptoService = CryptoServiceImpl.shared
        let persistenceController = PersistenceController.shared
        
        let authService = AuthenticationServiceImpl(
            keychainService: keychainService,
            persistenceController: persistenceController,
            cryptoService: cryptoService
        )
        
        let authViewModelInstance = AuthViewModel(authService: authService)

        _authViewModel = StateObject(wrappedValue: authViewModelInstance)

        // Auto-lock manager with auth service and lock action
        _autoLockManager = StateObject(wrappedValue: AutoLockManager(authService: authService) {
            authViewModelInstance.lock()
        })
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            SimpleRootView(authViewModel: authViewModel)
                .privacyScreen()
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    handleUniversalLink(userActivity)
                }
        }
    }

    // MARK: - Universal Links Handler

    private func handleUniversalLink(_ userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else { return }
        print("📱 收到 Universal Link: \(url.absoluteString)")
        // 应用会自动打开到卡片列表
    }
}

/// Simple root view for the new architecture
struct SimpleRootView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @AppStorage("com.quickhold.appearanceMode") private var appearanceModeRaw: Int = 0
    
    private var preferredColorScheme: ColorScheme? {
        // 0 = system, 1 = light, 2 = dark
        switch appearanceModeRaw {
        case 1:
            return .light
        case 2:
            return .dark
        default:
            return nil  // system
        }
    }
    
    var body: some View {
        Group {
            switch authViewModel.authState {
            case .locked:
                LockScreenView(viewModel: authViewModel)
                    .transition(.opacity)
                
            case .unlocked:
                MainContentView()
                    .transition(.opacity)
                
            case .setupRequired:
                WelcomeView(viewModel: authViewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: authViewModel.authState)
        .preferredColorScheme(preferredColorScheme)
    }
}

/// Main content view with ItemListView
struct MainContentView: View {
    private let itemService = ItemServiceImpl(
        persistenceController: PersistenceController.shared
    )
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingSettings = false
    
    var body: some View {
        TabView {
            ItemListView(itemService: itemService)
                .tabItem {
                    Label(localizationManager.localizedString("items.tab"), systemImage: "rectangle.stack")
                }
            
            SettingsTabView()
                .tabItem {
                    Label(localizationManager.localizedString("settings.tab"), systemImage: "gear")
                }
        }
        .environment(\.layoutDirection, localizationManager.layoutDirection)
    }
}

/// Settings tab placeholder
struct SettingsTabView: View {
    @StateObject private var settingsViewModel: SettingsViewModel
    
    init() {
        let authService = AuthenticationServiceImpl(
            keychainService: KeychainServiceImpl(),
            persistenceController: PersistenceController.shared,
            cryptoService: CryptoServiceImpl.shared
        )
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            SettingsView(viewModel: settingsViewModel)
        }
    }
}
