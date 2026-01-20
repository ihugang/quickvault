package com.quickvault.data.repository;

import com.quickvault.data.local.database.dao.CardDao;
import com.quickvault.data.local.database.dao.CardFieldDao;
import com.quickvault.domain.service.CryptoService;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata("javax.inject.Singleton")
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
public final class CardRepository_Factory implements Factory<CardRepository> {
  private final Provider<CardDao> cardDaoProvider;

  private final Provider<CardFieldDao> cardFieldDaoProvider;

  private final Provider<CryptoService> cryptoServiceProvider;

  public CardRepository_Factory(Provider<CardDao> cardDaoProvider,
      Provider<CardFieldDao> cardFieldDaoProvider, Provider<CryptoService> cryptoServiceProvider) {
    this.cardDaoProvider = cardDaoProvider;
    this.cardFieldDaoProvider = cardFieldDaoProvider;
    this.cryptoServiceProvider = cryptoServiceProvider;
  }

  @Override
  public CardRepository get() {
    return newInstance(cardDaoProvider.get(), cardFieldDaoProvider.get(), cryptoServiceProvider.get());
  }

  public static CardRepository_Factory create(Provider<CardDao> cardDaoProvider,
      Provider<CardFieldDao> cardFieldDaoProvider, Provider<CryptoService> cryptoServiceProvider) {
    return new CardRepository_Factory(cardDaoProvider, cardFieldDaoProvider, cryptoServiceProvider);
  }

  public static CardRepository newInstance(CardDao cardDao, CardFieldDao cardFieldDao,
      CryptoService cryptoService) {
    return new CardRepository(cardDao, cardFieldDao, cryptoService);
  }
}
