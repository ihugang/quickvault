# QuickVault Android 开发入门指南

## 📱 项目已创建完成

✅ 项目骨架已全部创建，包含：
- Gradle 配置和依赖管理
- Room 数据库架构（Entity + DAO）
- 服务层接口定义
- Hilt 依赖注入配置
- Material 3 主题和 UI 框架
- 中英双语资源文件

## 🚀 快速开始

### 1. 在 Android Studio 中打开项目

```bash
# 方式 1: 直接打开
在 Android Studio 中选择 "File" → "Open" → 选择 QuickVault-Android 文件夹

# 方式 2: 命令行
open -a "Android Studio" /Volumes/SN770/Downloads/Dev/2026/Products/QuickVault/QuickVault-Android
```

### 2. Gradle 同步

项目打开后：
1. Android Studio 会自动提示同步 Gradle
2. 点击 "Sync Now" 或等待自动同步完成
3. 首次同步会下载所有依赖（需要网络，约 3-5 分钟）

### 3. 运行应用

1. 点击顶部工具栏的 "Run" 按钮（绿色三角形）
2. 选择模拟器或连接真机
3. 应用将编译并安装

**当前效果**: 显示一个欢迎界面，文字 "QuickVault 随取 - Android 版本开发中..."

## 📂 项目结构说明

### 配置文件

```
QuickVault-Android/
├── build.gradle.kts           # 项目级 Gradle 配置
├── settings.gradle.kts        # Gradle 设置
├── gradle.properties          # Gradle 属性
└── app/
    ├── build.gradle.kts       # App 模块配置（最重要）
    ├── proguard-rules.pro     # ProGuard 混淆规则
    └── src/main/
        ├── AndroidManifest.xml
        ├── kotlin/com/quickvault/
        └── res/
```

### 核心代码层次

```
com.quickvault
│
├── 📱 presentation/           # UI 层（对应 iOS Views）
│   ├── MainActivity.kt        # 主 Activity
│   ├── theme/                 # Material 3 主题
│   ├── navigation/            # 导航配置
│   ├── screen/                # 各个界面（待实现）
│   └── components/            # 可复用组件（待实现）
│
├── 💼 domain/                 # 业务逻辑层（对应 iOS Services）
│   └── service/               # 服务接口（已定义，待实现）
│       ├── CryptoService.kt
│       ├── AuthService.kt
│       ├── CardService.kt
│       └── WatermarkService.kt
│
├── 💾 data/                   # 数据层（对应 iOS CoreData + Keychain）
│   ├── local/database/        # Room 数据库
│   │   ├── entity/            # 数据库实体（已创建）
│   │   ├── dao/               # DAO 接口（已创建）
│   │   └── QuickVaultDatabase.kt
│   ├── repository/            # Repository 层（待实现）
│   └── model/                 # DTO 模型（已创建）
│
├── 💉 di/                     # Hilt 依赖注入
│   ├── AppModule.kt           # 应用模块
│   ├── DatabaseModule.kt      # 数据库模块
│   └── ServiceModule.kt       # 服务模块（待填充）
│
└── 🛠️ util/                   # 工具类
    └── Constants.kt           # 常量定义
```

## 🎯 下一步开发任务

### 阶段 1: 实现加密服务（优先级最高）

创建 `CryptoServiceImpl.kt`：

```kotlin
// app/src/main/kotlin/com/quickvault/domain/service/impl/CryptoServiceImpl.kt
package com.quickvault.domain.service.impl

import android.content.Context
import com.google.crypto.tink.Aead
import com.google.crypto.tink.integration.android.AndroidKeysetManager
import com.quickvault.domain.service.CryptoService
import javax.inject.Inject

class CryptoServiceImpl @Inject constructor(
    private val context: Context
) : CryptoService {
    // TODO: 实现加密方法
}
```

### 阶段 2: 实现认证服务

创建 `AuthServiceImpl.kt`：
- 集成 BiometricPrompt
- 实现密码验证
- Keychain 存储

### 阶段 3: 实现 UI

从认证流程开始：
1. `SplashScreen.kt` - 启动页
2. `SetupScreen.kt` - 首次设置密码
3. `UnlockScreen.kt` - 解锁界面

## 🧪 验证项目可运行

### 检查点 1: Gradle 同步成功

```bash
# 在终端中运行（QuickVault-Android 目录下）
./gradlew tasks

# 应该能看到可用任务列表
```

### 检查点 2: 编译成功

```bash
# 编译 Debug 版本
./gradlew assembleDebug

# 成功后会生成 APK:
# app/build/outputs/apk/debug/app-debug.apk
```

### 检查点 3: 运行测试

```bash
# 运行单元测试（当前没有测试，但不应报错）
./gradlew test
```

## 📝 开发工作流建议

### 1. 每天开始前

```bash
git pull origin main
./gradlew clean
```

### 2. 开发新功能

```bash
git checkout -b feature/crypto-service
# 开发...
./gradlew test
git add .
git commit -m "feat: implement CryptoService"
git push origin feature/crypto-service
```

### 3. 调试技巧

**Logcat 日志**:
```kotlin
import android.util.Log

Log.d("QuickVault", "Debug message")
Log.e("QuickVault", "Error message", exception)
```

**Compose 预览**:
```kotlin
@Preview(showBackground = true)
@Composable
fun MyScreenPreview() {
    QuickVaultTheme {
        MyScreen()
    }
}
```

## 🔧 常见问题

### Q: Gradle 同步失败

**A**: 检查网络连接，清理缓存：
```bash
./gradlew clean
rm -rf .gradle
# 重新打开 Android Studio
```

### Q: 找不到 Hilt 生成的类

**A**: 重新构建项目：
```bash
./gradlew clean build
```

### Q: Room 编译错误

**A**: 确保 KSP 插件正确配置：
```kotlin
// app/build.gradle.kts
plugins {
    id("com.google.devtools.ksp") version "1.9.22-1.0.17"
}
```

## 📚 学习资源

### Jetpack Compose
- [官方文档](https://developer.android.com/jetpack/compose)
- [Compose 示例](https://github.com/android/compose-samples)

### Room Database
- [官方指南](https://developer.android.com/training/data-storage/room)

### Hilt 依赖注入
- [官方教程](https://developer.android.com/training/dependency-injection/hilt-android)

### Android Security
- [Jetpack Security](https://developer.android.com/jetpack/androidx/releases/security)
- [BiometricPrompt](https://developer.android.com/training/sign-in/biometric-auth)

## 🎨 UI 设计参考

### Material Design 3
- [设计指南](https://m3.material.io/)
- [组件库](https://m3.material.io/components)

### iOS 到 Android 映射
| iOS 组件 | Android 对应 |
|---------|-------------|
| List | LazyColumn |
| NavigationLink | NavController.navigate() |
| TabView | BottomNavigation |
| Alert | AlertDialog |
| Sheet | ModalBottomSheet |
| TextField | OutlinedTextField |

## 🚦 开发里程碑

- [ ] **M1**: 加密和认证功能（1-2周）
- [ ] **M2**: 卡片 CRUD 功能（2-3周）
- [ ] **M3**: UI 界面完成（3-4周）
- [ ] **M4**: 测试和优化（1-2周）
- [ ] **M5**: 发布准备（1周）

**预计总时间**: 8-12 周（全职开发）

---

**准备好开始了吗？** 现在就用 Android Studio 打开项目，开始你的第一个功能吧！🚀
