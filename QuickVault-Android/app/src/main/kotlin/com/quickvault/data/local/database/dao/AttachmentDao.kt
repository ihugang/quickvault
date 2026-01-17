package com.quickvault.data.local.database.dao

import androidx.room.*
import com.quickvault.data.local.database.entity.AttachmentEntity
import kotlinx.coroutines.flow.Flow

/**
 * 附件 DAO
 * 对应 iOS 的 CoreData fetch/save 操作
 */
@Dao
interface AttachmentDao {

    /**
     * 获取卡片的所有附件
     * 对应 iOS 的 fetchAttachments(for cardId:)
     */
    @Query("SELECT * FROM attachments WHERE card_id = :cardId ORDER BY created_at DESC")
    fun getAttachmentsByCardId(cardId: String): Flow<List<AttachmentEntity>>

    /**
     * 根据 ID 获取附件
     */
    @Query("SELECT * FROM attachments WHERE id = :attachmentId")
    suspend fun getAttachmentById(attachmentId: String): AttachmentEntity?

    /**
     * 插入附件
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAttachment(attachment: AttachmentEntity): Long

    /**
     * 删除附件
     */
    @Query("DELETE FROM attachments WHERE id = :attachmentId")
    suspend fun deleteAttachment(attachmentId: String)

    /**
     * 删除卡片的所有附件
     * （通常由 ForeignKey CASCADE 自动处理，此方法用于手动清理）
     */
    @Query("DELETE FROM attachments WHERE card_id = :cardId")
    suspend fun deleteAttachmentsByCardId(cardId: String)

    /**
     * 获取附件数量
     */
    @Query("SELECT COUNT(*) FROM attachments WHERE card_id = :cardId")
    suspend fun getAttachmentCount(cardId: String): Int

    /**
     * 获取卡片所有附件的总大小
     */
    @Query("SELECT SUM(file_size) FROM attachments WHERE card_id = :cardId")
    suspend fun getTotalAttachmentSize(cardId: String): Long?
}
