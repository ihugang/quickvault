package com.quickvault.data.local.database

import android.content.Context
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.quickvault.domain.service.CryptoService
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import java.io.File

/**
 * 数据库迁移定义
 * 
 * Migration 2 -> 3:
 * 将附件数据从数据库BLOB字段迁移到文件系统
 */

/**
 * 从版本2迁移到版本3
 * 主要变更：
 * - 将 encrypted_data (BLOB) 改为 encrypted_file_path (TEXT)
 * - 将 thumbnail_data (BLOB) 改为 thumbnail_file_path (TEXT)
 * - 将现有的BLOB数据迁移到文件系统
 */
class Migration_2_3(
    private val context: Context
) : Migration(2, 3) {
    
    override fun migrate(database: SupportSQLiteDatabase) {
        // 1. 创建新表结构
        database.execSQL("""
            CREATE TABLE IF NOT EXISTS attachments_new (
                id TEXT PRIMARY KEY NOT NULL,
                item_id TEXT NOT NULL,
                file_name TEXT NOT NULL,
                file_type TEXT NOT NULL,
                file_size INTEGER NOT NULL,
                display_order INTEGER NOT NULL,
                encrypted_file_path TEXT NOT NULL,
                thumbnail_file_path TEXT,
                created_at INTEGER NOT NULL,
                FOREIGN KEY(item_id) REFERENCES items(id) ON DELETE CASCADE
            )
        """.trimIndent())
        
        // 2. 创建索引
        database.execSQL("CREATE INDEX IF NOT EXISTS index_attachments_new_item_id ON attachments_new(item_id)")
        
        // 3. 迁移数据：从BLOB到文件系统
        migrateAttachmentData(database)
        
        // 4. 删除旧表
        database.execSQL("DROP TABLE IF EXISTS attachments")
        
        // 5. 重命名新表
        database.execSQL("ALTER TABLE attachments_new RENAME TO attachments")
    }
    
    /**
     * 迁移附件数据
     */
    private fun migrateAttachmentData(database: SupportSQLiteDatabase) {
        val attachmentsDir = File(context.filesDir, "attachments").apply {
            if (!exists()) mkdirs()
        }
        val thumbnailsDir = File(context.filesDir, "thumbnails").apply {
            if (!exists()) mkdirs()
        }
        
        // 查询所有附件
        val cursor = database.query("SELECT * FROM attachments")
        
        try {
            val idIndex = cursor.getColumnIndex("id")
            val itemIdIndex = cursor.getColumnIndex("item_id")
            val fileNameIndex = cursor.getColumnIndex("file_name")
            val fileTypeIndex = cursor.getColumnIndex("file_type")
            val fileSizeIndex = cursor.getColumnIndex("file_size")
            val displayOrderIndex = cursor.getColumnIndex("display_order")
            val encryptedDataIndex = cursor.getColumnIndex("encrypted_data")
            val thumbnailDataIndex = cursor.getColumnIndex("thumbnail_data")
            val createdAtIndex = cursor.getColumnIndex("created_at")
            
            while (cursor.moveToNext()) {
                val id = cursor.getString(idIndex)
                val itemId = cursor.getString(itemIdIndex)
                val fileName = cursor.getString(fileNameIndex)
                val fileType = cursor.getString(fileTypeIndex)
                val fileSize = cursor.getLong(fileSizeIndex)
                val displayOrder = cursor.getInt(displayOrderIndex)
                val encryptedData = cursor.getBlob(encryptedDataIndex)
                val thumbnailData = if (!cursor.isNull(thumbnailDataIndex)) {
                    cursor.getBlob(thumbnailDataIndex)
                } else null
                val createdAt = cursor.getLong(createdAtIndex)
                
                // 保存加密数据到文件
                val file = File(attachmentsDir, id)
                file.writeBytes(encryptedData)
                val filePath = "attachments/$id"
                
                // 保存缩略图（如果有）
                val thumbnailPath = thumbnailData?.let { data ->
                    val thumbnailFile = File(thumbnailsDir, id)
                    thumbnailFile.writeBytes(data)
                    "thumbnails/$id"
                }
                
                // 插入到新表
                database.execSQL("""
                    INSERT INTO attachments_new 
                    (id, item_id, file_name, file_type, file_size, display_order, encrypted_file_path, thumbnail_file_path, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """.trimIndent(), arrayOf(
                    id, itemId, fileName, fileType, fileSize, displayOrder, filePath, thumbnailPath, createdAt
                ))
            }
        } finally {
            cursor.close()
        }
    }
}
