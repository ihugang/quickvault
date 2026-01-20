package com.quickvault.domain.service.impl;

import android.content.Context;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata
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
public final class BiometricServiceImpl_Factory implements Factory<BiometricServiceImpl> {
  private final Provider<Context> contextProvider;

  public BiometricServiceImpl_Factory(Provider<Context> contextProvider) {
    this.contextProvider = contextProvider;
  }

  @Override
  public BiometricServiceImpl get() {
    return newInstance(contextProvider.get());
  }

  public static BiometricServiceImpl_Factory create(Provider<Context> contextProvider) {
    return new BiometricServiceImpl_Factory(contextProvider);
  }

  public static BiometricServiceImpl newInstance(Context context) {
    return new BiometricServiceImpl(context);
  }
}
