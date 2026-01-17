package com.quickvault.domain.service

/**
 * 加密服务接口
 * 对应 iOS 的 CryptoService protocol
 */
interface CryptoService {

    /**
     * 加密字符串
     * 对应 iOS 的 encrypt(_:)
     */
    suspend fun encrypt(data: String): ByteArray

    /**
     * 解密字符串
     * 对应 iOS 的 decrypt(_:)
     */
    suspend fun decrypt(data: ByteArray): String

    /**
     * 加密文件数据（用于附件）
     * 对应 iOS 的 encryptFile(_:)
     */
    suspend fun encryptFile(data: ByteArray): ByteArray

    /**
     * 解密文件数据
     * 对应 iOS 的 decryptFile(_:)
     */
    suspend fun decryptFile(data: ByteArray): ByteArray

    /**
     * 从密码派生密钥（PBKDF2）
     * 对应 iOS 的 deriveKey(from:salt:)
     */
    fun deriveKey(password: String, salt: ByteArray): ByteArray

    /**
     * 生成随机盐值
     */
    fun generateSalt(): ByteArray

    /**
     * 哈希密码
     */
    fun hashPassword(password: String): String
}
