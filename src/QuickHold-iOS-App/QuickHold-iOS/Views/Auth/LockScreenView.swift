import SwiftUI
import QuickHoldCore

/// Lock screen view / 锁屏视图
struct LockScreenView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var viewId = UUID()

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App Icon
            VStack(spacing: 16) {
                Image("center-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)

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
                    .frame(height: 48)
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
                .frame(height: 48)
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
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .frame(height: 48)
                    .disabled(viewModel.isLoading)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
        .id(viewId)
        .task {
            // Only attempt biometric once when this specific view instance appears
            if viewModel.canUseBiometric {
                // Add a small delay to ensure view is fully rendered
                try? await Task.sleep(nanoseconds: 500_000_000)
                await viewModel.authenticateWithBiometric()
            }
        }
    }
}

#Preview {
    let keychainService = KeychainServiceImpl()
    let cryptoService = CryptoServiceImpl()
    let authService = AuthenticationServiceImpl(keychainService: keychainService, persistenceController: PersistenceController.shared, cryptoService: cryptoService)
    return LockScreenView(viewModel: AuthViewModel(authService: authService))
}
