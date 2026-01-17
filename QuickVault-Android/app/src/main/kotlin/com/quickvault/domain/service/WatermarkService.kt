package com.quickvault.domain.service

import android.graphics.Bitmap

/**
 * 水印服务接口（Android 独有，对应 iOS 的 WatermarkService）
 */
interface WatermarkService {

    /**
     * 应用水印到图片
     * 对应 iOS 的 applyWatermark(to:text:style:)
     */
    fun applyWatermark(
        bitmap: Bitmap,
        text: String,
        style: WatermarkStyle = WatermarkStyle()
    ): Bitmap

    /**
     * 移除水印（返回原图）
     */
    suspend fun removeWatermark(attachmentId: String): Result<Unit>

    /**
     * 更新水印文字
     */
    suspend fun updateWatermark(attachmentId: String, newText: String): Result<Unit>
}

/**
 * 水印样式
 * 对应 iOS 的 WatermarkStyle struct
 */
data class WatermarkStyle(
    val fontSize: Float = 80f,
    val opacity: Float = 0.3f,
    val angle: Float = -45f,  // 对角线 -45 度
    val color: Int = android.graphics.Color.GRAY
)
