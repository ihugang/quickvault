import SwiftUI
import QuickHoldCore

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
                    Image("center-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)

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
                    // Show existing data detection message
                    if viewModel.hasExistingCloudData {
                        HStack(spacing: 12) {
                            Image(systemName: "icloud.fill")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("auth.sync.detected.title".localized)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("auth.sync.detected.message".localized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }

                    Text("auth.welcome.subtitle".localized)
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    SecureField("auth.password.placeholder".localized, text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                        .frame(height: 48)

                    SecureField("auth.password.confirm".localized, text: $viewModel.confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                        .frame(height: 48)

                    Text("auth.password.hint".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    // Show syncing status
                    if viewModel.isSyncing {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text(viewModel.syncStatusMessage ?? "auth.sync.waiting".localized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
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
                    .frame(height: 48)
                    .disabled(viewModel.isLoading || viewModel.password.isEmpty || viewModel.confirmPassword.isEmpty)

                    // Show retry button if password mismatch
                    if viewModel.showRetryButton {
                        Button(action: {
                            Task {
                                await viewModel.retrySetup()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("auth.sync.retry".localized)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .frame(height: 48)
                    }
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
                    .frame(height: 48)

                    Button(action: {
                        dismiss()
                    }) {
                        Text("common.cancel".localized)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .frame(height: 48)
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
    let authService = AuthenticationServiceImpl(keychainService: keychainService, persistenceController: PersistenceController.shared, cryptoService: cryptoService)
    return WelcomeView(viewModel: AuthViewModel(authService: authService))
}
