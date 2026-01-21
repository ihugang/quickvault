import SwiftUI
import QuickHoldCore

/// Settings view / 设置视图
struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var showChangePassword = false
    @State private var showLanguagePicker = false
    @State private var showClearDataConfirmation = false
    @State private var clearDataPassword = ""
    
    var body: some View {
        NavigationStack {
            Form {
                // Security Section
                Section {
                    // Auto-Lock Timeout
                    Picker(localizationManager.localizedString("settings.security.autolock"), selection: $viewModel.autoLockTimeout) {
                        ForEach(AutoLockTimeout.allCases) { timeout in
                            Text(localizationManager.localizedString(timeout.localizationKey)).tag(timeout)
                        }
                    }
                    .onChange(of: viewModel.autoLockTimeout) { newValue in
                        viewModel.saveAutoLockTimeout(newValue)
                    }
                    
                    // Biometric Toggle
                    if viewModel.isBiometricAvailable {
                        Toggle(localizationManager.localizedString("settings.security.biometric"), isOn: Binding(
                            get: { viewModel.isBiometricEnabled },
                            set: { viewModel.toggleBiometric($0) }
                        ))
                    }
                    
                    // Change Password
                    Button {
                        showChangePassword = true
                    } label: {
                        HStack {
                            Text(localizationManager.localizedString("settings.security.changepassword"))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    // Clear All Data (Danger Zone)
                    Button(role: .destructive) {
                        showClearDataConfirmation = true
                    } label: {
                        HStack {
                            Text(localizationManager.localizedString("settings.security.cleardata"))
                            Spacer()
                        }
                    }
                } header: {
                    Text(localizationManager.localizedString("settings.security"))
                } footer: {
                    Text(localizationManager.localizedString("settings.security.cleardata.footer"))
                        .font(.caption)
                }
                
                // Appearance Section
                Section {
                    Picker(localizationManager.localizedString("settings.appearance"), selection: $viewModel.appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(localizationManager.localizedString(mode.localizationKey)).tag(mode)
                        }
                    }
                    .onChange(of: viewModel.appearanceMode) { newValue in
                        viewModel.saveAppearanceMode(newValue)
                    }
                } header: {
                    Text(localizationManager.localizedString("settings.appearance.title"))
                }
                
                // Language Section
                Section {
                    Button {
                        showLanguagePicker = true
                    } label: {
                        HStack {
                            Text(localizationManager.localizedString("settings.language"))
                            Spacer()
                            Text(localizationManager.isUsingSystemLanguage ?
                                 localizationManager.localizedString("settings.language.system") :
                                 localizationManager.currentLanguage.displayName)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text(localizationManager.localizedString("settings.language.title"))
                }
                
                // About Section
                Section {
                    HStack {
                        Text(localizationManager.localizedString("settings.about.version"))
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(localizationManager.localizedString("settings.about"))
                }

                // PhotoPC Promotion Section
                Section {
                    HStack(alignment: .center, spacing: 8) {
                        Image("photopc_icon")
                            .resizable()
                            .frame(width: 64, height: 64)
                            .cornerRadius(12)
                            .padding(.trailing, 8)
                            .onTapGesture {
                                if let url = URL(string: "https://apps.apple.com/cn/app/photopc/id1667798896?l=en-GB") {
                                    UIApplication.shared.open(url)
                                }
                            }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizationManager.localizedString("promo.photopc.title"))
                                .foregroundColor(.blue)
                                .font(.headline)
                                .onTapGesture {
                                    if let url = URL(string: "https://apps.apple.com/cn/app/photopc/id1667798896?l=en-GB") {
                                        UIApplication.shared.open(url)
                                    }
                                }

                            Text(localizationManager.localizedString("promo.photopc.description"))
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                                .lineLimit(3)
                                .padding(.vertical, 4)
                                .onTapGesture {
                                    if let url = URL(string: "https://apps.apple.com/cn/app/photopc/id1667798896?l=en-GB") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                        }
                    }
                } header: {
                    Text(localizationManager.localizedString("promo.photopc.title"))
                }

                // FoxVault Promotion Section
                Section {
                    HStack(alignment: .center, spacing: 8) {
                        Image("foxvault_icon")
                            .resizable()
                            .frame(width: 64, height: 64)
                            .cornerRadius(12)
                            .padding(.trailing, 8)
                            .onTapGesture {
                                if let url = URL(string: "https://apps.apple.com/us/app/foxvault/id6755353875") {
                                    UIApplication.shared.open(url)
                                }
                            }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizationManager.localizedString("promo.foxvault.title"))
                                .foregroundColor(.blue)
                                .font(.headline)
                                .onTapGesture {
                                    if let url = URL(string: "https://apps.apple.com/us/app/foxvault/id6755353875") {
                                        UIApplication.shared.open(url)
                                    }
                                }

                            Text(localizationManager.localizedString("promo.foxvault.description"))
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                                .lineLimit(3)
                                .padding(.vertical, 4)
                                .onTapGesture {
                                    if let url = URL(string: "https://apps.apple.com/us/app/foxvault/id6755353875") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                        }
                    }
                } header: {
                    Text(localizationManager.localizedString("promo.foxvault.title"))
                }
            }
            .navigationTitle(localizationManager.localizedString("settings.title"))
            .environment(\.layoutDirection, localizationManager.layoutDirection)
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showLanguagePicker) {
                LanguagePickerSheet()
            }
            .alert(localizationManager.localizedString("settings.security.cleardata.confirm.title"), isPresented: $showClearDataConfirmation) {
                SecureField(localizationManager.localizedString("settings.security.cleardata.confirm.password"), text: $clearDataPassword)
                Button(localizationManager.localizedString("common.cancel"), role: .cancel) {
                    clearDataPassword = ""
                }
                Button(localizationManager.localizedString("settings.security.cleardata.confirm.delete"), role: .destructive) {
                    Task {
                        await viewModel.clearAllData(password: clearDataPassword)
                        clearDataPassword = ""
                    }
                }
            } message: {
                Text(localizationManager.localizedString("settings.security.cleardata.confirm.message"))
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
                // System Default Option
                Button {
                    localizationManager.useSystemLanguage()
                    dismiss()
                } label: {
                    HStack {
                        Text("settings.language.system".localized)
                            .foregroundStyle(.primary)
                        Spacer()
                        if localizationManager.isUsingSystemLanguage {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                ForEach(AppLanguage.allCases) { language in
                    Button {
                        localizationManager.setLanguage(language)
                        dismiss()
                    } label: {
                        HStack {
                            Text(language.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if !localizationManager.isUsingSystemLanguage && localizationManager.currentLanguage == language {
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
    let authService = AuthenticationServiceImpl(keychainService: keychainService, persistenceController: PersistenceController.shared, cryptoService: cryptoService)
    return SettingsView(viewModel: SettingsViewModel(authService: authService))
}
