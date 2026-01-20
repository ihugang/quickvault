package com.quickvault.data.model

/**
 * 项目数据传输对象
 * 对应 iOS 的 ItemDTO
 */
data class ItemDTO(
    val id: String,
    val title: String,
    val type: ItemType,
    val tags: List<String>,
    val isPinned: Boolean,
    val createdAt: Long,
    val updatedAt: Long,
    val textContent: String?,
    val images: List<ImageDTO>?,
    val files: List<FileDTO>?
)

enum class ItemType {
    TEXT,
    IMAGE,
    FILE
}

data class ImageDTO(
    val id: String,
    val fileName: String,
    val fileSize: Long,
    val displayOrder: Int,
    val thumbnailData: ByteArray?
)

data class FileDTO(
    val id: String,
    val fileName: String,
    val fileSize: Long,
    val mimeType: String,
    val displayOrder: Int,
    val thumbnailData: ByteArray?
)

data class ImageData(
    val data: ByteArray,
    val fileName: String
)

data class FileData(
    val data: ByteArray,
    val fileName: String,
    val mimeType: String
)
