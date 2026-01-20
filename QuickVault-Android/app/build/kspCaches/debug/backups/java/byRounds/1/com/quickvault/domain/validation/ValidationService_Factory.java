package com.quickvault.domain.validation;

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
public final class ValidationService_Factory implements Factory<ValidationService> {
  private final Provider<Context> contextProvider;

  public ValidationService_Factory(Provider<Context> contextProvider) {
    this.contextProvider = contextProvider;
  }

  @Override
  public ValidationService get() {
    return newInstance(contextProvider.get());
  }

  public static ValidationService_Factory create(Provider<Context> contextProvider) {
    return new ValidationService_Factory(contextProvider);
  }

  public static ValidationService newInstance(Context context) {
    return new ValidationService(context);
  }
}
