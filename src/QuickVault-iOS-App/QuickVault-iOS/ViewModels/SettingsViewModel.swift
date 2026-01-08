import Combine
import Foundation
import QuickVaultCore

/// App appearance mode / 外观模式
enum AppearanceMode: Int, CaseIterable, Identifiable {
    case system = 0
    case light = 1
    case dark = 2
    
    var id: Int { rawValue }
    
    var localizationKey: String {
        switch self {
        case .system: return "settings.appearance.auto"
        case .light: return "settings.appearance.light"
        case .dark: return "settings.appearance.dark"
        }
    }
}

/// Auto-lock timeout options / 自动锁定超时选项
enum AutoLockTimeout: Int, CaseIterable, Identifiable {
    case immediately = 0
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case never = -1
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .immediately: return "立即 / Immediately"
        case .oneMinute: return "1 分钟 / 1 minute"
        case .fiveMinutes: return "5 分钟 / 5 minutes"
        case .fifteenMinutes: return "15 分钟 / 15 minutes"
        case .thirtyMinutes: return "30 分钟 / 30 minutes"
        case .never: return "从不 / Never"
        }
    }
    
    var localizationKey: String {
        switch self {
        case .immediately: return "settings.security.autolock.immediately"
        case .oneMinute: return "settings.security.autolock.1min"
        case .fiveMinutes: return "settings.security.autolock.5min"
        case .fifteenMinutes: return "settings.security.autolock.15min"
        case .thirtyMinutes: return "settings.security.autolock.15min"
        case .never: return "settings.security.autolock.never"
        }
    }
}

/// Settings view model / 设置视图模型
@MainActor
class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var autoLockTimeout: AutoLockTimeout = .fiveMinutes
    @Published var appearanceMode: AppearanceMode = .system
    @Published var isBiometricEnabled: Bool = false
    @Published var isBiometricAvailable: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Password change fields
    @Published var oldPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmNewPassword: String = ""
    
    // MARK: - Dependencies
    
    private let authService: AuthenticationService
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Keys
    
    private let autoLockTimeoutKey = "com.quickvault.autoLockTimeout"
    private let appearanceModeKey = "com.quickvault.appearanceMode"
    
    // MARK: - Initialization
    
    init(authService: AuthenticationService) {
        self.authService = authService
        loadSettings()
    }
    
    // MARK: - Load Settings
    
    func loadSettings() {
        // Load auto-lock timeout
        let savedTimeout = userDefaults.integer(forKey: autoLockTimeoutKey)
        autoLockTimeout = AutoLockTimeout(rawValue: savedTimeout) ?? .fiveMinutes
        
        // Load appearance mode
        let savedAppearance = userDefaults.integer(forKey: appearanceModeKey)
        appearanceMode = AppearanceMode(rawValue: savedAppearance) ?? .system
        
        // Load biometric settings
        isBiometricAvailable = authService.isBiometricAvailable()
        isBiometricEnabled = authService.isBiometricEnabled()
    }
    
    // MARK: - Save Auto-Lock Timeout
    
    func saveAutoLockTimeout(_ timeout: AutoLockTimeout) {
        autoLockTimeout = timeout
        userDefaults.set(timeout.rawValue, forKey: autoLockTimeoutKey)
    }
    
    // MARK: - Save Appearance Mode
    
    func saveAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
        userDefaults.set(mode.rawValue, forKey: appearanceModeKey)
    }
    
    // MARK: - Toggle Biometric
    
    func toggleBiometric(_ enabled: Bool) {
        do {
            try authService.enableBiometric(enabled)
            isBiometricEnabled = enabled
            successMessage = enabled 
                ? "settings.security.biometric.enabled".localized
                : "settings.security.biometric.disabled".localized
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Change Password
    
    func changePassword() async -> Bool {
        // Validate inputs
        guard !oldPassword.isEmpty else {
            errorMessage = "auth.change.current".localized
            return false
        }
        
        guard newPassword.count >= 8 else {
            errorMessage = "auth.password.hint".localized
            return false
        }
        
        guard newPassword == confirmNewPassword else {
            errorMessage = "auth.password.mismatch".localized
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.changePassword(oldPassword: oldPassword, newPassword: newPassword)
            clearPasswordFields()
            successMessage = "auth.change.success".localized
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - Clear Password Fields
    
    func clearPasswordFields() {
        oldPassword = ""
        newPassword = ""
        confirmNewPassword = ""
    }
    
    // MARK: - Clear Messages
    
    func clearError() {
        errorMessage = nil
    }
    
    func clearSuccess() {
        successMessage = nil
    }
    
    // MARK: - App Info
    
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
