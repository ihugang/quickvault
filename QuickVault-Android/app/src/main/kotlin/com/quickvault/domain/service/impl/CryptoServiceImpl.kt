package com.quickvault.domain.service.impl

import android.content.Context
import com.google.crypto.tink.Aead
import com.google.crypto.tink.KeyTemplates
import com.google.crypto.tink.aead.AeadConfig
import com.google.crypto.tink.integration.android.AndroidKeysetManager
import com.quickvault.R
import com.quickvault.data.local.keystore.SecureKeyManager
import com.quickvault.domain.service.CryptoService
import com.quickvault.util.Constants
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 加密服务实现
 * 使用 Tink 库提供 AES-256-GCM 加密
 * 对应 iOS 的 CryptoServiceImpl
 */
@Singleton
class CryptoServiceImpl @Inject constructor(
    private val context: Context,
    private val keyManager: SecureKeyManager
) : CryptoService {

    private val aead: Aead by lazy {
        AeadConfig.register()

        val keysetManager = AndroidKeysetManager.Builder()
            .withSharedPref(context, Constants.KEYSET_NAME, Constants.KEYSET_PREF_NAME)
            .withKeyTemplate(KeyTemplates.get("AES256_GCM"))
            .withMasterKeyUri("android-keystore://${Constants.KEYSTORE_ALIAS}")
            .build()

        keysetManager.keysetHandle.getPrimitive(Aead::class.java)
    }

    /**
     * 加密字符串
     * 对应 iOS 的 func encrypt(_ data: String) throws -> Data
     */
    override suspend fun encrypt(data: String): ByteArray = withContext(Dispatchers.IO) {
        try {
            val plaintext = data.toByteArray(Charsets.UTF_8)
            aead.encrypt(plaintext, null)
        } catch (e: Exception) {
            throw CryptoException(
                context.getString(R.string.crypto_error_encrypt, e.message ?: ""),
                e
            )
        }
    }

    /**
     * 解密字符串
     * 对应 iOS 的 func decrypt(_ data: Data) throws -> String
     */
    override suspend fun decrypt(data: ByteArray): String = withContext(Dispatchers.IO) {
        try {
            val plaintext = aead.decrypt(data, null)
            String(plaintext, Charsets.UTF_8)
        } catch (e: Exception) {
            throw CryptoException(
                context.getString(R.string.crypto_error_decrypt, e.message ?: ""),
                e
            )
        }
    }

    /**
     * 加密文件数据（用于附件）
     * 对应 iOS 的 func encryptFile(_ data: Data) throws -> Data
     */
    override suspend fun encryptFile(data: ByteArray): ByteArray = withContext(Dispatchers.IO) {
        try {
            aead.encrypt(data, null)
        } catch (e: Exception) {
            throw CryptoException(
                context.getString(R.string.crypto_error_encrypt_file, e.message ?: ""),
                e
            )
        }
    }

    /**
     * 解密文件数据
     * 对应 iOS 的 func decryptFile(_ data: Data) throws -> Data
     */
    override suspend fun decryptFile(data: ByteArray): ByteArray = withContext(Dispatchers.IO) {
        try {
            aead.decrypt(data, null)
        } catch (e: Exception) {
            throw CryptoException(
                context.getString(R.string.crypto_error_decrypt_file, e.message ?: ""),
                e
            )
        }
    }

    /**
     * 从密码派生密钥（PBKDF2-HMAC-SHA256）
     * 对应 iOS 的 func deriveKey(from password: String, salt: Data) throws -> SymmetricKey
     *
     * 使用 100,000 次迭代，与 iOS 保持一致
     */
    override fun deriveKey(password: String, salt: ByteArray): ByteArray {
        try {
            val spec = PBEKeySpec(
                password.toCharArray(),
                salt,
                Constants.PBKDF2_ITERATIONS,
                Constants.AES_KEY_SIZE
            )
            val factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
            return factory.generateSecret(spec).encoded
        } catch (e: Exception) {
            throw CryptoException(
                context.getString(R.string.crypto_error_derive_key, e.message ?: ""),
                e
            )
        }
    }

    /**
     * 生成随机盐值
     * 对应 iOS 的 func generateSalt() -> Data
     */
    override fun generateSalt(): ByteArray {
        return keyManager.generateSalt()
    }

    /**
     * 哈希密码（SHA-256）
     * 用于验证密码，不用于加密
     */
    override fun hashPassword(password: String): String {
        try {
            val digest = MessageDigest.getInstance("SHA-256")
            val hash = digest.digest(password.toByteArray(Charsets.UTF_8))
            return hash.joinToString("") { "%02x".format(it) }
        } catch (e: Exception) {
            throw CryptoException(
                context.getString(R.string.crypto_error_hash_password, e.message ?: ""),
                e
            )
        }
    }
}

/**
 * 加密异常
 */
class CryptoException(message: String, cause: Throwable? = null) : Exception(message, cause)
