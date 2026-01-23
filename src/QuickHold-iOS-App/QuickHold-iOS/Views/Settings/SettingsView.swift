import SwiftUI
import QuickHoldCore

// MARK: - Color Palette
private enum SettingsPalette {
    static let primary = Color(red: 0.20, green: 0.40, blue: 0.70)       // #3366B3
    static let secondary = Color(red: 0.15, green: 0.65, blue: 0.60)     // #26A699
    static let accent = Color(red: 0.95, green: 0.70, blue: 0.20)        // #F2B333
    static let promoBackground = Color(.secondarySystemGroupedBackground)
    static let promoBorder = Color(.separator)
}

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
                // 安全说明卡 - Security Info Card
                securityInfoSection
                
                // 安全与隐私 - Security & Privacy
                securitySection
                
                // 外观与语言 - Appearance & Language
                appearanceAndLanguageSection
                
                // 关于 - About
                aboutSection
                
                // 更多产品 - More Products
                moreProductsSection
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
    
    // MARK: - Security Info Section
    
    private var securityInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title2)
                        .foregroundStyle(SettingsPalette.primary)
                    Text(localizationManager.localizedString("settings.security.info.title"))
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    SecurityFeatureRow(
                        icon: "key.fill",
                        text: localizationManager.localizedString("settings.security.info.encryption")
                    )
                    SecurityFeatureRow(
                        icon: "iphone.and.arrow.forward",
                        text: localizationManager.localizedString("settings.security.info.local")
                    )
                    SecurityFeatureRow(
                        icon: "hourglass",
                        text: localizationManager.localizedString("settings.security.info.autolock")
                    )
                    SecurityFeatureRow(
                        icon: "network.slash",
                        text: localizationManager.localizedString("settings.security.info.offline")
                    )
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text(localizationManager.localizedString("settings.security.info.header"))
        }
    }
    
    // MARK: - Security Section
    
    private var securitySection: some View {
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
    }
    
    // MARK: - Appearance and Language Section
    
    private var appearanceAndLanguageSection: some View {
        Section {
            // Appearance Mode
            Picker(localizationManager.localizedString("settings.appearance"), selection: $viewModel.appearanceMode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(localizationManager.localizedString(mode.localizationKey)).tag(mode)
                }
            }
            .onChange(of: viewModel.appearanceMode) { newValue in
                viewModel.saveAppearanceMode(newValue)
            }
            
            // Language Selector
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
            Text(localizationManager.localizedString("settings.appearance.language.title"))
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
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
    }
    
    // MARK: - More Products Section
    
    private var moreProductsSection: some View {
        Section {
            // PhotoPC Promo Card
            PromoCard(
                iconName: "photopc_icon",
                title: localizationManager.localizedString("promo.photopc.title"),
                description: localizationManager.localizedString("promo.photopc.description"),
                url: "https://apps.apple.com/cn/app/photopc/id1667798896?l=en-GB"
            )

            // ChronoTrace Promo Card
            PromoCard(
                iconName: "chronotrace_icon",
                title: localizationManager.localizedString("promo.chronotrace.title"),
                description: localizationManager.localizedString("promo.chronotrace.description"),
                url: "https://apps.apple.com/us/app/chronotrace/id6753780589"
            )

            // FoxVault Promo Card
            PromoCard(
                iconName: "foxvault_icon",
                title: localizationManager.localizedString("promo.foxvault.title"),
                description: localizationManager.localizedString("promo.foxvault.description"),
                url: "https://apps.apple.com/us/app/foxvault/id6755353875"
            )

            // ScanBig Promo Card
            PromoCard(
                iconName: "scanbig_icon",
                title: localizationManager.localizedString("promo.scanbig.title"),
                description: localizationManager.localizedString("promo.scanbig.description"),
                url: "https://apps.apple.com/us/app/scanbig/id6739180761"
            )
        } header: {
            Text(localizationManager.localizedString("settings.more.products"))
        } footer: {
            Text(localizationManager.localizedString("settings.more.products.footer"))
                .font(.caption)
        }
    }
}

// MARK: - Security Feature Row

struct SecurityFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(SettingsPalette.secondary)
                .frame(width: 24, alignment: .center)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Promo Card

struct PromoCard: View {
    let iconName: String
    let title: String
    let description: String
    let url: String
    
    var body: some View {
        Button {
            if let targetURL = URL(string: url) {
                UIApplication.shared.open(targetURL)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // 图标
                Image(iconName)
                    .resizable()
                    .frame(width: 56, height: 56)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // 内容
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(SettingsPalette.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
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
