package com.quickvault.data.repository;

import com.quickvault.data.local.database.dao.AttachmentDao;
import com.quickvault.data.local.storage.FileStorageService;
import com.quickvault.domain.service.CryptoService;
import com.quickvault.domain.service.WatermarkService;
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
public final class AttachmentRepository_Factory implements Factory<AttachmentRepository> {
  private final Provider<AttachmentDao> attachmentDaoProvider;

  private final Provider<CryptoService> cryptoServiceProvider;

  private final Provider<WatermarkService> watermarkServiceProvider;

  private final Provider<FileStorageService> fileStorageServiceProvider;

  public AttachmentRepository_Factory(Provider<AttachmentDao> attachmentDaoProvider,
      Provider<CryptoService> cryptoServiceProvider,
      Provider<WatermarkService> watermarkServiceProvider,
      Provider<FileStorageService> fileStorageServiceProvider) {
    this.attachmentDaoProvider = attachmentDaoProvider;
    this.cryptoServiceProvider = cryptoServiceProvider;
    this.watermarkServiceProvider = watermarkServiceProvider;
    this.fileStorageServiceProvider = fileStorageServiceProvider;
  }

  @Override
  public AttachmentRepository get() {
    return newInstance(attachmentDaoProvider.get(), cryptoServiceProvider.get(), watermarkServiceProvider.get(), fileStorageServiceProvider.get());
  }

  public static AttachmentRepository_Factory create(Provider<AttachmentDao> attachmentDaoProvider,
      Provider<CryptoService> cryptoServiceProvider,
      Provider<WatermarkService> watermarkServiceProvider,
      Provider<FileStorageService> fileStorageServiceProvider) {
    return new AttachmentRepository_Factory(attachmentDaoProvider, cryptoServiceProvider, watermarkServiceProvider, fileStorageServiceProvider);
  }

  public static AttachmentRepository newInstance(AttachmentDao attachmentDao,
      CryptoService cryptoService, WatermarkService watermarkService,
      FileStorageService fileStorageService) {
    return new AttachmentRepository(attachmentDao, cryptoService, watermarkService, fileStorageService);
  }
}
