package com.quickvault.presentation.lifecycle

import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.quickvault.domain.service.AuthService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 应用生命周期观察者
 * 对应 iOS 的 SceneDelegate / AppDelegate 生命周期
 *
 * 功能：
 * - 应用进入后台时自动锁定
 * - 超时自动锁定（可配置）
 */
@Singleton
class AppLifecycleObserver @Inject constructor(
    private val authService: AuthService
) : DefaultLifecycleObserver {

    companion object {
        private const val AUTO_LOCK_TIMEOUT_MS = 5 * 60 * 1000L // 5 分钟
    }

    private val scope = CoroutineScope(Dispatchers.Main + Job())
    private var autoLockJob: Job? = null
    private var backgroundTimestamp: Long = 0

    /**
     * 应用进入前台
     * 对应 iOS 的 sceneWillEnterForeground
     */
    override fun onStart(owner: LifecycleOwner) {
        super.onStart(owner)

        // 取消自动锁定计时器
        autoLockJob?.cancel()
        autoLockJob = null

        // 检查是否需要锁定（基于后台时长）
        if (backgroundTimestamp > 0) {
            val backgroundDuration = System.currentTimeMillis() - backgroundTimestamp
            if (backgroundDuration > AUTO_LOCK_TIMEOUT_MS) {
                // 超时，锁定应用
                authService.lock()
            }
            backgroundTimestamp = 0
        }
    }

    /**
     * 应用进入后台
     * 对应 iOS 的 sceneDidEnterBackground
     */
    override fun onStop(owner: LifecycleOwner) {
        super.onStop(owner)

        // 记录进入后台的时间
        backgroundTimestamp = System.currentTimeMillis()

        // 启动自动锁定计时器
        startAutoLockTimer()
    }

    /**
     * 应用销毁
     */
    override fun onDestroy(owner: LifecycleOwner) {
        super.onDestroy(owner)
        autoLockJob?.cancel()
    }

    /**
     * 启动自动锁定计时器
     * 对应 iOS 的自动锁定逻辑
     */
    private fun startAutoLockTimer() {
        autoLockJob = scope.launch {
            delay(AUTO_LOCK_TIMEOUT_MS)
            // 超时后锁定
            authService.lock()
        }
    }

    /**
     * 重置自动锁定计时器
     * 在用户活动时调用（可选）
     */
    fun resetAutoLockTimer() {
        autoLockJob?.cancel()
        startAutoLockTimer()
    }

    /**
     * 立即锁定
     */
    fun lockNow() {
        autoLockJob?.cancel()
        authService.lock()
    }
}
