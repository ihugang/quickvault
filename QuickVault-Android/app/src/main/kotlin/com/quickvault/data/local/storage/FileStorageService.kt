package com.quickvault.data.local.storage

import android.content.Context
import java.io.File
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 文件存储服务
 * 负责管理加密文件的文件系统存储
 */
@Singleton
class FileStorageService @Inject constructor(
    private val context: Context
) {
    companion object {
        private const val ATTACHMENTS_DIR = "attachments"
        private const val THUMBNAILS_DIR = "thumbnails"
    }

    private val attachmentsDir: File by lazy {
        File(context.filesDir, ATTACHMENTS_DIR).apply {
            if (!exists()) mkdirs()
        }
    }

    private val thumbnailsDir: File by lazy {
        File(context.filesDir, THUMBNAILS_DIR).apply {
            if (!exists()) mkdirs()
        }
    }

    /**
     * 保存加密的附件数据到文件系统
     * @param id 附件ID（用作文件名）
     * @param encryptedData 加密后的数据
     * @return 文件相对路径
     */
    fun saveAttachment(id: String, encryptedData: ByteArray): Result<String> {
        return try {
            val file = File(attachmentsDir, id)
            file.writeBytes(encryptedData)
            Result.success("$ATTACHMENTS_DIR/$id")
        } catch (e: IOException) {
            Result.failure(e)
        }
    }

    /**
     * 保存加密的缩略图数据到文件系统
     * @param id 附件ID（用作文件名）
     * @param encryptedThumbnail 加密后的缩略图数据
     * @return 文件相对路径
     */
    fun saveThumbnail(id: String, encryptedThumbnail: ByteArray): Result<String> {
        return try {
            val file = File(thumbnailsDir, id)
            file.writeBytes(encryptedThumbnail)
            Result.success("$THUMBNAILS_DIR/$id")
        } catch (e: IOException) {
            Result.failure(e)
        }
    }

    /**
     * 读取加密的附件数据
     * @param relativePath 文件相对路径
     * @return 加密的数据
     */
    fun readAttachment(relativePath: String): Result<ByteArray> {
        return try {
            val file = File(context.filesDir, relativePath)
            if (!file.exists()) {
                return Result.failure(IOException("文件不存在: $relativePath"))
            }
            Result.success(file.readBytes())
        } catch (e: IOException) {
            Result.failure(e)
        }
    }

    /**
     * 读取加密的缩略图数据
     * @param relativePath 文件相对路径
     * @return 加密的缩略图数据
     */
    fun readThumbnail(relativePath: String): Result<ByteArray> {
        return try {
            val file = File(context.filesDir, relativePath)
            if (!file.exists()) {
                return Result.failure(IOException("缩略图不存在: $relativePath"))
            }
            Result.success(file.readBytes())
        } catch (e: IOException) {
            Result.failure(e)
        }
    }

    /**
     * 删除附件文件
     * @param relativePath 文件相对路径
     */
    fun deleteAttachment(relativePath: String): Result<Unit> {
        return try {
            val file = File(context.filesDir, relativePath)
            if (file.exists()) {
                file.delete()
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * 删除缩略图文件
     * @param relativePath 文件相对路径
     */
    fun deleteThumbnail(relativePath: String?): Result<Unit> {
        if (relativePath == null) return Result.success(Unit)
        return try {
            val file = File(context.filesDir, relativePath)
            if (file.exists()) {
                file.delete()
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * 获取附件文件的绝对路径
     * @param relativePath 文件相对路径
     * @return 绝对路径
     */
    fun getAbsolutePath(relativePath: String): String {
        return File(context.filesDir, relativePath).absolutePath
    }

    /**
     * 检查文件是否存在
     * @param relativePath 文件相对路径
     */
    fun exists(relativePath: String): Boolean {
        return File(context.filesDir, relativePath).exists()
    }

    /**
     * 获取文件大小
     * @param relativePath 文件相对路径
     */
    fun getFileSize(relativePath: String): Long {
        val file = File(context.filesDir, relativePath)
        return if (file.exists()) file.length() else 0
    }

    /**
     * 清理所有附件文件（用于测试或重置）
     */
    fun clearAll(): Result<Unit> {
        return try {
            attachmentsDir.deleteRecursively()
            thumbnailsDir.deleteRecursively()
            attachmentsDir.mkdirs()
            thumbnailsDir.mkdirs()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
