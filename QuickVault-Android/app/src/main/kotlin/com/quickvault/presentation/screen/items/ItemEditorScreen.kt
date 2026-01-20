package com.quickvault.presentation.screen.items

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.quickvault.R
import com.quickvault.data.model.FileData
import com.quickvault.data.model.ImageData
import com.quickvault.data.model.ItemType
import com.quickvault.presentation.viewmodel.ItemEditorViewModel
import com.quickvault.util.getFileName
import com.quickvault.util.getMimeType
import com.quickvault.util.readBytesFromUri
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ItemEditorScreen(
    onNavigateBack: () -> Unit,
    viewModel: ItemEditorViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val title by viewModel.title.collectAsState()
    val tags by viewModel.tags.collectAsState()
    val itemType by viewModel.itemType.collectAsState()
    val textContent by viewModel.textContent.collectAsState()
    val images by viewModel.images.collectAsState()
    val files by viewModel.files.collectAsState()
    val imageMetadata by viewModel.imageMetadata.collectAsState()
    val fileMetadata by viewModel.fileMetadata.collectAsState()

    val context = LocalContext.current
    val coroutineScope = androidx.compose.runtime.rememberCoroutineScope()

    var tagInput by remember { mutableStateOf("") }
    var selectedImageData by remember { mutableStateOf<ByteArray?>(null) }
    var selectedImageName by remember { mutableStateOf("") }

    val imagePicker = rememberLauncherForActivityResult(
        ActivityResultContracts.GetMultipleContents()
    ) { uris ->
        if (uris.isNotEmpty()) {
            viewModel.setLoading(true)
            coroutineScope.launch {
                try {
                    val newImages = uris.mapNotNull { uri ->
                        readBytesFromUri(context, uri)?.let { bytes ->
                            ImageData(bytes, getFileName(context, uri))
                        }
                    }
                    if (newImages.isNotEmpty()) {
                        viewModel.addImages(newImages)
                    }
                } finally {
                    viewModel.setLoading(false)
                }
            }
        }
    }

    val filePicker = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenMultipleDocuments()
    ) { uris ->
        if (uris.isNotEmpty()) {
            viewModel.setLoading(true)
            coroutineScope.launch {
                try {
                    val newFiles = uris.mapNotNull { uri ->
                        readBytesFromUri(context, uri)?.let { bytes ->
                            FileData(bytes, getFileName(context, uri), getMimeType(context, uri))
                        }
                    }
                    if (newFiles.isNotEmpty()) {
                        viewModel.addFiles(newFiles)
                    }
                } finally {
                    viewModel.setLoading(false)
                }
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        if (uiState.isEditMode) {
                            stringResource(R.string.items_edit_title)
                        } else {
                            stringResource(R.string.items_create_title, typeLabel(itemType))
                        }
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(imageVector = Icons.Default.Close, contentDescription = stringResource(R.string.common_close))
                    }
                },
                actions = {
                    TextButton(
                        onClick = {
                            viewModel.save {
                                onNavigateBack()
                            }
                        },
                        enabled = title.isNotBlank() && !uiState.isLoading
                    ) {
                        if (uiState.isLoading) {
                            CircularProgressIndicator(modifier = Modifier.size(18.dp), strokeWidth = 2.dp)
                        } else {
                            val label = if (uiState.isEditMode) {
                                stringResource(R.string.common_save)
                            } else {
                                stringResource(R.string.items_create_button)
                            }
                            Text(label)
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
            item {
                OutlinedTextField(
                    value = title,
                    onValueChange = viewModel::setTitle,
                    label = { Text(stringResource(R.string.items_info_title)) },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
            }

            if (itemType == ItemType.TEXT) {
                item {
                    OutlinedTextField(
                        value = textContent,
                        onValueChange = viewModel::setTextContent,
                        label = { Text(stringResource(R.string.items_content)) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(min = 120.dp)
                    )
                }
            } else if (itemType == ItemType.IMAGE) {
                item {
                    Button(onClick = {
                        imagePicker.launch("image/*")
                    }) {
                        Text(stringResource(R.string.items_images_select))
                    }
                }
                
                // 显示已有图片（编辑模式）
                if (uiState.isEditMode && imageMetadata.isNotEmpty()) {
                    item {
                        Text(
                            text = stringResource(R.string.items_images_existing, imageMetadata.size),
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.secondary
                        )
                    }
                }
                items(imageMetadata.chunked(3)) { rowImages ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        rowImages.forEach { image ->
                            image.thumbnailData?.let { thumbnailData ->
                                ExistingImageThumbnailCard(
                                    imageData = thumbnailData,
                                    fileName = image.fileName,
                                    onRemove = { viewModel.removeExistingImage(image.id) },
                                    onClick = {
                                        coroutineScope.launch {
                                            val fullData = viewModel.getImageFullData(image.id)
                                            if (fullData != null) {
                                                selectedImageData = fullData
                                                selectedImageName = image.fileName
                                            }
                                        }
                                    },
                                    modifier = Modifier.weight(1f)
                                )
                            }
                        }
                        repeat(3 - rowImages.size) {
                            Spacer(modifier = Modifier.weight(1f))
                        }
                    }
                }
                
                // 显示新添加的图片
                if (images.isNotEmpty()) {
                    item {
                        Text(
                            text = stringResource(R.string.items_images_new, images.size),
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
                items(images.chunked(3)) { rowImages ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        rowImages.forEachIndexed { indexInRow, image ->
                            val index = images.indexOf(image)
                            ImageThumbnailCard(
                                imageData = image.data,
                                fileName = image.fileName,
                                onRemove = { viewModel.removeImage(index) },
                                onClick = {
                                    selectedImageData = image.data
                                    selectedImageName = image.fileName
                                },
                                modifier = Modifier.weight(1f)
                            )
                        }
                        repeat(3 - rowImages.size) {
                            Spacer(modifier = Modifier.weight(1f))
                        }
                    }
                }
            } else if (itemType == ItemType.FILE) {
                item {
                    Button(onClick = {
                        filePicker.launch(arrayOf("*/*"))
                    }) {
                        Text(stringResource(R.string.items_files_select))
                    }
                }
                
                // 显示已有文件（编辑模式）
                if (uiState.isEditMode && fileMetadata.isNotEmpty()) {
                    item {
                        Text(
                            text = stringResource(R.string.items_files_existing, fileMetadata.size),
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.secondary
                        )
                    }
                }
                items(fileMetadata) { file ->
                    AttachmentRow(
                        name = file.fileName,
                        onRemove = { viewModel.removeExistingFile(file.id) }
                    )
                }
                
                // 显示新添加的文件
                if (files.isNotEmpty()) {
                    item {
                        Text(
                            text = stringResource(R.string.items_files_new, files.size),
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
                itemsIndexed(files) { index, file ->
                    AttachmentRow(
                        name = file.fileName,
                        onRemove = { viewModel.removeFile(index) }
                    )
                }
            }

            item {
                OutlinedTextField(
                    value = tagInput,
                    onValueChange = { tagInput = it },
                    label = { Text(stringResource(R.string.items_tags_placeholder)) },
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(onClick = {
                        if (tagInput.isNotBlank()) {
                            viewModel.addTag(tagInput.trim())
                            tagInput = ""
                        }
                    }) {
                        Text(stringResource(R.string.items_tags_add))
                    }
                }
            }

            if (tags.isNotEmpty()) {
                items(tags) { tag ->
                    AttachmentRow(
                        name = tag,
                        onRemove = { viewModel.removeTag(tag) }
                    )
                }
            }

            if (uiState.errorMessage != null) {
                item {
                    Text(text = uiState.errorMessage ?: "", color = MaterialTheme.colorScheme.error)
                }
            }
        }
    }

    // 图片查看器
    selectedImageData?.let { imageData ->
        ImageViewerDialog(
            imageData = imageData,
            fileName = selectedImageName,
            imageCount = images.size,
            watermarkService = com.quickvault.domain.service.impl.WatermarkServiceImpl(context),
            onDismiss = { selectedImageData = null },
            onShare = { bitmap, style, text, applyToAll ->
                val watermarkService = com.quickvault.domain.service.impl.WatermarkServiceImpl(context)
                
                coroutineScope.launch {
                    try {
                        val uris = java.util.ArrayList<Uri>()
                        
                        if (applyToAll && images.size > 1) {
                            // 批量处理所有图片
                            images.forEach { image ->
                                val original = android.graphics.BitmapFactory.decodeByteArray(image.data, 0, image.data.size)
                                
                                val watermarked = watermarkService.applyWatermark(
                                    bitmap = original,
                                    text = text,
                                    style = style
                                )
                                
                                val uri = saveBitmapToCache(context, watermarked, "shared_${image.fileName}")
                                uris.add(uri)
                            }
                        } else {
                            // 仅分享当前图片
                            val uri = saveBitmapToCache(context, bitmap, "shared_image.jpg")
                            uris.add(uri)
                        }
                        
                        if (uris.isNotEmpty()) {
                            val shareIntent = android.content.Intent().apply {
                                if (uris.size > 1) {
                                    action = android.content.Intent.ACTION_SEND_MULTIPLE
                                    putParcelableArrayListExtra(android.content.Intent.EXTRA_STREAM, uris)
                                    type = "image/*"
                                } else {
                                    action = android.content.Intent.ACTION_SEND
                                    putExtra(android.content.Intent.EXTRA_STREAM, uris.first())
                                    type = "image/jpeg"
                                }
                                addFlags(android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            context.startActivity(android.content.Intent.createChooser(shareIntent, context.getString(R.string.watermark_share)))
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        )
    }
    
    // 全屏加载指示器
    if (uiState.isLoading) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.7f)),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator()
        }
    }
}

@Composable
private fun AttachmentRow(name: String, onRemove: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = name,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f)
        )
        IconButton(onClick = onRemove) {
            Icon(imageVector = Icons.Default.Delete, contentDescription = stringResource(R.string.common_delete))
        }
    }
}

@Composable
private fun ImageThumbnailCard(
    imageData: ByteArray,
    fileName: String,
    onRemove: () -> Unit,
    onClick: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.aspectRatio(1f),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        onClick = onClick
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            // 显示图片
            Image(
                bitmap = android.graphics.BitmapFactory.decodeByteArray(imageData, 0, imageData.size)
                    .asImageBitmap(),
                contentDescription = fileName,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
            // 删除按钮
            IconButton(
                onClick = onRemove,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(4.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Delete,
                    contentDescription = stringResource(R.string.common_delete),
                    tint = MaterialTheme.colorScheme.onSurface,
                    modifier = Modifier
                        .size(20.dp)
                        .background(
                            MaterialTheme.colorScheme.surface.copy(alpha = 0.7f),
                            CircleShape
                        )
                        .padding(2.dp)
                )
            }
        }
    }
}

@Composable
private fun ExistingImageThumbnailCard(
    imageData: ByteArray,
    fileName: String,
    onRemove: () -> Unit,
    onClick: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.aspectRatio(1f),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.secondaryContainer),
        onClick = onClick
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            // 显示图片缩略图
            Image(
                bitmap = android.graphics.BitmapFactory.decodeByteArray(imageData, 0, imageData.size)
                    .asImageBitmap(),
                contentDescription = fileName,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
            // 删除按钮
            IconButton(
                onClick = onRemove,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(4.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Delete,
                    contentDescription = stringResource(R.string.common_delete),
                    tint = MaterialTheme.colorScheme.error,
                    modifier = Modifier
                        .size(20.dp)
                        .background(
                            MaterialTheme.colorScheme.surface.copy(alpha = 0.7f),
                            CircleShape
                        )
                        .padding(2.dp)
                )
            }
        }
    }
}

@Composable
private fun typeLabel(type: ItemType): String {
    return when (type) {
        ItemType.TEXT -> stringResource(R.string.items_type_text)
        ItemType.IMAGE -> stringResource(R.string.items_type_image)
        ItemType.FILE -> stringResource(R.string.items_type_file)
    }
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
