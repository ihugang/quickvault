import SwiftUI
import QuickVaultCore

/// Lock screen view / 锁屏视图
struct LockScreenView: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Icon
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("app.name".localized)
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            // Authentication Form
            VStack(spacing: 20) {
                SecureField("auth.password.placeholder".localized, text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                    .submitLabel(.done)
                    .onSubmit {
                        Task {
                            await viewModel.authenticateWithPassword()
                        }
                    }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    Task {
                        await viewModel.authenticateWithPassword()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("auth.unlock.button".localized)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading || viewModel.password.isEmpty)
                
                // Biometric Button
                if viewModel.canUseBiometric {
                    Button(action: {
                        Task {
                            await viewModel.authenticateWithBiometric()
                        }
                    }) {
                        HStack {
                            Image(systemName: "faceid")
                            Text("auth.unlock.biometric".localized)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Automatically try biometric on appear
            if viewModel.canUseBiometric {
                Task {
                    await viewModel.authenticateWithBiometric()
                }
            }
        }
    }
}

#Preview {
    let keychainService = KeychainServiceImpl()
    let cryptoService = CryptoServiceImpl()
    let authService = AuthenticationServiceImpl(keychainService: keychainService, cryptoService: cryptoService)
    return LockScreenView(viewModel: AuthViewModel(authService: authService))
}
