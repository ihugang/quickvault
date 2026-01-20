package com.quickvault.presentation.screen.items

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.quickvault.R
import com.quickvault.domain.service.WatermarkService
import com.quickvault.domain.service.WatermarkStyle

/**
 * 图片查看器对话框
 * 支持图片缩放、平移和添加水印（同屏实时预览）
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ImageViewerDialog(
    imageData: ByteArray,
    fileName: String,
    watermarkService: WatermarkService,
    onDismiss: () -> Unit
) {
    var scale by remember { mutableStateOf(1f) }
    var offset by remember { mutableStateOf(Offset.Zero) }
    var showWatermarkSettings by remember { mutableStateOf(true) } // 默认显示设置面板
    
    // 水印设置
    var enableWatermark by remember { mutableStateOf(false) }
    var watermarkText by remember { mutableStateOf("机密 / Confidential") }
    var fontSize by remember { mutableStateOf(80f) }
    var opacity by remember { mutableStateOf(0.3f) }
    var lineSpacing by remember { mutableStateOf(1.5f) } // 1.0=密集, 1.5=正常, 2.0=稀疏

    val originalBitmap = remember(imageData) {
        BitmapFactory.decodeByteArray(imageData, 0, imageData.size)
    }

    // 实时生成带水印的图片
    val displayBitmap = remember(enableWatermark, watermarkText, fontSize, opacity, lineSpacing) {
        if (enableWatermark && watermarkText.isNotBlank()) {
            watermarkService.applyWatermark(
                bitmap = originalBitmap,
                text = watermarkText,
                style = WatermarkStyle(
                    fontSize = fontSize,
                    opacity = opacity,
                    lineSpacing = lineSpacing
                )
            )
        } else {
            originalBitmap
        }
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            usePlatformDefaultWidth = false,
            decorFitsSystemWindows = false
        )
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .windowInsetsPadding(WindowInsets.systemBars) // Column 整体避开顶部状态栏和底部导航栏
            ) {
                // 顶部操作栏
                TopAppBar(
                    title = { 
                        Text(
                            text = fileName,
                            color = Color.White,
                            maxLines = 1
                        )
                    },
                    navigationIcon = {
                        IconButton(onClick = onDismiss) {
                            Icon(
                                imageVector = Icons.Default.Close,
                                contentDescription = stringResource(R.string.common_close),
                                tint = Color.White
                            )
                        }
                    },
                    actions = {
                        IconButton(onClick = { showWatermarkSettings = !showWatermarkSettings }) {
                            Icon(
                                imageVector = Icons.Default.Settings,
                                contentDescription = stringResource(R.string.watermark_settings),
                                tint = if (showWatermarkSettings) MaterialTheme.colorScheme.primary else Color.White
                            )
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = Color.Black.copy(alpha = 0.7f)
                    )
                )
                
                // 图片显示区域
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f)
                        .pointerInput(Unit) {
                            detectTransformGestures { _, pan, zoom, _ ->
                                scale = (scale * zoom).coerceIn(0.5f, 5f)
                                offset = if (scale > 1f) {
                                    Offset(
                                        x = (offset.x + pan.x).coerceIn(-size.width.toFloat(), size.width.toFloat()),
                                        y = (offset.y + pan.y).coerceIn(-size.height.toFloat(), size.height.toFloat())
                                    )
                                } else {
                                    Offset.Zero
                                }
                            }
                        },
                    contentAlignment = if (showWatermarkSettings) Alignment.TopCenter else Alignment.Center
                ) {
                    Image(
                        bitmap = displayBitmap.asImageBitmap(),
                        contentDescription = fileName,
                        modifier = Modifier
                            .fillMaxWidth()
                            .aspectRatio(displayBitmap.width.toFloat() / displayBitmap.height.toFloat(), matchHeightConstraintsFirst = false)
                            .graphicsLayer(
                                scaleX = scale,
                                scaleY = scale,
                                translationX = offset.x,
                                translationY = offset.y
                            )
                    )
                    
                    // 缩放提示
                    if (scale != 1f) {
                        Text(
                            text = "${(scale * 100).toInt()}%",
                            color = Color.White,
                            style = if (showWatermarkSettings) MaterialTheme.typography.bodySmall else MaterialTheme.typography.bodyLarge,
                            modifier = Modifier
                                .align(if (showWatermarkSettings) Alignment.TopEnd else Alignment.BottomCenter)
                                .padding(16.dp)
                                .background(Color.Black.copy(alpha = 0.7f), MaterialTheme.shapes.small)
                                .padding(horizontal = if (showWatermarkSettings) 12.dp else 16.dp, vertical = if (showWatermarkSettings) 6.dp else 8.dp)
                        )
                    }
                }
                
                // 水印设置面板
                AnimatedVisibility(
                    visible = showWatermarkSettings,
                    enter = slideInVertically(initialOffsetY = { it }),
                    exit = slideOutVertically(targetOffsetY = { it })
                ) {
                    WatermarkSettingsPanel(
                        enableWatermark = enableWatermark,
                        onEnableWatermarkChange = { enableWatermark = it },
                        watermarkText = watermarkText,
                        onWatermarkTextChange = { watermarkText = it },
                        fontSize = fontSize,
                        onFontSizeChange = { fontSize = it },
                        opacity = opacity,
                        onOpacityChange = { opacity = it },
                        lineSpacing = lineSpacing,
                        onLineSpacingChange = { lineSpacing = it }
                    )
                }
            }
        }
    }
}

/**
 * 水印设置面板（底部面板，与预览同屏）
 */
@Composable
private fun WatermarkSettingsPanel(
    enableWatermark: Boolean,
    onEnableWatermarkChange: (Boolean) -> Unit,
    watermarkText: String,
    onWatermarkTextChange: (String) -> Unit,
    fontSize: Float,
    onFontSizeChange: (Float) -> Unit,
    opacity: Float,
    onOpacityChange: (Float) -> Unit,
    lineSpacing: Float,
    onLineSpacingChange: (Float) -> Unit
) {
    val scrollState = rememberScrollState()
    
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(max = 500.dp), // 限制最大高度，避免遮挡顶部内容
        color = MaterialTheme.colorScheme.surfaceContainerHigh,
        shadowElevation = 24.dp,
        tonalElevation = 8.dp
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(scrollState) // 添加滚动功能
                .padding(horizontal = 20.dp, vertical = 24.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // 标题栏和开关
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = stringResource(R.string.watermark_settings),
                        style = MaterialTheme.typography.headlineSmall,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = stringResource(R.string.watermark_enable),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Switch(
                    checked = enableWatermark,
                    onCheckedChange = onEnableWatermarkChange
                )
            }
            
            Divider()

            if (enableWatermark) {
                // 水印文字输入
                OutlinedTextField(
                    value = watermarkText,
                    onValueChange = onWatermarkTextChange,
                    label = { Text(stringResource(R.string.watermark_text)) },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )

                // 字体大小
                Column {
                    Text(
                        text = stringResource(R.string.watermark_font_size, fontSize.toInt()),
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Slider(
                        value = fontSize,
                        onValueChange = onFontSizeChange,
                        valueRange = 40f..120f,
                        steps = 7
                    )
                }

                // 行间距
                Column {
                    val spacingLabel = when {
                        lineSpacing <= 1.0f -> stringResource(R.string.watermark_spacing_dense)
                        lineSpacing >= 2.0f -> stringResource(R.string.watermark_spacing_sparse)
                        else -> stringResource(R.string.watermark_spacing_normal)
                    }
                    Text(
                        text = "${stringResource(R.string.watermark_spacing)}: $spacingLabel",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        FilterChip(
                            selected = lineSpacing <= 1.0f,
                            onClick = { onLineSpacingChange(1.0f) },
                            label = { Text(stringResource(R.string.watermark_spacing_dense)) },
                            modifier = Modifier.weight(1f)
                        )
                        FilterChip(
                            selected = lineSpacing > 1.0f && lineSpacing < 2.0f,
                            onClick = { onLineSpacingChange(1.5f) },
                            label = { Text(stringResource(R.string.watermark_spacing_normal)) },
                            modifier = Modifier.weight(1f)
                        )
                        FilterChip(
                            selected = lineSpacing >= 2.0f,
                            onClick = { onLineSpacingChange(2.0f) },
                            label = { Text(stringResource(R.string.watermark_spacing_sparse)) },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }

                // 透明度
                Column {
                    Text(
                        text = stringResource(R.string.watermark_opacity, (opacity * 100).toInt()),
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Slider(
                        value = opacity,
                        onValueChange = onOpacityChange,
                        valueRange = 0.1f..0.8f
                    )
                }
            }
        }
    }
}
