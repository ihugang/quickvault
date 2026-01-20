package com.quickvault.presentation.lifecycle;

import com.quickvault.domain.service.AuthService;
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
public final class AppLifecycleObserver_Factory implements Factory<AppLifecycleObserver> {
  private final Provider<AuthService> authServiceProvider;

  public AppLifecycleObserver_Factory(Provider<AuthService> authServiceProvider) {
    this.authServiceProvider = authServiceProvider;
  }

  @Override
  public AppLifecycleObserver get() {
    return newInstance(authServiceProvider.get());
  }

  public static AppLifecycleObserver_Factory create(Provider<AuthService> authServiceProvider) {
    return new AppLifecycleObserver_Factory(authServiceProvider);
  }

  public static AppLifecycleObserver newInstance(AuthService authService) {
    return new AppLifecycleObserver(authService);
  }
}
