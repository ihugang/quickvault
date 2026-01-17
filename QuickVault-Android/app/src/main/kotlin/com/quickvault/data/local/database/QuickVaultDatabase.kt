package com.quickvault.data.local.database

import androidx.room.Database
import androidx.room.RoomDatabase
import com.quickvault.data.local.database.dao.CardDao
import com.quickvault.data.local.database.dao.CardFieldDao
import com.quickvault.data.local.database.dao.AttachmentDao
import com.quickvault.data.local.database.entity.CardEntity
import com.quickvault.data.local.database.entity.CardFieldEntity
import com.quickvault.data.local.database.entity.AttachmentEntity

/**
 * QuickVault 数据库
 * 对应 iOS 的 PersistenceController + CoreData Stack
 */
@Database(
    entities = [
        CardEntity::class,
        CardFieldEntity::class,
        AttachmentEntity::class
    ],
    version = 1,
    exportSchema = true
)
abstract class QuickVaultDatabase : RoomDatabase() {

    abstract fun cardDao(): CardDao
    abstract fun cardFieldDao(): CardFieldDao
    abstract fun attachmentDao(): AttachmentDao
}
