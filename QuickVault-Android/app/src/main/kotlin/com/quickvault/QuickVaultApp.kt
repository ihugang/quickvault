package com.quickvault

import android.app.Application
import com.quickvault.domain.service.DeviceReportService
import dagger.hilt.android.HiltAndroidApp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * QuickVault Application 类
 * 对应 iOS 的 @main struct QuickVaultApp
 */
@HiltAndroidApp
class QuickVaultApp : Application() {

    @Inject
    lateinit var deviceReportService: DeviceReportService
    
    private val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onCreate() {
        super.onCreate()
        
        // 报告设备信息到云端
        applicationScope.launch {
            deviceReportService.reportDeviceIfNeeded()
        }
    }
}
