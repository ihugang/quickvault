package com.quickvault.presentation.screen.cards

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.quickvault.R
import com.quickvault.domain.service.impl.CardServiceImpl
import com.quickvault.presentation.viewmodel.CardEditorViewModel

/**
 * 卡片编辑界面
 * 对应 iOS 的 CardEditorScreen
 *
 * 功能：
 * - 创建新卡片
 * - 编辑现有卡片
 * - 根据模板动态生成字段
 * - 标签管理
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CardEditorScreen(
    onNavigateBack: () -> Unit,
    viewModel: CardEditorViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val title by viewModel.title.collectAsState()
    val group by viewModel.group.collectAsState()
    val cardType by viewModel.cardType.collectAsState()
    val fields by viewModel.fields.collectAsState()
    val tags by viewModel.tags.collectAsState()

    var showCardTypePicker by remember { mutableStateOf(false) }
    var tagInput by remember { mutableStateOf("") }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        if (uiState.isEditMode) {
                            stringResource(R.string.card_editor_title_edit)
                        } else {
                            stringResource(R.string.card_editor_title_new)
                        }
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = stringResource(R.string.common_cancel)
                        )
                    }
                },
                actions = {
                    // 保存按钮
                    TextButton(
                        onClick = {
                            viewModel.saveCard {
                                onNavigateBack()
                            }
                        },
                        enabled = !uiState.isLoading && title.isNotBlank()
                    ) {
                        if (uiState.isLoading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text(stringResource(R.string.common_save))
                        }
                    }
                }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // 错误消息
            if (uiState.errorMessage != null) {
                item {
                    Card(
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.errorContainer
                        )
                    ) {
                        Text(
                            text = uiState.errorMessage!!,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            style = MaterialTheme.typography.bodyMedium,
                            modifier = Modifier.padding(16.dp)
                        )
                    }
                }
            }

            // 卡片类型选择（仅新建时显示）
            if (!uiState.isEditMode) {
                item {
                    Column {
                        Text(
                            text = stringResource(R.string.card_editor_type_label),
                            style = MaterialTheme.typography.labelLarge
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        OutlinedCard(
                            onClick = { showCardTypePicker = true },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(getCardTypeName(cardType))
                                Icon(
                                    imageVector = Icons.Default.ArrowDropDown,
                                    contentDescription = null
                                )
                            }
                        }
                    }
                }
            }

            // 标题
            item {
                OutlinedTextField(
                    value = title,
                    onValueChange = { viewModel.setTitle(it) },
                    label = { Text(stringResource(R.string.card_editor_title_label)) },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next)
                )
            }

            // 分组
            item {
                OutlinedTextField(
                    value = group,
                    onValueChange = { viewModel.setGroup(it) },
                    label = { Text(stringResource(R.string.card_editor_group_label)) },
                    placeholder = { Text(stringResource(R.string.card_editor_group_placeholder)) },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next)
                )
            }

            // 字段区域标题
            item {
                Divider()
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = stringResource(R.string.card_editor_fields_title),
                    style = MaterialTheme.typography.titleMedium
                )
            }

            // 动态字段
            itemsIndexed(fields) { index, field ->
                FieldInput(
                    label = getFieldDisplayName(field.label),
                    value = field.value,
                    isRequired = field.isRequired,
                    onValueChange = { viewModel.updateFieldValue(index, it) },
                    fieldKey = field.label
                )
            }

            // 标签区域标题
            item {
                Divider()
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = stringResource(R.string.card_editor_tags_title),
                    style = MaterialTheme.typography.titleMedium
                )
            }

            // 标签输入
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = tagInput,
                        onValueChange = { tagInput = it },
                        label = { Text(stringResource(R.string.card_editor_add_tag_label)) },
                        modifier = Modifier.weight(1f),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done)
                    )
                    IconButton(
                        onClick = {
                            if (tagInput.isNotBlank()) {
                                viewModel.addTag(tagInput.trim())
                                tagInput = ""
                            }
                        }
                    ) {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = stringResource(R.string.card_editor_add_tag_action)
                        )
                    }
                }
            }

            // 标签列表
            if (tags.isNotEmpty()) {
                item {
                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        tags.forEach { tag ->
                            FilterChip(
                                selected = false,
                                onClick = { viewModel.removeTag(tag) },
                                label = { Text(tag) },
                                trailingIcon = {
                                    Icon(
                                        imageVector = Icons.Default.Close,
                                        contentDescription = stringResource(R.string.card_editor_remove_tag_action),
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                            )
                        }
                    }
                }
            }

            // 底部空白
            item {
                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }

    // 卡片类型选择对话框
    if (showCardTypePicker) {
        CardTypePickerDialog(
            currentType = cardType,
            onSelectType = { type ->
                viewModel.setCardType(type)
                showCardTypePicker = false
            },
            onDismiss = { showCardTypePicker = false }
        )
    }
}

/**
 * 单个字段输入
 */
@Composable
fun FieldInput(
    label: String,
    value: String,
    isRequired: Boolean,
    onValueChange: (String) -> Unit,
    fieldKey: String
) {
    // 根据字段类型决定输入方式
    val keyboardType = when (fieldKey) {
        "phone", "postalCode", "bankAccount" -> KeyboardType.Phone
        else -> KeyboardType.Text
    }

    val maxLines = if (fieldKey in listOf("content", "notes", "address")) 4 else 1

    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = {
            Text(
                if (isRequired) "$label *" else label
            )
        },
        modifier = Modifier.fillMaxWidth(),
        singleLine = maxLines == 1,
        maxLines = maxLines,
        keyboardOptions = KeyboardOptions(
            keyboardType = keyboardType,
            imeAction = ImeAction.Next
        )
    )
}

/**
 * 卡片类型选择对话框
 */
@Composable
fun CardTypePickerDialog(
    currentType: String,
    onSelectType: (String) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.card_editor_type_picker_title)) },
        text = {
            Column {
                CardTypeOption(
                    type = CardServiceImpl.CARD_TYPE_ADDRESS,
                    isSelected = currentType == CardServiceImpl.CARD_TYPE_ADDRESS,
                    onClick = { onSelectType(CardServiceImpl.CARD_TYPE_ADDRESS) }
                )
                CardTypeOption(
                    type = CardServiceImpl.CARD_TYPE_INVOICE,
                    isSelected = currentType == CardServiceImpl.CARD_TYPE_INVOICE,
                    onClick = { onSelectType(CardServiceImpl.CARD_TYPE_INVOICE) }
                )
                CardTypeOption(
                    type = CardServiceImpl.CARD_TYPE_GENERAL,
                    isSelected = currentType == CardServiceImpl.CARD_TYPE_GENERAL,
                    onClick = { onSelectType(CardServiceImpl.CARD_TYPE_GENERAL) }
                )
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.common_confirm))
            }
        }
    )
}

/**
 * 卡片类型选项
 */
@Composable
fun CardTypeOption(
    type: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    ListItem(
        headlineContent = { Text(getCardTypeName(type)) },
        supportingContent = { Text(getCardTypeDescription(type)) },
        leadingContent = {
            RadioButton(
                selected = isSelected,
                onClick = onClick
            )
        },
        modifier = Modifier.fillMaxWidth()
    )
}

/**
 * 获取卡片类型名称
 */
@Composable
private fun getCardTypeName(type: String): String {
    return when (type) {
        CardServiceImpl.CARD_TYPE_ADDRESS -> stringResource(R.string.cards_type_address)
        CardServiceImpl.CARD_TYPE_INVOICE -> stringResource(R.string.cards_type_invoice)
        CardServiceImpl.CARD_TYPE_GENERAL -> stringResource(R.string.cards_type_general)
        else -> type
    }
}

/**
 * 获取卡片类型描述
 */
@Composable
private fun getCardTypeDescription(type: String): String {
    return when (type) {
        CardServiceImpl.CARD_TYPE_ADDRESS -> stringResource(R.string.card_editor_type_address_desc)
        CardServiceImpl.CARD_TYPE_INVOICE -> stringResource(R.string.card_editor_type_invoice_desc)
        CardServiceImpl.CARD_TYPE_GENERAL -> stringResource(R.string.card_editor_type_general_desc)
        else -> ""
    }
}

/**
 * 获取字段显示名称（中英双语）
 */
@Composable
private fun getFieldDisplayName(fieldKey: String): String {
    return when (fieldKey) {
        "recipient" -> stringResource(R.string.field_recipient)
        "phone" -> stringResource(R.string.field_phone)
        "province" -> stringResource(R.string.field_province)
        "city" -> stringResource(R.string.field_city)
        "district" -> stringResource(R.string.field_district)
        "address" -> stringResource(R.string.field_address)
        "postalCode" -> stringResource(R.string.field_postalcode)
        "notes" -> stringResource(R.string.field_notes)
        "companyName" -> stringResource(R.string.field_companyname)
        "taxId" -> stringResource(R.string.field_taxid)
        "bankName" -> stringResource(R.string.field_bankname)
        "bankAccount" -> stringResource(R.string.field_bankaccount)
        "content" -> stringResource(R.string.field_content)
        else -> fieldKey
    }
}

/**
 * FlowRow 布局（用于标签）
 */
@Composable
fun FlowRow(
    modifier: Modifier = Modifier,
    horizontalArrangement: Arrangement.Horizontal = Arrangement.Start,
    content: @Composable () -> Unit
) {
    Column(modifier = modifier) {
        Row(
            horizontalArrangement = horizontalArrangement,
            modifier = Modifier.fillMaxWidth()
        ) {
            content()
        }
    }
}
