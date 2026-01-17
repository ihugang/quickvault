package com.quickvault.domain.service.impl

import com.quickvault.data.local.keystore.SecureKeyManager
import com.quickvault.domain.service.AuthService
import com.quickvault.domain.service.AuthState
import com.quickvault.domain.service.BiometricService
import com.quickvault.domain.service.CryptoService
import com.quickvault.util.Constants
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
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
    private val biometricService: BiometricService
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
            Result.failure(AuthException("设置密码失败 Setup failed: ${e.message}", e))
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
                ?: return Result.failure(AuthException("未找到密码 Password not found"))

            if (passwordHash != storedHash) {
                // 密码错误
                failedAttempts++
                lastFailedTime = System.currentTimeMillis()

                val remainingAttempts = Constants.MAX_AUTH_ATTEMPTS - failedAttempts
                if (remainingAttempts > 0) {
                    return Result.failure(
                        AuthException("密码错误，剩余 $remainingAttempts 次尝试 Wrong password, $remainingAttempts attempts left")
                    )
                } else {
                    return Result.failure(
                        AuthException("密码错误次数过多，请等待 30 秒 Too many attempts, wait 30s")
                    )
                }
            }

            // 3. 密码正确，解锁
            failedAttempts = 0
            _authState.value = AuthState.UNLOCKED

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(AuthException("认证失败 Authentication failed: ${e.message}", e))
        }
    }

    /**
     * 使用生物识别认证
     * 对应 iOS 的 authenticateWithBiometric()
     */
    override suspend fun authenticateWithBiometric(): Result<Unit> {
        return try {
            // 1. 检查是否启用生物识别
            if (!keyManager.isBiometricEnabled()) {
                return Result.failure(AuthException("生物识别未启用 Biometric not enabled"))
            }

            // 2. 检查设备支持
            if (!biometricService.isBiometricAvailable()) {
                return Result.failure(AuthException("设备不支持生物识别 Biometric not available"))
            }

            // 3. 执行生物识别
            val result = biometricService.authenticate()

            if (result.isSuccess) {
                _authState.value = AuthState.UNLOCKED
                failedAttempts = 0
                Result.success(Unit)
            } else {
                Result.failure(result.exceptionOrNull() ?: AuthException("生物识别失败 Biometric failed"))
            }
        } catch (e: Exception) {
            Result.failure(AuthException("生物识别认证失败 Biometric auth failed: ${e.message}", e))
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
                ?: return Result.failure(AuthException("未找到密码 Password not found"))

            if (oldHash != storedHash) {
                return Result.failure(AuthException("旧密码错误 Old password incorrect"))
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
            Result.failure(AuthException("修改密码失败 Change password failed: ${e.message}", e))
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
                    AuthException("密码至少需要 ${Constants.MIN_PASSWORD_LENGTH} 个字符 Password must be at least ${Constants.MIN_PASSWORD_LENGTH} characters")
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
                throw AuthException("请等待 $remainingSeconds 秒后重试 Wait $remainingSeconds seconds")
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
