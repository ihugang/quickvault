package com.quickvault.di;

import android.content.Context;
import com.quickvault.domain.service.WatermarkService;
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
public final class ServiceModule_ProvideWatermarkServiceFactory implements Factory<WatermarkService> {
  private final Provider<Context> contextProvider;

  public ServiceModule_ProvideWatermarkServiceFactory(Provider<Context> contextProvider) {
    this.contextProvider = contextProvider;
  }

  @Override
  public WatermarkService get() {
    return provideWatermarkService(contextProvider.get());
  }

  public static ServiceModule_ProvideWatermarkServiceFactory create(
      Provider<Context> contextProvider) {
    return new ServiceModule_ProvideWatermarkServiceFactory(contextProvider);
  }

  public static WatermarkService provideWatermarkService(Context context) {
    return Preconditions.checkNotNullFromProvides(ServiceModule.INSTANCE.provideWatermarkService(context));
  }
}
