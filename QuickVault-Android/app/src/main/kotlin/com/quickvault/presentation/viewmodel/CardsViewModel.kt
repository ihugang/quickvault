package com.quickvault.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import android.content.Context
import com.quickvault.data.model.CardDTO
import com.quickvault.domain.service.CardService
import com.quickvault.R
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 卡片列表 ViewModel
 * 对应 iOS 的 CardsViewModel
 *
 * 职责：
 * - 管理卡片列表状态
 * - 处理搜索功能
 * - 处理分组过滤
 * - 管理置顶操作
 */
@HiltViewModel
class CardsViewModel @Inject constructor(
    private val cardService: CardService,
    @ApplicationContext private val context: Context
) : ViewModel() {

    // UI 状态
    private val _uiState = MutableStateFlow(CardsUiState())
    val uiState: StateFlow<CardsUiState> = _uiState.asStateFlow()

    // 搜索查询
    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    // 当前选中的分组
    private val _selectedGroup = MutableStateFlow<String?>(null)
    val selectedGroup: StateFlow<String?> = _selectedGroup.asStateFlow()

    // 卡片列表流（响应式）
    val cards: StateFlow<List<CardDTO>> = combine(
        _searchQuery,
        _selectedGroup
    ) { query, group ->
        Pair(query, group)
    }.flatMapLatest { (query, group) ->
        when {
            query.isNotBlank() -> cardService.searchCards(query)
            group != null -> cardService.getCardsByGroup(group)
            else -> cardService.getAllCards()
        }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )

    /**
     * 设置搜索查询
     */
    fun setSearchQuery(query: String) {
        _searchQuery.value = query
    }

    /**
     * 设置选中的分组
     */
    fun setSelectedGroup(group: String?) {
        _selectedGroup.value = group
    }

    /**
     * 切换卡片置顶状态
     */
    fun togglePin(cardId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }

            cardService.togglePin(cardId)
                .onSuccess {
                    _uiState.update { state ->
                        state.copy(isLoading = false)
                    }
                }
                .onFailure { error ->
                    _uiState.update { state ->
                        state.copy(
                            isLoading = false,
                            errorMessage = error.message ?: context.getString(R.string.cards_error_toggle_pin)
                        )
                    }
                }
        }
    }

    /**
     * 删除卡片
     */
    fun deleteCard(cardId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }

            cardService.deleteCard(cardId)
                .onSuccess {
                    _uiState.update { state ->
                        state.copy(
                            isLoading = false,
                            successMessage = context.getString(R.string.cards_success_deleted)
                        )
                    }
                }
                .onFailure { error ->
                    _uiState.update { state ->
                        state.copy(
                            isLoading = false,
                            errorMessage = error.message ?: context.getString(R.string.cards_error_delete)
                        )
                    }
                }
        }
    }

    /**
     * 清除成功消息
     */
    fun clearSuccessMessage() {
        _uiState.update { it.copy(successMessage = null) }
    }

    /**
     * 清除错误消息
     */
    fun clearErrorMessage() {
        _uiState.update { it.copy(errorMessage = null) }
    }

    /**
     * 获取所有分组（从卡片列表中提取唯一分组）
     */
    val groups: StateFlow<List<String>> = cards.map { cardList ->
        cardList.map { it.group }.distinct().sorted()
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )
}

/**
 * 卡片列表 UI 状态
 */
data class CardsUiState(
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val successMessage: String? = null
)
