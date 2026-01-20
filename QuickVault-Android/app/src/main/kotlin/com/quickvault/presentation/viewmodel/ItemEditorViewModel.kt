package com.quickvault.presentation.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.quickvault.data.model.FileData
import com.quickvault.data.model.FileDTO
import com.quickvault.data.model.ImageData
import com.quickvault.data.model.ImageDTO
import com.quickvault.data.model.ItemDTO
import com.quickvault.data.model.ItemType
import com.quickvault.domain.service.ItemService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ItemEditorViewModel @Inject constructor(
    private val itemService: ItemService,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val itemId: String? = savedStateHandle.get<String>("itemId")
    private val initialType: ItemType? = savedStateHandle.get<String>("itemType")?.let { raw ->
        runCatching { ItemType.valueOf(raw) }.getOrNull()
    }

    private val _uiState = MutableStateFlow(ItemEditorUiState())
    val uiState: StateFlow<ItemEditorUiState> = _uiState.asStateFlow()

    private val _title = MutableStateFlow("")
    val title: StateFlow<String> = _title.asStateFlow()

    private val _tags = MutableStateFlow<List<String>>(emptyList())
    val tags: StateFlow<List<String>> = _tags.asStateFlow()

    private val _itemType = MutableStateFlow(ItemType.TEXT)
    val itemType: StateFlow<ItemType> = _itemType.asStateFlow()

    private val _textContent = MutableStateFlow("")
    val textContent: StateFlow<String> = _textContent.asStateFlow()

    private val _images = MutableStateFlow<List<ImageData>>(emptyList())
    val images: StateFlow<List<ImageData>> = _images.asStateFlow()

    private val _files = MutableStateFlow<List<FileData>>(emptyList())
    val files: StateFlow<List<FileData>> = _files.asStateFlow()

    private val _imageMetadata = MutableStateFlow<List<ImageDTO>>(emptyList())
    val imageMetadata: StateFlow<List<ImageDTO>> = _imageMetadata.asStateFlow()

    private val _fileMetadata = MutableStateFlow<List<FileDTO>>(emptyList())
    val fileMetadata: StateFlow<List<FileDTO>> = _fileMetadata.asStateFlow()

    private val _createdAt = MutableStateFlow(0L)
    val createdAt: StateFlow<Long> = _createdAt.asStateFlow()

    private val _updatedAt = MutableStateFlow(0L)
    val updatedAt: StateFlow<Long> = _updatedAt.asStateFlow()

    private val _isPinned = MutableStateFlow(false)
    val isPinned: StateFlow<Boolean> = _isPinned.asStateFlow()

    init {
        if (itemId == null) {
            initialType?.let { _itemType.value = it }
        } else {
            loadItem(itemId)
        }
    }

    private fun loadItem(id: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            itemService.getItem(id)
                .onSuccess { item ->
                    applyItem(item)
                    _uiState.update { it.copy(isLoading = false, isEditMode = true, itemId = id) }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoading = false, errorMessage = error.message) }
                }
        }
    }
    
    /**
     * 重新加载项目数据
     * 用于从编辑画面返回后刷新详细画面
     */
    fun refresh() {
        itemId?.let { loadItem(it) }
    }

    private fun applyItem(item: ItemDTO) {
        _title.value = item.title
        _tags.value = item.tags
        _itemType.value = item.type
        _textContent.value = item.textContent ?: ""
        _createdAt.value = item.createdAt
        _updatedAt.value = item.updatedAt
        _isPinned.value = item.isPinned
        _imageMetadata.value = item.images ?: emptyList()
        _fileMetadata.value = item.files ?: emptyList()
    }

    fun setTitle(value: String) {
        _title.value = value
    }

    fun setItemType(type: ItemType) {
        if (!uiState.value.isEditMode) {
            _itemType.value = type
        }
    }

    fun setTextContent(value: String) {
        _textContent.value = value
    }

    fun addTag(tag: String) {
        if (tag.isNotBlank() && tag !in _tags.value) {
            _tags.value = _tags.value + tag
        }
    }

    fun removeTag(tag: String) {
        _tags.value = _tags.value - tag
    }

    fun addImages(newImages: List<ImageData>) {
        _images.value = _images.value + newImages
    }

    fun addFiles(newFiles: List<FileData>) {
        _files.value = _files.value + newFiles
    }

    fun removeImage(index: Int) {
        _images.value = _images.value.toMutableList().apply { removeAt(index) }
    }

    fun removeFile(index: Int) {
        _files.value = _files.value.toMutableList().apply { removeAt(index) }
    }
    
    fun removeExistingImage(imageId: String) {
        viewModelScope.launch {
            itemService.removeAttachment(imageId)
                .onSuccess {
                    _imageMetadata.value = _imageMetadata.value.filter { it.id != imageId }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(errorMessage = error.message) }
                }
        }
    }
    
    fun removeExistingFile(fileId: String) {
        viewModelScope.launch {
            itemService.removeAttachment(fileId)
                .onSuccess {
                    _fileMetadata.value = _fileMetadata.value.filter { it.id != fileId }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(errorMessage = error.message) }
                }
        }
    }

    fun setLoading(loading: Boolean) {
        _uiState.update { it.copy(isLoading = loading) }
    }

    fun save(onSuccess: () -> Unit) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }

            val result = if (itemId == null) {
                createNewItem()
            } else {
                updateExistingItem(itemId)
            }

            result.onSuccess {
                _uiState.update { it.copy(isLoading = false) }
                onSuccess()
            }.onFailure { error ->
                _uiState.update { it.copy(isLoading = false, errorMessage = error.message) }
            }
        }
    }

    private suspend fun createNewItem(): Result<Unit> {
        val titleValue = title.value.trim()
        val tagsValue = tags.value
        return when (itemType.value) {
            ItemType.TEXT -> itemService.createTextItem(titleValue, textContent.value, tagsValue).map { }
            ItemType.IMAGE -> itemService.createImageItem(titleValue, images.value, tagsValue).map { }
            ItemType.FILE -> itemService.createFileItem(titleValue, files.value, tagsValue).map { }
        }
    }

    private suspend fun updateExistingItem(id: String): Result<Unit> {
        val titleValue = title.value.trim()
        val tagsValue = tags.value
        val result = when (itemType.value) {
            ItemType.TEXT -> itemService.updateTextItem(id, titleValue, textContent.value, tagsValue)
            ItemType.IMAGE -> itemService.updateImageItem(id, titleValue, tagsValue)
            ItemType.FILE -> itemService.updateFileItem(id, titleValue, tagsValue)
        }
        if (result.isSuccess) {
            when (itemType.value) {
                ItemType.IMAGE -> if (images.value.isNotEmpty()) {
                    itemService.addImages(id, images.value)
                }
                ItemType.FILE -> if (files.value.isNotEmpty()) {
                    itemService.addFiles(id, files.value)
                }
                else -> Unit
            }
        }
        return result.map { }
    }

    fun togglePin() {
        itemId?.let { id ->
            viewModelScope.launch {
                itemService.togglePin(id)
                    .onSuccess {
                        _isPinned.value = !_isPinned.value
                    }
            }
        }
    }

    fun delete(onSuccess: () -> Unit) {
        itemId?.let { id ->
            viewModelScope.launch {
                _uiState.update { it.copy(isLoading = true) }
                itemService.deleteItem(id)
                    .onSuccess {
                        _uiState.update { it.copy(isLoading = false) }
                        onSuccess()
                    }
                    .onFailure { error ->
                        _uiState.update { it.copy(isLoading = false, errorMessage = error.message) }
                    }
            }
        }
    }
    
    suspend fun getImageFullData(imageId: String): ByteArray? {
        return itemService.getImageFullData(imageId).getOrNull()
    }

    suspend fun getFileData(fileId: String): ByteArray? {
        return itemService.getFileData(fileId).getOrNull()
    }
}

data class ItemEditorUiState(
    val isLoading: Boolean = false,
    val isEditMode: Boolean = false,
    val itemId: String? = null,
    val errorMessage: String? = null
)
