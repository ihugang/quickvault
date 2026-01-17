package com.quickvault.presentation.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * 导航路由
 * 对应 iOS 的 NavigationStack 路由
 */
object Routes {
    const val SPLASH = "splash"
    const val SETUP = "setup"
    const val UNLOCK = "unlock"
    const val MAIN = "main"
    const val CARD_DETAIL = "card_detail/{cardId}"
    const val CARD_EDITOR = "card_editor?cardId={cardId}"
}

/**
 * Bottom Navigation 屏幕
 * 对应 iOS 的 TabView
 */
sealed class Screen(
    val route: String,
    val label: String,
    val icon: ImageVector
) {
    object Cards : Screen(
        route = "cards",
        label = "卡片",
        icon = Icons.Default.CreditCard
    )

    object Search : Screen(
        route = "search",
        label = "搜索",
        icon = Icons.Default.Search
    )

    object Settings : Screen(
        route = "settings",
        label = "设置",
        icon = Icons.Default.Settings
    )
}
