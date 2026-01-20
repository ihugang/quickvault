package com.quickvault.domain.service

import com.quickvault.data.model.RemoteHosts
import com.quickvault.data.model.RemoteInvokeResults

/**
 * 设备报告服务接口
 * Device Report Service Interface
 */
interface DeviceReportService {
    /**
     * 如果需要则报告设备信息到云端
     * Report device information to cloud if needed
     */
    suspend fun reportDeviceIfNeeded(itemCount: Int = 0)
    
    /**
     * 强制报告设备信息（用于测试）
     * Force report device information (for testing)
     */
    suspend fun forceReportDevice(itemCount: Int = 0): Result<RemoteInvokeResults<RemoteHosts>>
    
    /**
     * 重置报告状态（用于测试）
     * Reset report status (for testing)
     */
    fun resetReportStatus()
    
    /**
     * 获取设备ID
     * Get device ID
     */
    fun getDeviceId(): String
}