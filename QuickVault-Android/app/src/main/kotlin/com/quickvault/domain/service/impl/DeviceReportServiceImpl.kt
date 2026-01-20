package com.quickvault.domain.service.impl

import android.content.Context
import android.os.Build
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.quickvault.data.model.DeviceReportRequestData
import com.quickvault.data.model.DeviceReportError
import com.quickvault.data.model.DeviceReportResponseData
import com.quickvault.data.model.ItemType
import com.quickvault.data.model.RemoteInvokeResults
import com.quickvault.domain.service.VersionInfo
import com.quickvault.data.repository.ItemRepository
import com.quickvault.domain.service.DeviceReportService
import com.quickvault.util.NetworkUtil
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.*
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 设备报告服务实现
 * Device Report Service Implementation
 */
@Singleton
class DeviceReportServiceImpl @Inject constructor(
    @ApplicationContext private val context: Context,
    private val itemRepository: ItemRepository
) : DeviceReportService {
    
    companion object {
        private const val TAG = "DeviceReportService"
        private const val API_BASE_URL = "https://api.apiandlogs.com/api"
        private const val APPLICATION_ID = "DD8CCB23-85C7-429A-A9D7-CCD1D7A28E8F"
        private const val DEVICE_ID_KEY = "report_device_id"
        private const val REPORT_STATUS_KEY = "has_reported_device"
        private const val ENCRYPTED_PREFS_NAME = "device_report_prefs"
        private const val LAST_VERSION_CHECK_KEY = "last_version_check"
    }
    
    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }
    
    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .build()
    
    private val encryptedPrefs by lazy {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        
        EncryptedSharedPreferences.create(
            context,
            ENCRYPTED_PREFS_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }
    
    override suspend fun reportDeviceIfNeeded(itemCount: Int) {
        Log.d(TAG, "Reporting device on app startup")
        
        try {
            val result = forceReportDevice(itemCount)
            if (result.isSuccess) {
                Log.d(TAG, "✅ Device report success")
            } else {
                Log.w(TAG, "⚠️ Device report failed: ${result.exceptionOrNull()?.message}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "⚠️ Device report error", e)
        }
    }
    
    override suspend fun forceReportDevice(itemCount: Int): Result<RemoteInvokeResults<DeviceReportResponseData>> {
        return withContext(Dispatchers.IO) {
            try {
                val itemCounts = getItemCounts()
                val payload = createReportPayload(
                    photoNum = itemCounts.image,
                    videoNum = itemCounts.text,
                    docNum = itemCounts.file
                )
                val response = sendReportRequest(payload)
                
                // 保存最新版本检查时间
                encryptedPrefs.edit()
                    .putLong(LAST_VERSION_CHECK_KEY, System.currentTimeMillis())
                    .apply()
                
                Result.success(response)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to report device", e)
                Result.failure(e)
            }
        }
    }
    
    override fun resetReportStatus() {
        encryptedPrefs.edit()
            .putBoolean(REPORT_STATUS_KEY, false)
            .apply()
        Log.d(TAG, "Reset report status for testing")
    }
    
    override fun getDeviceId(): String {
        var deviceId = encryptedPrefs.getString(DEVICE_ID_KEY, null)
        if (deviceId == null) {
            deviceId = UUID.randomUUID().toString()
            encryptedPrefs.edit()
                .putString(DEVICE_ID_KEY, deviceId)
                .apply()
            Log.d(TAG, "Generated new device ID: $deviceId")
        }
        return deviceId
    }
    
    private fun hasReportedDevice(): Boolean {
        val hasReported = encryptedPrefs.getBoolean(REPORT_STATUS_KEY, false)
        Log.d(TAG, "hasReportedDevice: $hasReported")
        return hasReported
    }
    
    private fun markDeviceAsReported() {
        encryptedPrefs.edit()
            .putBoolean(REPORT_STATUS_KEY, true)
            .apply()
        Log.d(TAG, "markDeviceAsReported: Device marked as reported")
    }
    
    private suspend fun createReportPayload(photoNum: Int, videoNum: Int, docNum: Int): DeviceReportRequestData {
        return DeviceReportRequestData(
            applicationId = APPLICATION_ID,
            deviceId = getDeviceId(),
            name = getDeviceName(),
            os = 2, // Android
            osName = "Android",
            osVersion = Build.VERSION.RELEASE,
            model = "${Build.MANUFACTURER} ${Build.MODEL}",
            localIp = NetworkUtil.getLocalIpAddress() ?: "",
            localPort = 0,
            appVersion = getAppVersion(),
            catId = "",
            catType = "",
            photoNum = photoNum,
            videoNum = videoNum,
            docNum = docNum,
            vipLevel = 0
        )
    }
    
    private suspend fun sendReportRequest(payload: DeviceReportRequestData): RemoteInvokeResults<DeviceReportResponseData> {
        val url = "$API_BASE_URL/Device/ReportDevice"
        val jsonPayload = json.encodeToString(DeviceReportRequestData.serializer(), payload)
        
        Log.d(TAG, "🌐 [DeviceReport] 请求: $url")
        Log.d(TAG, "   body: $jsonPayload")
        
        val requestBody = jsonPayload.toRequestBody("application/json".toMediaType())
        val request = Request.Builder()
            .url(url)
            .post(requestBody)
            .addHeader("Content-Type", "application/json")
            .addHeader("X-Application-Id", APPLICATION_ID)
            .build()
        
        val response = httpClient.newCall(request).execute()
        
        if (!response.isSuccessful) {
            Log.e(TAG, "Server error: ${response.code}")
            throw DeviceReportError.ServerError
        }
        
        val responseBody = response.body?.string() ?: throw DeviceReportError.NetworkError
        Log.d(TAG, "🔁 [DeviceReport] 响应(${response.code}): $responseBody")
        
        return try {
            json.decodeFromString<RemoteInvokeResults<DeviceReportResponseData>>(responseBody)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to decode response", e)
            throw DeviceReportError.DecodingError
        }
    }
    
    private fun getDeviceName(): String {
        return try {
            Build.MODEL ?: "Android Device"
        } catch (e: Exception) {
            "Android Device"
        }
    }
    
    private fun getAppVersion(): String {
        return try {
            val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
            "${packageInfo.versionName} (${packageInfo.longVersionCode})"
        } catch (e: Exception) {
            "1.0.0 (1)"
        }
    }
    
    private suspend fun getItemCounts(): ItemCounts {
        return withContext(Dispatchers.IO) {
            try {
                val textCount = itemRepository.countItemsByType(ItemType.TEXT)
                val imageCount = itemRepository.countItemsByType(ItemType.IMAGE)  
                val fileCount = itemRepository.countItemsByType(ItemType.FILE)
                
                ItemCounts(
                    text = textCount,
                    image = imageCount,
                    file = fileCount
                )
            } catch (e: Exception) {
                Log.e(TAG, "Failed to get item counts", e)
                ItemCounts(0, 0, 0)
            }
        }
    }
    
    override suspend fun checkVersionUpdate(): VersionInfo? {
        return withContext(Dispatchers.IO) {
            try {
                val result = forceReportDevice(0)
                if (result.isSuccess) {
                    val response = result.getOrNull()
                    val data = response?.data
                    if (data != null) {
                        val currentVersion = getAppVersion()
                        val latestVersion = data.newestVersion
                        val hasUpdate = compareVersions(currentVersion, latestVersion) < 0
                        
                        Log.d(TAG, "Version check: current=$currentVersion, latest=$latestVersion, hasUpdate=$hasUpdate")
                        
                        return@withContext VersionInfo(
                            currentVersion = currentVersion,
                            latestVersion = latestVersion,
                            hasUpdate = hasUpdate,
                            downloadUrl = data.downloadUrl
                        )
                    }
                }
                null
            } catch (e: Exception) {
                Log.e(TAG, "Failed to check version update", e)
                null
            }
        }
    }
    
    /**
     * 比较版本号
     * @return -1 if version1 < version2, 0 if equal, 1 if version1 > version2
     */
    private fun compareVersions(version1: String, version2: String): Int {
        try {
            val v1Parts = version1.split(".").map { it.toIntOrNull() ?: 0 }
            val v2Parts = version2.split(".").map { it.toIntOrNull() ?: 0 }
            
            val maxLength = maxOf(v1Parts.size, v2Parts.size)
            
            for (i in 0 until maxLength) {
                val v1Part = v1Parts.getOrElse(i) { 0 }
                val v2Part = v2Parts.getOrElse(i) { 0 }
                
                when {
                    v1Part < v2Part -> return -1
                    v1Part > v2Part -> return 1
                }
            }
            return 0
        } catch (e: Exception) {
            Log.e(TAG, "Failed to compare versions: $version1 vs $version2", e)
            return 0
        }
    }
    
    private data class ItemCounts(
        val text: Int,
        val image: Int,
        val file: Int
    )
}