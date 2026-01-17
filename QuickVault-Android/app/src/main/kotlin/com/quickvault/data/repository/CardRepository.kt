package com.quickvault.data.repository

import com.quickvault.data.local.database.dao.CardDao
import com.quickvault.data.local.database.dao.CardFieldDao
import com.quickvault.data.local.database.dao.CardWithFields
import com.quickvault.data.local.database.entity.CardEntity
import com.quickvault.data.local.database.entity.CardFieldEntity
import com.quickvault.data.model.CardDTO
import com.quickvault.data.model.CardFieldDTO
import com.quickvault.domain.service.CryptoService
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import org.json.JSONArray
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 卡片数据仓库
 * 负责数据库操作和加密/解密
 * 对应 iOS 的 Repository 模式（iOS 中直接在 Service 层）
 */
@Singleton
class CardRepository @Inject constructor(
    private val cardDao: CardDao,
    private val cardFieldDao: CardFieldDao,
    private val cryptoService: CryptoService
) {

    /**
     * 获取所有卡片（带字段）
     * Flow 会自动响应数据库变化
     */
    fun getAllCards(): Flow<List<CardDTO>> {
        return cardDao.getAllCardsWithFields()
            .map { cards -> cards.map { it.toDTO() } }
    }

    /**
     * 根据 ID 获取卡片
     */
    suspend fun getCardById(id: String): CardDTO? {
        return cardDao.getCardWithFields(id)?.toDTO()
    }

    /**
     * 搜索卡片
     */
    fun searchCards(query: String): Flow<List<CardDTO>> {
        return cardDao.searchCards(query)
            .map { cards ->
                // 搜索需要解密字段进行匹配
                cards.mapNotNull { card ->
                    val cardWithFields = cardDao.getCardWithFields(card.id)
                    cardWithFields?.toDTO()
                }.filter { dto ->
                    // 在标题、字段值、标签中搜索
                    dto.title.contains(query, ignoreCase = true) ||
                    dto.fields.any { it.value.contains(query, ignoreCase = true) } ||
                    dto.tags.any { it.contains(query, ignoreCase = true) }
                }
            }
    }

    /**
     * 按分组获取卡片
     */
    fun getCardsByGroup(group: String): Flow<List<CardDTO>> {
        return cardDao.getCardsByGroup(group)
            .map { cards ->
                cards.mapNotNull { card ->
                    cardDao.getCardWithFields(card.id)?.toDTO()
                }
            }
    }

    /**
     * 创建卡片
     */
    suspend fun createCard(
        title: String,
        group: String,
        cardType: String,
        fields: List<CardFieldDTO>,
        tags: List<String>
    ): CardDTO {
        val now = System.currentTimeMillis()

        // 1. 创建卡片实体
        val cardEntity = CardEntity(
            title = title,
            cardType = cardType,
            group = group,
            isPinned = false,
            tagsJson = tags.toJsonArray(),
            createdAt = now,
            updatedAt = now
        )

        cardDao.insertCard(cardEntity)

        // 2. 加密并保存字段
        val fieldEntities = fields.mapIndexed { index, field ->
            val encryptedValue = cryptoService.encrypt(field.value)
            CardFieldEntity(
                cardId = cardEntity.id,
                label = field.label,
                encryptedValue = encryptedValue,
                isRequired = field.isRequired,
                displayOrder = index
            )
        }

        cardFieldDao.insertFields(fieldEntities)

        // 3. 返回 DTO
        return CardDTO(
            id = cardEntity.id,
            title = title,
            group = group,
            cardType = cardType,
            fields = fields.mapIndexed { index, field ->
                CardFieldDTO(
                    id = fieldEntities[index].id,
                    label = field.label,
                    value = field.value,
                    isRequired = field.isRequired,
                    displayOrder = index
                )
            },
            isPinned = false,
            tags = tags,
            createdAt = now,
            updatedAt = now
        )
    }

    /**
     * 更新卡片
     */
    suspend fun updateCard(
        id: String,
        title: String? = null,
        group: String? = null,
        fields: List<CardFieldDTO>? = null,
        tags: List<String>? = null
    ): CardDTO? {
        val cardWithFields = cardDao.getCardWithFields(id) ?: return null
        val now = System.currentTimeMillis()

        // 1. 更新卡片基本信息
        val updatedCard = cardWithFields.card.copy(
            title = title ?: cardWithFields.card.title,
            group = group ?: cardWithFields.card.group,
            tagsJson = tags?.toJsonArray() ?: cardWithFields.card.tagsJson,
            updatedAt = now
        )

        cardDao.updateCard(updatedCard)

        // 2. 如果需要更新字段
        if (fields != null) {
            // 删除旧字段
            cardFieldDao.deleteFieldsByCardId(id)

            // 插入新字段（加密）
            val newFieldEntities = fields.mapIndexed { index, field ->
                val encryptedValue = cryptoService.encrypt(field.value)
                CardFieldEntity(
                    cardId = id,
                    label = field.label,
                    encryptedValue = encryptedValue,
                    isRequired = field.isRequired,
                    displayOrder = index
                )
            }

            cardFieldDao.insertFields(newFieldEntities)
        }

        return getCardById(id)
    }

    /**
     * 删除卡片
     */
    suspend fun deleteCard(id: String) {
        cardDao.deleteCard(id)
        // 由于设置了 CASCADE，字段和附件会自动删除
    }

    /**
     * 切换置顶状态
     */
    suspend fun togglePin(id: String): CardDTO? {
        val cardWithFields = cardDao.getCardWithFields(id) ?: return null
        val newPinStatus = !cardWithFields.card.isPinned

        cardDao.updatePinStatus(
            cardId = id,
            isPinned = newPinStatus,
            updatedAt = System.currentTimeMillis()
        )

        return getCardById(id)
    }

    /**
     * 将 CardWithFields 转换为 CardDTO
     * 会解密所有字段
     */
    private suspend fun CardWithFields.toDTO(): CardDTO {
        return CardDTO(
            id = card.id,
            title = card.title,
            group = card.group,
            cardType = card.cardType,
            fields = fields.map { field ->
                CardFieldDTO(
                    id = field.id,
                    label = field.label,
                    value = cryptoService.decrypt(field.encryptedValue),
                    isRequired = field.isRequired,
                    displayOrder = field.displayOrder
                )
            }.sortedBy { it.displayOrder },
            isPinned = card.isPinned,
            tags = card.tagsJson.fromJsonArray(),
            createdAt = card.createdAt,
            updatedAt = card.updatedAt
        )
    }

    /**
     * List<String> 转 JSON 数组字符串
     */
    private fun List<String>.toJsonArray(): String {
        val jsonArray = JSONArray()
        forEach { jsonArray.put(it) }
        return jsonArray.toString()
    }

    /**
     * JSON 数组字符串转 List<String>
     */
    private fun String.fromJsonArray(): List<String> {
        return try {
            val jsonArray = JSONArray(this)
            List(jsonArray.length()) { i -> jsonArray.getString(i) }
        } catch (e: Exception) {
            emptyList()
        }
    }
}
