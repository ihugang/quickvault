package com.quickvault.data.local.keystore

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.quickvault.util.Constants
import java.security.SecureRandom
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 安全密钥管理器
 * 使用 Android Keystore 和 EncryptedSharedPreferences 存储敏感数据
 * 对应 iOS 的 KeychainService
 */
@Singleton
class SecureKeyManager @Inject constructor(
    private val context: Context
) {
    private val masterKey: MasterKey by lazy {
        MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
    }

    private val encryptedPrefs: SharedPreferences by lazy {
        EncryptedSharedPreferences.create(
            context,
            "quickvault_secure_prefs",
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    companion object {
        private const val KEY_SALT = "crypto_salt"
        private const val KEY_PASSWORD_HASH = "password_hash"
        private const val KEY_MASTER_KEY = "master_key"
        private const val KEY_IS_SETUP = "is_setup"
        private const val KEY_BIOMETRIC_ENABLED = "biometric_enabled"
    }

    /**
     * 保存加密盐值
     * 对应 iOS 的 KeychainService.save(key:data:)
     */
    fun saveSalt(salt: ByteArray) {
        encryptedPrefs.edit()
            .putString(KEY_SALT, salt.toBase64())
            .apply()
    }

    /**
     * 获取加密盐值
     * 对应 iOS 的 KeychainService.load(key:)
     */
    fun getSalt(): ByteArray? {
        return encryptedPrefs.getString(KEY_SALT, null)?.fromBase64()
    }

    /**
     * 生成新的随机盐值
     */
    fun generateSalt(): ByteArray {
        val salt = ByteArray(Constants.SALT_LENGTH)
        SecureRandom().nextBytes(salt)
        return salt
    }

    /**
     * 保存密码哈希
     */
    fun savePasswordHash(hash: String) {
        encryptedPrefs.edit()
            .putString(KEY_PASSWORD_HASH, hash)
            .apply()
    }

    /**
     * 获取密码哈希
     */
    fun getPasswordHash(): String? {
        return encryptedPrefs.getString(KEY_PASSWORD_HASH, null)
    }

    /**
     * 保存主密钥
     */
    fun saveMasterKey(key: ByteArray) {
        encryptedPrefs.edit()
            .putString(KEY_MASTER_KEY, key.toBase64())
            .apply()
    }

    /**
     * 获取主密钥
     */
    fun getMasterKey(): ByteArray? {
        return encryptedPrefs.getString(KEY_MASTER_KEY, null)?.fromBase64()
    }

    /**
     * 标记应用已完成初始设置
     */
    fun markSetupComplete() {
        encryptedPrefs.edit()
            .putBoolean(KEY_IS_SETUP, true)
            .apply()
    }

    /**
     * 检查是否已完成初始设置
     */
    fun isSetupComplete(): Boolean {
        return encryptedPrefs.getBoolean(KEY_IS_SETUP, false)
    }

    /**
     * 保存生物识别启用状态
     */
    fun setBiometricEnabled(enabled: Boolean) {
        encryptedPrefs.edit()
            .putBoolean(KEY_BIOMETRIC_ENABLED, enabled)
            .apply()
    }

    /**
     * 检查生物识别是否启用
     */
    fun isBiometricEnabled(): Boolean {
        return encryptedPrefs.getBoolean(KEY_BIOMETRIC_ENABLED, true)
    }

    /**
     * 清除所有数据（用于重置应用）
     */
    fun clearAll() {
        encryptedPrefs.edit().clear().apply()
    }

    /**
     * 删除指定密钥
     */
    fun delete(key: String) {
        encryptedPrefs.edit().remove(key).apply()
    }

    // 扩展函数：ByteArray 转 Base64
    private fun ByteArray.toBase64(): String {
        return android.util.Base64.encodeToString(this, android.util.Base64.NO_WRAP)
    }

    // 扩展函数：Base64 转 ByteArray
    private fun String.fromBase64(): ByteArray {
        return android.util.Base64.decode(this, android.util.Base64.NO_WRAP)
    }
}
