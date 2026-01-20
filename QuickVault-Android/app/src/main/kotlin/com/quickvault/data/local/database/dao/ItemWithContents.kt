package com.quickvault.data.local.database.dao

import androidx.room.Embedded
import androidx.room.Relation
import com.quickvault.data.local.database.entity.AttachmentEntity
import com.quickvault.data.local.database.entity.ItemEntity
import com.quickvault.data.local.database.entity.TextContentEntity

data class ItemWithContents(
    @Embedded val item: ItemEntity,
    @Relation(
        parentColumn = "id",
        entityColumn = "item_id"
    )
    val textContents: List<TextContentEntity>,
    @Relation(
        parentColumn = "id",
        entityColumn = "item_id"
    )
    val attachments: List<AttachmentEntity>
)
