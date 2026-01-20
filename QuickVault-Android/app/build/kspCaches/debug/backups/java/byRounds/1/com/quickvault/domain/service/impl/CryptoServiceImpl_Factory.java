package com.quickvault.domain.service.impl;

import android.content.Context;
import com.quickvault.data.local.keystore.SecureKeyManager;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata("javax.inject.Singleton")
@QualifierMetadata
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
public final class CryptoServiceImpl_Factory implements Factory<CryptoServiceImpl> {
  private final Provider<Context> contextProvider;

  private final Provider<SecureKeyManager> keyManagerProvider;

  public CryptoServiceImpl_Factory(Provider<Context> contextProvider,
      Provider<SecureKeyManager> keyManagerProvider) {
    this.contextProvider = contextProvider;
    this.keyManagerProvider = keyManagerProvider;
  }

  @Override
  public CryptoServiceImpl get() {
    return newInstance(contextProvider.get(), keyManagerProvider.get());
  }

  public static CryptoServiceImpl_Factory create(Provider<Context> contextProvider,
      Provider<SecureKeyManager> keyManagerProvider) {
    return new CryptoServiceImpl_Factory(contextProvider, keyManagerProvider);
  }

  public static CryptoServiceImpl newInstance(Context context, SecureKeyManager keyManager) {
    return new CryptoServiceImpl(context, keyManager);
  }
}
