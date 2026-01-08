import SwiftUI
import QuickVaultCore

/// Settings view / 设置视图
struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var showChangePassword = false
    @State private var showLanguagePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Security Section
                Section {
                    // Auto-Lock Timeout
                    Picker("settings.security.autolock".localized, selection: $viewModel.autoLockTimeout) {
                        ForEach(AutoLockTimeout.allCases) { timeout in
                            Text(timeout.localizationKey.localized).tag(timeout)
                        }
                    }
                    .onChange(of: viewModel.autoLockTimeout) { _, newValue in
                        viewModel.saveAutoLockTimeout(newValue)
                    }
                    
                    // Biometric Toggle
                    if viewModel.isBiometricAvailable {
                        Toggle("settings.security.biometric".localized, isOn: Binding(
                            get: { viewModel.isBiometricEnabled },
                            set: { viewModel.toggleBiometric($0) }
                        ))
                    }
                    
                    // Change Password
                    Button {
                        showChangePassword = true
                    } label: {
                        HStack {
                            Text("settings.security.changepassword".localized)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("settings.security".localized)
                }
                
                // Language Section
                Section {
                    Button {
                        showLanguagePicker = true
                    } label: {
                        HStack {
                            Text("settings.language".localized)
                            Spacer()
                            Text(localizationManager.currentLanguage.displayName)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("settings.language.title".localized)
                }
                
                // About Section
                Section {
                    HStack {
                        Text("settings.about.version".localized)
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("settings.about".localized)
                }
            }
            .navigationTitle("settings.title".localized)
            .environment(\.layoutDirection, localizationManager.layoutDirection)
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showLanguagePicker) {
                LanguagePickerSheet()
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

/// Language picker sheet / 语言选择表单
struct LanguagePickerSheet: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        localizationManager.setLanguage(language)
                        dismiss()
                    } label: {
                        HStack {
                            Text(language.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if localizationManager.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("settings.language.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close".localized) {
                        dismiss()
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
                    SecureField("auth.change.current".localized, text: $viewModel.oldPassword)
                        .textContentType(.password)
                }
                
                Section {
                    SecureField("auth.change.new".localized, text: $viewModel.newPassword)
                        .textContentType(.newPassword)
                    
                    SecureField("auth.change.confirm".localized, text: $viewModel.confirmNewPassword)
                        .textContentType(.newPassword)
                } footer: {
                    Text("auth.password.hint".localized)
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("auth.change.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        viewModel.clearPasswordFields()
                        viewModel.clearError()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
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
