package com.quickvault.di;

import android.content.Context;
import com.quickvault.domain.service.BiometricService;
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
public final class ServiceModule_ProvideBiometricServiceFactory implements Factory<BiometricService> {
  private final Provider<Context> contextProvider;

  public ServiceModule_ProvideBiometricServiceFactory(Provider<Context> contextProvider) {
    this.contextProvider = contextProvider;
  }

  @Override
  public BiometricService get() {
    return provideBiometricService(contextProvider.get());
  }

  public static ServiceModule_ProvideBiometricServiceFactory create(
      Provider<Context> contextProvider) {
    return new ServiceModule_ProvideBiometricServiceFactory(contextProvider);
  }

  public static BiometricService provideBiometricService(Context context) {
    return Preconditions.checkNotNullFromProvides(ServiceModule.INSTANCE.provideBiometricService(context));
  }
}
