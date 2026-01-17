package com.quickvault.domain.service.impl

import com.quickvault.data.model.CardDTO
import com.quickvault.data.model.CardFieldDTO
import com.quickvault.data.repository.CardRepository
import com.quickvault.domain.service.CardService
import com.quickvault.domain.validation.ValidationResult
import com.quickvault.domain.validation.ValidationService
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 卡片服务实现
 * 对应 iOS 的 CardService implementation
 *
 * 职责：
 * - 业务逻辑验证（标题、必填字段、格式验证）
 * - 模板特定验证（地址、发票、通用文本）
 * - 包装 Repository 调用并返回 Result
 */
@Singleton
class CardServiceImpl @Inject constructor(
    private val cardRepository: CardRepository,
    private val validationService: ValidationService
) : CardService {

    companion object {
        // 卡片类型常量 - 对应 iOS 的 CardType enum
        const val CARD_TYPE_ADDRESS = "address"
        const val CARD_TYPE_INVOICE = "invoice"
        const val CARD_TYPE_GENERAL = "general"

        // 地址卡片字段 key
        private const val FIELD_RECIPIENT = "recipient"
        private const val FIELD_PHONE = "phone"
        private const val FIELD_PROVINCE = "province"
        private const val FIELD_CITY = "city"
        private const val FIELD_DISTRICT = "district"
        private const val FIELD_ADDRESS = "address"
        private const val FIELD_POSTAL_CODE = "postalCode"

        // 发票卡片字段 key
        private const val FIELD_COMPANY_NAME = "companyName"
        private const val FIELD_TAX_ID = "taxId"
        private const val FIELD_BANK_NAME = "bankName"
        private const val FIELD_BANK_ACCOUNT = "bankAccount"
    }

    /**
     * 创建卡片
     * 对应 iOS 的 createCard(title:group:cardType:fields:tags:)
     */
    override suspend fun createCard(
        title: String,
        group: String,
        cardType: String,
        fields: List<CardFieldDTO>,
        tags: List<String>
    ): Result<CardDTO> {
        return try {
            // 1. 验证标题
            val titleValidation = validationService.validateCardTitle(title)
            if (!titleValidation.isValid()) {
                return Result.failure(
                    IllegalArgumentException(titleValidation.getErrorMessage() ?: "标题验证失败")
                )
            }

            // 2. 验证卡片类型
            if (cardType !in listOf(CARD_TYPE_ADDRESS, CARD_TYPE_INVOICE, CARD_TYPE_GENERAL)) {
                return Result.failure(
                    IllegalArgumentException("无效的卡片类型 Invalid card type: $cardType")
                )
            }

            // 3. 验证字段（根据卡片类型）
            val fieldValidation = validateCardFields(cardType, fields)
            if (!fieldValidation.isValid()) {
                return Result.failure(
                    IllegalArgumentException(fieldValidation.getErrorMessage() ?: "字段验证失败")
                )
            }

            // 4. 调用 Repository 创建卡片（自动加密）
            val cardDTO = cardRepository.createCard(
                title = title,
                group = group,
                cardType = cardType,
                fields = fields,
                tags = tags
            )

            Result.success(cardDTO)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * 更新卡片
     * 对应 iOS 的 updateCard(id:title:group:fields:tags:)
     */
    override suspend fun updateCard(
        id: String,
        title: String?,
        group: String?,
        fields: List<CardFieldDTO>?,
        tags: List<String>?
    ): Result<CardDTO> {
        return try {
            // 1. 验证标题（如果提供）
            if (title != null) {
                val titleValidation = validationService.validateCardTitle(title)
                if (!titleValidation.isValid()) {
                    return Result.failure(
                        IllegalArgumentException(titleValidation.getErrorMessage() ?: "标题验证失败")
                    )
                }
            }

            // 2. 如果更新字段，需要先获取卡片类型进行验证
            if (fields != null) {
                val existingCard = cardRepository.getCardById(id)
                    ?: return Result.failure(IllegalArgumentException("卡片不存在 Card not found"))

                val fieldValidation = validateCardFields(existingCard.cardType, fields)
                if (!fieldValidation.isValid()) {
                    return Result.failure(
                        IllegalArgumentException(fieldValidation.getErrorMessage() ?: "字段验证失败")
                    )
                }
            }

            // 3. 调用 Repository 更新
            val updatedCard = cardRepository.updateCard(id, title, group, fields, tags)
                ?: return Result.failure(IllegalArgumentException("卡片不存在 Card not found"))

            Result.success(updatedCard)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * 删除卡片
     * 对应 iOS 的 deleteCard(id:)
     */
    override suspend fun deleteCard(id: String): Result<Unit> {
        return try {
            cardRepository.deleteCard(id)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * 获取所有卡片
     * 对应 iOS 的 fetchAllCards()
     */
    override fun getAllCards(): Flow<List<CardDTO>> {
        return cardRepository.getAllCards()
    }

    /**
     * 获取单个卡片
     * 对应 iOS 的 fetchCard(id:)
     */
    override suspend fun getCard(id: String): Result<CardDTO> {
        return try {
            val card = cardRepository.getCardById(id)
                ?: return Result.failure(IllegalArgumentException("卡片不存在 Card not found"))
            Result.success(card)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * 搜索卡片
     * 对应 iOS 的 searchCards(query:)
     */
    override fun searchCards(query: String): Flow<List<CardDTO>> {
        return cardRepository.searchCards(query)
    }

    /**
     * 切换置顶状态
     * 对应 iOS 的 togglePin(id:)
     */
    override suspend fun togglePin(id: String): Result<CardDTO> {
        return try {
            val card = cardRepository.togglePin(id)
                ?: return Result.failure(IllegalArgumentException("卡片不存在 Card not found"))
            Result.success(card)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * 按分组获取卡片
     */
    override fun getCardsByGroup(group: String): Flow<List<CardDTO>> {
        return cardRepository.getCardsByGroup(group)
    }

    /**
     * 根据卡片类型验证字段
     * 对应 iOS 的字段模板验证逻辑
     */
    private fun validateCardFields(cardType: String, fields: List<CardFieldDTO>): ValidationResult {
        return when (cardType) {
            CARD_TYPE_ADDRESS -> validateAddressFields(fields)
            CARD_TYPE_INVOICE -> validateInvoiceFields(fields)
            CARD_TYPE_GENERAL -> validateGeneralFields(fields)
            else -> ValidationResult.Error("未知的卡片类型 Unknown card type: $cardType")
        }
    }

    /**
     * 验证地址卡片字段
     * 对应 iOS 的 AddressTemplate 验证
     *
     * 必填字段：收件人、手机号、省、市、区、详细地址
     * 可选字段：邮编、备注
     */
    private fun validateAddressFields(fields: List<CardFieldDTO>): ValidationResult {
        val fieldMap = fields.associateBy { it.label }

        // 1. 验证必填字段存在
        val requiredFields = listOf(
            FIELD_RECIPIENT to "收件人",
            FIELD_PHONE to "手机号",
            FIELD_PROVINCE to "省",
            FIELD_CITY to "市",
            FIELD_DISTRICT to "区",
            FIELD_ADDRESS to "详细地址"
        )

        for ((key, displayName) in requiredFields) {
            val field = fieldMap[key]
            if (field == null || field.value.isBlank()) {
                return ValidationResult.Error("$displayName 不能为空 $displayName cannot be empty")
            }
        }

        // 2. 验证手机号格式
        val phoneField = fieldMap[FIELD_PHONE]
        if (phoneField != null) {
            val phoneValidation = validationService.validatePhoneNumber(phoneField.value)
            if (!phoneValidation.isValid()) {
                return phoneValidation
            }
        }

        // 3. 验证邮编格式（如果提供）
        val postalCodeField = fieldMap[FIELD_POSTAL_CODE]
        if (postalCodeField != null && postalCodeField.value.isNotBlank()) {
            val postalCodeValidation = validationService.validatePostalCode(postalCodeField.value)
            if (!postalCodeValidation.isValid()) {
                return postalCodeValidation
            }
        }

        return ValidationResult.Valid
    }

    /**
     * 验证发票卡片字段
     * 对应 iOS 的 InvoiceTemplate 验证
     *
     * 必填字段：公司名称、税号、地址、电话、开户行、银行账号
     * 可选字段：备注
     */
    private fun validateInvoiceFields(fields: List<CardFieldDTO>): ValidationResult {
        val fieldMap = fields.associateBy { it.label }

        // 1. 验证必填字段存在
        val requiredFields = listOf(
            FIELD_COMPANY_NAME to "公司名称",
            FIELD_TAX_ID to "税号",
            FIELD_ADDRESS to "地址",
            FIELD_PHONE to "电话",
            FIELD_BANK_NAME to "开户行",
            FIELD_BANK_ACCOUNT to "银行账号"
        )

        for ((key, displayName) in requiredFields) {
            val field = fieldMap[key]
            if (field == null || field.value.isBlank()) {
                return ValidationResult.Error("$displayName 不能为空 $displayName cannot be empty")
            }
        }

        // 2. 验证税号格式
        val taxIdField = fieldMap[FIELD_TAX_ID]
        if (taxIdField != null) {
            val taxIdValidation = validationService.validateTaxId(taxIdField.value)
            if (!taxIdValidation.isValid()) {
                return taxIdValidation
            }
        }

        // 3. 验证银行账号格式
        val bankAccountField = fieldMap[FIELD_BANK_ACCOUNT]
        if (bankAccountField != null) {
            val bankAccountValidation = validationService.validateBankAccount(bankAccountField.value)
            if (!bankAccountValidation.isValid()) {
                return bankAccountValidation
            }
        }

        return ValidationResult.Valid
    }

    /**
     * 验证通用文本卡片字段
     * 对应 iOS 的 GeneralTextTemplate 验证
     *
     * 至少需要一个字段（内容）
     */
    private fun validateGeneralFields(fields: List<CardFieldDTO>): ValidationResult {
        if (fields.isEmpty()) {
            return ValidationResult.Error("至少需要一个字段 At least one field is required")
        }

        // 验证所有字段都不为空
        val emptyField = fields.find { it.value.isBlank() }
        if (emptyField != null) {
            return ValidationResult.Error("字段 ${emptyField.label} 不能为空 Field cannot be empty")
        }

        return ValidationResult.Valid
    }
}
