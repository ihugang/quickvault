import Combine
import Foundation
import QuickVaultCore

/// Authentication view model / 认证视图模型
@MainActor
class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var authState: AuthenticationState = .locked
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var showBiometricPrompt: Bool = false
    
    // MARK: - Dependencies
    
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var isSetupRequired: Bool {
        authState == .setupRequired
    }
    
    var isLocked: Bool {
        authState == .locked
    }
    
    var isUnlocked: Bool {
        authState == .unlocked
    }
    
    var canUseBiometric: Bool {
        authService.isBiometricAvailable() && authService.isBiometricEnabled()
    }
    
    var isBiometricAvailable: Bool {
        authService.isBiometricAvailable()
    }
    
    // MARK: - Initialization
    
    init(authService: AuthenticationService) {
        self.authService = authService
        
        authService.authenticationStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.authState = state
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Setup
    
    func setupPassword() async {
        guard password.count >= 8 else {
            errorMessage = "密码必须至少 8 个字符 / Password must be at least 8 characters"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "密码不匹配 / Passwords do not match"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.setupMasterPassword(password)
            password = ""
            confirmPassword = ""
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Authentication
    
    func authenticateWithPassword() async {
        guard !password.isEmpty else {
            errorMessage = "请输入密码 / Please enter password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.authenticateWithPassword(password)
            password = ""
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func authenticateWithBiometric() async {
        guard canUseBiometric else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.authenticateWithBiometric()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Biometric Management
    
    func enableBiometric(_ enabled: Bool) {
        do {
            try authService.enableBiometric(enabled)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Lock
    
    func lock() {
        authService.lock()
        password = ""
        confirmPassword = ""
        errorMessage = nil
    }
    
    // MARK: - Password Change
    
    func changePassword(oldPassword: String, newPassword: String, confirmNewPassword: String) async -> Bool {
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
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - Clear Error
    
    func clearError() {
        errorMessage = nil
    }
}
