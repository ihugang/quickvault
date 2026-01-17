package com.quickvault.presentation.screen.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.quickvault.BuildConfig
import com.quickvault.presentation.viewmodel.SettingsViewModel

/**
 * 设置界面
 * 对应 iOS 的 SettingsScreen
 *
 * 功能：
 * - 安全设置（生物识别、修改密码）
 * - 应用设置（自动锁定时间等）
 * - 关于应用
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateToUnlock: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val isBiometricEnabled by viewModel.isBiometricEnabled.collectAsState()
    val isBiometricAvailable by viewModel.isBiometricAvailable.collectAsState()

    var showChangePasswordDialog by remember { mutableStateOf(false) }
    var showAboutDialog by remember { mutableStateOf(false) }

    // 显示成功消息
    LaunchedEffect(uiState.successMessage) {
        uiState.successMessage?.let {
            kotlinx.coroutines.delay(2000)
            viewModel.clearSuccessMessage()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("设置 Settings") }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(vertical = 8.dp)
        ) {
            // 安全设置区域
            item {
                SectionHeader(title = "安全 Security")
            }

            // 生物识别开关
            if (isBiometricAvailable) {
                item {
                    SettingsSwitchItem(
                        title = "生物识别解锁",
                        subtitle = "使用指纹或面部识别 Use fingerprint or face",
                        icon = Icons.Default.Fingerprint,
                        checked = isBiometricEnabled,
                        onCheckedChange = { viewModel.toggleBiometric(it) }
                    )
                }
            }

            // 修改密码
            item {
                SettingsClickableItem(
                    title = "修改主密码",
                    subtitle = "Change master password",
                    icon = Icons.Default.Lock,
                    onClick = { showChangePasswordDialog = true }
                )
            }

            // 立即锁定
            item {
                SettingsClickableItem(
                    title = "立即锁定",
                    subtitle = "Lock app now",
                    icon = Icons.Default.LockClock,
                    onClick = {
                        viewModel.lockApp {
                            onNavigateToUnlock()
                        }
                    }
                )
            }

            item {
                Divider(modifier = Modifier.padding(vertical = 8.dp))
            }

            // 应用设置区域
            item {
                SectionHeader(title = "应用 Application")
            }

            // 关于
            item {
                SettingsClickableItem(
                    title = "关于 QuickVault",
                    subtitle = "版本、开源协议 Version, licenses",
                    icon = Icons.Default.Info,
                    onClick = { showAboutDialog = true }
                )
            }

            // 成功/错误消息
            if (uiState.successMessage != null || uiState.errorMessage != null) {
                item {
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = if (uiState.errorMessage != null) {
                                MaterialTheme.colorScheme.errorContainer
                            } else {
                                MaterialTheme.colorScheme.primaryContainer
                            }
                        )
                    ) {
                        Text(
                            text = uiState.successMessage ?: uiState.errorMessage ?: "",
                            modifier = Modifier.padding(16.dp),
                            color = if (uiState.errorMessage != null) {
                                MaterialTheme.colorScheme.onErrorContainer
                            } else {
                                MaterialTheme.colorScheme.onPrimaryContainer
                            }
                        )
                    }
                }
            }
        }
    }

    // 修改密码对话框
    if (showChangePasswordDialog) {
        ChangePasswordDialog(
            onDismiss = { showChangePasswordDialog = false },
            onConfirm = { current, new ->
                viewModel.changePassword(current, new) {
                    showChangePasswordDialog = false
                }
            },
            isLoading = uiState.isLoading
        )
    }

    // 关于对话框
    if (showAboutDialog) {
        AboutDialog(
            onDismiss = { showAboutDialog = false }
        )
    }
}

/**
 * 区域标题
 */
@Composable
fun SectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleSmall,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
    )
}

/**
 * 可点击的设置项
 */
@Composable
fun SettingsClickableItem(
    title: String,
    subtitle: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onClick: () -> Unit
) {
    ListItem(
        headlineContent = { Text(title) },
        supportingContent = { Text(subtitle) },
        leadingContent = {
            Icon(
                imageVector = icon,
                contentDescription = title,
                tint = MaterialTheme.colorScheme.primary
            )
        },
        trailingContent = {
            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = null
            )
        },
        modifier = Modifier.clickable { onClick() }
    )
}

/**
 * 开关设置项
 */
@Composable
fun SettingsSwitchItem(
    title: String,
    subtitle: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    ListItem(
        headlineContent = { Text(title) },
        supportingContent = { Text(subtitle) },
        leadingContent = {
            Icon(
                imageVector = icon,
                contentDescription = title,
                tint = MaterialTheme.colorScheme.primary
            )
        },
        trailingContent = {
            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange
            )
        }
    )
}

/**
 * 修改密码对话框
 */
@Composable
fun ChangePasswordDialog(
    onDismiss: () -> Unit,
    onConfirm: (String, String) -> Unit,
    isLoading: Boolean
) {
    var currentPassword by remember { mutableStateOf("") }
    var newPassword by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("修改主密码 Change Password") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = currentPassword,
                    onValueChange = {
                        currentPassword = it
                        error = null
                    },
                    label = { Text("当前密码 Current") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = newPassword,
                    onValueChange = {
                        newPassword = it
                        error = null
                    },
                    label = { Text("新密码 New (min 8 chars)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = confirmPassword,
                    onValueChange = {
                        confirmPassword = it
                        error = null
                    },
                    label = { Text("确认新密码 Confirm") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                if (error != null) {
                    Text(
                        text = error!!,
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    when {
                        currentPassword.isEmpty() -> error = "请输入当前密码"
                        newPassword.length < 8 -> error = "新密码至少8个字符"
                        newPassword != confirmPassword -> error = "密码不匹配"
                        else -> onConfirm(currentPassword, newPassword)
                    }
                },
                enabled = !isLoading
            ) {
                if (isLoading) {
                    CircularProgressIndicator(modifier = Modifier.size(20.dp))
                } else {
                    Text("确定 OK")
                }
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss, enabled = !isLoading) {
                Text("取消 Cancel")
            }
        }
    )
}

/**
 * 关于对话框
 */
@Composable
fun AboutDialog(
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        icon = {
            Icon(
                imageVector = Icons.Default.Shield,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.primary
            )
        },
        title = { Text("QuickVault 随取") },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(8.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "版本 Version: ${BuildConfig.VERSION_NAME}",
                    style = MaterialTheme.typography.bodyMedium
                )

                Divider(modifier = Modifier.padding(vertical = 8.dp))

                Text(
                    text = "安全的本地信息管理应用\nSecure local information manager",
                    style = MaterialTheme.typography.bodySmall,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center
                )

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = "• AES-256-GCM 加密\n• 本地优先，无云同步\n• 开源软件",
                    style = MaterialTheme.typography.bodySmall,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center
                )
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("关闭 Close")
            }
        }
    )
}
