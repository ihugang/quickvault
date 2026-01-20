package com.quickvault.data.local.database.entity

import androidx.room.*

/**
 * 附件实体
 * 对应 iOS 的 CardAttachment (CoreData)
 *
 * 字段说明：
 * - id: 附件唯一标识
 * - itemId: 所属项目 ID（外键）
 * - fileName: 原始文件名
 * - fileType: 文件 MIME 类型（image/jpeg, application/pdf 等）
 * - fileSize: 文件大小（字节）
 * - encryptedData: 加密后的文件数据
 * - thumbnailData: 加密后的缩略图数据（仅图片）
 * - createdAt: 创建时间戳
 */
@Entity(
    tableName = "attachments",
    foreignKeys = [
        ForeignKey(
            entity = ItemEntity::class,
            parentColumns = ["id"],
            childColumns = ["item_id"],
            onDelete = ForeignKey.CASCADE // 项目删除时级联删除附件
        )
    ],
    indices = [Index(value = ["item_id"])]
)
data class AttachmentEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,

    @ColumnInfo(name = "item_id")
    val itemId: String,

    @ColumnInfo(name = "file_name")
    val fileName: String,

    @ColumnInfo(name = "file_type")
    val fileType: String,

    @ColumnInfo(name = "file_size")
    val fileSize: Long,

    @ColumnInfo(name = "display_order")
    val displayOrder: Int,

    @ColumnInfo(name = "encrypted_data", typeAffinity = ColumnInfo.BLOB)
    val encryptedData: ByteArray,

    @ColumnInfo(name = "thumbnail_data", typeAffinity = ColumnInfo.BLOB)
    val thumbnailData: ByteArray? = null,

    @ColumnInfo(name = "created_at")
    val createdAt: Long
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as AttachmentEntity

        if (id != other.id) return false
        if (itemId != other.itemId) return false
        if (fileName != other.fileName) return false
        if (fileType != other.fileType) return false
        if (fileSize != other.fileSize) return false
        if (displayOrder != other.displayOrder) return false
        if (!encryptedData.contentEquals(other.encryptedData)) return false
        if (thumbnailData != null) {
            if (other.thumbnailData == null) return false
            if (!thumbnailData.contentEquals(other.thumbnailData)) return false
        } else if (other.thumbnailData != null) return false
        if (createdAt != other.createdAt) return false

        return true
    }

    override fun hashCode(): Int {
        var result = id.hashCode()
        result = 31 * result + itemId.hashCode()
        result = 31 * result + fileName.hashCode()
        result = 31 * result + fileType.hashCode()
        result = 31 * result + fileSize.hashCode()
        result = 31 * result + displayOrder
        result = 31 * result + encryptedData.contentHashCode()
        result = 31 * result + (thumbnailData?.contentHashCode() ?: 0)
        result = 31 * result + createdAt.hashCode()
        return result
    }
}
