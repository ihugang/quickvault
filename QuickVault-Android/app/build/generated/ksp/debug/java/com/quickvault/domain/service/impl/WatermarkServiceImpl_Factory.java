package com.quickvault.domain.service.impl;

import android.content.Context;
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
public final class WatermarkServiceImpl_Factory implements Factory<WatermarkServiceImpl> {
  private final Provider<Context> contextProvider;

  public WatermarkServiceImpl_Factory(Provider<Context> contextProvider) {
    this.contextProvider = contextProvider;
  }

  @Override
  public WatermarkServiceImpl get() {
    return newInstance(contextProvider.get());
  }

  public static WatermarkServiceImpl_Factory create(Provider<Context> contextProvider) {
    return new WatermarkServiceImpl_Factory(contextProvider);
  }

  public static WatermarkServiceImpl newInstance(Context context) {
    return new WatermarkServiceImpl(context);
  }
}
