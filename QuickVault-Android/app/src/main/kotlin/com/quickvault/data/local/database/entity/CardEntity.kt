package com.quickvault.data.local.database.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.UUID

/**
 * 卡片实体
 * 对应 iOS 的 Card (CoreData Entity)
 */
@Entity(
    tableName = "cards",
    indices = [
        Index(value = ["title"]),
        Index(value = ["group"]),
        Index(value = ["is_pinned"])
    ]
)
data class CardEntity(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),

    @ColumnInfo(name = "title")
    val title: String,

    @ColumnInfo(name = "card_type")
    val cardType: String,  // "Address" / "Invoice" / "GeneralText"

    @ColumnInfo(name = "group")
    val group: String,  // "Personal" / "Company"

    @ColumnInfo(name = "is_pinned")
    val isPinned: Boolean = false,

    @ColumnInfo(name = "tags_json")
    val tagsJson: String = "[]",  // JSON 数组

    @ColumnInfo(name = "created_at")
    val createdAt: Long = System.currentTimeMillis(),

    @ColumnInfo(name = "updated_at")
    val updatedAt: Long = System.currentTimeMillis()
)

/**
 * 卡片字段实体
 * 对应 iOS 的 CardField (CoreData Entity)
 */
@Entity(
    tableName = "card_fields",
    foreignKeys = [
        androidx.room.ForeignKey(
            entity = CardEntity::class,
            parentColumns = ["id"],
            childColumns = ["card_id"],
            onDelete = androidx.room.ForeignKey.CASCADE
        )
    ],
    indices = [Index("card_id")]
)
data class CardFieldEntity(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),

    @ColumnInfo(name = "card_id")
    val cardId: String,

    @ColumnInfo(name = "label")
    val label: String,  // "收件人" / "手机号" 等

    @ColumnInfo(name = "encrypted_value")
    val encryptedValue: ByteArray,  // 加密后的字段值

    @ColumnInfo(name = "is_required")
    val isRequired: Boolean = true,

    @ColumnInfo(name = "display_order")
    val displayOrder: Int
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as CardFieldEntity

        if (id != other.id) return false
        if (!encryptedValue.contentEquals(other.encryptedValue)) return false

        return true
    }

    override fun hashCode(): Int {
        var result = id.hashCode()
        result = 31 * result + encryptedValue.contentHashCode()
        return result
    }
}
