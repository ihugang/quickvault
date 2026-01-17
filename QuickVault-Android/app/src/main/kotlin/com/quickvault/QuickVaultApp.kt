package com.quickvault

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/**
 * QuickVault Application 类
 * 对应 iOS 的 @main struct QuickVaultApp
 */
@HiltAndroidApp
class QuickVaultApp : Application() {

    override fun onCreate() {
        super.onCreate()
        // TODO: 初始化配置
    }
}
