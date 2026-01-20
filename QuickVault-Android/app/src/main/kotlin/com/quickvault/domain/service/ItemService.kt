package com.quickvault.domain.service

import com.quickvault.data.model.FileData
import com.quickvault.data.model.ImageData
import com.quickvault.data.model.ItemDTO

interface ItemService {
    suspend fun createTextItem(title: String, content: String, tags: List<String>): Result<ItemDTO>
    suspend fun createImageItem(title: String, images: List<ImageData>, tags: List<String>): Result<ItemDTO>
    suspend fun createFileItem(title: String, files: List<FileData>, tags: List<String>): Result<ItemDTO>

    fun getAllItems(): kotlinx.coroutines.flow.Flow<List<ItemDTO>>
    suspend fun getItem(id: String): Result<ItemDTO>
    fun searchItems(query: String): kotlinx.coroutines.flow.Flow<List<ItemDTO>>

    suspend fun updateTextItem(id: String, title: String?, content: String?, tags: List<String>?): Result<ItemDTO>
    suspend fun updateImageItem(id: String, title: String?, tags: List<String>?): Result<ItemDTO>
    suspend fun updateFileItem(id: String, title: String?, tags: List<String>?): Result<ItemDTO>
    suspend fun addImages(itemId: String, images: List<ImageData>): Result<Unit>
    suspend fun addFiles(itemId: String, files: List<FileData>): Result<Unit>
    suspend fun removeAttachment(attachmentId: String): Result<Unit>

    suspend fun deleteItem(id: String): Result<Unit>
    suspend fun togglePin(id: String): Result<ItemDTO>

    suspend fun getShareableText(id: String): Result<String>
    suspend fun getShareableImages(id: String): Result<List<ByteArray>>
    suspend fun getShareableFiles(id: String): Result<List<Triple<ByteArray, String, String>>>
    
    suspend fun getImageFullData(imageId: String): Result<ByteArray>
    suspend fun getFileData(fileId: String): Result<ByteArray>
}
