package com.quickvault.domain.validation

import android.content.Context
import com.quickvault.R
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 数据验证服务
 * 对应 iOS 的 ValidationService
 */
@Singleton
class ValidationService @Inject constructor(
    @ApplicationContext private val context: Context
) {

    /**
     * 验证手机号格式
     * 支持中国手机号（11 位，以 1 开头）
     * 对应 iOS 的手机号验证
     */
    fun validatePhoneNumber(phone: String): ValidationResult {
        if (phone.isBlank()) {
            return ValidationResult.Error(context.getString(R.string.validation_phone_required))
        }

        // 中国手机号：11 位，以 1 开头
        val phoneRegex = "^1[3-9]\\d{9}$".toRegex()
        if (!phone.matches(phoneRegex)) {
            return ValidationResult.Error(context.getString(R.string.validation_phone_invalid))
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
            return ValidationResult.Error(context.getString(R.string.validation_taxid_required))
        }

        // 统一社会信用代码：18 位数字或大写字母
        if (taxId.length != 18) {
            return ValidationResult.Error(context.getString(R.string.validation_taxid_length))
        }

        val taxIdRegex = "^[0-9A-Z]{18}$".toRegex()
        if (!taxId.matches(taxIdRegex)) {
            return ValidationResult.Error(context.getString(R.string.validation_taxid_invalid))
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
            return ValidationResult.Error(context.getString(R.string.validation_postal_invalid))
        }

        return ValidationResult.Valid
    }

    /**
     * 验证必填字段
     */
    fun validateRequired(value: String, fieldName: String): ValidationResult {
        if (value.isBlank()) {
            return ValidationResult.Error(context.getString(R.string.validation_required_field, fieldName))
        }
        return ValidationResult.Valid
    }

    /**
     * 验证卡片标题
     */
    fun validateCardTitle(title: String): ValidationResult {
        if (title.isBlank()) {
            return ValidationResult.Error(context.getString(R.string.validation_title_required))
        }

        if (title.length > 100) {
            return ValidationResult.Error(context.getString(R.string.validation_title_too_long, 100))
        }

        return ValidationResult.Valid
    }

    /**
     * 验证银行账号格式
     * 中国银行账号：通常 16-19 位数字
     */
    fun validateBankAccount(account: String): ValidationResult {
        if (account.isBlank()) {
            return ValidationResult.Error(context.getString(R.string.validation_bank_required))
        }

        val accountRegex = "^\\d{16,19}$".toRegex()
        if (!account.matches(accountRegex)) {
            return ValidationResult.Error(context.getString(R.string.validation_bank_invalid))
        }

        return ValidationResult.Valid
    }

    /**
     * 验证附件文件大小
     */
    fun validateFileSize(sizeInBytes: Long, maxSizeInBytes: Long = 10 * 1024 * 1024): ValidationResult {
        if (sizeInBytes > maxSizeInBytes) {
            val maxMB = maxSizeInBytes / (1024 * 1024)
            return ValidationResult.Error(context.getString(R.string.validation_file_too_large, maxMB))
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
