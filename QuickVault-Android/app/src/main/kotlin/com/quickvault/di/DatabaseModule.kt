package com.quickvault.di

import android.content.Context
import androidx.room.Room
import com.quickvault.data.local.database.QuickVaultDatabase
import com.quickvault.data.local.database.dao.AttachmentDao
import com.quickvault.data.local.database.dao.ItemDao
import com.quickvault.util.Constants
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * 数据库依赖注入模块
 * 提供 Room Database 和 DAO 实例
 */
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(
        @ApplicationContext context: Context
    ): QuickVaultDatabase {
        return Room.databaseBuilder(
            context,
            QuickVaultDatabase::class.java,
            Constants.DATABASE_NAME
        )
            .fallbackToDestructiveMigration()  // 开发阶段，生产环境需要 Migration
            .build()
    }

    @Provides
    @Singleton
    fun provideItemDao(database: QuickVaultDatabase): ItemDao {
        return database.itemDao()
    }

    @Provides
    @Singleton
    fun provideAttachmentDao(database: QuickVaultDatabase): AttachmentDao {
        return database.attachmentDao()
    }
}
