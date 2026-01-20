package com.quickvault.presentation.screen.auth;

import android.content.Context;
import com.quickvault.domain.service.AuthService;
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
public final class AuthViewModel_Factory implements Factory<AuthViewModel> {
  private final Provider<AuthService> authServiceProvider;

  private final Provider<Context> contextProvider;

  public AuthViewModel_Factory(Provider<AuthService> authServiceProvider,
      Provider<Context> contextProvider) {
    this.authServiceProvider = authServiceProvider;
    this.contextProvider = contextProvider;
  }

  @Override
  public AuthViewModel get() {
    return newInstance(authServiceProvider.get(), contextProvider.get());
  }

  public static AuthViewModel_Factory create(Provider<AuthService> authServiceProvider,
      Provider<Context> contextProvider) {
    return new AuthViewModel_Factory(authServiceProvider, contextProvider);
  }

  public static AuthViewModel newInstance(AuthService authService, Context context) {
    return new AuthViewModel(authService, context);
  }
}
