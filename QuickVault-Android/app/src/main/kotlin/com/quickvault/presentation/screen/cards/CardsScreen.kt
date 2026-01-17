package com.quickvault.presentation.screen.cards

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.quickvault.R
import com.quickvault.data.model.CardDTO
import com.quickvault.presentation.viewmodel.CardsViewModel
import java.text.SimpleDateFormat
import java.util.*

/**
 * 卡片列表界面
 * 对应 iOS 的 CardsScreen
 *
 * 功能：
 * - 显示卡片列表（置顶卡片优先）
 * - 搜索功能
 * - 分组过滤
 * - 卡片操作（置顶、编辑、删除）
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CardsScreen(
    onNavigateToCardEditor: (String?) -> Unit, // null = 新建卡片，非 null = 编辑卡片
    viewModel: CardsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val cards by viewModel.cards.collectAsState()
    val searchQuery by viewModel.searchQuery.collectAsState()
    val selectedGroup by viewModel.selectedGroup.collectAsState()
    val groups by viewModel.groups.collectAsState()

    var showGroupFilter by remember { mutableStateOf(false) }

    // 显示成功消息
    LaunchedEffect(uiState.successMessage) {
        uiState.successMessage?.let {
            // Toast 或 Snackbar 通知
            viewModel.clearSuccessMessage()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.app_name)) },
                actions = {
                    // 分组过滤按钮
                    IconButton(onClick = { showGroupFilter = true }) {
                        Badge(
                            containerColor = if (selectedGroup != null) MaterialTheme.colorScheme.primary
                            else MaterialTheme.colorScheme.surfaceVariant
                        ) {
                            Icon(
                                imageVector = Icons.Default.FilterList,
                                contentDescription = "分组过滤"
                            )
                        }
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { onNavigateToCardEditor(null) }
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = "添加卡片"
                )
            }
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // 搜索框
            SearchBar(
                query = searchQuery,
                onQueryChange = { viewModel.setSearchQuery(it) },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
            )

            // 当前分组显示
            if (selectedGroup != null) {
                FilterChip(
                    selected = true,
                    onClick = { viewModel.setSelectedGroup(null) },
                    label = { Text("分组: $selectedGroup") },
                    trailingIcon = {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "清除分组过滤",
                            modifier = Modifier.size(18.dp)
                        )
                    },
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
                )
            }

            // 错误消息
            if (uiState.errorMessage != null) {
                Text(
                    text = uiState.errorMessage!!,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }

            // 卡片列表
            if (cards.isEmpty()) {
                EmptyState(
                    searchQuery = searchQuery,
                    selectedGroup = selectedGroup
                )
            } else {
                CardsList(
                    cards = cards,
                    onCardClick = { card -> onNavigateToCardEditor(card.id) },
                    onTogglePin = { cardId -> viewModel.togglePin(cardId) },
                    onDeleteCard = { cardId -> viewModel.deleteCard(cardId) }
                )
            }
        }
    }

    // 分组过滤对话框
    if (showGroupFilter) {
        GroupFilterDialog(
            groups = groups,
            selectedGroup = selectedGroup,
            onSelectGroup = { group ->
                viewModel.setSelectedGroup(group)
                showGroupFilter = false
            },
            onDismiss = { showGroupFilter = false }
        )
    }
}

/**
 * 搜索框
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        placeholder = { Text("搜索卡片... Search cards...") },
        leadingIcon = {
            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = "搜索"
            )
        },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "清除搜索"
                    )
                }
            }
        },
        modifier = modifier,
        singleLine = true
    )
}

/**
 * 卡片列表
 */
@Composable
fun CardsList(
    cards: List<CardDTO>,
    onCardClick: (CardDTO) -> Unit,
    onTogglePin: (String) -> Unit,
    onDeleteCard: (String) -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = 8.dp)
    ) {
        items(cards, key = { it.id }) { card ->
            CardItem(
                card = card,
                onClick = { onCardClick(card) },
                onTogglePin = { onTogglePin(card.id) },
                onDelete = { onDeleteCard(card.id) }
            )
        }
    }
}

/**
 * 单个卡片项
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CardItem(
    card: CardDTO,
    onClick: () -> Unit,
    onTogglePin: () -> Unit,
    onDelete: () -> Unit
) {
    var showMenu by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp)
            .clickable { onClick() },
        colors = CardDefaults.cardColors(
            containerColor = if (card.isPinned) {
                MaterialTheme.colorScheme.primaryContainer
            } else {
                MaterialTheme.colorScheme.surface
            }
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // 卡片图标（根据类型）
            Icon(
                imageVector = when (card.cardType) {
                    "address" -> Icons.Default.LocationOn
                    "invoice" -> Icons.Default.Receipt
                    else -> Icons.Default.TextFields
                },
                contentDescription = card.cardType,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(40.dp)
            )

            Spacer(modifier = Modifier.width(16.dp))

            // 卡片信息
            Column(
                modifier = Modifier.weight(1f)
            ) {
                // 标题
                Text(
                    text = card.title,
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(modifier = Modifier.height(4.dp))

                // 分组和时间
                Text(
                    text = "${card.group} • ${formatDate(card.updatedAt)}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                // 标签
                if (card.tags.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = card.tags.joinToString(" • "),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }

            // 置顶图标
            if (card.isPinned) {
                Icon(
                    imageVector = Icons.Default.PushPin,
                    contentDescription = "已置顶",
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
            }

            // 更多菜单
            Box {
                IconButton(onClick = { showMenu = true }) {
                    Icon(
                        imageVector = Icons.Default.MoreVert,
                        contentDescription = "更多操作"
                    )
                }

                DropdownMenu(
                    expanded = showMenu,
                    onDismissRequest = { showMenu = false }
                ) {
                    DropdownMenuItem(
                        text = { Text(if (card.isPinned) "取消置顶" else "置顶") },
                        onClick = {
                            onTogglePin()
                            showMenu = false
                        },
                        leadingIcon = {
                            Icon(
                                imageVector = Icons.Default.PushPin,
                                contentDescription = null
                            )
                        }
                    )

                    DropdownMenuItem(
                        text = { Text("编辑") },
                        onClick = {
                            onClick()
                            showMenu = false
                        },
                        leadingIcon = {
                            Icon(
                                imageVector = Icons.Default.Edit,
                                contentDescription = null
                            )
                        }
                    )

                    DropdownMenuItem(
                        text = { Text("删除", color = MaterialTheme.colorScheme.error) },
                        onClick = {
                            onDelete()
                            showMenu = false
                        },
                        leadingIcon = {
                            Icon(
                                imageVector = Icons.Default.Delete,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.error
                            )
                        }
                    )
                }
            }
        }
    }
}

/**
 * 空状态提示
 */
@Composable
fun EmptyState(
    searchQuery: String,
    selectedGroup: String?
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                imageVector = if (searchQuery.isNotEmpty() || selectedGroup != null) {
                    Icons.Default.SearchOff
                } else {
                    Icons.Default.CreditCard
                },
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Text(
                text = when {
                    searchQuery.isNotEmpty() -> "未找到匹配的卡片\nNo cards found"
                    selectedGroup != null -> "该分组暂无卡片\nNo cards in this group"
                    else -> "暂无卡片\n点击 + 添加第一张卡片\nNo cards yet\nTap + to add your first card"
                },
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
        }
    }
}

/**
 * 分组过滤对话框
 */
@Composable
fun GroupFilterDialog(
    groups: List<String>,
    selectedGroup: String?,
    onSelectGroup: (String?) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("选择分组 Select Group") },
        text = {
            LazyColumn {
                // "全部" 选项
                item {
                    ListItem(
                        headlineContent = { Text("全部 All") },
                        modifier = Modifier.clickable { onSelectGroup(null) },
                        leadingContent = {
                            RadioButton(
                                selected = selectedGroup == null,
                                onClick = { onSelectGroup(null) }
                            )
                        }
                    )
                }

                // 各个分组
                items(groups) { group ->
                    ListItem(
                        headlineContent = { Text(group) },
                        modifier = Modifier.clickable { onSelectGroup(group) },
                        leadingContent = {
                            RadioButton(
                                selected = selectedGroup == group,
                                onClick = { onSelectGroup(group) }
                            )
                        }
                    )
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("确定 OK")
            }
        }
    )
}

/**
 * 格式化日期
 */
private fun formatDate(timestamp: Long): String {
    val sdf = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault())
    return sdf.format(Date(timestamp))
}
