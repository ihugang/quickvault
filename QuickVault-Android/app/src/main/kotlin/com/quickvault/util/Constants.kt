package com.quickvault.util

/**
 * 应用常量
 * 对应 iOS 的 Consts.swift
 */
object Constants {
    // Database
    const val DATABASE_NAME = "quickvault.db"
    const val DATABASE_VERSION = 1

    // Encryption
    const val PBKDF2_ITERATIONS = 100_000
    const val AES_KEY_SIZE = 256
    const val SALT_LENGTH = 32

    // Keystore
    const val KEYSTORE_ALIAS = "quickvault_master_key"
    const val CRYPTO_PREFS_NAME = "crypto_prefs"
    const val KEYSET_NAME = "keyset"
    const val KEYSET_PREF_NAME = "keyset_prefs"

    // Authentication
    const val MAX_AUTH_ATTEMPTS = 3
    const val AUTH_DELAY_MS = 30_000L // 30 seconds
    const val MIN_PASSWORD_LENGTH = 8

    // Auto Lock
    const val DEFAULT_LOCK_TIMEOUT_MS = 5 * 60 * 1000L // 5 minutes

    // Attachments
    const val MAX_ATTACHMENT_SIZE = 10 * 1024 * 1024 // 10MB

    // Watermark
    const val WATERMARK_DEFAULT_OPACITY = 0.3f
    const val WATERMARK_DEFAULT_ANGLE = -45f
    const val WATERMARK_DEFAULT_FONT_SIZE = 80f

    // Card Types
    const val CARD_TYPE_ADDRESS = "Address"
    const val CARD_TYPE_INVOICE = "Invoice"
    const val CARD_TYPE_GENERAL = "GeneralText"

    // Card Groups
    const val GROUP_PERSONAL = "Personal"
    const val GROUP_COMPANY = "Company"
}
