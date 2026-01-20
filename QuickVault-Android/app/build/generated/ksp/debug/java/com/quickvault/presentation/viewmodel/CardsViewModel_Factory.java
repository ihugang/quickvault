package com.quickvault.presentation.viewmodel;

import android.content.Context;
import com.quickvault.domain.service.CardService;
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
public final class CardsViewModel_Factory implements Factory<CardsViewModel> {
  private final Provider<CardService> cardServiceProvider;

  private final Provider<Context> contextProvider;

  public CardsViewModel_Factory(Provider<CardService> cardServiceProvider,
      Provider<Context> contextProvider) {
    this.cardServiceProvider = cardServiceProvider;
    this.contextProvider = contextProvider;
  }

  @Override
  public CardsViewModel get() {
    return newInstance(cardServiceProvider.get(), contextProvider.get());
  }

  public static CardsViewModel_Factory create(Provider<CardService> cardServiceProvider,
      Provider<Context> contextProvider) {
    return new CardsViewModel_Factory(cardServiceProvider, contextProvider);
  }

  public static CardsViewModel newInstance(CardService cardService, Context context) {
    return new CardsViewModel(cardService, context);
  }
}
