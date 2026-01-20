package com.quickvault.domain.service.impl

import android.content.Context
import com.quickvault.R
import com.quickvault.data.model.FileData
import com.quickvault.data.model.ImageData
import com.quickvault.data.model.ItemDTO
import com.quickvault.data.model.ItemType
import com.quickvault.data.repository.ItemRepository
import com.quickvault.domain.service.ItemService
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ItemServiceImpl @Inject constructor(
    private val itemRepository: ItemRepository,
    @ApplicationContext private val context: Context
) : ItemService {

    override suspend fun createTextItem(
        title: String,
        content: String,
        tags: List<String>
    ): Result<ItemDTO> {
        return try {
            val item = itemRepository.createItem(title, ItemType.TEXT, tags)
            itemRepository.setTextContent(item.id, content)
            Result.success(itemRepository.getItemById(item.id) ?: item)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun createImageItem(
        title: String,
        images: List<ImageData>,
        tags: List<String>
    ): Result<ItemDTO> {
        return try {
            val item = itemRepository.createItem(title, ItemType.IMAGE, tags)
            images.forEachIndexed { index, image ->
                itemRepository.addAttachment(
                    itemId = item.id,
                    data = image.data,
                    fileName = image.fileName,
                    mimeType = "image/*",
                    displayOrder = index,
                    addWatermark = false
                )
            }
            Result.success(itemRepository.getItemById(item.id) ?: item)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun createFileItem(
        title: String,
        files: List<FileData>,
        tags: List<String>
    ): Result<ItemDTO> {
        return try {
            val item = itemRepository.createItem(title, ItemType.FILE, tags)
            files.forEachIndexed { index, file ->
                itemRepository.addAttachment(
                    itemId = item.id,
                    data = file.data,
                    fileName = file.fileName,
                    mimeType = file.mimeType,
                    displayOrder = index,
                    addWatermark = false
                )
            }
            Result.success(itemRepository.getItemById(item.id) ?: item)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override fun getAllItems(): Flow<List<ItemDTO>> {
        return itemRepository.getAllItems()
    }

    override suspend fun getItem(id: String): Result<ItemDTO> {
        return itemRepository.getItemById(id)?.let { Result.success(it) }
            ?: Result.failure(IllegalArgumentException(context.getString(R.string.items_error_not_found)))
    }

    override fun searchItems(query: String): Flow<List<ItemDTO>> {
        return itemRepository.searchItems(query)
    }

    override suspend fun updateTextItem(
        id: String,
        title: String?,
        content: String?,
        tags: List<String>?
    ): Result<ItemDTO> {
        return try {
            content?.let { itemRepository.setTextContent(id, it) }
            val updated = itemRepository.updateItem(id, title, tags) ?: return Result.failure(
                IllegalArgumentException(context.getString(R.string.items_error_not_found))
            )
            Result.success(updated)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun updateImageItem(id: String, title: String?, tags: List<String>?): Result<ItemDTO> {
        return try {
            val updated = itemRepository.updateItem(id, title, tags) ?: return Result.failure(
                IllegalArgumentException(context.getString(R.string.items_error_not_found))
            )
            Result.success(updated)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun updateFileItem(id: String, title: String?, tags: List<String>?): Result<ItemDTO> {
        return try {
            val updated = itemRepository.updateItem(id, title, tags) ?: return Result.failure(
                IllegalArgumentException(context.getString(R.string.items_error_not_found))
            )
            Result.success(updated)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun addImages(itemId: String, images: List<ImageData>): Result<Unit> {
        return try {
            val existing = itemRepository.getItemById(itemId) ?: return Result.failure(
                IllegalArgumentException(context.getString(R.string.items_error_not_found))
            )
            val startIndex = existing.images?.size ?: 0
            images.forEachIndexed { index, image ->
                itemRepository.addAttachment(
                    itemId = itemId,
                    data = image.data,
                    fileName = image.fileName,
                    mimeType = "image/*",
                    displayOrder = startIndex + index,
                    addWatermark = false
                )
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun addFiles(itemId: String, files: List<FileData>): Result<Unit> {
        return try {
            val existing = itemRepository.getItemById(itemId) ?: return Result.failure(
                IllegalArgumentException(context.getString(R.string.items_error_not_found))
            )
            val startIndex = existing.files?.size ?: 0
            files.forEachIndexed { index, file ->
                itemRepository.addAttachment(
                    itemId = itemId,
                    data = file.data,
                    fileName = file.fileName,
                    mimeType = file.mimeType,
                    displayOrder = startIndex + index,
                    addWatermark = false
                )
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun removeAttachment(attachmentId: String): Result<Unit> {
        return try {
            itemRepository.deleteAttachment(attachmentId)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun deleteItem(id: String): Result<Unit> {
        return try {
            itemRepository.deleteItem(id)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun togglePin(id: String): Result<ItemDTO> {
        return itemRepository.togglePin(id)?.let { Result.success(it) }
            ?: Result.failure(IllegalArgumentException(context.getString(R.string.items_error_not_found)))
    }

    override suspend fun getShareableText(id: String): Result<String> {
        val item = itemRepository.getItemById(id)
            ?: return Result.failure(IllegalArgumentException(context.getString(R.string.items_error_not_found)))
        return Result.success(item.textContent ?: "")
    }

    override suspend fun getShareableImages(id: String): Result<List<ByteArray>> {
        val item = itemRepository.getItemById(id)
            ?: return Result.failure(IllegalArgumentException(context.getString(R.string.items_error_not_found)))
        val images = item.images?.mapNotNull { it.thumbnailData } ?: emptyList()
        return Result.success(images)
    }

    override suspend fun getShareableFiles(id: String): Result<List<Triple<ByteArray, String, String>>> {
        val item = itemRepository.getItemById(id)
            ?: return Result.failure(IllegalArgumentException(context.getString(R.string.items_error_not_found)))
        val files = item.files?.map {
            Triple(it.thumbnailData ?: ByteArray(0), it.fileName, it.mimeType)
        } ?: emptyList()
        return Result.success(files)
    }
}
