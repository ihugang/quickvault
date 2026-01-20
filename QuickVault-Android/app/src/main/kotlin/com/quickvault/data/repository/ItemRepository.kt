package com.quickvault.data.repository

import com.quickvault.data.local.database.dao.ItemDao
import com.quickvault.data.local.database.dao.ItemWithContents
import com.quickvault.data.local.database.entity.ItemEntity
import com.quickvault.data.local.database.entity.TextContentEntity
import com.quickvault.data.model.FileDTO
import com.quickvault.data.model.ImageDTO
import com.quickvault.data.model.ItemDTO
import com.quickvault.data.model.ItemType
import com.quickvault.domain.service.CryptoService
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import org.json.JSONArray
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ItemRepository @Inject constructor(
    private val itemDao: ItemDao,
    private val attachmentRepository: AttachmentRepository,
    private val cryptoService: CryptoService
) {

    fun getAllItems(): Flow<List<ItemDTO>> {
        return itemDao.getAllItems().map { items ->
            items.map { mapToDTO(it) }
        }
    }

    fun searchItems(query: String): Flow<List<ItemDTO>> {
        return itemDao.searchItems(query).map { items ->
            items.map { mapToDTO(it) }
        }
    }

    suspend fun getItemById(id: String): ItemDTO? {
        return itemDao.getItem(id)?.let { mapToDTO(it) }
    }

    suspend fun createItem(
        title: String,
        type: ItemType,
        tags: List<String>
    ): ItemDTO {
        val now = System.currentTimeMillis()
        val item = ItemEntity(
            id = UUID.randomUUID().toString(),
            title = title,
            type = type.name.lowercase(),
            tagsJson = tagsToJson(tags),
            isPinned = false,
            createdAt = now,
            updatedAt = now
        )
        itemDao.insertItem(item)
        return mapToDTO(ItemWithContents(item, emptyList(), emptyList()))
    }

    suspend fun updateItem(
        id: String,
        title: String?,
        tags: List<String>?,
        updatedAt: Long = System.currentTimeMillis()
    ): ItemDTO? {
        val existing = itemDao.getItem(id) ?: return null
        val item = existing.item.copy(
            title = title ?: existing.item.title,
            tagsJson = tags?.let { tagsToJson(it) } ?: existing.item.tagsJson,
            updatedAt = updatedAt
        )
        itemDao.updateItem(item)
        return mapToDTO(existing.copy(item = item))
    }

    suspend fun deleteItem(id: String) {
        itemDao.deleteItem(id)
    }

    suspend fun togglePin(id: String): ItemDTO? {
        val existing = itemDao.getItem(id) ?: return null
        val updated = existing.item.copy(isPinned = !existing.item.isPinned)
        itemDao.updateItem(updated)
        return mapToDTO(existing.copy(item = updated))
    }

    suspend fun setTextContent(itemId: String, content: String) {
        val encrypted = cryptoService.encrypt(content)
        val textEntity = TextContentEntity(
            id = UUID.randomUUID().toString(),
            itemId = itemId,
            encryptedContent = encrypted,
            createdAt = System.currentTimeMillis()
        )
        itemDao.deleteTextContent(itemId)
        itemDao.insertTextContent(textEntity)
    }

    suspend fun addAttachment(
        itemId: String,
        data: ByteArray,
        fileName: String,
        mimeType: String,
        displayOrder: Int,
        addWatermark: Boolean
    ) {
        attachmentRepository.addAttachment(
            itemId = itemId,
            data = data,
            fileName = fileName,
            fileType = mimeType,
            addWatermark = addWatermark,
            displayOrder = displayOrder
        )
    }

    suspend fun deleteAttachment(attachmentId: String) {
        attachmentRepository.deleteAttachment(attachmentId)
    }

    suspend fun deleteAttachmentsByItemId(itemId: String) {
        attachmentRepository.deleteAttachmentsByItemId(itemId)
    }

    private suspend fun mapToDTO(itemWithContents: ItemWithContents): ItemDTO {
        val item = itemWithContents.item
        val textContent = itemWithContents.textContents.firstOrNull()
            ?.let { cryptoService.decrypt(it.encryptedContent) }
        val attachments = itemWithContents.attachments.sortedBy { it.displayOrder }
        val images = attachments
            .filter { it.fileType.startsWith("image/") }
            .map {
                ImageDTO(
                    id = it.id,
                    fileName = it.fileName,
                    fileSize = it.fileSize,
                    displayOrder = it.displayOrder,
                    thumbnailData = it.thumbnailData?.let { data -> cryptoService.decryptFile(data) }
                )
            }
        val files = attachments
            .filterNot { it.fileType.startsWith("image/") }
            .map {
                FileDTO(
                    id = it.id,
                    fileName = it.fileName,
                    fileSize = it.fileSize,
                    mimeType = it.fileType,
                    displayOrder = it.displayOrder,
                    thumbnailData = it.thumbnailData?.let { data -> cryptoService.decryptFile(data) }
                )
            }
        return ItemDTO(
            id = item.id,
            title = item.title,
            type = when (item.type) {
                "text" -> ItemType.TEXT
                "image" -> ItemType.IMAGE
                "file" -> ItemType.FILE
                else -> ItemType.TEXT
            },
            tags = jsonToTags(item.tagsJson),
            isPinned = item.isPinned,
            createdAt = item.createdAt,
            updatedAt = item.updatedAt,
            textContent = textContent,
            images = if (images.isEmpty()) null else images,
            files = if (files.isEmpty()) null else files
        )
    }

    private fun tagsToJson(tags: List<String>): String {
        val array = JSONArray()
        tags.forEach { array.put(it) }
        return array.toString()
    }

    private fun jsonToTags(json: String): List<String> {
        return runCatching {
            val array = JSONArray(json)
            List(array.length()) { index -> array.getString(index) }
        }.getOrDefault(emptyList())
    }
}
