package com.quickvault.domain.validation

import javax.inject.Inject
import javax.inject.Singleton

/**
 * 数据验证服务
 * 对应 iOS 的 ValidationService
 */
@Singleton
class ValidationService @Inject constructor() {

    /**
     * 验证手机号格式
     * 支持中国手机号（11 位，以 1 开头）
     * 对应 iOS 的手机号验证
     */
    fun validatePhoneNumber(phone: String): ValidationResult {
        if (phone.isBlank()) {
            return ValidationResult.Error("手机号不能为空 Phone number cannot be empty")
        }

        // 中国手机号：11 位，以 1 开头
        val phoneRegex = "^1[3-9]\\d{9}$".toRegex()
        if (!phone.matches(phoneRegex)) {
            return ValidationResult.Error("手机号格式错误，应为 11 位数字 Invalid phone format (11 digits starting with 1)")
        }

        return ValidationResult.Valid
    }

    /**
     * 验证税号格式
     * 中国统一社会信用代码：18 位
     * 对应 iOS 的税号验证
     */
    fun validateTaxId(taxId: String): ValidationResult {
        if (taxId.isBlank()) {
            return ValidationResult.Error("税号不能为空 Tax ID cannot be empty")
        }

        // 统一社会信用代码：18 位数字或大写字母
        if (taxId.length != 18) {
            return ValidationResult.Error("税号应为 18 位统一社会信用代码 Tax ID should be 18 characters")
        }

        val taxIdRegex = "^[0-9A-Z]{18}$".toRegex()
        if (!taxId.matches(taxIdRegex)) {
            return ValidationResult.Error("税号格式错误 Invalid tax ID format")
        }

        return ValidationResult.Valid
    }

    /**
     * 验证邮编格式
     * 中国邮编：6 位数字
     */
    fun validatePostalCode(postalCode: String): ValidationResult {
        if (postalCode.isBlank()) {
            return ValidationResult.Valid  // 邮编是可选字段
        }

        val postalCodeRegex = "^\\d{6}$".toRegex()
        if (!postalCode.matches(postalCodeRegex)) {
            return ValidationResult.Error("邮编应为 6 位数字 Postal code should be 6 digits")
        }

        return ValidationResult.Valid
    }

    /**
     * 验证必填字段
     */
    fun validateRequired(value: String, fieldName: String): ValidationResult {
        if (value.isBlank()) {
            return ValidationResult.Error("$fieldName 不能为空 $fieldName cannot be empty")
        }
        return ValidationResult.Valid
    }

    /**
     * 验证卡片标题
     */
    fun validateCardTitle(title: String): ValidationResult {
        if (title.isBlank()) {
            return ValidationResult.Error("标题不能为空 Title cannot be empty")
        }

        if (title.length > 100) {
            return ValidationResult.Error("标题过长（最多 100 字符）Title too long (max 100 chars)")
        }

        return ValidationResult.Valid
    }

    /**
     * 验证银行账号格式
     * 中国银行账号：通常 16-19 位数字
     */
    fun validateBankAccount(account: String): ValidationResult {
        if (account.isBlank()) {
            return ValidationResult.Error("银行账号不能为空 Bank account cannot be empty")
        }

        val accountRegex = "^\\d{16,19}$".toRegex()
        if (!account.matches(accountRegex)) {
            return ValidationResult.Error("银行账号格式错误（16-19 位数字）Invalid bank account (16-19 digits)")
        }

        return ValidationResult.Valid
    }

    /**
     * 验证附件文件大小
     */
    fun validateFileSize(sizeInBytes: Long, maxSizeInBytes: Long = 10 * 1024 * 1024): ValidationResult {
        if (sizeInBytes > maxSizeInBytes) {
            val maxMB = maxSizeInBytes / (1024 * 1024)
            return ValidationResult.Error("文件过大（最大 ${maxMB}MB）File too large (max ${maxMB}MB)")
        }
        return ValidationResult.Valid
    }
}

/**
 * 验证结果
 */
sealed class ValidationResult {
    object Valid : ValidationResult()
    data class Error(val message: String) : ValidationResult()

    fun isValid(): Boolean = this is Valid
    fun getErrorMessage(): String? = (this as? Error)?.message
}
