package com.quickvault.presentation.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.quickvault.data.model.FileData
import com.quickvault.data.model.ImageData
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
                    _uiState.update { it.copy(isLoading = false, isEditMode = true) }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoading = false, errorMessage = error.message) }
                }
        }
    }

    private fun applyItem(item: ItemDTO) {
        _title.value = item.title
        _tags.value = item.tags
        _itemType.value = item.type
        _textContent.value = item.textContent ?: ""
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
}

data class ItemEditorUiState(
    val isLoading: Boolean = false,
    val isEditMode: Boolean = false,
    val errorMessage: String? = null
)
