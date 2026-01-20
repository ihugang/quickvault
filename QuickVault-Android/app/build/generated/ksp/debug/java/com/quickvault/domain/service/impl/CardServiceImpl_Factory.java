package com.quickvault.domain.service.impl;

import android.content.Context;
import com.quickvault.data.repository.CardRepository;
import com.quickvault.domain.validation.ValidationService;
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
public final class CardServiceImpl_Factory implements Factory<CardServiceImpl> {
  private final Provider<CardRepository> cardRepositoryProvider;

  private final Provider<ValidationService> validationServiceProvider;

  private final Provider<Context> contextProvider;

  public CardServiceImpl_Factory(Provider<CardRepository> cardRepositoryProvider,
      Provider<ValidationService> validationServiceProvider, Provider<Context> contextProvider) {
    this.cardRepositoryProvider = cardRepositoryProvider;
    this.validationServiceProvider = validationServiceProvider;
    this.contextProvider = contextProvider;
  }

  @Override
  public CardServiceImpl get() {
    return newInstance(cardRepositoryProvider.get(), validationServiceProvider.get(), contextProvider.get());
  }

  public static CardServiceImpl_Factory create(Provider<CardRepository> cardRepositoryProvider,
      Provider<ValidationService> validationServiceProvider, Provider<Context> contextProvider) {
    return new CardServiceImpl_Factory(cardRepositoryProvider, validationServiceProvider, contextProvider);
  }

  public static CardServiceImpl newInstance(CardRepository cardRepository,
      ValidationService validationService, Context context) {
    return new CardServiceImpl(cardRepository, validationService, context);
  }
}
