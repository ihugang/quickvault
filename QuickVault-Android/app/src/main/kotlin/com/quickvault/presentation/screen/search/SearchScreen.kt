package com.quickvault.presentation.screen.search

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
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.quickvault.data.model.CardDTO
import com.quickvault.presentation.viewmodel.CardsViewModel
import java.text.SimpleDateFormat
import java.util.*

/**
 * 搜索界面
 * 对应 iOS 的 SearchScreen
 *
 * 功能：
 * - 全局搜索卡片
 * - 实时搜索结果
 * - 搜索历史（可选）
 * - 高级筛选（可选）
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchScreen(
    onNavigateToCardEditor: (String) -> Unit,
    viewModel: CardsViewModel = hiltViewModel()
) {
    val searchQuery by viewModel.searchQuery.collectAsState()
    val cards by viewModel.cards.collectAsState()

    val focusRequester = remember { FocusRequester() }

    // 自动聚焦搜索框
    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }

    Scaffold(
        topBar = {
            SearchTopBar(
                query = searchQuery,
                onQueryChange = { viewModel.setSearchQuery(it) },
                onClear = { viewModel.setSearchQuery("") },
                focusRequester = focusRequester
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // 搜索提示或快捷操作
            if (searchQuery.isEmpty()) {
                SearchEmptyState()
            } else {
                // 搜索结果
                if (cards.isEmpty()) {
                    SearchNoResults(query = searchQuery)
                } else {
                    SearchResults(
                        cards = cards,
                        query = searchQuery,
                        onCardClick = { card -> onNavigateToCardEditor(card.id) }
                    )
                }
            }
        }
    }
}

/**
 * 搜索顶部栏
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchTopBar(
    query: String,
    onQueryChange: (String) -> Unit,
    onClear: () -> Unit,
    focusRequester: FocusRequester
) {
    TopAppBar(
        title = {
            TextField(
                value = query,
                onValueChange = onQueryChange,
                placeholder = { Text("搜索卡片、字段、标签... Search...") },
                modifier = Modifier
                    .fillMaxWidth()
                    .focusRequester(focusRequester),
                singleLine = true,
                colors = TextFieldDefaults.colors(
                    focusedContainerColor = MaterialTheme.colorScheme.surface,
                    unfocusedContainerColor = MaterialTheme.colorScheme.surface,
                    focusedIndicatorColor = MaterialTheme.colorScheme.transparent,
                    unfocusedIndicatorColor = MaterialTheme.colorScheme.transparent
                ),
                trailingIcon = {
                    if (query.isNotEmpty()) {
                        IconButton(onClick = onClear) {
                            Icon(
                                imageVector = Icons.Default.Close,
                                contentDescription = "清除搜索"
                            )
                        }
                    }
                },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Search,
                        contentDescription = "搜索"
                    )
                }
            )
        }
    )
}

/**
 * 空状态（未输入搜索）
 */
@Composable
fun SearchEmptyState() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Text(
                text = "搜索卡片内容\nSearch cards",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )

            Text(
                text = "支持搜索标题、字段值、标签\nSearch by title, fields, or tags",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
        }
    }
}

/**
 * 无结果提示
 */
@Composable
fun SearchNoResults(query: String) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier.padding(32.dp)
        ) {
            Icon(
                imageVector = Icons.Default.SearchOff,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Text(
                text = "未找到匹配结果\nNo results found",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )

            Text(
                text = "搜索: \"$query\"",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.primary,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )

            Text(
                text = "尝试使用不同的关键词\nTry different keywords",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
        }
    }
}

/**
 * 搜索结果列表
 */
@Composable
fun SearchResults(
    cards: List<CardDTO>,
    query: String,
    onCardClick: (CardDTO) -> Unit
) {
    Column {
        // 结果统计
        Text(
            text = "找到 ${cards.size} 个结果 / Found ${cards.size} results",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
        )

        Divider()

        // 结果列表
        LazyColumn(
            contentPadding = PaddingValues(vertical = 8.dp)
        ) {
            items(cards, key = { it.id }) { card ->
                SearchResultItem(
                    card = card,
                    query = query,
                    onClick = { onCardClick(card) }
                )
            }
        }
    }
}

/**
 * 搜索结果项
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchResultItem(
    card: CardDTO,
    query: String,
    onClick: () -> Unit
) {
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
            // 卡片图标
            Icon(
                imageVector = when (card.cardType) {
                    "address" -> Icons.Default.LocationOn
                    "invoice" -> Icons.Default.Receipt
                    else -> Icons.Default.TextFields
                },
                contentDescription = card.cardType,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(32.dp)
            )

            Spacer(modifier = Modifier.width(16.dp))

            // 卡片信息
            Column(
                modifier = Modifier.weight(1f)
            ) {
                // 标题（高亮匹配文字）
                Text(
                    text = card.title,
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(modifier = Modifier.height(4.dp))

                // 匹配的字段（显示第一个匹配的字段）
                val matchedField = card.fields.find {
                    it.value.contains(query, ignoreCase = true)
                }
                if (matchedField != null) {
                    Text(
                        text = "${matchedField.label}: ${matchedField.value}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                Spacer(modifier = Modifier.height(4.dp))

                // 分组和时间
                Text(
                    text = "${card.group} • ${formatDate(card.updatedAt)}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                // 标签（如果匹配）
                val matchedTags = card.tags.filter {
                    it.contains(query, ignoreCase = true)
                }
                if (matchedTags.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "标签: ${matchedTags.joinToString(", ")}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary
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
            }
        }
    }
}

/**
 * 格式化日期
 */
private fun formatDate(timestamp: Long): String {
    val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
    return sdf.format(Date(timestamp))
}
