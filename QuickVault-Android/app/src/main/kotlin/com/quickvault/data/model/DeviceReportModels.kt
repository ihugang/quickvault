package com.quickvault.data.model

import kotlinx.serialization.Serializable
import java.util.*

/**
 * 设备报告请求数据模型
 * Device Report Request Data Model
 */
@Serializable
data class DeviceReportRequestData(
    val applicationId: String,
    val deviceId: String,
    val name: String,
    val os: Byte, // iOS = 1, Android = 2, macOS = 3
    val osName: String,
    val osVersion: String,
    val model: String,
    val localIp: String = "",
    val localPort: Int = 0,
    val appVersion: String,
    val catId: String = "",
    val catType: String = "",
    val photoNum: Int,
    val videoNum: Int,
    val docNum: Int,
    val vipLevel: Byte = 0
)

/**
 * 远程主机信息
 */
@Serializable
data class RemoteHost(
    val deviceId: String,
    val ip: String,
    val port: Int,
    val name: String
)

/**
 * 远程主机列表响应
 */
@Serializable
data class RemoteHosts(
    val hosts: List<RemoteHost>? = null,
    val wanIp: String? = null
)

/**
 * API响应结果模型
 */
@Serializable
data class RemoteInvokeResults<T>(
    val success: Boolean = false,
    val errorNumber: Int = 0,
    val errorMessage: String? = null,
    val data: T? = null
)

/**
 * 设备报告错误类型
 */
sealed class DeviceReportError : Exception() {
    object ServerError : DeviceReportError()
    object NetworkError : DeviceReportError()
    object DecodingError : DeviceReportError()
    
    override val message: String
        get() = when (this) {
            is ServerError -> "服务器错误 / Server error"
            is NetworkError -> "网络错误 / Network error"
            is DecodingError -> "数据解析错误 / Decoding error"
        }
}