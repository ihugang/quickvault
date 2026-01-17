package com.quickvault.domain.service

import com.quickvault.data.model.CardDTO
import com.quickvault.data.model.CardFieldDTO
import kotlinx.coroutines.flow.Flow

/**
 * 卡片服务接口
 * 对应 iOS 的 CardService protocol
 */
interface CardService {

    /**
     * 创建卡片
     * 对应 iOS 的 createCard(title:group:cardType:fields:tags:)
     */
    suspend fun createCard(
        title: String,
        group: String,
        cardType: String,
        fields: List<CardFieldDTO>,
        tags: List<String> = emptyList()
    ): Result<CardDTO>

    /**
     * 更新卡片
     * 对应 iOS 的 updateCard(id:title:group:fields:tags:)
     */
    suspend fun updateCard(
        id: String,
        title: String? = null,
        group: String? = null,
        fields: List<CardFieldDTO>? = null,
        tags: List<String>? = null
    ): Result<CardDTO>

    /**
     * 删除卡片
     * 对应 iOS 的 deleteCard(id:)
     */
    suspend fun deleteCard(id: String): Result<Unit>

    /**
     * 获取所有卡片
     * 对应 iOS 的 fetchAllCards()
     */
    fun getAllCards(): Flow<List<CardDTO>>

    /**
     * 获取单个卡片
     * 对应 iOS 的 fetchCard(id:)
     */
    suspend fun getCard(id: String): Result<CardDTO>

    /**
     * 搜索卡片
     * 对应 iOS 的 searchCards(query:)
     */
    fun searchCards(query: String): Flow<List<CardDTO>>

    /**
     * 切换置顶状态
     * 对应 iOS 的 togglePin(id:)
     */
    suspend fun togglePin(id: String): Result<CardDTO>

    /**
     * 按分组获取卡片
     */
    fun getCardsByGroup(group: String): Flow<List<CardDTO>>
}
