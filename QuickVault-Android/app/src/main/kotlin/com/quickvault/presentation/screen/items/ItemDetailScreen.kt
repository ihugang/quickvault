package com.quickvault.presentation.screen.items

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.Photo
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material.icons.filled.Share
import android.content.ClipData
import android.content.ClipboardManager
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.quickvault.R
import com.quickvault.data.model.ItemType
import com.quickvault.presentation.viewmodel.ItemEditorViewModel
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * 项目详细画面
 * 显示项目的完整信息，提供编辑和删除功能
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ItemDetailScreen(
    onNavigateBack: () -> Unit,
    onNavigateToEdit: (String) -> Unit,
    viewModel: ItemEditorViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val title by viewModel.title.collectAsState()
    val tags by viewModel.tags.collectAsState()
    val itemType by viewModel.itemType.collectAsState()
    val textContent by viewModel.textContent.collectAsState()
    val imageMetadata by viewModel.imageMetadata.collectAsState()
    val fileMetadata by viewModel.fileMetadata.collectAsState()
    val createdAt by viewModel.createdAt.collectAsState()
    val updatedAt by viewModel.updatedAt.collectAsState()
    val isPinned by viewModel.isPinned.collectAsState()

    var showDeleteDialog by remember { mutableStateOf(false) }
    var selectedImageData by remember { mutableStateOf<ByteArray?>(null) }
    var selectedImageName by remember { mutableStateOf("") }
    var isLoadingImage by remember { mutableStateOf(false) }
    val coroutineScope = rememberCoroutineScope()
    val context = androidx.compose.ui.platform.LocalContext.current

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(title) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = stringResource(R.string.common_back)
                        )
                    }
                },
                actions = {
                    // 置顶按钮
                    IconButton(onClick = { viewModel.togglePin() }) {
                        Icon(
                            imageVector = Icons.Default.PushPin,
                            contentDescription = stringResource(R.string.items_pinned),
                            tint = if (isPinned) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    // 分享按钮
                    if (itemType == ItemType.TEXT || (itemType == ItemType.IMAGE && imageMetadata.isNotEmpty())) {
                        IconButton(onClick = {
                            if (itemType == ItemType.TEXT) {
                                // 文本分享：复制到剪贴板并打开系统分享
                                val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                                val clip = ClipData.newPlainText("content", textContent)
                                clipboard.setPrimaryClip(clip)
                                
                                val shareIntent = Intent(Intent.ACTION_SEND).apply {
                                    type = "text/plain"
                                    putExtra(Intent.EXTRA_TEXT, textContent)
                                }
                                context.startActivity(Intent.createChooser(shareIntent, context.getString(R.string.common_share)))
                            } else if (itemType == ItemType.IMAGE && imageMetadata.isNotEmpty()) {
                                // 图片分享：打开第一张图片的查看器
                                val firstImage = imageMetadata.first()
                                isLoadingImage = true
                                selectedImageName = firstImage.fileName
                                coroutineScope.launch {
                                    val fullData = viewModel.getImageFullData(firstImage.id)
                                    selectedImageData = fullData
                                    isLoadingImage = false
                                }
                            }
                        }) {
                            Icon(
                                imageVector = Icons.Default.Share,
                                contentDescription = stringResource(R.string.common_share)
                            )
                        }
                    }
                    // 编辑按钮
                    IconButton(onClick = {
                        uiState.itemId?.let { onNavigateToEdit(it) }
                    }) {
                        Icon(
                            imageVector = Icons.Default.Edit,
                            contentDescription = stringResource(R.string.common_edit)
                        )
                    }
                    // 删除按钮
                    IconButton(onClick = { showDeleteDialog = true }) {
                        Icon(
                            imageVector = Icons.Default.Delete,
                            contentDescription = stringResource(R.string.common_delete)
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        if (uiState.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // 类型图标和标题
                item {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            imageVector = when (itemType) {
                                ItemType.TEXT -> Icons.Default.Description
                                ItemType.IMAGE -> Icons.Default.Photo
                                ItemType.FILE -> Icons.Default.Folder
                            },
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(48.dp)
                        )
                        Spacer(modifier = Modifier.width(16.dp))
                        Column {
                            Text(
                                text = title,
                                style = MaterialTheme.typography.headlineSmall
                            )
                            Text(
                                text = typeLabel(itemType),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                // 标签
                if (tags.isNotEmpty()) {
                    item {
                        DetailSection(title = stringResource(R.string.items_tags_section)) {
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                tags.forEach { tag ->
                                    SuggestionChip(
                                        onClick = { },
                                        label = { Text(tag) }
                                    )
                                }
                            }
                        }
                    }
                }

                // 文本内容
                if (itemType == ItemType.TEXT && textContent.isNotBlank()) {
                    item {
                        DetailSection(title = stringResource(R.string.items_content)) {
                            Card(
                                modifier = Modifier.fillMaxWidth(),
                                colors = CardDefaults.cardColors(
                                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                                )
                            ) {
                                Text(
                                    text = textContent,
                                    style = MaterialTheme.typography.bodyMedium,
                                    modifier = Modifier.padding(16.dp)
                                )
                            }
                        }
                    }
                }

                // 图片
                if (imageMetadata.isNotEmpty()) {
                    item {
                        DetailSection(title = stringResource(R.string.items_images_count, imageMetadata.size)) {
                            // 图片网格显示，每行3个
                            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                imageMetadata.chunked(3).forEach { rowImages ->
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        rowImages.forEach { image ->
                                            ImageThumbnailDisplay(
                                                thumbnailData = image.thumbnailData,
                                                fileName = image.fileName,
                                                onClick = {
                                                    // 加载完整图片数据
                                                    isLoadingImage = true
                                                    selectedImageName = image.fileName
                                                    coroutineScope.launch {
                                                        val fullData = viewModel.getImageFullData(image.id)
                                                        selectedImageData = fullData
                                                        isLoadingImage = false
                                                    }
                                                },
                                                modifier = Modifier.weight(1f)
                                            )
                                        }
                                        // 填充空白
                                        repeat(3 - rowImages.size) {
                                            Spacer(modifier = Modifier.weight(1f))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 文件
                if (fileMetadata.isNotEmpty()) {
                    item {
                        DetailSection(title = stringResource(R.string.items_files_count, fileMetadata.size)) {
                            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                fileMetadata.forEach { file ->
                                    FileInfoCard(
                                        fileName = file.fileName,
                                        mimeType = file.mimeType,
                                        onClick = {
                                            // 预览文件：保存到缓存并调用系统预览
                                            coroutineScope.launch {
                                                try {
                                                    val fileData = viewModel.getFileData(file.id)
                                                    if (fileData != null) {
                                                        val uri = saveFileToCache(context, fileData, file.fileName)
                                                        val intent = Intent(Intent.ACTION_VIEW).apply {
                                                            setDataAndType(uri, file.mimeType)
                                                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                                        }
                                                        try {
                                                            context.startActivity(intent)
                                                        } catch (e: android.content.ActivityNotFoundException) {
                                                            android.widget.Toast.makeText(context, context.getString(R.string.error_no_app_preview), android.widget.Toast.LENGTH_SHORT).show()
                                                        } catch (e: Exception) {
                                                            android.widget.Toast.makeText(context, context.getString(R.string.error_preview_failed), android.widget.Toast.LENGTH_SHORT).show()
                                                        }
                                                    }
                                                } catch (e: Exception) {
                                                    e.printStackTrace()
                                                    android.widget.Toast.makeText(context, context.getString(R.string.error_preview_failed), android.widget.Toast.LENGTH_SHORT).show()
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                }

                // 时间信息
                item {
                    DetailSection(title = stringResource(R.string.items_info)) {
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            InfoRow(
                                label = stringResource(R.string.items_created),
                                value = formatDateTime(createdAt)
                            )
                            InfoRow(
                                label = stringResource(R.string.items_modified),
                                value = formatDateTime(updatedAt)
                            )
                        }
                    }
                }
            }
        }
    }

    // 删除确认对话框
    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text(stringResource(R.string.items_delete_title)) },
            text = { Text(stringResource(R.string.items_delete_confirm)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.delete {
                            onNavigateBack()
                        }
                        showDeleteDialog = false
                    }
                ) {
                    Text(stringResource(R.string.common_delete))
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text(stringResource(R.string.common_cancel))
                }
            }
        )
    }

    // 加载图片指示器
    if (isLoadingImage) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator()
        }
    }

    // 图片查看器
    selectedImageData?.let { imageData ->
        val context = androidx.compose.ui.platform.LocalContext.current
            ImageViewerDialog(
                imageData = imageData,
                fileName = selectedImageName,
                imageCount = imageMetadata.size,
                watermarkService = androidx.hilt.navigation.compose.hiltViewModel<ItemEditorViewModel>().run {
                    com.quickvault.domain.service.impl.WatermarkServiceImpl(
                        androidx.compose.ui.platform.LocalContext.current
                    )
                },
                onDismiss = { selectedImageData = null },
                onShare = { bitmap, style, text, applyToAll ->
                    val watermarkService = com.quickvault.domain.service.impl.WatermarkServiceImpl(context)
                    
                    coroutineScope.launch {
                        try {
                            val uris = ArrayList<Uri>()
                            
                            if (applyToAll && imageMetadata.size > 1) {
                                // 批量处理所有图片
                                // 显示加载中提示（实际应该用Toast或Dialog，此处简化）
                                
                                imageMetadata.forEach { meta ->
                                    // 1. 获取原图
                                    val fullData = viewModel.getImageFullData(meta.id)
                                    if (fullData != null) {
                                        val original = android.graphics.BitmapFactory.decodeByteArray(fullData, 0, fullData.size)
                                        
                                        // 2. 应用水印
                                        val watermarked = watermarkService.applyWatermark(
                                            bitmap = original,
                                            text = text,
                                            style = style
                                        )
                                        
                                        // 3. 保存并记录URI
                                        val uri = saveBitmapToCache(context, watermarked, "shared_${meta.fileName}")
                                        uris.add(uri)
                                    }
                                }
                            } else {
                                // 仅分享当前图片
                                val uri = saveBitmapToCache(context, bitmap, "shared_image.jpg")
                                uris.add(uri)
                            }
                            
                            if (uris.isNotEmpty()) {
                                val shareIntent = Intent().apply {
                                    if (uris.size > 1) {
                                        action = Intent.ACTION_SEND_MULTIPLE
                                        putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                                        type = "image/*"
                                    } else {
                                        action = Intent.ACTION_SEND
                                        putExtra(Intent.EXTRA_STREAM, uris.first())
                                        type = "image/jpeg"
                                    }
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                context.startActivity(Intent.createChooser(shareIntent, context.getString(R.string.watermark_share)))
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }
                }
            )  }
}

@Composable
private fun DetailSection(
    title: String,
    content: @Composable () -> Unit
) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        content()
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium
        )
    }
}

@Composable
private fun ImageThumbnailDisplay(
    thumbnailData: ByteArray?,
    fileName: String,
    onClick: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.aspectRatio(1f),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        onClick = onClick
    ) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            if (thumbnailData != null && thumbnailData.isNotEmpty()) {
                Image(
                    bitmap = android.graphics.BitmapFactory.decodeByteArray(thumbnailData, 0, thumbnailData.size)
                        .asImageBitmap(),
                    contentDescription = fileName,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            } else {
                // 如果没有缩略图，显示图标和文件名
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.padding(8.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Photo,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(48.dp)
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = fileName,
                        style = MaterialTheme.typography.bodySmall,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                        textAlign = TextAlign.Center
                    )
                }
            }
        }
    }
}

@Composable
private fun ImageInfoCard(fileName: String, index: Int) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Photo,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = fileName,
                    style = MaterialTheme.typography.bodyMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = stringResource(R.string.items_image_number, index),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun FileInfoCard(fileName: String, mimeType: String, onClick: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth().clickable { onClick() },
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Folder,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = fileName,
                    style = MaterialTheme.typography.bodyMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = mimeType,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun typeLabel(type: ItemType): String {
    return stringResource(
        when (type) {
            ItemType.TEXT -> R.string.items_type_text
            ItemType.IMAGE -> R.string.items_type_image
            ItemType.FILE -> R.string.items_type_file
        }
    )
}

private fun formatDateTime(timestamp: Long): String {
    val sdf = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault())
    return sdf.format(Date(timestamp))
}

/**
 * 将Bitmap保存到缓存目录并返回FileProvider URI
 */
private fun saveBitmapToCache(context: Context, bitmap: Bitmap, fileName: String): Uri {
    val cacheDir = java.io.File(context.cacheDir, "shared")
    if (!cacheDir.exists()) {
        cacheDir.mkdirs()
    }
    val file = java.io.File(cacheDir, fileName)
    file.outputStream().use { outputStream ->
        bitmap.compress(Bitmap.CompressFormat.JPEG, 95, outputStream)
    }
    return androidx.core.content.FileProvider.getUriForFile(
        context,
        "${context.packageName}.fileprovider",
        file
    )
}

/**
 * 将文件数据保存到缓存目录并返回FileProvider URI
 */
private fun saveFileToCache(context: Context, data: ByteArray, fileName: String): Uri {
    val cacheDir = java.io.File(context.cacheDir, "shared_files")
    if (!cacheDir.exists()) {
        cacheDir.mkdirs()
    }
    val file = java.io.File(cacheDir, fileName)
    file.writeBytes(data)
    return androidx.core.content.FileProvider.getUriForFile(
        context,
        "${context.packageName}.fileprovider",
        file
    )
}
