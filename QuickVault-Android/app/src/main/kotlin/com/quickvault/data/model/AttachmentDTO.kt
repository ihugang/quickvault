package com.quickvault.data.model

/**
 * 附件 DTO（数据传输对象）
 * 对应 iOS 的 Attachment model
 *
 * 用于应用层，包含解密后的数据
 */
data class AttachmentDTO(
    val id: String,
    val cardId: String,
    val fileName: String,
    val fileType: String,
    val fileSize: Long,
    val data: ByteArray, // 解密后的文件数据
    val thumbnail: ByteArray? = null, // 解密后的缩略图数据
    val createdAt: Long
) {
    /**
     * 是否为图片类型
     */
    fun isImage(): Boolean {
        return fileType.startsWith("image/", ignoreCase = true)
    }

    /**
     * 是否为 PDF
     */
    fun isPdf(): Boolean {
        return fileType.equals("application/pdf", ignoreCase = true)
    }

    /**
     * 获取文件大小（可读格式）
     */
    fun getFormattedSize(): String {
        val kb = fileSize / 1024.0
        val mb = kb / 1024.0
        return when {
            mb >= 1.0 -> String.format("%.2f MB", mb)
            kb >= 1.0 -> String.format("%.2f KB", kb)
            else -> "$fileSize B"
        }
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as AttachmentDTO

        if (id != other.id) return false
        if (cardId != other.cardId) return false
        if (fileName != other.fileName) return false
        if (fileType != other.fileType) return false
        if (fileSize != other.fileSize) return false
        if (!data.contentEquals(other.data)) return false
        if (thumbnail != null) {
            if (other.thumbnail == null) return false
            if (!thumbnail.contentEquals(other.thumbnail)) return false
        } else if (other.thumbnail != null) return false
        if (createdAt != other.createdAt) return false

        return true
    }

    override fun hashCode(): Int {
        var result = id.hashCode()
        result = 31 * result + cardId.hashCode()
        result = 31 * result + fileName.hashCode()
        result = 31 * result + fileType.hashCode()
        result = 31 * result + fileSize.hashCode()
        result = 31 * result + data.contentHashCode()
        result = 31 * result + (thumbnail?.contentHashCode() ?: 0)
        result = 31 * result + createdAt.hashCode()
        return result
    }
}
