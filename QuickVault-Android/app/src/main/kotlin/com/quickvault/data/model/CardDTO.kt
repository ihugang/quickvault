package com.quickvault.data.model

import java.util.UUID

/**
 * 卡片数据传输对象
 * 对应 iOS 的 CardDTO
 */
data class CardDTO(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val group: String,
    val cardType: String,
    val fields: List<CardFieldDTO>,
    val isPinned: Boolean = false,
    val tags: List<String> = emptyList(),
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)

/**
 * 卡片字段数据传输对象
 * 对应 iOS 的 CardFieldDTO
 */
data class CardFieldDTO(
    val id: String = UUID.randomUUID().toString(),
    val label: String,
    val value: String,
    val isRequired: Boolean = true,
    val displayOrder: Int
)

/**
 * 附件数据传输对象
 * 对应 iOS 的 AttachmentDTO
 */
data class AttachmentDTO(
    val id: String = UUID.randomUUID().toString(),
    val cardId: String,
    val fileName: String,
    val mimeType: String,
    val fileSize: Long,
    val hasWatermark: Boolean = false,
    val watermarkText: String? = null,
    val createdAt: Long = System.currentTimeMillis()
)

/**
 * 卡片模板定义
 * 对应 iOS 的 CardTemplate.swift
 */
object CardTemplate {

    /**
     * 地址模板字段
     */
    fun addressFields(): List<CardFieldDTO> = listOf(
        CardFieldDTO(label = "收件人", value = "", isRequired = true, displayOrder = 0),
        CardFieldDTO(label = "手机号", value = "", isRequired = true, displayOrder = 1),
        CardFieldDTO(label = "省", value = "", isRequired = true, displayOrder = 2),
        CardFieldDTO(label = "市", value = "", isRequired = true, displayOrder = 3),
        CardFieldDTO(label = "区", value = "", isRequired = true, displayOrder = 4),
        CardFieldDTO(label = "详细地址", value = "", isRequired = true, displayOrder = 5),
        CardFieldDTO(label = "邮编", value = "", isRequired = false, displayOrder = 6),
        CardFieldDTO(label = "备注", value = "", isRequired = false, displayOrder = 7)
    )

    /**
     * 发票模板字段
     */
    fun invoiceFields(): List<CardFieldDTO> = listOf(
        CardFieldDTO(label = "公司名称", value = "", isRequired = true, displayOrder = 0),
        CardFieldDTO(label = "税号", value = "", isRequired = true, displayOrder = 1),
        CardFieldDTO(label = "地址", value = "", isRequired = true, displayOrder = 2),
        CardFieldDTO(label = "电话", value = "", isRequired = true, displayOrder = 3),
        CardFieldDTO(label = "开户行", value = "", isRequired = true, displayOrder = 4),
        CardFieldDTO(label = "银行账号", value = "", isRequired = true, displayOrder = 5),
        CardFieldDTO(label = "备注", value = "", isRequired = false, displayOrder = 6)
    )

    /**
     * 通用文本模板字段
     */
    fun generalTextFields(): List<CardFieldDTO> = listOf(
        CardFieldDTO(label = "内容", value = "", isRequired = true, displayOrder = 0)
    )
}
