package com.quickvault.data.local.database.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * 项目实体
 * 对应 iOS 的 Item
 */
@Entity(
    tableName = "items",
    indices = [
        Index(value = ["title"]),
        Index(value = ["type"]),
        Index(value = ["is_pinned"])
    ]
)
data class ItemEntity(
    @PrimaryKey
    val id: String,

    @ColumnInfo(name = "title")
    val title: String,

    @ColumnInfo(name = "type")
    val type: String,

    @ColumnInfo(name = "tags_json")
    val tagsJson: String = "[]",

    @ColumnInfo(name = "is_pinned")
    val isPinned: Boolean = false,

    @ColumnInfo(name = "created_at")
    val createdAt: Long,

    @ColumnInfo(name = "updated_at")
    val updatedAt: Long
)
