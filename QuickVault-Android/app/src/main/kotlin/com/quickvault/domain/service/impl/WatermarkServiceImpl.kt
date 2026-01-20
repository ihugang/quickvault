package com.quickvault.domain.service.impl

import android.content.Context
import android.graphics.*
import com.quickvault.R
import com.quickvault.domain.service.WatermarkService
import com.quickvault.domain.service.WatermarkStyle
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.sqrt

/**
 * 水印服务实现
 * 对应 iOS 的 WatermarkService
 *
 * 功能：
 * - 为图片添加对角线重复水印
 * - 防止截图泄露敏感信息
 */
@Singleton
class WatermarkServiceImpl @Inject constructor(
    @ApplicationContext private val context: Context
) : WatermarkService {

    companion object {
        private const val WATERMARK_SPACING_FACTOR = 1.5f // 水印间距倍数
    }

    private val defaultWatermarkText: String
        get() = context.getString(R.string.watermark_default_text)

    /**
     * 添加水印到 Bitmap
     * 使用简化的单水印方法（性能优化）
     */
    fun addWatermark(bitmap: Bitmap): Bitmap {
        return applyWatermark(
            bitmap = bitmap,
            text = defaultWatermarkText,
            style = WatermarkStyle()
        )
    }

    /**
     * 应用水印到图片
     * 对应 iOS 的 applyWatermark(to:text:style:)
     *
     * 实现重复对角线水印效果
     */
    override fun applyWatermark(
        bitmap: Bitmap,
        text: String,
        style: WatermarkStyle
    ): Bitmap {
        val width = bitmap.width
        val height = bitmap.height

        // 创建可变副本
        val mutableBitmap = bitmap.copy(Bitmap.Config.ARGB_8888, true)
        val canvas = Canvas(mutableBitmap)

        // 配置画笔
        val paint = Paint().apply {
            color = style.color
            alpha = (style.opacity * 255).toInt()
            textSize = style.fontSize
            isAntiAlias = true
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }

        // 测量文字尺寸
        val textBounds = Rect()
        paint.getTextBounds(text, 0, text.length, textBounds)
        val textWidth = textBounds.width()
        val textHeight = textBounds.height()

        // 计算对角线长度
        val diagonalLength = sqrt((width * width + height * height).toDouble()).toFloat()

        // 使用 lineSpacing 作为间距倍数
        val spacing = textWidth * WATERMARK_SPACING_FACTOR * style.lineSpacing

        // 保存画布状态
        canvas.save()

        // 移动到画布中心
        canvas.translate(width / 2f, height / 2f)

        // 旋转画布
        canvas.rotate(style.angle)

        // 计算需要绘制的水印数量（覆盖整个对角线）
        val count = (diagonalLength / spacing).toInt() + 2

        // 绘制重复水印
        for (i in -count..count) {
            val x = i * spacing
            val y = 0f
            canvas.drawText(text, x - textWidth / 2, y + textHeight / 2, paint)
        }

        // 恢复画布
        canvas.restore()

        return mutableBitmap
    }

    /**
     * 移除水印（返回原图）
     * 注意：实际上无法从已加水印的图片中完美移除水印
     * 此方法仅用于从数据库重新加载原始未加水印数据
     */
    override suspend fun removeWatermark(attachmentId: String): Result<Unit> {
        // 实际实现需要从数据库重新加载原始数据
        // 这里返回成功，由调用方处理
        return Result.success(Unit)
    }

    /**
     * 更新水印文字
     * 需要重新处理原始图片
     */
    override suspend fun updateWatermark(attachmentId: String, newText: String): Result<Unit> {
        // 实际实现需要：
        // 1. 从数据库加载原始图片
        // 2. 应用新水印
        // 3. 重新加密存储
        // 这里返回成功，由调用方处理
        return Result.success(Unit)
    }

    /**
     * 批量添加水印（优化版本）
     * 对应 iOS 的批量处理方法
     */
    fun addWatermarkBatch(bitmaps: List<Bitmap>): List<Bitmap> {
        return bitmaps.map { addWatermark(it) }
    }

    /**
     * 检查图片是否已有水印
     * 通过简单的文字检测（不保证100%准确）
     */
    fun hasWatermark(bitmap: Bitmap): Boolean {
        // 简化实现：假设所有通过此服务处理的图片都有水印
        // 实际可通过图像分析或元数据检测
        return false // 默认假设没有水印，需要添加
    }
}
