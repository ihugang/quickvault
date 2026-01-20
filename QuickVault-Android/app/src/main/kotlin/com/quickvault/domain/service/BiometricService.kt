package com.quickvault.domain.service

/**
 * 生物识别服务接口
 * 对应 iOS 的 LocalAuthentication framework
 */
interface BiometricService {

    /**
     * 检查设备是否支持生物识别
     */
    fun isBiometricAvailable(): Boolean

    /**
     * 执行生物识别认证
     * 对应 iOS 的 LAContext.evaluatePolicy
     * @param activity 用于显示生物识别提示的 Activity（可选）
     */
    suspend fun authenticate(activity: android.app.Activity? = null): Result<Boolean>

    /**
     * 获取生物识别类型（指纹、面部等）
     */
    fun getBiometricType(): BiometricType
}

/**
 * 生物识别类型
 */
enum class BiometricType {
    NONE,           // 不支持
    FINGERPRINT,    // 指纹
    FACE,           // 面部识别
    IRIS,           // 虹膜
    UNKNOWN         // 未知类型
}
