package com.quickvault.domain.service.impl;

import android.content.Context;
import com.quickvault.data.local.keystore.SecureKeyManager;
import com.quickvault.domain.service.BiometricService;
import com.quickvault.domain.service.CryptoService;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
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
public final class AuthServiceImpl_Factory implements Factory<AuthServiceImpl> {
  private final Provider<SecureKeyManager> keyManagerProvider;

  private final Provider<CryptoService> cryptoServiceProvider;

  private final Provider<BiometricService> biometricServiceProvider;

  private final Provider<Context> contextProvider;

  public AuthServiceImpl_Factory(Provider<SecureKeyManager> keyManagerProvider,
      Provider<CryptoService> cryptoServiceProvider,
      Provider<BiometricService> biometricServiceProvider, Provider<Context> contextProvider) {
    this.keyManagerProvider = keyManagerProvider;
    this.cryptoServiceProvider = cryptoServiceProvider;
    this.biometricServiceProvider = biometricServiceProvider;
    this.contextProvider = contextProvider;
  }

  @Override
  public AuthServiceImpl get() {
    return newInstance(keyManagerProvider.get(), cryptoServiceProvider.get(), biometricServiceProvider.get(), contextProvider.get());
  }

  public static AuthServiceImpl_Factory create(Provider<SecureKeyManager> keyManagerProvider,
      Provider<CryptoService> cryptoServiceProvider,
      Provider<BiometricService> biometricServiceProvider, Provider<Context> contextProvider) {
    return new AuthServiceImpl_Factory(keyManagerProvider, cryptoServiceProvider, biometricServiceProvider, contextProvider);
  }

  public static AuthServiceImpl newInstance(SecureKeyManager keyManager,
      CryptoService cryptoService, BiometricService biometricService, Context context) {
    return new AuthServiceImpl(keyManager, cryptoService, biometricService, context);
  }
}
