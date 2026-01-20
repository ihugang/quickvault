package com.quickvault.util

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.os.LocaleList
import androidx.core.os.ConfigurationCompat
import java.util.Locale

/**
 * 语言管理器
 * 管理应用的多语言切换
 */
object LanguageManager {

    private const val PREF_NAME = "language_settings"
    private const val KEY_LANGUAGE = "selected_language"

    /**
     * 支持的语言列表
     */
    enum class Language(
        val code: String,
        val displayName: String,
        val nativeName: String
    ) {
        ENGLISH("en", "English", "English"),
        CHINESE_SIMPLIFIED("zh", "Chinese Simplified", "简体中文");

        companion object {
            fun fromCode(code: String): Language? {
                return values().find { it.code.equals(code, ignoreCase = true) }
            }

            /**
             * 获取所有支持的语言列表
             */
            fun getAllLanguages(): List<Language> {
                return values().toList()
            }
        }
    }

    /**
     * 获取当前设置的语言
     * 如果未设置，返回系统默认语言
     */
    fun getCurrentLanguage(context: Context): Language {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        val savedCode = prefs.getString(KEY_LANGUAGE, null)

        return if (savedCode != null) {
            Language.fromCode(savedCode) ?: getSystemLanguage()
        } else {
            getSystemLanguage()
        }
    }

    /**
     * 获取系统默认语言
     */
    fun getSystemLanguage(): Language {
        val systemLocale = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            LocaleList.getDefault()[0]
        } else {
            Locale.getDefault()
        }

        return when (systemLocale.language) {
            "zh" -> Language.CHINESE_SIMPLIFIED
            else -> Language.ENGLISH
        }
    }

    /**
     * 设置应用语言
     */
    fun setLanguage(context: Context, language: Language) {
        // 保存语言设置
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_LANGUAGE, language.code).apply()

        // 应用语言设置
        applyLanguage(context, language)
    }

    /**
     * 应用语言设置到 Context
     */
    fun applyLanguage(context: Context, language: Language) {
        val locale = createLocale(language.code)
        Locale.setDefault(locale)

        val config = Configuration(context.resources.configuration)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            config.setLocale(locale)
            config.setLocales(LocaleList(locale))
        } else {
            @Suppress("DEPRECATION")
            config.locale = locale
        }

        @Suppress("DEPRECATION")
        context.resources.updateConfiguration(config, context.resources.displayMetrics)
    }

    /**
     * 创建 Locale 对象
     */
    private fun createLocale(languageCode: String): Locale {
        return when {
            languageCode.contains("-r") -> {
                // 处理 zh-rTW, pt-rBR 等格式
                val parts = languageCode.split("-r")
                Locale(parts[0], parts[1])
            }
            languageCode.contains("_") -> {
                // 处理 zh_TW, pt_BR 等格式
                val parts = languageCode.split("_")
                Locale(parts[0], parts[1])
            }
            else -> Locale(languageCode)
        }
    }

    /**
     * 重启当前 Activity 以应用语言更改
     */
    fun restartActivity(activity: Activity) {
        val intent = activity.intent
        activity.finish()
        activity.startActivity(intent)
    }

    /**
     * 获取适用于当前 Context 的 Context（应用了语言设置）
     */
    fun wrap(context: Context): Context {
        val language = getCurrentLanguage(context)
        val locale = createLocale(language.code)

        val config = Configuration(context.resources.configuration)
        Locale.setDefault(locale)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            config.setLocale(locale)
            config.setLocales(LocaleList(locale))
        } else {
            @Suppress("DEPRECATION")
            config.locale = locale
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
            context.createConfigurationContext(config)
        } else {
            @Suppress("DEPRECATION")
            context.resources.updateConfiguration(config, context.resources.displayMetrics)
            context
        }
    }
}
