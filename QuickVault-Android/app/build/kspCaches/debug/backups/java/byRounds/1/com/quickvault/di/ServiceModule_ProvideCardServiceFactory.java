package com.quickvault.di;

import android.content.Context;
import com.quickvault.data.repository.CardRepository;
import com.quickvault.domain.service.CardService;
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
public final class ServiceModule_ProvideCardServiceFactory implements Factory<CardService> {
  private final Provider<CardRepository> cardRepositoryProvider;

  private final Provider<ValidationService> validationServiceProvider;

  private final Provider<Context> contextProvider;

  public ServiceModule_ProvideCardServiceFactory(Provider<CardRepository> cardRepositoryProvider,
      Provider<ValidationService> validationServiceProvider, Provider<Context> contextProvider) {
    this.cardRepositoryProvider = cardRepositoryProvider;
    this.validationServiceProvider = validationServiceProvider;
    this.contextProvider = contextProvider;
  }

  @Override
  public CardService get() {
    return provideCardService(cardRepositoryProvider.get(), validationServiceProvider.get(), contextProvider.get());
  }

  public static ServiceModule_ProvideCardServiceFactory create(
      Provider<CardRepository> cardRepositoryProvider,
      Provider<ValidationService> validationServiceProvider, Provider<Context> contextProvider) {
    return new ServiceModule_ProvideCardServiceFactory(cardRepositoryProvider, validationServiceProvider, contextProvider);
  }

  public static CardService provideCardService(CardRepository cardRepository,
      ValidationService validationService, Context context) {
    return Preconditions.checkNotNullFromProvides(ServiceModule.INSTANCE.provideCardService(cardRepository, validationService, context));
  }
}
