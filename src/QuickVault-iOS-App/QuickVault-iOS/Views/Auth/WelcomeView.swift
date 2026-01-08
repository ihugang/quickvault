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
                    
                    Text("app.name".localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("app.tagline".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Password Setup Form
                VStack(spacing: 20) {
                    Text("auth.welcome.subtitle".localized)
                        .font(.headline)
                    
                    SecureField("auth.password.placeholder".localized, text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                    
                    SecureField("auth.password.confirm".localized, text: $viewModel.confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                    
                    Text("auth.password.hint".localized)
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
                            Text("auth.setup.button".localized)
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
                
                Text("settings.security.biometric.enable".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("auth.unlock.biometric".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        viewModel.enableBiometric(true)
                        dismiss()
                    }) {
                        Text("common.confirm".localized)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("common.cancel".localized)
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
