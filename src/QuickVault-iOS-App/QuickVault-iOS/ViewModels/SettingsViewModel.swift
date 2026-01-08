import Combine
import Foundation
import QuickVaultCore

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
        
        // Load biometric settings
        isBiometricAvailable = authService.isBiometricAvailable()
        isBiometricEnabled = authService.isBiometricEnabled()
    }
    
    // MARK: - Save Auto-Lock Timeout
    
    func saveAutoLockTimeout(_ timeout: AutoLockTimeout) {
        autoLockTimeout = timeout
        userDefaults.set(timeout.rawValue, forKey: autoLockTimeoutKey)
    }
    
    // MARK: - Toggle Biometric
    
    func toggleBiometric(_ enabled: Bool) {
        do {
            try authService.enableBiometric(enabled)
            isBiometricEnabled = enabled
            successMessage = enabled 
                ? "已启用生物识别 / Biometric enabled"
                : "已禁用生物识别 / Biometric disabled"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Change Password
    
    func changePassword() async -> Bool {
        // Validate inputs
        guard !oldPassword.isEmpty else {
            errorMessage = "请输入当前密码 / Please enter current password"
            return false
        }
        
        guard newPassword.count >= 8 else {
            errorMessage = "新密码必须至少 8 个字符 / New password must be at least 8 characters"
            return false
        }
        
        guard newPassword == confirmNewPassword else {
            errorMessage = "新密码不匹配 / New passwords do not match"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.changePassword(oldPassword: oldPassword, newPassword: newPassword)
            clearPasswordFields()
            successMessage = "密码已更改 / Password changed successfully"
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
