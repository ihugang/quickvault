# QuickVault Android 随取

QuickVault 的 Android 版本 - 安全的本地信息管理应用

## 项目概述

QuickVault Android 是从 iOS 版本迁移而来，采用相同的核心架构和安全机制：
- **本地优先**: 所有数据仅存储在设备本地（Room Database）
- **字段级加密**: AES-256-GCM 加密所有敏感字段
- **生物识别**: 支持指纹和面部识别
- **零网络依赖**: 无云同步，纯离线运行

## 技术栈

### UI 框架
- **Jetpack Compose** - 声明式 UI（对应 iOS SwiftUI）
- **Material Design 3** - 现代化设计系统
- **Navigation Compose** - 类型安全的导航（对应 iOS NavigationStack）

### 数据层
- **Room Database** - SQLite ORM（对应 iOS CoreData）
- **Kotlin Flow** - 响应式数据流（对应 iOS Combine）
- **DataStore** - 偏好设置存储（对应 iOS UserDefaults）

### 安全
- **Jetpack Security Crypto** - AES-256-GCM 加密
- **Android Keystore** - 安全密钥存储（对应 iOS Keychain）
- **BiometricPrompt** - 生物识别认证

### 架构
- **MVVM** - Model-View-ViewModel 架构模式
- **Hilt** - 依赖注入框架
- **Kotlin Coroutines** - 异步编程（对应 iOS async/await）

## 项目结构

```
app/src/main/kotlin/com/quickvault/
├── QuickVaultApp.kt                    # Application 入口
├── di/                                 # 依赖注入模块
│   ├── AppModule.kt
│   ├── DatabaseModule.kt
│   └── ServiceModule.kt
├── data/                               # 数据层
│   ├── local/
│   │   └── database/
│   │       ├── QuickVaultDatabase.kt   # Room Database
│   │       ├── entity/                 # 数据库实体（对应 CoreData Entity）
│   │       │   ├── CardEntity.kt
│   │       │   ├── CardFieldEntity.kt
│   │       │   └── AttachmentEntity.kt
│   │       └── dao/                    # 数据访问对象
│   │           ├── CardDao.kt
│   │           ├── CardFieldDao.kt
│   │           └── AttachmentDao.kt
│   ├── repository/                     # Repository 层
│   └── model/                          # DTO 模型
│       └── CardDTO.kt
├── domain/                             # 业务逻辑层
│   └── service/                        # 服务接口
│       ├── CryptoService.kt            # 加密服务（对应 iOS CryptoService）
│       ├── AuthService.kt              # 认证服务
│       ├── CardService.kt              # 卡片服务
│       └── WatermarkService.kt         # 水印服务（Android 独有）
├── presentation/                       # UI 层
│   ├── MainActivity.kt
│   ├── theme/                          # Material 3 主题
│   │   ├── Theme.kt
│   │   ├── Color.kt
│   │   └── Type.kt
│   ├── navigation/                     # 导航
│   │   └── NavGraph.kt
│   ├── screen/                         # 界面
│   │   ├── splash/                     # 启动页
│   │   ├── auth/                       # 认证（设置/解锁）
│   │   ├── cards/                      # 卡片列表
│   │   ├── search/                     # 搜索
│   │   ├── detail/                     # 卡片详情
│   │   ├── editor/                     # 卡片编辑
│   │   └── settings/                   # 设置
│   └── components/                     # 可复用组件
└── util/                               # 工具类
    └── Constants.kt
```

## iOS vs Android 对应关系

| 功能 | iOS | Android |
|------|-----|---------|
| UI 框架 | SwiftUI | Jetpack Compose |
| 数据库 | CoreData | Room Database |
| 加密 | CryptoKit | Jetpack Security Crypto |
| 安全存储 | Keychain | Android Keystore |
| 生物识别 | LocalAuthentication | BiometricPrompt |
| 导航 | NavigationStack + TabView | Navigation Compose + BottomNavigation |
| 异步 | async/await + Combine | Coroutines + Flow |
| 依赖注入 | 手动注入 | Hilt (Dagger) |

## 核心功能

### ✅ 已实现（骨架）
- [x] 项目结构和配置
- [x] Room 数据库实体和 DAO
- [x] 服务接口定义（CryptoService, AuthService, CardService, WatermarkService）
- [x] Hilt 依赖注入配置
- [x] Material 3 主题
- [x] 中英双语字符串资源

### 🚧 待实现
- [ ] CryptoService 实现（AES-256-GCM 加密）
- [ ] AuthService 实现（生物识别 + 密码）
- [ ] CardService 实现（CRUD 操作）
- [ ] WatermarkService 实现（图片水印）
- [ ] Repository 层实现
- [ ] UI 界面实现
  - [ ] 启动页和认证流程
  - [ ] 卡片列表（Bottom Navigation）
  - [ ] 卡片详情和编辑
  - [ ] 搜索功能
  - [ ] 设置页面
- [ ] 自动锁定机制
- [ ] 单元测试

## 开发环境要求

- **Android Studio**: Hedgehog (2023.1.1) 或更高
- **Kotlin**: 1.9.22
- **Gradle**: 8.2.2
- **Min SDK**: 26 (Android 8.0)
- **Target SDK**: 35 (Android 15)
- **Compile SDK**: 35

## 构建和运行

### 1. 在 Android Studio 中打开项目

```bash
# 克隆仓库后，用 Android Studio 打开 QuickVault-Android 文件夹
# 或在终端中运行：
open -a "Android Studio" QuickVault-Android
```

### 2. Gradle 同步

项目打开后，Android Studio 会自动同步 Gradle 依赖。如果没有，手动点击 "Sync Project with Gradle Files"。

### 3. 运行应用

- 点击 "Run" 按钮（绿色三角形）
- 选择模拟器或真机
- 应用将编译并安装到设备上

### 4. 构建 APK

```bash
# Debug APK
./gradlew assembleDebug

# Release APK
./gradlew assembleRelease
```

## 测试

```bash
# 运行单元测试
./gradlew test

# 运行 UI 测试
./gradlew connectedAndroidTest
```

## 安全说明

### 数据存储
- 所有敏感字段值使用 AES-256-GCM 加密后存储在 Room Database
- 加密密钥存储在 Android Keystore（硬件支持）
- 主密码使用 PBKDF2-HMAC-SHA256 派生（100,000 次迭代）

### 认证机制
- 生物识别（指纹/面部）作为主要认证方式
- 主密码作为备用认证方式
- 连续失败 3 次后强制 30 秒延迟
- 后台立即锁定

### 隐私保护
- 无网络权限（除非启用更新检查）
- 禁用云备份（`android:allowBackup="false"`）
- 不收集任何用户数据
- 不包含第三方追踪

## 下一步开发任务

### 优先级 1（核心功能）
1. 实现 CryptoService（加密/解密）
2. 实现 AuthService（认证）
3. 实现 CardService（卡片 CRUD）
4. 实现认证 UI（SetupScreen, UnlockScreen）
5. 实现卡片列表 UI（CardsScreen）

### 优先级 2（完善功能）
6. 实现卡片编辑 UI（CardEditorScreen）
7. 实现搜索功能
8. 实现设置页面
9. 实现水印功能
10. 实现自动锁定

### 优先级 3（测试和优化）
11. 编写单元测试
12. 编写 UI 测试
13. 性能优化
14. 安全审计

## 开发规范

### 代码风格
- 遵循 Kotlin 官方代码风格
- 使用 ktlint 格式化代码
- 命名规范：
  - 类名：PascalCase
  - 函数/变量：camelCase
  - 常量：UPPER_SNAKE_CASE

### Commit 规范
```
feat: 添加新功能
fix: 修复 bug
refactor: 重构代码
docs: 更新文档
test: 添加测试
chore: 构建/配置更新
```

### 分支策略
- `main`: 稳定版本
- `develop`: 开发分支
- `feature/*`: 功能分支
- `fix/*`: 修复分支

## License

与 iOS 版本保持一致

---

**注意**: 此项目仍在开发中，当前仅包含项目骨架和基础配置。
