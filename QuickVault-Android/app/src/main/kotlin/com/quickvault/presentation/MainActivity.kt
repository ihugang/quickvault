package com.quickvault.presentation

import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.fragment.app.FragmentActivity
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import androidx.navigation.NavType
import com.quickvault.presentation.navigation.Routes
import com.quickvault.presentation.navigation.Screen
import com.quickvault.presentation.screen.auth.SetupScreen
import com.quickvault.presentation.screen.auth.UnlockScreen
import com.quickvault.data.model.ItemType
import com.quickvault.presentation.screen.items.ItemDetailScreen
import com.quickvault.presentation.screen.items.ItemEditorScreen
import com.quickvault.presentation.screen.items.ItemsScreen
import com.quickvault.presentation.screen.search.SearchScreen
import com.quickvault.presentation.screen.settings.SettingsScreen
import com.quickvault.presentation.screen.splash.SplashScreen
import com.quickvault.presentation.theme.QuickVaultTheme
import android.content.Context
import com.quickvault.presentation.lifecycle.AppLifecycleObserver
import com.quickvault.util.LanguageManager
import com.quickvault.util.ThemeManager
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember

/**
 * 主 Activity
 * 对应 iOS 的 @main struct QuickVaultApp
 */
@AndroidEntryPoint
class MainActivity : FragmentActivity() {

    @Inject
    lateinit var appLifecycleObserver: AppLifecycleObserver

    @Inject
    lateinit var themeManager: ThemeManager

    override fun attachBaseContext(newBase: Context) {
        // 应用语言设置
        super.attachBaseContext(LanguageManager.wrap(newBase))
    }

    private val _currentTheme = mutableStateOf(themeManager.getThemeMode())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 注册生命周期观察者（自动锁定）
        lifecycle.addObserver(appLifecycleObserver)

        setContent {
            QuickVaultTheme(themeMode = _currentTheme.value) {
                QuickVaultApp()
            }
        }
    }

    /**
     * 更新主题模式
     */
    fun updateTheme(themeMode: com.quickvault.util.ThemeMode) {
        themeManager.setThemeMode(themeMode)
        _currentTheme.value = themeMode
    }
}

/**
 * QuickVault 应用导航
 */
@Composable
fun QuickVaultApp() {
    val navController = rememberNavController()

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        NavHost(
            navController = navController,
            startDestination = Routes.SPLASH
        ) {
            // 启动页
            composable(Routes.SPLASH) {
                SplashScreen(
                    onNavigateToSetup = {
                        navController.navigate(Routes.SETUP) {
                            popUpTo(Routes.SPLASH) { inclusive = true }
                        }
                    },
                    onNavigateToUnlock = {
                        navController.navigate(Routes.UNLOCK) {
                            popUpTo(Routes.SPLASH) { inclusive = true }
                        }
                    }
                )
            }

            // 首次设置密码
            composable(Routes.SETUP) {
                SetupScreen(
                    onSetupComplete = {
                        navController.navigate(Routes.MAIN) {
                            popUpTo(Routes.SETUP) { inclusive = true }
                        }
                    }
                )
            }

            // 解锁界面
            composable(Routes.UNLOCK) {
                UnlockScreen(
                    onUnlockSuccess = {
                        navController.navigate(Routes.MAIN) {
                            popUpTo(Routes.UNLOCK) { inclusive = true }
                        }
                    }
                )
            }

            // 主界面（带底部导航和项目功能）
            composable(Routes.MAIN) {
                MainScreenWithNavigation()
            }
        }
    }
}

/**
 * 主界面（带底部导航和完整路由）
 * 对应 iOS 的 TabView + NavigationStack
 */
@Composable
fun MainScreenWithNavigation() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    val screens = listOf(
        Screen.Items,
        Screen.Search,
        Screen.Settings
    )

    // 检查是否在底部导航的顶层屏幕（显示底部导航栏）
    val showBottomBar = currentDestination?.route in screens.map { it.route }

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    screens.forEach { screen ->
                        NavigationBarItem(
                            icon = { Icon(screen.icon, contentDescription = stringResource(screen.labelRes)) },
                            label = { Text(stringResource(screen.labelRes)) },
                            selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true,
                            onClick = {
                                navController.navigate(screen.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        )
                    }
                }
            }
        }
    ) { paddingValues ->
        NavHost(
            navController = navController,
            startDestination = Screen.Items.route,
            modifier = Modifier.padding(bottom = paddingValues.calculateBottomPadding())
        ) {
            // 项目列表
            composable(Screen.Items.route) {
                ItemsScreen(
                    onCreateItem = { type ->
                        navController.navigate("item_editor?itemType=${type.name}")
                    },
                    onViewItem = { itemId ->
                        navController.navigate("item_detail/$itemId")
                    }
                )
            }

            // 搜索
            composable(Screen.Search.route) {
                SearchScreen(
                    onNavigateToItemDetail = { itemId ->
                        navController.navigate("item_detail/$itemId")
                    }
                )
            }

            // 设置
            composable(Screen.Settings.route) {
                SettingsScreen(
                    onNavigateToUnlock = {
                        // 锁定后返回解锁界面
                        // 需要从父导航控制器导航
                        // TODO: 实现应用级别的锁定状态管理
                    }
                )
            }

            // 项目详细画面
            composable(
                route = "item_detail/{itemId}",
                arguments = listOf(
                    navArgument("itemId") {
                        type = NavType.StringType
                    }
                )
            ) {
                ItemDetailScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToEdit = { itemId ->
                        navController.navigate("item_editor/$itemId")
                    }
                )
            }

            // 项目编辑器 - 新建（带可选类型）
            composable(
                route = "item_editor?itemType={itemType}",
                arguments = listOf(
                    navArgument("itemType") {
                        type = NavType.StringType
                        defaultValue = ItemType.TEXT.name
                    }
                )
            ) {
                ItemEditorScreen(
                    onNavigateBack = { navController.popBackStack() }
                )
            }

            // 项目编辑器 - 编辑（带 itemId）
            composable(
                route = "item_editor/{itemId}",
                arguments = listOf(
                    navArgument("itemId") {
                        type = NavType.StringType
                    }
                )
            ) {
                ItemEditorScreen(
                    onNavigateBack = { navController.popBackStack() }
                )
            }
        }
    }
}

/**
 * 占位符屏幕（功能开发中）
 */
@Composable
fun PlaceholderScreen(title: String) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = androidx.compose.ui.Alignment.Center
    ) {
        Column(
            horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.headlineMedium,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )

            Text(
                text = stringResource(com.quickvault.R.string.common_feature_in_development),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
        }
    }
}
