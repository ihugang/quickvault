package com.quickvault.di;

import android.content.Context;
import com.quickvault.data.local.keystore.SecureKeyManager;
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
public final class ServiceModule_ProvideCryptoServiceFactory implements Factory<CryptoService> {
  private final Provider<Context> contextProvider;

  private final Provider<SecureKeyManager> keyManagerProvider;

  public ServiceModule_ProvideCryptoServiceFactory(Provider<Context> contextProvider,
      Provider<SecureKeyManager> keyManagerProvider) {
    this.contextProvider = contextProvider;
    this.keyManagerProvider = keyManagerProvider;
  }

  @Override
  public CryptoService get() {
    return provideCryptoService(contextProvider.get(), keyManagerProvider.get());
  }

  public static ServiceModule_ProvideCryptoServiceFactory create(Provider<Context> contextProvider,
      Provider<SecureKeyManager> keyManagerProvider) {
    return new ServiceModule_ProvideCryptoServiceFactory(contextProvider, keyManagerProvider);
  }

  public static CryptoService provideCryptoService(Context context, SecureKeyManager keyManager) {
    return Preconditions.checkNotNullFromProvides(ServiceModule.INSTANCE.provideCryptoService(context, keyManager));
  }
}
