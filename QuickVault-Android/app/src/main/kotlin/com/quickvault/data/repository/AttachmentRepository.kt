package com.quickvault.data.repository

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.quickvault.data.local.database.dao.AttachmentDao
import com.quickvault.data.local.database.entity.AttachmentEntity
import com.quickvault.data.model.AttachmentDTO
import com.quickvault.domain.service.CryptoService
import com.quickvault.domain.service.WatermarkService
import com.quickvault.domain.service.WatermarkStyle
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.io.ByteArrayOutputStream
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 附件数据仓库
 * 负责附件的加密存储和解密读取
 * 对应 iOS 的 AttachmentRepository
 */
@Singleton
class AttachmentRepository @Inject constructor(
    private val attachmentDao: AttachmentDao,
    private val cryptoService: CryptoService,
    private val watermarkService: WatermarkService
) {

    companion object {
        private const val THUMBNAIL_MAX_WIDTH = 200
        private const val THUMBNAIL_MAX_HEIGHT = 200
        private const val THUMBNAIL_QUALITY = 80
    }

    /**
     * 获取项目的所有附件（解密后）
     * 对应 iOS 的 fetchAttachments(for itemId:)
     */
    fun getAttachmentsByItemId(itemId: String): Flow<List<AttachmentDTO>> {
        return attachmentDao.getAttachmentsByItemId(itemId)
            .map { entities ->
                entities.map { it.toDTO() }
            }
    }

    /**
     * 根据 ID 获取附件（解密后）
     */
    suspend fun getAttachmentById(attachmentId: String): AttachmentDTO? {
        return attachmentDao.getAttachmentById(attachmentId)?.toDTO()
    }

    /**
     * 添加附件
     * 对应 iOS 的 addAttachment(to cardId:, data:, fileName:, fileType:)
     *
     * @param itemId 项目 ID
     * @param data 文件原始数据
     * @param fileName 文件名
     * @param fileType MIME 类型
     * @param addWatermark 是否添加水印（仅图片）
     */
    suspend fun addAttachment(
        itemId: String,
        data: ByteArray,
        fileName: String,
        fileType: String,
        addWatermark: Boolean = true,
        displayOrder: Int = 0
    ): AttachmentDTO {
        val now = System.currentTimeMillis()

        // 1. 处理图片水印（如果是图片且需要水印）
        val processedData = if (fileType.startsWith("image/") && addWatermark) {
            addWatermarkToImage(data)
        } else {
            data
        }

        // 2. 加密文件数据
        val encryptedData = cryptoService.encryptFile(processedData)

        // 3. 生成缩略图（仅图片）
        val encryptedThumbnail = if (fileType.startsWith("image/")) {
            val thumbnailData = generateThumbnail(processedData)
            cryptoService.encryptFile(thumbnailData)
        } else {
            null
        }

        // 4. 创建实体并保存
        val entity = AttachmentEntity(
            id = UUID.randomUUID().toString(),
            itemId = itemId,
            fileName = fileName,
            fileType = fileType,
            fileSize = data.size.toLong(),
            displayOrder = displayOrder,
            encryptedData = encryptedData,
            thumbnailData = encryptedThumbnail,
            createdAt = now
        )

        attachmentDao.insertAttachment(entity)

        // 5. 返回 DTO
        return AttachmentDTO(
            id = entity.id,
            itemId = itemId,
            fileName = fileName,
            fileType = fileType,
            fileSize = data.size.toLong(),
            displayOrder = displayOrder,
            data = processedData,
            thumbnail = encryptedThumbnail?.let { cryptoService.decryptFile(it) },
            createdAt = now
        )
    }

    /**
     * 删除附件
     * 对应 iOS 的 deleteAttachment(id:)
     */
    suspend fun deleteAttachment(attachmentId: String) {
        attachmentDao.deleteAttachment(attachmentId)
    }

    /**
     * 删除项目的所有附件
     */
    suspend fun deleteAttachmentsByItemId(itemId: String) {
        attachmentDao.deleteAttachmentsByItemId(itemId)
    }

    /**
     * 获取附件数量
     */
    suspend fun getAttachmentCount(itemId: String): Int {
        return attachmentDao.getAttachmentCount(itemId)
    }

    /**
     * 获取附件总大小
     */
    suspend fun getTotalAttachmentSize(itemId: String): Long {
        return attachmentDao.getTotalAttachmentSize(itemId) ?: 0L
    }

    /**
     * 将 Entity 转换为 DTO（解密）
     */
    private suspend fun AttachmentEntity.toDTO(): AttachmentDTO {
        // 解密文件数据
        val decryptedData = cryptoService.decryptFile(encryptedData)

        // 解密缩略图（如果有）
        val decryptedThumbnail = thumbnailData?.let {
            cryptoService.decryptFile(it)
        }

        return AttachmentDTO(
            id = id,
            itemId = itemId,
            fileName = fileName,
            fileType = fileType,
            fileSize = fileSize,
            displayOrder = displayOrder,
            data = decryptedData,
            thumbnail = decryptedThumbnail,
            createdAt = createdAt
        )
    }

    /**
     * 为图片添加水印
     * 对应 iOS 的 WatermarkService.applyWatermark()
     */
    private fun addWatermarkToImage(imageData: ByteArray, watermarkText: String = "QuickVault"): ByteArray {
        val bitmap = BitmapFactory.decodeByteArray(imageData, 0, imageData.size)
        val watermarkedBitmap = watermarkService.applyWatermark(
            bitmap = bitmap,
            text = watermarkText,
            style = WatermarkStyle()
        )

        val outputStream = ByteArrayOutputStream()
        watermarkedBitmap.compress(Bitmap.CompressFormat.JPEG, 90, outputStream)
        return outputStream.toByteArray()
    }

    /**
     * 生成缩略图
     * 对应 iOS 的缩略图生成逻辑
     */
    private fun generateThumbnail(imageData: ByteArray): ByteArray {
        val options = BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }
        BitmapFactory.decodeByteArray(imageData, 0, imageData.size, options)

        // 计算缩放比例
        val scale = calculateThumbnailScale(
            options.outWidth,
            options.outHeight,
            THUMBNAIL_MAX_WIDTH,
            THUMBNAIL_MAX_HEIGHT
        )

        // 解码并缩放
        options.inJustDecodeBounds = false
        options.inSampleSize = scale

        val bitmap = BitmapFactory.decodeByteArray(imageData, 0, imageData.size, options)
        val scaledBitmap = Bitmap.createScaledBitmap(
            bitmap,
            minOf(bitmap.width, THUMBNAIL_MAX_WIDTH),
            minOf(bitmap.height, THUMBNAIL_MAX_HEIGHT),
            true
        )

        val outputStream = ByteArrayOutputStream()
        scaledBitmap.compress(Bitmap.CompressFormat.JPEG, THUMBNAIL_QUALITY, outputStream)

        bitmap.recycle()
        if (scaledBitmap != bitmap) {
            scaledBitmap.recycle()
        }

        return outputStream.toByteArray()
    }

    /**
     * 计算缩略图缩放比例
     */
    private fun calculateThumbnailScale(
        width: Int,
        height: Int,
        maxWidth: Int,
        maxHeight: Int
    ): Int {
        var scale = 1
        if (width > maxWidth || height > maxHeight) {
            val widthScale = width / maxWidth
            val heightScale = height / maxHeight
            scale = maxOf(widthScale, heightScale)
        }
        return scale
    }
}
