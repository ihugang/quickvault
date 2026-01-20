package com.quickvault.di;

import com.quickvault.data.local.database.QuickVaultDatabase;
import com.quickvault.data.local.database.dao.CardFieldDao;
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
public final class DatabaseModule_ProvideCardFieldDaoFactory implements Factory<CardFieldDao> {
  private final Provider<QuickVaultDatabase> databaseProvider;

  public DatabaseModule_ProvideCardFieldDaoFactory(Provider<QuickVaultDatabase> databaseProvider) {
    this.databaseProvider = databaseProvider;
  }

  @Override
  public CardFieldDao get() {
    return provideCardFieldDao(databaseProvider.get());
  }

  public static DatabaseModule_ProvideCardFieldDaoFactory create(
      Provider<QuickVaultDatabase> databaseProvider) {
    return new DatabaseModule_ProvideCardFieldDaoFactory(databaseProvider);
  }

  public static CardFieldDao provideCardFieldDao(QuickVaultDatabase database) {
    return Preconditions.checkNotNullFromProvides(DatabaseModule.INSTANCE.provideCardFieldDao(database));
  }
}
