package com.quickvault.presentation.screen.items

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Button
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
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
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

    val context = LocalContext.current

    var tagInput by remember { mutableStateOf("") }

    val imagePicker = rememberLauncherForActivityResult(
        ActivityResultContracts.GetMultipleContents()
    ) { uris ->
        val newImages = uris.mapNotNull { uri ->
            readBytesFromUri(context, uri)?.let { bytes ->
                ImageData(bytes, getFileName(context, uri))
            }
        }
        if (newImages.isNotEmpty()) {
            viewModel.addImages(newImages)
        }
    }

    val filePicker = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenMultipleDocuments()
    ) { uris ->
        val newFiles = uris.mapNotNull { uri ->
            readBytesFromUri(context, uri)?.let { bytes ->
                FileData(bytes, getFileName(context, uri), getMimeType(context, uri))
            }
        }
        if (newFiles.isNotEmpty()) {
            viewModel.addFiles(newFiles)
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
                itemsIndexed(images) { index, image ->
                    AttachmentRow(
                        name = image.fileName,
                        onRemove = { viewModel.removeImage(index) }
                    )
                }
            } else if (itemType == ItemType.FILE) {
                item {
                    Button(onClick = {
                        filePicker.launch(arrayOf("*/*"))
                    }) {
                        Text(stringResource(R.string.items_files_select))
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
}

@Composable
private fun AttachmentRow(name: String, onRemove: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(text = name, maxLines = 1)
        IconButton(onClick = onRemove) {
            Icon(imageVector = Icons.Default.Delete, contentDescription = stringResource(R.string.common_delete))
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
