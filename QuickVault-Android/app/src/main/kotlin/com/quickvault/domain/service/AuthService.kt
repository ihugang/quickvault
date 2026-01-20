package com.quickvault.domain.service

/**
 * 认证服务接口
 * 对应 iOS 的 AuthenticationService protocol
 */
interface AuthService {

    /**
     * 检查是否已设置主密码
     */
    suspend fun isSetup(): Boolean

    /**
     * 设置主密码（首次使用）
     * 对应 iOS 的 setupMasterPassword(_:)
     */
    suspend fun setupMasterPassword(password: String): Result<Unit>

    /**
     * 使用密码认证
     * 对应 iOS 的 authenticateWithPassword(_:)
     */
    suspend fun authenticateWithPassword(password: String): Result<Unit>

    /**
     * 使用生物识别认证
     * 对应 iOS 的 authenticateWithBiometric()
     * @param activity 用于显示生物识别提示的 Activity（可选）
     */
    suspend fun authenticateWithBiometric(activity: android.app.Activity? = null): Result<Unit>

    /**
     * 修改主密码
     * 对应 iOS 的 changePassword(oldPassword:newPassword:)
     */
    suspend fun changePassword(oldPassword: String, newPassword: String): Result<Unit>

    /**
     * 锁定应用
     * 对应 iOS 的 lock()
     */
    fun lock()

    /**
     * 检查是否已锁定
     */
    fun isLocked(): Boolean

    /**
     * 验证密码强度
     */
    fun validatePassword(password: String): Result<Unit>
}

/**
 * 认证状态
 * 对应 iOS 的 AuthenticationState
 */
enum class AuthState {
    LOCKED,
    UNLOCKED,
    NOT_SETUP
}
