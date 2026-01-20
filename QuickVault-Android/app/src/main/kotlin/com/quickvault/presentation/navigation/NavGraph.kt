package com.quickvault.presentation.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.annotation.StringRes
import com.quickvault.R

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
    @StringRes val labelRes: Int,
    val icon: ImageVector
) {
    object Cards : Screen(
        route = "cards",
        labelRes = R.string.nav_cards,
        icon = Icons.Default.CreditCard
    )

    object Search : Screen(
        route = "search",
        labelRes = R.string.nav_search,
        icon = Icons.Default.Search
    )

    object Settings : Screen(
        route = "settings",
        labelRes = R.string.nav_settings,
        icon = Icons.Default.Settings
    )
}
