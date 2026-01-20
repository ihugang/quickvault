package com.quickvault.di;

import android.content.Context;
import com.quickvault.data.local.keystore.SecureKeyManager;
import com.quickvault.domain.service.AuthService;
import com.quickvault.domain.service.BiometricService;
import com.quickvault.domain.service.CryptoService;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.Preconditions;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata("javax.inject.Singleton")
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
public final class ServiceModule_ProvideAuthServiceFactory implements Factory<AuthService> {
  private final Provider<Context> contextProvider;

  private final Provider<SecureKeyManager> keyManagerProvider;

  private final Provider<CryptoService> cryptoServiceProvider;

  private final Provider<BiometricService> biometricServiceProvider;

  public ServiceModule_ProvideAuthServiceFactory(Provider<Context> contextProvider,
      Provider<SecureKeyManager> keyManagerProvider, Provider<CryptoService> cryptoServiceProvider,
      Provider<BiometricService> biometricServiceProvider) {
    this.contextProvider = contextProvider;
    this.keyManagerProvider = keyManagerProvider;
    this.cryptoServiceProvider = cryptoServiceProvider;
    this.biometricServiceProvider = biometricServiceProvider;
  }

  @Override
  public AuthService get() {
    return provideAuthService(contextProvider.get(), keyManagerProvider.get(), cryptoServiceProvider.get(), biometricServiceProvider.get());
  }

  public static ServiceModule_ProvideAuthServiceFactory create(Provider<Context> contextProvider,
      Provider<SecureKeyManager> keyManagerProvider, Provider<CryptoService> cryptoServiceProvider,
      Provider<BiometricService> biometricServiceProvider) {
    return new ServiceModule_ProvideAuthServiceFactory(contextProvider, keyManagerProvider, cryptoServiceProvider, biometricServiceProvider);
  }

  public static AuthService provideAuthService(Context context, SecureKeyManager keyManager,
      CryptoService cryptoService, BiometricService biometricService) {
    return Preconditions.checkNotNullFromProvides(ServiceModule.INSTANCE.provideAuthService(context, keyManager, cryptoService, biometricService));
  }
}
