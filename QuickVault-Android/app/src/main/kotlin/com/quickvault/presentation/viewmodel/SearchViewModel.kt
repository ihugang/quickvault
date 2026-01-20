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
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SearchViewModel @Inject constructor(
    private val itemService: ItemService
) : ViewModel() {

    private val _uiState = MutableStateFlow(SearchUiState())
    val uiState: StateFlow<SearchUiState> = _uiState.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    val searchResults: StateFlow<List<ItemDTO>> = itemService.getAllItems()
        .combine(_searchQuery) { items, query ->
            if (query.isBlank()) {
                emptyList()
            } else {
                items.filter {
                    it.title.contains(query, ignoreCase = true) ||
                        it.tags.any { tag -> tag.contains(query, ignoreCase = true) }
                }
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun setSearchQuery(query: String) {
        _searchQuery.value = query
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

data class SearchUiState(
    val isLoading: Boolean = false,
    val errorMessage: String? = null
)