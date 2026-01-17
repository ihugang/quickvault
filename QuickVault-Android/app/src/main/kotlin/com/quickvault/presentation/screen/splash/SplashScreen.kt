package com.quickvault.presentation.screen.splash

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.quickvault.R
import com.quickvault.presentation.screen.auth.AuthViewModel
import kotlinx.coroutines.delay

/**
 * 启动页
 * 检查是否已设置密码，决定跳转到 Setup 还是 Unlock
 */
@Composable
fun SplashScreen(
    onNavigateToSetup: () -> Unit,
    onNavigateToUnlock: () -> Unit,
    viewModel: AuthViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(uiState.isSetup) {
        // 显示启动画面 1 秒
        delay(1000)

        // 根据是否已设置密码跳转
        if (uiState.isSetup) {
            onNavigateToUnlock()
        } else {
            onNavigateToSetup()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = stringResource(R.string.app_name),
                style = MaterialTheme.typography.headlineLarge
            )

            CircularProgressIndicator()
        }
    }
}
