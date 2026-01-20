package com.quickvault.presentation.viewmodel;

import android.content.Context;
import androidx.lifecycle.SavedStateHandle;
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
public final class CardEditorViewModel_Factory implements Factory<CardEditorViewModel> {
  private final Provider<CardService> cardServiceProvider;

  private final Provider<Context> contextProvider;

  private final Provider<SavedStateHandle> savedStateHandleProvider;

  public CardEditorViewModel_Factory(Provider<CardService> cardServiceProvider,
      Provider<Context> contextProvider, Provider<SavedStateHandle> savedStateHandleProvider) {
    this.cardServiceProvider = cardServiceProvider;
    this.contextProvider = contextProvider;
    this.savedStateHandleProvider = savedStateHandleProvider;
  }

  @Override
  public CardEditorViewModel get() {
    return newInstance(cardServiceProvider.get(), contextProvider.get(), savedStateHandleProvider.get());
  }

  public static CardEditorViewModel_Factory create(Provider<CardService> cardServiceProvider,
      Provider<Context> contextProvider, Provider<SavedStateHandle> savedStateHandleProvider) {
    return new CardEditorViewModel_Factory(cardServiceProvider, contextProvider, savedStateHandleProvider);
  }

  public static CardEditorViewModel newInstance(CardService cardService, Context context,
      SavedStateHandle savedStateHandle) {
    return new CardEditorViewModel(cardService, context, savedStateHandle);
  }
}
