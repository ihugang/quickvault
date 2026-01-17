package com.quickvault.domain.service.impl

import android.content.Context
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import com.quickvault.R
import com.quickvault.domain.service.BiometricService
import com.quickvault.domain.service.BiometricType
import kotlinx.coroutines.suspendCancellableCoroutine
import javax.inject.Inject
import kotlin.coroutines.resume

/**
 * 生物识别服务实现
 * 使用 AndroidX BiometricPrompt API
 * 对应 iOS 的 LocalAuthentication
 */
class BiometricServiceImpl @Inject constructor(
    private val context: Context
) : BiometricService {

    private val biometricManager = BiometricManager.from(context)

    /**
     * 检查设备是否支持生物识别
     * 对应 iOS 的 LAContext.canEvaluatePolicy
     */
    override fun isBiometricAvailable(): Boolean {
        val result = biometricManager.canAuthenticate(
            Authenticators.BIOMETRIC_STRONG or Authenticators.DEVICE_CREDENTIAL
        )
        return result == BiometricManager.BIOMETRIC_SUCCESS
    }

    /**
     * 执行生物识别认证
     * 对应 iOS 的 LAContext.evaluatePolicy
     */
    override suspend fun authenticate(): Result<Boolean> {
        if (!isBiometricAvailable()) {
            return Result.failure(BiometricException("生物识别不可用 Biometric not available"))
        }

        // 需要 FragmentActivity 上下文
        val activity = context as? FragmentActivity
            ?: return Result.failure(BiometricException("需要 Activity 上下文 Activity context required"))

        return suspendCancellableCoroutine { continuation ->
            val executor = ContextCompat.getMainExecutor(context)

            val promptInfo = BiometricPrompt.PromptInfo.Builder()
                .setTitle(context.getString(R.string.auth_biometric_title))
                .setSubtitle(context.getString(R.string.auth_biometric_subtitle))
                .setAllowedAuthenticators(
                    Authenticators.BIOMETRIC_STRONG or Authenticators.DEVICE_CREDENTIAL
                )
                .build()

            val biometricPrompt = BiometricPrompt(
                activity,
                executor,
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                        super.onAuthenticationSucceeded(result)
                        if (continuation.isActive) {
                            continuation.resume(Result.success(true))
                        }
                    }

                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                        super.onAuthenticationError(errorCode, errString)
                        if (continuation.isActive) {
                            val message = when (errorCode) {
                                BiometricPrompt.ERROR_CANCELED -> "用户取消 User canceled"
                                BiometricPrompt.ERROR_USER_CANCELED -> "用户取消 User canceled"
                                BiometricPrompt.ERROR_LOCKOUT -> "尝试次数过多，已锁定 Too many attempts"
                                BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> "永久锁定 Permanently locked"
                                BiometricPrompt.ERROR_NO_BIOMETRICS -> "未录入生物识别 No biometrics enrolled"
                                else -> errString.toString()
                            }
                            continuation.resume(Result.failure(BiometricException(message)))
                        }
                    }

                    override fun onAuthenticationFailed() {
                        super.onAuthenticationFailed()
                        // 单次失败，不终止流程
                    }
                }
            )

            // 取消协程时取消生物识别提示
            continuation.invokeOnCancellation {
                biometricPrompt.cancelAuthentication()
            }

            biometricPrompt.authenticate(promptInfo)
        }
    }

    /**
     * 获取生物识别类型
     */
    override fun getBiometricType(): BiometricType {
        return when (biometricManager.canAuthenticate(Authenticators.BIOMETRIC_STRONG)) {
            BiometricManager.BIOMETRIC_SUCCESS -> {
                // 检测具体类型（需要更多逻辑）
                BiometricType.FINGERPRINT  // 默认返回指纹
            }
            else -> BiometricType.NONE
        }
    }
}

/**
 * 生物识别异常
 */
class BiometricException(message: String) : Exception(message)
