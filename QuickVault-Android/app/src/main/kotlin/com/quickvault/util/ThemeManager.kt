package com.quickvault.util

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 主题模式枚举
 */
enum class ThemeMode {
    SYSTEM,  // 跟随系统
    LIGHT,   // 浅色模式
    DARK;    // 深色模式

    companion object {
        fun fromString(value: String?): ThemeMode {
            return when (value) {
                "LIGHT" -> LIGHT
                "DARK" -> DARK
                else -> SYSTEM
            }
        }
    }
}

/**
 * 主题管理器
 * 负责保存和读取用户的主题偏好设置
 */
@Singleton
class ThemeManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private const val PREF_NAME = "theme_preferences"
        private const val KEY_THEME_MODE = "theme_mode"
    }

    private val prefs by lazy {
        context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    }

    /**
     * 获取当前主题模式
     */
    fun getThemeMode(): ThemeMode {
        val value = prefs.getString(KEY_THEME_MODE, null)
        return ThemeMode.fromString(value)
    }

    /**
     * 设置主题模式
     */
    fun setThemeMode(mode: ThemeMode) {
        prefs.edit()
            .putString(KEY_THEME_MODE, mode.name)
            .apply()
    }
}
