package com.quickvault.di;

import com.quickvault.data.local.database.QuickVaultDatabase;
import com.quickvault.data.local.database.dao.AttachmentDao;
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
public final class DatabaseModule_ProvideAttachmentDaoFactory implements Factory<AttachmentDao> {
  private final Provider<QuickVaultDatabase> databaseProvider;

  public DatabaseModule_ProvideAttachmentDaoFactory(Provider<QuickVaultDatabase> databaseProvider) {
    this.databaseProvider = databaseProvider;
  }

  @Override
  public AttachmentDao get() {
    return provideAttachmentDao(databaseProvider.get());
  }

  public static DatabaseModule_ProvideAttachmentDaoFactory create(
      Provider<QuickVaultDatabase> databaseProvider) {
    return new DatabaseModule_ProvideAttachmentDaoFactory(databaseProvider);
  }

  public static AttachmentDao provideAttachmentDao(QuickVaultDatabase database) {
    return Preconditions.checkNotNullFromProvides(DatabaseModule.INSTANCE.provideAttachmentDao(database));
  }
}
