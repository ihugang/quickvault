package com.quickvault.data.local.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import com.quickvault.data.local.database.entity.AttachmentEntity
import com.quickvault.data.local.database.entity.ItemEntity
import com.quickvault.data.local.database.entity.TextContentEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface ItemDao {

    @Transaction
    @Query("SELECT * FROM items ORDER BY updated_at DESC")
    fun getAllItems(): Flow<List<ItemWithContents>>

    @Transaction
    @Query("SELECT * FROM items WHERE id = :itemId")
    suspend fun getItem(itemId: String): ItemWithContents?

    @Transaction
    @Query(
        "SELECT * FROM items " +
            "WHERE title LIKE '%' || :query || '%' " +
            "OR tags_json LIKE '%' || :query || '%'" +
            "ORDER BY updated_at DESC"
    )
    fun searchItems(query: String): Flow<List<ItemWithContents>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertItem(item: ItemEntity)

    @Update
    suspend fun updateItem(item: ItemEntity)

    @Query("DELETE FROM items WHERE id = :itemId")
    suspend fun deleteItem(itemId: String)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTextContent(textContent: TextContentEntity)

    @Query("DELETE FROM item_texts WHERE item_id = :itemId")
    suspend fun deleteTextContent(itemId: String)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAttachments(attachments: List<AttachmentEntity>)

    @Query("DELETE FROM attachments WHERE id = :attachmentId")
    suspend fun deleteAttachment(attachmentId: String)

    @Query("DELETE FROM attachments WHERE item_id = :itemId")
    suspend fun deleteAttachmentsByItemId(itemId: String)
    
    @Query("SELECT COUNT(*) FROM items WHERE type = :type")
    suspend fun countItemsByType(type: String): Int
}
