import SwiftUI
import QuickVaultCore

/// Welcome view for first-time setup / 首次设置欢迎视图
struct WelcomeView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var showBiometricSetup = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // App Icon and Title
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                    
                    Text("随取 / QuickVault")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("安全存储您的个人信息\nSecurely store your personal information")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Password Setup Form
                VStack(spacing: 20) {
                    Text("创建主密码 / Create Master Password")
                        .font(.headline)
                    
                    SecureField("密码 / Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                    
                    SecureField("确认密码 / Confirm Password", text: $viewModel.confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                    
                    Text("密码至少需要 8 个字符\nPassword must be at least 8 characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.setupPassword()
                            if viewModel.isUnlocked && viewModel.isBiometricAvailable {
                                showBiometricSetup = true
                            }
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("创建密码 / Create Password")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading || viewModel.password.isEmpty || viewModel.confirmPassword.isEmpty)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showBiometricSetup) {
                BiometricSetupSheet(viewModel: viewModel)
            }
        }
    }
}

/// Biometric setup sheet / 生物识别设置表单
struct BiometricSetupSheet: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "faceid")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                
                Text("启用 Face ID / Enable Face ID")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("使用 Face ID 快速解锁应用\nUse Face ID to quickly unlock the app")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        viewModel.enableBiometric(true)
                        dismiss()
                    }) {
                        Text("启用 / Enable")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("稍后设置 / Set Up Later")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 32)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    let keychainService = KeychainServiceImpl()
    let cryptoService = CryptoServiceImpl()
    let authService = AuthenticationServiceImpl(keychainService: keychainService, cryptoService: cryptoService)
    return WelcomeView(viewModel: AuthViewModel(authService: authService))
}
