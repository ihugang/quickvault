package com.quickvault.data.local.database.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * 文本内容实体
 * 对应 iOS 的 TextContent
 */
@Entity(
    tableName = "item_texts",
    foreignKeys = [
        ForeignKey(
            entity = ItemEntity::class,
            parentColumns = ["id"],
            childColumns = ["item_id"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["item_id"])]
)
data class TextContentEntity(
    @PrimaryKey
    val id: String,

    @ColumnInfo(name = "item_id")
    val itemId: String,

    @ColumnInfo(name = "encrypted_content", typeAffinity = ColumnInfo.BLOB)
    val encryptedContent: ByteArray,

    @ColumnInfo(name = "created_at")
    val createdAt: Long
)
