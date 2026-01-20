package com.quickvault.presentation.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import android.content.Context
import com.quickvault.data.model.CardDTO
import com.quickvault.data.model.CardFieldDTO
import com.quickvault.domain.service.CardService
import com.quickvault.domain.service.impl.CardServiceImpl
import com.quickvault.R
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 卡片编辑 ViewModel
 * 对应 iOS 的 CardEditorViewModel
 *
 * 职责：
 * - 管理卡片编辑状态
 * - 处理字段动态生成（根据模板）
 * - 保存卡片
 */
@HiltViewModel
class CardEditorViewModel @Inject constructor(
    private val cardService: CardService,
    @ApplicationContext private val context: Context,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    // 卡片 ID（null = 新建，非 null = 编辑）
    private val cardId: String? = savedStateHandle.get<String>("cardId")

    // UI 状态
    private val _uiState = MutableStateFlow(CardEditorUiState())
    val uiState: StateFlow<CardEditorUiState> = _uiState.asStateFlow()

    // 标题
    private val _title = MutableStateFlow("")
    val title: StateFlow<String> = _title.asStateFlow()

    // 分组
    private val _group = MutableStateFlow("")
    val group: StateFlow<String> = _group.asStateFlow()

    // 卡片类型
    private val _cardType = MutableStateFlow(CardServiceImpl.CARD_TYPE_ADDRESS)
    val cardType: StateFlow<String> = _cardType.asStateFlow()

    // 字段列表
    private val _fields = MutableStateFlow<List<CardFieldDTO>>(emptyList())
    val fields: StateFlow<List<CardFieldDTO>> = _fields.asStateFlow()

    // 标签
    private val _tags = MutableStateFlow<List<String>>(emptyList())
    val tags: StateFlow<List<String>> = _tags.asStateFlow()

    init {
        if (cardId != null) {
            loadCard(cardId)
        } else {
            // 新建卡片 - 初始化默认字段模板
            initializeTemplate(CardServiceImpl.CARD_TYPE_ADDRESS)
        }
    }

    /**
     * 加载现有卡片
     */
    private fun loadCard(id: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            cardService.getCard(id)
                .onSuccess { card ->
                    _title.value = card.title
                    _group.value = card.group
                    _cardType.value = card.cardType
                    _fields.value = card.fields
                    _tags.value = card.tags
                    _uiState.update { it.copy(isLoading = false, isEditMode = true) }
                }
                .onFailure { error ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            errorMessage = error.message ?: context.getString(R.string.card_editor_error_load)
                        )
                    }
                }
        }
    }

    /**
     * 设置标题
     */
    fun setTitle(title: String) {
        _title.value = title
    }

    /**
     * 设置分组
     */
    fun setGroup(group: String) {
        _group.value = group
    }

    /**
     * 设置卡片类型（并重置字段）
     */
    fun setCardType(type: String) {
        if (_cardType.value != type) {
            _cardType.value = type
            initializeTemplate(type)
        }
    }

    /**
     * 更新字段值
     */
    fun updateFieldValue(index: Int, value: String) {
        val updatedFields = _fields.value.toMutableList()
        if (index in updatedFields.indices) {
            updatedFields[index] = updatedFields[index].copy(value = value)
            _fields.value = updatedFields
        }
    }

    /**
     * 添加标签
     */
    fun addTag(tag: String) {
        if (tag.isNotBlank() && tag !in _tags.value) {
            _tags.value = _tags.value + tag
        }
    }

    /**
     * 移除标签
     */
    fun removeTag(tag: String) {
        _tags.value = _tags.value - tag
    }

    /**
     * 保存卡片
     */
    fun saveCard(onSuccess: () -> Unit) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }

            val result = if (cardId != null) {
                // 更新现有卡片
                cardService.updateCard(
                    id = cardId,
                    title = _title.value,
                    group = _group.value,
                    fields = _fields.value,
                    tags = _tags.value
                )
            } else {
                // 创建新卡片
                cardService.createCard(
                    title = _title.value,
                    group = _group.value,
                    cardType = _cardType.value,
                    fields = _fields.value,
                    tags = _tags.value
                )
            }

            result
                .onSuccess {
                    _uiState.update { it.copy(isLoading = false) }
                    onSuccess()
                }
                .onFailure { error ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            errorMessage = error.message ?: context.getString(R.string.card_editor_error_save)
                        )
                    }
                }
        }
    }

    /**
     * 初始化字段模板
     * 对应 iOS 的 CardTemplate
     */
    private fun initializeTemplate(type: String) {
        _fields.value = when (type) {
            CardServiceImpl.CARD_TYPE_ADDRESS -> createAddressTemplate()
            CardServiceImpl.CARD_TYPE_INVOICE -> createInvoiceTemplate()
            CardServiceImpl.CARD_TYPE_GENERAL -> createGeneralTemplate()
            else -> emptyList()
        }
    }

    /**
     * 地址模板
     * 对应 iOS 的 AddressTemplate
     */
    private fun createAddressTemplate(): List<CardFieldDTO> {
        return listOf(
            CardFieldDTO(label = "recipient", value = "", isRequired = true, displayOrder = 0),
            CardFieldDTO(label = "phone", value = "", isRequired = true, displayOrder = 1),
            CardFieldDTO(label = "province", value = "", isRequired = true, displayOrder = 2),
            CardFieldDTO(label = "city", value = "", isRequired = true, displayOrder = 3),
            CardFieldDTO(label = "district", value = "", isRequired = true, displayOrder = 4),
            CardFieldDTO(label = "address", value = "", isRequired = true, displayOrder = 5),
            CardFieldDTO(label = "postalCode", value = "", isRequired = false, displayOrder = 6),
            CardFieldDTO(label = "notes", value = "", isRequired = false, displayOrder = 7)
        )
    }

    /**
     * 发票模板
     * 对应 iOS 的 InvoiceTemplate
     */
    private fun createInvoiceTemplate(): List<CardFieldDTO> {
        return listOf(
            CardFieldDTO(label = "companyName", value = "", isRequired = true, displayOrder = 0),
            CardFieldDTO(label = "taxId", value = "", isRequired = true, displayOrder = 1),
            CardFieldDTO(label = "address", value = "", isRequired = true, displayOrder = 2),
            CardFieldDTO(label = "phone", value = "", isRequired = true, displayOrder = 3),
            CardFieldDTO(label = "bankName", value = "", isRequired = true, displayOrder = 4),
            CardFieldDTO(label = "bankAccount", value = "", isRequired = true, displayOrder = 5),
            CardFieldDTO(label = "notes", value = "", isRequired = false, displayOrder = 6)
        )
    }

    /**
     * 通用模板
     * 对应 iOS 的 GeneralTextTemplate
     */
    private fun createGeneralTemplate(): List<CardFieldDTO> {
        return listOf(
            CardFieldDTO(label = "content", value = "", isRequired = true, displayOrder = 0)
        )
    }

    /**
     * 清除错误消息
     */
    fun clearErrorMessage() {
        _uiState.update { it.copy(errorMessage = null) }
    }
}

/**
 * 卡片编辑 UI 状态
 */
data class CardEditorUiState(
    val isLoading: Boolean = false,
    val isEditMode: Boolean = false, // true = 编辑模式，false = 新建模式
    val errorMessage: String? = null
)
