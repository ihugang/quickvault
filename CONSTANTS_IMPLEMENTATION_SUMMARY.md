# 常量集中管理实施总结 / Constants Centralization Summary

## 📋 完成概述 / Completion Overview

**实施日期**: 2026-01-15  
**状态**: ✅ 基础设施完成，迁移进行中

---

## 🎯 目标 / Objectives

将 QuickVault 项目中分散的常量字符串集中管理，提高代码质量：

1. **类型安全** - 编译时检查，避免拼写错误
2. **易于维护** - 单点修改，全局生效
3. **代码可读** - 语义化命名，自文档化
4. **减少重复** - 消除魔法字符串和数字

---

## 📁 创建的文件 / Files Created

### 1. 核心常量文件 / Core Constants

#### [AppConstants.swift](src/QuickVaultKit/Sources/QuickVaultCore/Constants/AppConstants.swift)
应用级别常量定义，包含：

- **Bundle IDs** - `com.codans.quickvault`, `com.codans.quickhold`
- **Logger** - 日志子系统和分类
  - Subsystem: `AppConstants.Logger.subsystem`
  - Categories: auth, crypto, keychain, storage, item, sync
- **Keychain Keys** - 钥匙串存储键
  - `masterPasswordKey`, `encryptionKeyKey`, `biometricPasswordKey`
- **UserDefaults Keys** - 用户设置键（15+ 个）
- **Notification Names** - 系统通知（7 个）
- **System Icons** - SF Symbols 图标名（20+ 个）
- **CoreData** - 实体和模型名称
- **Crypto** - 加密常量
  - Key size: 32 bytes (AES-256)
  - PBKDF2 iterations: 100,000
  - Salt size: 16 bytes
- **Validation** - 验证规则
  - Password length: 8-128
  - Max tags: 20
  - Max images: 20
  - Max file size: 50MB
- **Auto Lock** - 锁定超时值
- **Rate Limiting** - 速率限制配置
- **Watermark** - 水印设置
- **App URLs** - 外部应用链接

#### [LocalizationKeys.swift](src/QuickVaultKit/Sources/QuickVaultCore/Constants/LocalizationKeys.swift)
本地化字符串键定义，包含：

- **Authentication** - 认证模块（30+ 键）
  - Welcome, Setup, Login, Password, Change Password, Errors
- **Items** - 项目管理（50+ 键）
  - List, Types, Create, Detail, Delete, Images, Files, Tags
- **Settings** - 设置模块（20+ 键）
  - Security, Appearance, Language, About
- **Watermark** - 水印功能（10+ 键）
- **Export** - 导出功能
- **OCR** - OCR 识别
- **Promo** - 应用推广
- **Common** - 通用字符串

**String Extension** - 便捷本地化方法：
```swift
let text = LocalizationKeys.Items.title.localized
let formatted = LocalizationKeys.Auth.Error.rateLimited.localized(30)
```

### 2. 文档和工具 / Documentation & Tools

#### [CONSTANTS_GUIDE.md](CONSTANTS_GUIDE.md)
详细的使用指南，包括：
- 使用示例（Before/After）
- 最佳实践
- 迁移指南
- 注意事项

#### [CONSTANTS_MIGRATION_PLAN.md](CONSTANTS_MIGRATION_PLAN.md)
迁移计划文档，包括：
- 进度追踪表
- 优先级分级
- 检查清单
- 时间规划

#### [find_hardcoded_strings.sh](scripts/find_hardcoded_strings.sh)
自动化查找工具，可检测：
- UserDefaults 键
- 本地化键
- SF Symbols 图标
- 通知名称
- Logger 子系统
- 钥匙串键
- 魔法数字

---

## ✅ 已完成的迁移 / Completed Migrations

### 1. AuthenticationService.swift (100%)
- ✅ Logger subsystem: `AppConstants.Logger.subsystem`
- ✅ Logger category: `AppConstants.Logger.Category.auth`
- ✅ Error localization keys: `LocalizationKeys.Auth.Error.*`
- ✅ UserDefaults key: `AppConstants.UserDefaultsKeys.appLanguage`
- ✅ Keychain keys: `AppConstants.Keychain.*`
  - `masterPasswordKey`
  - `biometricPasswordKey`
- ✅ UserDefaults keys:
  - `biometricEnabled`
  - `failedAttempts`
  - `lastFailedAttempt`
- ✅ Rate limiting constants:
  - `maxFailedAttempts` → `AppConstants.RateLimit.maxFailedAttempts`
  - `rateLimitDuration` → `AppConstants.RateLimit.lockoutDuration`

### 2. AutoLockManager.swift (100%)
- ✅ UserDefaults key: `AppConstants.UserDefaultsKeys.autoLockTimeout`
- ✅ Timeout constants: `AppConstants.AutoLock.*`
  - `defaultTimeout` (60秒)
  - `briefSwitchThreshold` (30秒)

### 3. ItemType.swift (100%)
- ✅ Localization keys: `LocalizationKeys.Items.ItemType.*`
  - `text`, `image`, `file`
- ✅ System icons: `AppConstants.SystemIcon.*`
  - `textDocument`, `image`, `file`

### 4. CryptoService.swift (100%)
- ✅ Logger subsystem: `AppConstants.Logger.subsystem`
- ✅ Logger category: `AppConstants.Logger.Category.crypto`
- ✅ Crypto constants: `AppConstants.Crypto.*`
  - `pbkdf2Iterations` (100,000)
  - `keySize` (32 bytes)
  - `saltSize` (16 bytes)

---

## 📊 统计数据 / Statistics

### 常量定义 / Constants Defined

| 类别 / Category | 数量 / Count |
|----------------|-------------|
| Bundle IDs | 2 |
| Logger Categories | 6 |
| Keychain Keys | 3 |
| UserDefaults Keys | 10 |
| Notification Names | 7 |
| System Icons | 25+ |
| CoreData Entities | 7 |
| Crypto Constants | 4 |
| Validation Rules | 8 |
| Auto Lock Timeouts | 6 |
| Localization Keys | 150+ |
| **总计 / Total** | **220+** |

### 代码行数 / Lines of Code

| 文件 / File | 行数 / Lines |
|------------|-------------|
| AppConstants.swift | 216 |
| LocalizationKeys.swift | 220 |
| CONSTANTS_GUIDE.md | 350 |
| CONSTANTS_MIGRATION_PLAN.md | 380 |
| find_hardcoded_strings.sh | 140 |
| **总计 / Total** | **1,306** |

### 已迁移代码 / Migrated Code

| 文件 / File | 替换数 / Replacements |
|------------|----------------------|
| AuthenticationService.swift | 11 |
| AutoLockManager.swift | 3 |
| ItemType.swift | 6 |
| CryptoService.swift | 5 |
| **总计 / Total** | **25** |

---

## 💡 代码示例 / Code Examples

### Before / 之前

```swift
// 硬编码字符串
private let logger = Logger(subsystem: "com.codans.quickhold", category: "AuthService")
private let autoLockKey = "com.quickhold.autoLockTimeout"
let timeout = 300
let iterations = 100_000
let errorKey = "auth.error.password.incorrect"
Image(systemName: "checkmark.circle.fill")
```

### After / 之后

```swift
// 使用常量
private let logger = Logger(
  subsystem: AppConstants.Logger.subsystem, 
  category: AppConstants.Logger.Category.auth
)
private let autoLockKey = AppConstants.UserDefaultsKeys.autoLockTimeout
let timeout = AppConstants.AutoLock.fiveMinutes
let iterations = AppConstants.Crypto.pbkdf2Iterations
let errorKey = LocalizationKeys.Auth.Error.passwordIncorrect
Image(systemName: AppConstants.SystemIcon.checkmark)
```

---

## 🎁 核心优势 / Key Benefits

### 1. 类型安全 / Type Safety
```swift
// ✅ 编译时检查
AppConstants.UserDefaultsKeys.autoLockTimeout

// ❌ 运行时才发现拼写错误
"com.quickvault.autoLockTimoeut"  // typo!
```

### 2. 智能提示 / Auto-completion
IDE 自动提示所有可用常量，无需记忆完整字符串。

### 3. 全局搜索 / Global Search
一键查找所有使用某个常量的位置。

### 4. 重构友好 / Refactor-friendly
修改常量值只需一处更改，自动应用到所有引用。

### 5. 自文档化 / Self-documenting
常量名称即文档，代码更易理解。

---

## 🚀 下一步计划 / Next Steps

### 短期 (本周) / Short-term (This Week)

1. **完成核心视图迁移**
   - [ ] ItemListView.swift
   - [ ] ItemDetailView.swift
   - [ ] CreateItemSheet.swift
   - [ ] SettingsView.swift

2. **完成 View Models 迁移**
   - [ ] SettingsViewModel.swift

3. **运行查找脚本**
   - 更新统计数据
   - 识别遗漏项

### 中期 (2周内) / Mid-term (2 Weeks)

1. **完成所有 iOS Services**
   - [ ] ItemService.swift
   - [ ] FileStorageManager.swift
   - [ ] LocalizationManager.swift

2. **更新测试文件**
   - [ ] AuthenticationServiceTests.swift
   - [ ] 其他核心测试

### 长期 (1个月) / Long-term (1 Month)

1. **macOS App 迁移**
   - 评估 macOS 代码库
   - 制定迁移计划
   - 逐步实施

2. **代码审查与优化**
   - 检查遗漏的常量
   - 优化分组结构
   - 补充文档

---

## 📚 参考资源 / Resources

### 内部文档 / Internal Docs
- [CONSTANTS_GUIDE.md](CONSTANTS_GUIDE.md) - 详细使用指南
- [CONSTANTS_MIGRATION_PLAN.md](CONSTANTS_MIGRATION_PLAN.md) - 迁移计划
- [AGENTS.md](AGENTS.md) - 项目指南

### 代码文件 / Code Files
- [AppConstants.swift](src/QuickVaultKit/Sources/QuickVaultCore/Constants/AppConstants.swift)
- [LocalizationKeys.swift](src/QuickVaultKit/Sources/QuickVaultCore/Constants/LocalizationKeys.swift)

### 工具脚本 / Tools
- [find_hardcoded_strings.sh](scripts/find_hardcoded_strings.sh)

---

## 🤝 贡献指南 / Contributing

### 添加新常量 / Adding New Constants

1. **确定类型** - 判断是应用常量还是本地化键
2. **选择位置** - 在合适的枚举中添加
3. **命名规范** - 使用清晰的语义化名称
4. **添加注释** - 必要时添加说明
5. **更新文档** - 在迁移计划中标记

### 迁移现有代码 / Migrating Existing Code

1. **使用工具** - 运行 `find_hardcoded_strings.sh`
2. **小步迁移** - 一次一个文件或模块
3. **测试验证** - 每次迁移后运行测试
4. **提交代码** - 及时提交避免积累
5. **更新文档** - 在迁移计划中标记完成

---

## ⚠️ 注意事项 / Important Notes

1. **向后兼容** - 不要随意修改已使用的常量值
2. **命名一致** - 遵循现有命名规范
3. **避免重复** - 先检查是否已存在相似常量
4. **文档同步** - 重要变更需更新文档
5. **团队沟通** - 大规模迁移前与团队讨论

---

## 📈 项目影响 / Project Impact

### 代码质量提升 / Code Quality Improvements

- ✅ 消除了 25+ 处硬编码字符串
- ✅ 统一了 220+ 个常量的管理方式
- ✅ 提高了代码的可维护性
- ✅ 增强了类型安全性
- ✅ 改善了代码可读性

### 开发效率提升 / Development Efficiency

- ✅ 减少了拼写错误
- ✅ 加快了代码编写速度（自动完成）
- ✅ 简化了重构流程
- ✅ 降低了维护成本

### 团队协作改善 / Team Collaboration

- ✅ 统一了编码规范
- ✅ 提供了清晰的文档
- ✅ 建立了可持续的流程

---

## ✨ 总结 / Summary

QuickVault 项目已成功建立了**常量集中管理系统**，包括：

1. **2 个核心常量文件** - AppConstants 和 LocalizationKeys
2. **3 份详细文档** - 使用指南、迁移计划、总结报告
3. **1 个自动化工具** - 硬编码字符串查找脚本
4. **4 个已迁移文件** - 核心服务和模型
5. **220+ 个定义常量** - 覆盖应用各个方面

系统已投入使用，后续将持续迁移现有代码，最终实现**零硬编码字符串**的目标。

---

**创建日期**: 2026-01-15  
**最后更新**: 2026-01-15  
**版本**: 1.0.0  
**状态**: ✅ 已完成基础设施，🟡 迁移进行中
