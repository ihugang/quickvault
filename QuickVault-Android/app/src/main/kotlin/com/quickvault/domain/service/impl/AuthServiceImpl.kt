package com.quickvault.domain.service.impl

import android.content.Context
import com.quickvault.R
import com.quickvault.data.local.keystore.SecureKeyManager
import com.quickvault.domain.service.AuthService
import com.quickvault.domain.service.AuthState
import com.quickvault.domain.service.BiometricService
import com.quickvault.domain.service.CryptoService
import com.quickvault.util.Constants
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 认证服务实现
 * 对应 iOS 的 AuthenticationService
 */
@Singleton
class AuthServiceImpl @Inject constructor(
    private val keyManager: SecureKeyManager,
    private val cryptoService: CryptoService,
    private val biometricService: BiometricService,
    @ApplicationContext private val context: Context
) : AuthService {

    private val _authState = MutableStateFlow(AuthState.LOCKED)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()

    private var failedAttempts = 0
    private var lastFailedTime = 0L

    /**
     * 检查是否已设置主密码
     * 对应 iOS 的检查 Keychain 中是否有密码
     */
    override suspend fun isSetup(): Boolean {
        return keyManager.isSetupComplete()
    }

    /**
     * 设置主密码（首次使用）
     * 对应 iOS 的 setupMasterPassword(_:)
     */
    override suspend fun setupMasterPassword(password: String): Result<Unit> {
        return try {
            // 1. 验证密码强度
            validatePassword(password).getOrThrow()

            // 2. 生成盐值
            val salt = cryptoService.generateSalt()
            keyManager.saveSalt(salt)

            // 3. 派生主密钥
            val masterKey = cryptoService.deriveKey(password, salt)
            keyManager.saveMasterKey(masterKey)

            // 4. 保存密码哈希（用于验证）
            val passwordHash = cryptoService.hashPassword(password)
            keyManager.savePasswordHash(passwordHash)

            // 5. 标记已完成设置
            keyManager.markSetupComplete()

            // 6. 解锁应用
            _authState.value = AuthState.UNLOCKED

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(
                AuthException(
                    context.getString(R.string.auth_error_setup_failed, e.message ?: ""),
                    e
                )
            )
        }
    }

    /**
     * 使用密码认证
     * 对应 iOS 的 authenticateWithPassword(_:)
     */
    override suspend fun authenticateWithPassword(password: String): Result<Unit> {
        return try {
            // 1. 检查失败重试限制
            checkFailedAttempts()

            // 2. 验证密码
            val passwordHash = cryptoService.hashPassword(password)
            val storedHash = keyManager.getPasswordHash()
                ?: return Result.failure(
                    AuthException(context.getString(R.string.auth_error_no_password))
                )

            if (passwordHash != storedHash) {
                // 密码错误
                failedAttempts++
                lastFailedTime = System.currentTimeMillis()

                val remainingAttempts = Constants.MAX_AUTH_ATTEMPTS - failedAttempts
                if (remainingAttempts > 0) {
                    return Result.failure(
                        AuthException(
                            context.getString(
                                R.string.auth_error_wrong_password_attempts,
                                remainingAttempts
                            )
                        )
                    )
                } else {
                    return Result.failure(
                        AuthException(context.getString(R.string.auth_error_rate_limited, 30))
                    )
                }
            }

            // 3. 密码正确，解锁
            failedAttempts = 0
            _authState.value = AuthState.UNLOCKED

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(
                AuthException(
                    context.getString(R.string.auth_error_authentication_failed, e.message ?: ""),
                    e
                )
            )
        }
    }

    /**
     * 使用生物识别认证
     * 对应 iOS 的 authenticateWithBiometric()
     * @param activity 用于显示生物识别提示的 Activity
     */
    override suspend fun authenticateWithBiometric(activity: android.app.Activity?): Result<Unit> {
        return try {
            // 1. 检查是否启用生物识别
            if (!keyManager.isBiometricEnabled()) {
                return Result.failure(
                    AuthException(context.getString(R.string.auth_error_biometric_not_enabled))
                )
            }

            // 2. 检查设备支持
            if (!biometricService.isBiometricAvailable()) {
                return Result.failure(
                    AuthException(context.getString(R.string.auth_error_biometric_unavailable))
                )
            }

            // 3. 执行生物识别（传递 Activity）
            val result = biometricService.authenticate(activity)

            if (result.isSuccess) {
                _authState.value = AuthState.UNLOCKED
                failedAttempts = 0
                Result.success(Unit)
            } else {
                Result.failure(
                    result.exceptionOrNull()
                        ?: AuthException(context.getString(R.string.auth_error_biometric_failed))
                )
            }
        } catch (e: Exception) {
            Result.failure(
                AuthException(
                    context.getString(
                        R.string.auth_error_biometric_failed_with_reason,
                        e.message ?: ""
                    ),
                    e
                )
            )
        }
    }

    /**
     * 修改主密码
     * 对应 iOS 的 changePassword(oldPassword:newPassword:)
     */
    override suspend fun changePassword(oldPassword: String, newPassword: String): Result<Unit> {
        return try {
            // 1. 验证旧密码
            val oldHash = cryptoService.hashPassword(oldPassword)
            val storedHash = keyManager.getPasswordHash()
                ?: return Result.failure(
                    AuthException(context.getString(R.string.auth_error_no_password))
                )

            if (oldHash != storedHash) {
                return Result.failure(
                    AuthException(context.getString(R.string.auth_error_old_password_incorrect))
                )
            }

            // 2. 验证新密码强度
            validatePassword(newPassword).getOrThrow()

            // 3. 生成新的盐值和密钥
            val salt = cryptoService.generateSalt()
            keyManager.saveSalt(salt)

            val masterKey = cryptoService.deriveKey(newPassword, salt)
            keyManager.saveMasterKey(masterKey)

            // 4. 保存新密码哈希
            val newHash = cryptoService.hashPassword(newPassword)
            keyManager.savePasswordHash(newHash)

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(
                AuthException(
                    context.getString(
                        R.string.auth_error_change_password_failed,
                        e.message ?: ""
                    ),
                    e
                )
            )
        }
    }

    /**
     * 锁定应用
     * 对应 iOS 的 lock()
     */
    override fun lock() {
        _authState.value = AuthState.LOCKED
        failedAttempts = 0
    }

    /**
     * 检查是否已锁定
     */
    override fun isLocked(): Boolean {
        return _authState.value == AuthState.LOCKED
    }

    /**
     * 验证密码强度
     */
    override fun validatePassword(password: String): Result<Unit> {
        return when {
            password.length < Constants.MIN_PASSWORD_LENGTH -> {
                Result.failure(
                    AuthException(context.getString(R.string.auth_error_password_too_short))
                )
            }
            else -> Result.success(Unit)
        }
    }

    /**
     * 检查失败重试限制
     */
    private fun checkFailedAttempts() {
        if (failedAttempts >= Constants.MAX_AUTH_ATTEMPTS) {
            val elapsed = System.currentTimeMillis() - lastFailedTime
            if (elapsed < Constants.AUTH_DELAY_MS) {
                val remainingSeconds = (Constants.AUTH_DELAY_MS - elapsed) / 1000
                throw AuthException(
                    context.getString(R.string.auth_error_rate_limited, remainingSeconds)
                )
            } else {
                // 延迟时间已过，重置计数
                failedAttempts = 0
            }
        }
    }
}

/**
 * 认证异常
 */
class AuthException(message: String, cause: Throwable? = null) : Exception(message, cause)
