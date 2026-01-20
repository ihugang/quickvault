package com.quickvault.di;

import com.quickvault.data.local.database.QuickVaultDatabase;
import com.quickvault.data.local.database.dao.CardDao;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.Preconditions;
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
public final class DatabaseModule_ProvideCardDaoFactory implements Factory<CardDao> {
  private final Provider<QuickVaultDatabase> databaseProvider;

  public DatabaseModule_ProvideCardDaoFactory(Provider<QuickVaultDatabase> databaseProvider) {
    this.databaseProvider = databaseProvider;
  }

  @Override
  public CardDao get() {
    return provideCardDao(databaseProvider.get());
  }

  public static DatabaseModule_ProvideCardDaoFactory create(
      Provider<QuickVaultDatabase> databaseProvider) {
    return new DatabaseModule_ProvideCardDaoFactory(databaseProvider);
  }

  public static CardDao provideCardDao(QuickVaultDatabase database) {
    return Preconditions.checkNotNullFromProvides(DatabaseModule.INSTANCE.provideCardDao(database));
  }
}
