package com.quickvault.presentation.screen.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.quickvault.domain.service.AuthService
import com.quickvault.domain.service.AuthState
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 认证 ViewModel
 * 对应 iOS 的 AuthViewModel
 */
@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authService: AuthService
) : ViewModel() {

    // UI 状态
    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    // 检查是否已设置密码
    init {
        viewModelScope.launch {
            val isSetup = authService.isSetup()
            _uiState.update { it.copy(isSetup = isSetup) }
        }
    }

    /**
     * 设置主密码（首次使用）
     */
    fun setupPassword(password: String, confirmPassword: String) {
        if (password != confirmPassword) {
            _uiState.update {
                it.copy(errorMessage = "密码不匹配 Passwords do not match")
            }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }

            val result = authService.setupMasterPassword(password)

            _uiState.update {
                if (result.isSuccess) {
                    it.copy(
                        isLoading = false,
                        isAuthenticated = true,
                        isSetup = true
                    )
                } else {
                    it.copy(
                        isLoading = false,
                        errorMessage = result.exceptionOrNull()?.message ?: "设置失败 Setup failed"
                    )
                }
            }
        }
    }

    /**
     * 使用密码解锁
     */
    fun unlockWithPassword(password: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }

            val result = authService.authenticateWithPassword(password)

            _uiState.update {
                if (result.isSuccess) {
                    it.copy(
                        isLoading = false,
                        isAuthenticated = true
                    )
                } else {
                    it.copy(
                        isLoading = false,
                        errorMessage = result.exceptionOrNull()?.message ?: "认证失败 Auth failed"
                    )
                }
            }
        }
    }

    /**
     * 使用生物识别解锁
     */
    fun unlockWithBiometric() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }

            val result = authService.authenticateWithBiometric()

            _uiState.update {
                if (result.isSuccess) {
                    it.copy(
                        isLoading = false,
                        isAuthenticated = true
                    )
                } else {
                    it.copy(
                        isLoading = false,
                        errorMessage = result.exceptionOrNull()?.message
                    )
                }
            }
        }
    }

    /**
     * 锁定应用
     */
    fun lock() {
        authService.lock()
        _uiState.update {
            it.copy(isAuthenticated = false)
        }
    }

    /**
     * 清除错误消息
     */
    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }
}

/**
 * 认证 UI 状态
 */
data class AuthUiState(
    val isLoading: Boolean = false,
    val isAuthenticated: Boolean = false,
    val isSetup: Boolean = false,
    val errorMessage: String? = null
)
