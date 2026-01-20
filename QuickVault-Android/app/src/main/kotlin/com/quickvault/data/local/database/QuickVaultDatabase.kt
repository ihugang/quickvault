package com.quickvault.data.local.database

import androidx.room.Database
import androidx.room.RoomDatabase
import com.quickvault.data.local.database.dao.AttachmentDao
import com.quickvault.data.local.database.dao.ItemDao
import com.quickvault.data.local.database.entity.AttachmentEntity
import com.quickvault.data.local.database.entity.ItemEntity
import com.quickvault.data.local.database.entity.TextContentEntity

/**
 * QuickVault 数据库
 * 对应 iOS 的 PersistenceController + CoreData Stack
 */
@Database(
    entities = [
        ItemEntity::class,
        TextContentEntity::class,
        AttachmentEntity::class
    ],
    version = 2,
    exportSchema = true
)
abstract class QuickVaultDatabase : RoomDatabase() {

    abstract fun itemDao(): ItemDao
    abstract fun attachmentDao(): AttachmentDao
}
