package com.quickvault.presentation.viewmodel

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.quickvault.data.local.keystore.SecureKeyManager
import com.quickvault.domain.service.AuthService
import com.quickvault.domain.service.BiometricService
import com.quickvault.domain.service.DeviceReportService
import com.quickvault.util.LanguageManager
import com.quickvault.util.ThemeManager
import com.quickvault.util.ThemeMode
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 设置界面 ViewModel
 * 对应 iOS 的 SettingsViewModel
 *
 * 职责：
 * - 管理应用设置（生物识别、自动锁定等）
 * - 修改主密码
 * - 应用信息展示
 */
@HiltViewModel
class SettingsViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val authService: AuthService,
    private val biometricService: BiometricService,
    private val keyManager: SecureKeyManager,
    private val themeManager: ThemeManager,
    private val deviceReportService: DeviceReportService
) : ViewModel() {

    // UI 状态
    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    // 生物识别是否启用
    private val _isBiometricEnabled = MutableStateFlow(false)
    val isBiometricEnabled: StateFlow<Boolean> = _isBiometricEnabled.asStateFlow()

    // 生物识别是否可用
    private val _isBiometricAvailable = MutableStateFlow(false)
    val isBiometricAvailable: StateFlow<Boolean> = _isBiometricAvailable.asStateFlow()

    // 当前语言
    private val _currentLanguage = MutableStateFlow(LanguageManager.getCurrentLanguage(context))
    val currentLanguage: StateFlow<LanguageManager.Language> = _currentLanguage.asStateFlow()

    // 当前主题模式
    private val _currentTheme = MutableStateFlow(themeManager.getThemeMode())
    val currentTheme: StateFlow<ThemeMode> = _currentTheme.asStateFlow()

    init {
        checkBiometricAvailability()
        loadSettings()
    }

    /**
     * 检查生物识别可用性
     */
    private fun checkBiometricAvailability() {
        viewModelScope.launch {
            val available = biometricService.isBiometricAvailable()
            _isBiometricAvailable.value = available
        }
    }

    /**
     * 加载设置
     */
    private fun loadSettings() {
        _isBiometricEnabled.value = keyManager.isBiometricEnabled()
    }

    /**
     * 切换生物识别
     */
    fun toggleBiometric(activity: android.app.Activity?, enable: Boolean) {
        viewModelScope.launch {
            if (enable) {
                // 验证生物识别后启用
                biometricService.authenticate(activity)
                    .onSuccess { success ->
                        if (success) {
                            // TODO: 实现 enableBiometric() 方法
                            // authService.enableBiometric()
                            _isBiometricEnabled.value = true
                            _uiState.update {
                                it.copy(successMessage = context.getString(com.quickvault.R.string.settings_security_biometric_enabled))
                            }
                        }
                    }
                    .onFailure { error ->
                        _uiState.update {
                            it.copy(
                                errorMessage = error.message
                                    ?: context.getString(com.quickvault.R.string.settings_biometric_enable_failed)
                            )
                        }
                    }
            } else {
                // TODO: 实现 disableBiometric() 方法
                // authService.disableBiometric()
                _isBiometricEnabled.value = false
                _uiState.update {
                    it.copy(successMessage = context.getString(com.quickvault.R.string.settings_security_biometric_disabled))
                }
            }
        }
    }

    /**
     * 修改密码
     */
    fun changePassword(
        currentPassword: String,
        newPassword: String,
        onSuccess: () -> Unit
    ) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }

            authService.changePassword(currentPassword, newPassword)
                .onSuccess {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            successMessage = context.getString(com.quickvault.R.string.auth_change_success)
                        )
                    }
                    onSuccess()
                }
                .onFailure { error ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            errorMessage = error.message ?: context.getString(com.quickvault.R.string.auth_change_failed)
                        )
                    }
                }
        }
    }

    /**
     * 锁定应用
     */
    fun lockApp(onLocked: () -> Unit) {
        authService.lock()
        onLocked()
    }

    /**
     * 清除成功消息
     */
    fun clearSuccessMessage() {
        _uiState.update { it.copy(successMessage = null) }
    }

    /**
     * 清除错误消息
     */
    fun clearErrorMessage() {
        _uiState.update { it.copy(errorMessage = null) }
    }

    /**
     * 设置语言
     */
    fun setLanguage(language: LanguageManager.Language) {
        LanguageManager.setLanguage(context, language)
        _currentLanguage.value = language
    }

    /**
     * 获取所有可用语言
     */
    fun getAvailableLanguages(): List<LanguageManager.Language> {
        return LanguageManager.Language.getAllLanguages()
    }

    /**
     * 设置主题模式
     */
    fun setTheme(mode: ThemeMode) {
        themeManager.setThemeMode(mode)
        _currentTheme.value = mode
    }
    
    /**
     * 强制报告设备信息（用于测试）
     */
    fun forceReportDevice() {
        viewModelScope.launch {
            try {
                _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
                
                val result = deviceReportService.forceReportDevice()
                if (result.isSuccess) {
                    val response = result.getOrNull()
                    if (response?.success == true) {
                        val hostCount = response.data?.hosts?.size ?: 0
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            successMessage = "设备报告成功！发现 $hostCount 个远程主机"
                        )
                    } else {
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            errorMessage = "设备报告失败: ${response?.errorMessage ?: "未知错误"}"
                        )
                    }
                } else {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        errorMessage = "设备报告失败: ${result.exceptionOrNull()?.message}"
                    )
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "设备报告错误: ${e.message}"
                )
            }
        }
    }
    
    /**
     * 重置设备报告状态
     */
    fun resetDeviceReportStatus() {
        deviceReportService.resetReportStatus()
        _uiState.value = _uiState.value.copy(
            successMessage = "设备报告状态已重置"
        )
    }
    
    /**
     * 获取设备ID
     */
    fun getDeviceId(): String {
        return deviceReportService.getDeviceId()
    }
    
    /**
     * 清除消息状态
     */
    fun clearMessages() {
        _uiState.value = _uiState.value.copy(
            errorMessage = null,
            successMessage = null
        )
    }
}

/**
 * 设置 UI 状态
 */
data class SettingsUiState(
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val successMessage: String? = null
)
