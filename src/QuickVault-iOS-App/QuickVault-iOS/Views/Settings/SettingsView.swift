import SwiftUI
import QuickVaultCore

/// Settings view / 设置视图
struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showChangePassword = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Security Section
                Section {
                    // Auto-Lock Timeout
                    Picker("自动锁定 / Auto-Lock", selection: $viewModel.autoLockTimeout) {
                        ForEach(AutoLockTimeout.allCases) { timeout in
                            Text(timeout.displayName).tag(timeout)
                        }
                    }
                    .onChange(of: viewModel.autoLockTimeout) { _, newValue in
                        viewModel.saveAutoLockTimeout(newValue)
                    }
                    
                    // Biometric Toggle
                    if viewModel.isBiometricAvailable {
                        Toggle("Face ID / Touch ID", isOn: Binding(
                            get: { viewModel.isBiometricEnabled },
                            set: { viewModel.toggleBiometric($0) }
                        ))
                    }
                    
                    // Change Password
                    Button {
                        showChangePassword = true
                    } label: {
                        HStack {
                            Text("更改密码 / Change Password")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("安全 / Security")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("版本 / Version")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("关于 / About")
                }
            }
            .navigationTitle("设置 / Settings")
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordSheet(viewModel: viewModel)
            }
            .overlay {
                if let success = viewModel.successMessage {
                    ToastView(message: success, isSuccess: true)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                viewModel.clearSuccess()
                            }
                        }
                }
                
                if let error = viewModel.errorMessage {
                    ToastView(message: error, isSuccess: false)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                viewModel.clearError()
                            }
                        }
                }
            }
        }
    }
}

/// Change password sheet / 更改密码表单
struct ChangePasswordSheet: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("当前密码 / Current Password", text: $viewModel.oldPassword)
                        .textContentType(.password)
                } header: {
                    Text("验证 / Verification")
                }
                
                Section {
                    SecureField("新密码 / New Password", text: $viewModel.newPassword)
                        .textContentType(.newPassword)
                    
                    SecureField("确认新密码 / Confirm New Password", text: $viewModel.confirmNewPassword)
                        .textContentType(.newPassword)
                } header: {
                    Text("新密码 / New Password")
                } footer: {
                    Text("密码至少需要 8 个字符\nPassword must be at least 8 characters")
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("更改密码 / Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消 / Cancel") {
                        viewModel.clearPasswordFields()
                        viewModel.clearError()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存 / Save") {
                        Task {
                            if await viewModel.changePassword() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading || 
                             viewModel.oldPassword.isEmpty || 
                             viewModel.newPassword.isEmpty || 
                             viewModel.confirmNewPassword.isEmpty)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
    }
}

#Preview {
    let keychainService = KeychainServiceImpl()
    let cryptoService = CryptoServiceImpl()
    let authService = AuthenticationServiceImpl(keychainService: keychainService, cryptoService: cryptoService)
    return SettingsView(viewModel: SettingsViewModel(authService: authService))
}
