package com.quickvault.data.local.database.dao

import androidx.room.*
import com.quickvault.data.local.database.entity.CardEntity
import com.quickvault.data.local.database.entity.CardFieldEntity
import com.quickvault.data.local.database.entity.AttachmentEntity
import kotlinx.coroutines.flow.Flow

/**
 * 卡片 DAO
 * 对应 iOS 的 CoreData NSManagedObjectContext 操作
 */
@Dao
interface CardDao {

    @Transaction
    @Query("SELECT * FROM cards ORDER BY is_pinned DESC, updated_at DESC")
    fun getAllCardsWithFields(): Flow<List<CardWithFields>>

    @Transaction
    @Query("SELECT * FROM cards WHERE id = :cardId")
    suspend fun getCardWithFields(cardId: String): CardWithFields?

    @Query("SELECT * FROM cards WHERE title LIKE '%' || :query || '%' ORDER BY is_pinned DESC, updated_at DESC")
    fun searchCards(query: String): Flow<List<CardEntity>>

    @Query("SELECT * FROM cards WHERE `group` = :group ORDER BY is_pinned DESC, updated_at DESC")
    fun getCardsByGroup(group: String): Flow<List<CardEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCard(card: CardEntity): Long

    @Update
    suspend fun updateCard(card: CardEntity)

    @Query("DELETE FROM cards WHERE id = :cardId")
    suspend fun deleteCard(cardId: String)

    @Query("UPDATE cards SET is_pinned = :isPinned, updated_at = :updatedAt WHERE id = :cardId")
    suspend fun updatePinStatus(cardId: String, isPinned: Boolean, updatedAt: Long)
}

/**
 * 卡片字段 DAO
 */
@Dao
interface CardFieldDao {

    @Query("SELECT * FROM card_fields WHERE card_id = :cardId ORDER BY display_order ASC")
    suspend fun getFieldsByCardId(cardId: String): List<CardFieldEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertField(field: CardFieldEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFields(fields: List<CardFieldEntity>)

    @Query("DELETE FROM card_fields WHERE card_id = :cardId")
    suspend fun deleteFieldsByCardId(cardId: String)

    @Delete
    suspend fun deleteField(field: CardFieldEntity)
}

/**
 * 附件 DAO
 */
@Dao
interface AttachmentDao {

    @Query("SELECT * FROM attachments WHERE card_id = :cardId ORDER BY created_at DESC")
    suspend fun getAttachmentsByCardId(cardId: String): List<AttachmentEntity>

    @Query("SELECT * FROM attachments WHERE id = :attachmentId")
    suspend fun getAttachmentById(attachmentId: String): AttachmentEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAttachment(attachment: AttachmentEntity)

    @Query("DELETE FROM attachments WHERE id = :attachmentId")
    suspend fun deleteAttachment(attachmentId: String)

    @Update
    suspend fun updateAttachment(attachment: AttachmentEntity)
}

/**
 * 卡片与字段的一对多关系
 * 对应 iOS CoreData 的 Relationship
 */
data class CardWithFields(
    @Embedded val card: CardEntity,

    @Relation(
        parentColumn = "id",
        entityColumn = "card_id"
    )
    val fields: List<CardFieldEntity>,

    @Relation(
        parentColumn = "id",
        entityColumn = "card_id"
    )
    val attachments: List<AttachmentEntity>
)
