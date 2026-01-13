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
    
    // 防止生物识别重复调用
    private var isBiometricInProgress: Bool = false
    private var lastBiometricAttempt: Date?
    private var biometricFailureCount: Int = 0
    private var lastBiometricFailure: Date?
    
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
            errorMessage = "auth.password.hint".localized
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "auth.password.mismatch".localized
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
            errorMessage = "auth.password.placeholder".localized
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
        // 先检查是否已解锁,如果已解锁直接返回
        guard authState == .locked else {
            print("[AuthViewModel] Already unlocked, skipping biometric auth")
            return
        }

        guard canUseBiometric else {
            print("[AuthViewModel] Biometric not available or enabled")
            return
        }

        // 防止重复调用
        guard !isBiometricInProgress else {
            print("[AuthViewModel] Biometric already in progress, skipping")
            return
        }

        // 检查失败冷却时间 (连续失败3次后需要等待10秒)
        if biometricFailureCount >= 3 {
            if let lastFailure = lastBiometricFailure {
                let elapsed = Date().timeIntervalSince(lastFailure)
                if elapsed < 10.0 {
                    let remaining = Int(10.0 - elapsed)
                    errorMessage = "生物识别失败次数过多,请等待 \(remaining) 秒 / Too many biometric failures, please wait \(remaining) seconds"
                    return
                }
            }
            // 冷却时间已过,重置计数
            biometricFailureCount = 0
            lastBiometricFailure = nil
        }

        // 如果距离上次尝试不到2秒,直接返回(避免系统级重试)
        if let lastAttempt = lastBiometricAttempt {
            let elapsed = Date().timeIntervalSince(lastAttempt)
            if elapsed < 2.0 {
                print("[AuthViewModel] Too soon since last attempt, skipping")
                return
            }
        }

        print("[AuthViewModel] Starting biometric authentication")
        isBiometricInProgress = true
        lastBiometricAttempt = Date()
        isLoading = true
        errorMessage = nil

        do {
            try await authService.authenticateWithBiometric()
            // 成功后重置失败计数
            biometricFailureCount = 0
            lastBiometricFailure = nil
            print("[AuthViewModel] Biometric authentication completed successfully")
        } catch {
            // 失败计数增加
            biometricFailureCount += 1
            lastBiometricFailure = Date()
            errorMessage = error.localizedDescription
            print("[AuthViewModel] Biometric authentication failed: \(error)")
        }

        isLoading = false
        isBiometricInProgress = false
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
        // 重置生物识别状态
        biometricFailureCount = 0
        lastBiometricFailure = nil
        isBiometricInProgress = false
    }
    
    // MARK: - Password Change
    
    func changePassword(oldPassword: String, newPassword: String, confirmNewPassword: String) async -> Bool {
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
