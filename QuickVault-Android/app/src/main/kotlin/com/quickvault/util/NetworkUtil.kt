package com.quickvault.util

import android.util.Log
import java.net.InetAddress
import java.net.NetworkInterface
import java.util.*

/**
 * 网络工具类
 * Network Utility Class
 */
object NetworkUtil {
    
    private const val TAG = "NetworkUtil"
    
    /**
     * 获取本地IP地址
     * Get local IP address
     */
    fun getLocalIpAddress(): String? {
        try {
            val interfaces = Collections.list(NetworkInterface.getNetworkInterfaces())
            for (networkInterface in interfaces) {
                if (networkInterface.name.lowercase(Locale.getDefault()).contains("wlan") ||
                    networkInterface.name.lowercase(Locale.getDefault()).contains("eth")) {
                    
                    val addresses = Collections.list(networkInterface.inetAddresses)
                    for (address in addresses) {
                        if (!address.isLoopbackAddress && 
                            address is InetAddress && 
                            !address.hostAddress.contains(":")) {
                            return address.hostAddress
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get local IP address", e)
        }
        return null
    }
    
    /**
     * 检查是否为有效的IP地址
     * Check if IP address is valid
     */
    fun isValidIpAddress(ip: String?): Boolean {
        if (ip.isNullOrBlank()) return false
        
        return try {
            val parts = ip.split(".")
            if (parts.size != 4) return false
            
            parts.all { part ->
                val num = part.toIntOrNull()
                num != null && num in 0..255
            }
        } catch (e: Exception) {
            false
        }
    }
}