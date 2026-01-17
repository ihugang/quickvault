package com.quickvault.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.quickvault.data.local.keystore.SecureKeyManager
import com.quickvault.domain.service.AuthService
import com.quickvault.domain.service.BiometricService
import dagger.hilt.android.lifecycle.HiltViewModel
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
    private val authService: AuthService,
    private val biometricService: BiometricService,
    private val keyManager: SecureKeyManager
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

    init {
        checkBiometricAvailability()
        loadSettings()
    }

    /**
     * 检查生物识别可用性
     */
    private fun checkBiometricAvailability() {
        viewModelScope.launch {
            biometricService.isBiometricAvailable()
                .onSuccess { available ->
                    _isBiometricAvailable.value = available
                }
                .onFailure {
                    _isBiometricAvailable.value = false
                }
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
    fun toggleBiometric(enable: Boolean) {
        viewModelScope.launch {
            if (enable) {
                // 验证生物识别后启用
                biometricService.authenticate()
                    .onSuccess { success ->
                        if (success) {
                            authService.enableBiometric()
                            _isBiometricEnabled.value = true
                            _uiState.update {
                                it.copy(successMessage = "生物识别已启用 Biometric enabled")
                            }
                        }
                    }
                    .onFailure { error ->
                        _uiState.update {
                            it.copy(errorMessage = error.message ?: "启用失败 Failed to enable")
                        }
                    }
            } else {
                authService.disableBiometric()
                _isBiometricEnabled.value = false
                _uiState.update {
                    it.copy(successMessage = "生物识别已禁用 Biometric disabled")
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
                            successMessage = "密码已修改 Password changed"
                        )
                    }
                    onSuccess()
                }
                .onFailure { error ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            errorMessage = error.message ?: "修改失败 Failed to change"
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
}

/**
 * 设置 UI 状态
 */
data class SettingsUiState(
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val successMessage: String? = null
)
