package com.quickvault.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.quickvault.data.model.ItemDTO
import com.quickvault.domain.service.ItemService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ItemsViewModel @Inject constructor(
    private val itemService: ItemService
) : ViewModel() {

    private val _uiState = MutableStateFlow(ItemsUiState())
    val uiState: StateFlow<ItemsUiState> = _uiState.asStateFlow()

    private val _selectedTags = MutableStateFlow<Set<String>>(emptySet())
    val selectedTags: StateFlow<Set<String>> = _selectedTags.asStateFlow()
    
    // 获取所有标签
    val allTags: StateFlow<List<String>> = itemService.getAllTags()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val items: StateFlow<List<ItemDTO>> = itemService.getAllItems()
        .combine(_selectedTags) { items, selectedTags ->
            if (selectedTags.isEmpty()) {
                items
            } else {
                items.filter { item ->
                    selectedTags.any { tag ->
                        item.tags.any { itemTag -> itemTag.equals(tag, ignoreCase = true) }
                    }
                }
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val pinnedItems: StateFlow<List<ItemDTO>> = items.map { list ->
        list.filter { it.isPinned }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val unpinnedItems: StateFlow<List<ItemDTO>> = items.map { list ->
        list.filter { !it.isPinned }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun toggleTagFilter(tag: String) {
        val current = _selectedTags.value.toMutableSet()
        if (current.contains(tag)) {
            current.remove(tag)
        } else {
            current.add(tag)
        }
        _selectedTags.value = current
    }
    
    fun clearTagFilters() {
        _selectedTags.value = emptySet()
    }

    fun togglePin(itemId: String) {
        viewModelScope.launch {
            itemService.togglePin(itemId)
        }
    }

    fun deleteItem(itemId: String) {
        viewModelScope.launch {
            itemService.deleteItem(itemId)
        }
    }
}

data class ItemsUiState(
    val isLoading: Boolean = false,
    val errorMessage: String? = null
)
