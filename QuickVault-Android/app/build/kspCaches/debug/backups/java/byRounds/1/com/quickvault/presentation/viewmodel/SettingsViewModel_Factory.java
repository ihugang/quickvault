package com.quickvault.presentation.viewmodel;

import android.content.Context;
import com.quickvault.data.local.keystore.SecureKeyManager;
import com.quickvault.domain.service.AuthService;
import com.quickvault.domain.service.BiometricService;
import com.quickvault.domain.service.DeviceReportService;
import com.quickvault.util.ThemeManager;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata
@QualifierMetadata("dagger.hilt.android.qualifiers.ApplicationContext")
@DaggerGenerated
@Generated(
    value = "dagger.internal.codegen.ComponentProcessor",
    comments = "https://dagger.dev"
)
@SuppressWarnings({
    "unchecked",
    "rawtypes",
    "KotlinInternal",
    "KotlinInternalInJava"
})
public final class SettingsViewModel_Factory implements Factory<SettingsViewModel> {
  private final Provider<Context> contextProvider;

  private final Provider<AuthService> authServiceProvider;

  private final Provider<BiometricService> biometricServiceProvider;

  private final Provider<SecureKeyManager> keyManagerProvider;

  private final Provider<ThemeManager> themeManagerProvider;

  private final Provider<DeviceReportService> deviceReportServiceProvider;

  public SettingsViewModel_Factory(Provider<Context> contextProvider,
      Provider<AuthService> authServiceProvider,
      Provider<BiometricService> biometricServiceProvider,
      Provider<SecureKeyManager> keyManagerProvider, Provider<ThemeManager> themeManagerProvider,
      Provider<DeviceReportService> deviceReportServiceProvider) {
    this.contextProvider = contextProvider;
    this.authServiceProvider = authServiceProvider;
    this.biometricServiceProvider = biometricServiceProvider;
    this.keyManagerProvider = keyManagerProvider;
    this.themeManagerProvider = themeManagerProvider;
    this.deviceReportServiceProvider = deviceReportServiceProvider;
  }

  @Override
  public SettingsViewModel get() {
    return newInstance(contextProvider.get(), authServiceProvider.get(), biometricServiceProvider.get(), keyManagerProvider.get(), themeManagerProvider.get(), deviceReportServiceProvider.get());
  }

  public static SettingsViewModel_Factory create(Provider<Context> contextProvider,
      Provider<AuthService> authServiceProvider,
      Provider<BiometricService> biometricServiceProvider,
      Provider<SecureKeyManager> keyManagerProvider, Provider<ThemeManager> themeManagerProvider,
      Provider<DeviceReportService> deviceReportServiceProvider) {
    return new SettingsViewModel_Factory(contextProvider, authServiceProvider, biometricServiceProvider, keyManagerProvider, themeManagerProvider, deviceReportServiceProvider);
  }

  public static SettingsViewModel newInstance(Context context, AuthService authService,
      BiometricService biometricService, SecureKeyManager keyManager, ThemeManager themeManager,
      DeviceReportService deviceReportService) {
    return new SettingsViewModel(context, authService, biometricService, keyManager, themeManager, deviceReportService);
  }
}
