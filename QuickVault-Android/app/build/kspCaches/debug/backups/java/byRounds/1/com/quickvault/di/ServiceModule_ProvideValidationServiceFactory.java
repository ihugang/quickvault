package com.quickvault.di;

import android.content.Context;
import com.quickvault.domain.validation.ValidationService;
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
public final class ServiceModule_ProvideValidationServiceFactory implements Factory<ValidationService> {
  private final Provider<Context> contextProvider;

  public ServiceModule_ProvideValidationServiceFactory(Provider<Context> contextProvider) {
    this.contextProvider = contextProvider;
  }

  @Override
  public ValidationService get() {
    return provideValidationService(contextProvider.get());
  }

  public static ServiceModule_ProvideValidationServiceFactory create(
      Provider<Context> contextProvider) {
    return new ServiceModule_ProvideValidationServiceFactory(contextProvider);
  }

  public static ValidationService provideValidationService(Context context) {
    return Preconditions.checkNotNullFromProvides(ServiceModule.INSTANCE.provideValidationService(context));
  }
}
