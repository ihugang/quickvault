package com.quickvault.presentation.screen.settings

import android.app.Activity
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.quickvault.R
import com.quickvault.presentation.MainActivity
import com.quickvault.presentation.viewmodel.SettingsViewModel
import com.quickvault.util.LanguageManager
import com.quickvault.util.extensions.findActivity
import com.quickvault.domain.service.VersionInfo

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
    val context = LocalContext.current
    val activity = context.findActivity()
    val uriHandler = LocalUriHandler.current
    val uiState by viewModel.uiState.collectAsState()
    val isBiometricEnabled by viewModel.isBiometricEnabled.collectAsState()
    val isBiometricAvailable by viewModel.isBiometricAvailable.collectAsState()
    val currentLanguage by viewModel.currentLanguage.collectAsState()
    val currentTheme by viewModel.currentTheme.collectAsState()
    val versionInfo by viewModel.versionInfo.collectAsState()

    var showChangePasswordDialog by remember { mutableStateOf(false) }
    var showAboutDialog by remember { mutableStateOf(false) }
    var showLanguageDialog by remember { mutableStateOf(false) }
    var showThemeDialog by remember { mutableStateOf(false) }

    LaunchedEffect(showAboutDialog) {
        if (showAboutDialog) {
            viewModel.checkVersionUpdate()
        }
    }

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
                title = { Text(stringResource(R.string.settings_title)) }
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
                SectionHeader(title = stringResource(R.string.settings_security))
            }

            // 生物识别开关
            if (isBiometricAvailable) {
                item {
                    SettingsSwitchItem(
                        title = stringResource(R.string.settings_security_biometric),
                        subtitle = stringResource(R.string.settings_security_biometric_subtitle),
                        icon = Icons.Default.Fingerprint,
                        checked = isBiometricEnabled,
                        onCheckedChange = { viewModel.toggleBiometric(activity, it) }
                    )
                }
            }

            // 修改密码
            item {
                SettingsClickableItem(
                    title = stringResource(R.string.settings_security_changepassword),
                    subtitle = stringResource(R.string.settings_change_password_subtitle),
                    icon = Icons.Default.Lock,
                    onClick = { showChangePasswordDialog = true }
                )
            }

            // 立即锁定
            item {
                SettingsClickableItem(
                    title = stringResource(R.string.settings_lock_now_title),
                    subtitle = stringResource(R.string.settings_lock_now_subtitle),
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
                SectionHeader(title = stringResource(R.string.settings_app_section_title))
            }

            // 语言设置
            item {
                SettingsClickableItem(
                    title = stringResource(R.string.settings_language),
                    subtitle = currentLanguage.nativeName,
                    icon = Icons.Default.Language,
                    onClick = { showLanguageDialog = true }
                )
            }

            // 主题设置
            item {
                SettingsClickableItem(
                    title = stringResource(R.string.settings_theme),
                    subtitle = stringResource(
                        when (currentTheme) {
                            com.quickvault.util.ThemeMode.SYSTEM -> R.string.settings_theme_system
                            com.quickvault.util.ThemeMode.LIGHT -> R.string.settings_theme_light
                            com.quickvault.util.ThemeMode.DARK -> R.string.settings_theme_dark
                        }
                    ),
                    icon = Icons.Default.Palette,
                    onClick = { showThemeDialog = true }
                )
            }

            item {
                Divider(modifier = Modifier.padding(vertical = 8.dp))
            }

            // 开发者信息区域
            item {
                SectionHeader(title = "开发者信息 / Developer Info")
            }

            // 显示设备ID
            item {
                SettingsClickableItem(
                    title = "设备ID",
                    subtitle = viewModel.getDeviceId(),
                    icon = Icons.Default.PhoneAndroid,
                    onClick = { /* 可以复制到剪贴板 */ }
                )
            }

            // 关于
            item {
                SettingsClickableItem(
                    title = stringResource(R.string.settings_about),
                    subtitle = stringResource(R.string.settings_about_subtitle),
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
                            .padding(16.dp)
                            .clickable { viewModel.clearMessages() },
                        colors = CardDefaults.cardColors(
                            containerColor = if (uiState.errorMessage != null) {
                                MaterialTheme.colorScheme.errorContainer
                            } else {
                                MaterialTheme.colorScheme.primaryContainer
                            }
                        )
                    ) {
                        Row(
                            modifier = Modifier.padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = uiState.successMessage ?: uiState.errorMessage ?: "",
                                modifier = Modifier.weight(1f),
                                color = if (uiState.errorMessage != null) {
                                    MaterialTheme.colorScheme.onErrorContainer
                                } else {
                                    MaterialTheme.colorScheme.onPrimaryContainer
                                }
                            )
                            Icon(
                                imageVector = Icons.Default.Close,
                                contentDescription = "清除消息",
                                tint = if (uiState.errorMessage != null) {
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
            versionInfo = versionInfo,
            onDismiss = { showAboutDialog = false },
            onUpdateClick = {
                val url = if (!versionInfo?.downloadUrl.isNullOrBlank()) {
                    versionInfo?.downloadUrl ?: ""
                } else {
                    "https://timehound.vip"
                }
                if (url.isNotBlank()) {
                    uriHandler.openUri(url)
                }
            }
        )
    }

    // 语言选择对话框
    if (showLanguageDialog) {
        LanguageDialog(
            currentLanguage = currentLanguage,
            availableLanguages = viewModel.getAvailableLanguages(),
            onDismiss = { showLanguageDialog = false },
            onSelectLanguage = { language ->
                viewModel.setLanguage(language)
                showLanguageDialog = false
                // 重启Activity以应用语言更改
                (context as? Activity)?.let {
                    LanguageManager.restartActivity(it)
                }
            }
        )
    }

    // 主题选择对话框
    if (showThemeDialog) {
        ThemeDialog(
            currentTheme = currentTheme,
            onDismiss = { showThemeDialog = false },
            onSelectTheme = { theme ->
                viewModel.setTheme(theme)
                // 直接调用MainActivity的主题切换方法
                (activity as? MainActivity)?.updateTheme(theme)
                showThemeDialog = false
            }
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
    val currentPasswordRequired = stringResource(R.string.settings_change_password_error_current_required)
    val passwordTooShort = stringResource(R.string.settings_change_password_error_length)
    val passwordMismatch = stringResource(R.string.settings_change_password_error_mismatch)

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.settings_change_password_dialog_title)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = currentPassword,
                    onValueChange = {
                        currentPassword = it
                        error = null
                    },
                    label = { Text(stringResource(R.string.auth_change_current)) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = newPassword,
                    onValueChange = {
                        newPassword = it
                        error = null
                    },
                    label = { Text(stringResource(R.string.auth_change_new)) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = confirmPassword,
                    onValueChange = {
                        confirmPassword = it
                        error = null
                    },
                    label = { Text(stringResource(R.string.auth_change_confirm)) },
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
                        currentPassword.isEmpty() -> error = currentPasswordRequired
                        newPassword.length < 8 -> error = passwordTooShort
                        newPassword != confirmPassword -> error = passwordMismatch
                        else -> onConfirm(currentPassword, newPassword)
                    }
                },
                enabled = !isLoading
            ) {
                if (isLoading) {
                    CircularProgressIndicator(modifier = Modifier.size(20.dp))
                } else {
                    Text(stringResource(R.string.common_confirm))
                }
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss, enabled = !isLoading) {
                Text(stringResource(R.string.common_cancel))
            }
        }
    )
}

/**
 * 关于对话框
 */
@Composable
fun AboutDialog(
    versionInfo: VersionInfo?,
    onDismiss: () -> Unit,
    onUpdateClick: () -> Unit
) {
    val context = LocalContext.current
    val versionName = remember {
        runCatching {
            @Suppress("DEPRECATION")
            context.packageManager.getPackageInfo(context.packageName, 0).versionName
        }.getOrNull().orEmpty()
    }

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
        title = { Text(stringResource(R.string.app_name)) },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(8.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = stringResource(R.string.about_version, versionName),
                    style = MaterialTheme.typography.bodyMedium
                )

                if (versionInfo?.hasUpdate == true) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = stringResource(
                            R.string.about_update_available,
                            versionInfo.latestVersion
                        ),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.primary
                    )
                    TextButton(onClick = onUpdateClick) {
                        Text(stringResource(R.string.about_update_action))
                    }
                }

                Divider(modifier = Modifier.padding(vertical = 8.dp))

                Text(
                    text = stringResource(R.string.about_description),
                    style = MaterialTheme.typography.bodySmall,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center
                )

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = stringResource(R.string.about_features),
                    style = MaterialTheme.typography.bodySmall,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center
                )
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.common_close))
            }
        }
    )
}

/**
 * 语言选择对话框
 */
@Composable
fun LanguageDialog(
    currentLanguage: LanguageManager.Language,
    availableLanguages: List<LanguageManager.Language>,
    onDismiss: () -> Unit,
    onSelectLanguage: (LanguageManager.Language) -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        icon = {
            Icon(
                imageVector = Icons.Default.Language,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
        },
        title = { Text(stringResource(R.string.settings_language_select_title)) },
        text = {
            Column {
                availableLanguages.forEach { language ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onSelectLanguage(language) }
                            .padding(vertical = 12.dp, horizontal = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = language.nativeName,
                                style = MaterialTheme.typography.bodyLarge
                            )
                            Text(
                                text = language.displayName,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }

                        if (language == currentLanguage) {
                            Icon(
                                imageVector = Icons.Default.Check,
                                contentDescription = stringResource(R.string.common_selected),
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.common_cancel))
            }
        }
    )
}

/**
 * 主题选择对话框
 */
@Composable
fun ThemeDialog(
    currentTheme: com.quickvault.util.ThemeMode,
    onDismiss: () -> Unit,
    onSelectTheme: (com.quickvault.util.ThemeMode) -> Unit
) {
    val themes = listOf(
        com.quickvault.util.ThemeMode.SYSTEM to R.string.settings_theme_system,
        com.quickvault.util.ThemeMode.LIGHT to R.string.settings_theme_light,
        com.quickvault.util.ThemeMode.DARK to R.string.settings_theme_dark
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        icon = {
            Icon(
                imageVector = Icons.Default.Palette,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
        },
        title = { Text(stringResource(R.string.settings_theme_select_title)) },
        text = {
            Column {
                themes.forEach { (theme, nameRes) ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onSelectTheme(theme) }
                            .padding(vertical = 12.dp, horizontal = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = stringResource(nameRes),
                            style = MaterialTheme.typography.bodyLarge,
                            modifier = Modifier.weight(1f)
                        )

                        if (theme == currentTheme) {
                            Icon(
                                imageVector = Icons.Default.Check,
                                contentDescription = stringResource(R.string.common_selected),
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.common_cancel))
            }
        },
        confirmButton = {}
    )
}
