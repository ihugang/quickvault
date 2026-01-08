import SwiftUI
import QuickVaultCore

@main
struct QuickVaultApp: App {
    
    // MARK: - Core Services
    
    private let persistenceController = PersistenceController.shared
    private let keychainService = KeychainServiceImpl()
    private let cryptoService = CryptoServiceImpl()
    
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var cardListViewModel: CardListViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var autoLockManager: AutoLockManager
    
    // MARK: - Initialization
    
    init() {
        let keychainService = KeychainServiceImpl()
        let cryptoService = CryptoServiceImpl()
        let persistenceController = PersistenceController.shared
        
        let authService = AuthenticationServiceImpl(
            keychainService: keychainService,
            cryptoService: cryptoService
        )
        
        let cardService = CardServiceImpl(
            persistenceController: persistenceController,
            cryptoService: cryptoService
        )
        
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
        _cardListViewModel = StateObject(wrappedValue: CardListViewModel(cardService: cardService))
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(authService: authService))
        
        // Auto-lock manager with lock action
        let authViewModelInstance = AuthViewModel(authService: authService)
        _autoLockManager = StateObject(wrappedValue: AutoLockManager {
            authViewModelInstance.lock()
        })
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            RootView(
                authViewModel: authViewModel,
                cardListViewModel: cardListViewModel,
                settingsViewModel: settingsViewModel
            )
            .privacyScreen()
        }
    }
}

/// Root view that handles authentication state / 处理认证状态的根视图
struct RootView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var cardListViewModel: CardListViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        Group {
            switch authViewModel.authState {
            case .setupRequired:
                WelcomeView(viewModel: authViewModel)
                
            case .locked:
                LockScreenView(viewModel: authViewModel)
                
            case .unlocked:
                MainTabView(
                    cardListViewModel: cardListViewModel,
                    settingsViewModel: settingsViewModel
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.authState)
        .preferredColorScheme(colorScheme)
    }
    
    private var colorScheme: ColorScheme? {
        switch settingsViewModel.appearanceMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
