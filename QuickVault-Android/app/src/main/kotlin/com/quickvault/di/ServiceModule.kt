package com.quickvault.di

import android.content.Context
import com.quickvault.data.local.keystore.SecureKeyManager
import com.quickvault.data.repository.ItemRepository
import com.quickvault.domain.service.AuthService
import com.quickvault.domain.service.BiometricService
import com.quickvault.domain.service.CryptoService
import com.quickvault.domain.service.DeviceReportService
import com.quickvault.domain.service.ItemService
import com.quickvault.domain.service.WatermarkService
import com.quickvault.domain.service.impl.AuthServiceImpl
import com.quickvault.domain.service.impl.BiometricServiceImpl
import com.quickvault.domain.service.impl.CryptoServiceImpl
import com.quickvault.domain.service.impl.DeviceReportServiceImpl
import com.quickvault.domain.service.impl.ItemServiceImpl
import com.quickvault.domain.service.impl.WatermarkServiceImpl
import com.quickvault.domain.validation.ValidationService
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * 服务依赖注入模块
 * 提供各种业务服务的实例
 */
@Module
@InstallIn(SingletonComponent::class)
object ServiceModule {

    @Provides
    @Singleton
    fun provideSecureKeyManager(
        @ApplicationContext context: Context
    ): SecureKeyManager {
        return SecureKeyManager(context)
    }

    @Provides
    @Singleton
    fun provideCryptoService(
        @ApplicationContext context: Context,
        keyManager: SecureKeyManager
    ): CryptoService {
        return CryptoServiceImpl(context, keyManager)
    }

    @Provides
    @Singleton
    fun provideBiometricService(
        @ApplicationContext context: Context
    ): BiometricService {
        return BiometricServiceImpl(context)
    }

    @Provides
    @Singleton
    fun provideAuthService(
        @ApplicationContext context: Context,
        keyManager: SecureKeyManager,
        cryptoService: CryptoService,
        biometricService: BiometricService
    ): AuthService {
        return AuthServiceImpl(keyManager, cryptoService, biometricService, context)
    }

    @Provides
    @Singleton
    fun provideValidationService(
        @ApplicationContext context: Context
    ): ValidationService {
        return ValidationService(context)
    }

    @Provides
    @Singleton
    fun provideItemService(
        itemRepository: ItemRepository,
        @ApplicationContext context: Context
    ): ItemService {
        return ItemServiceImpl(itemRepository, context)
    }

    @Provides
    @Singleton
    fun provideWatermarkService(
        @ApplicationContext context: Context
    ): WatermarkService {
        return WatermarkServiceImpl(context)
    }
    
    @Provides
    @Singleton
    fun provideDeviceReportService(
        @ApplicationContext context: Context,
        itemRepository: ItemRepository
    ): DeviceReportService {
        return DeviceReportServiceImpl(context, itemRepository)
    }
}
