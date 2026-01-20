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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.quickvault.R
import com.quickvault.data.model.ItemDTO
import com.quickvault.data.model.ItemType
import com.quickvault.presentation.viewmodel.ItemsViewModel
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
    onNavigateToItemEditor: (String) -> Unit,
    viewModel: ItemsViewModel = hiltViewModel()
) {
    val searchQuery by viewModel.searchQuery.collectAsState()
    val items by viewModel.items.collectAsState()

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
                if (items.isEmpty()) {
                    SearchNoResults(query = searchQuery)
                } else {
                    SearchResults(
                        items = items,
                        query = searchQuery,
                        onItemClick = { item -> onNavigateToItemEditor(item.id) }
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
                placeholder = { Text(stringResource(R.string.search_placeholder_full)) },
                modifier = Modifier
                    .fillMaxWidth()
                    .focusRequester(focusRequester),
                singleLine = true,
                colors = TextFieldDefaults.colors(
                    focusedContainerColor = MaterialTheme.colorScheme.surface,
                    unfocusedContainerColor = MaterialTheme.colorScheme.surface,
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent
                ),
                trailingIcon = {
                    if (query.isNotEmpty()) {
                        IconButton(onClick = onClear) {
                            Icon(
                                imageVector = Icons.Default.Close,
                                contentDescription = stringResource(R.string.search_clear)
                            )
                        }
                    }
                },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Search,
                        contentDescription = stringResource(R.string.common_search)
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
                text = stringResource(R.string.search_empty_title),
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )

            Text(
                text = stringResource(R.string.search_empty_subtitle),
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
                text = stringResource(R.string.search_no_results_title),
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )

            Text(
                text = stringResource(R.string.search_query_label, query),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.primary,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )

            Text(
                text = stringResource(R.string.search_no_results_hint),
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
    items: List<ItemDTO>,
    query: String,
    onItemClick: (ItemDTO) -> Unit
) {
    Column {
        // 结果统计
        Text(
            text = stringResource(R.string.search_results_count, items.size),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
        )

        Divider()

        // 结果列表
        LazyColumn(
            contentPadding = PaddingValues(vertical = 8.dp)
        ) {
            items(items, key = { it.id }) { item ->
                SearchResultItem(
                    item = item,
                    query = query,
                    onClick = { onItemClick(item) }
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
    item: ItemDTO,
    query: String,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp)
            .clickable { onClick() },
        colors = CardDefaults.cardColors(
            containerColor = if (item.isPinned) {
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
                imageVector = when (item.type) {
                    ItemType.TEXT -> Icons.Default.TextFields
                    ItemType.IMAGE -> Icons.Default.Photo
                    ItemType.FILE -> Icons.Default.AttachFile
                },
                contentDescription = null,
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
                    text = item.title,
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(modifier = Modifier.height(4.dp))

                // 匹配的字段（显示第一个匹配的字段）
                val previewText = when (item.type) {
                    ItemType.TEXT -> item.textContent?.take(80).orEmpty()
                    ItemType.IMAGE -> stringResource(R.string.items_detail_images_count, item.images?.size ?: 0)
                    ItemType.FILE -> stringResource(R.string.items_detail_files_count, item.files?.size ?: 0)
                }
                if (previewText.isNotBlank()) {
                    Text(
                        text = previewText,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                Spacer(modifier = Modifier.height(4.dp))

                // 分组和时间
                Text(
                    text = formatDate(item.updatedAt),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                // 标签（如果匹配）
                val matchedTags = item.tags.filter {
                    it.contains(query, ignoreCase = true)
                }
                if (matchedTags.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = stringResource(
                            R.string.tags_label,
                            matchedTags.joinToString(", ")
                        ),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }

            // 置顶图标
            if (item.isPinned) {
                Icon(
                    imageVector = Icons.Default.PushPin,
                    contentDescription = stringResource(R.string.items_pinned),
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
