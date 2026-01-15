# 常量使用速查表 / Constants Quick Reference

## 快速开始 / Quick Start

### Import
```swift
import QuickVaultCore
```

所有常量都定义在 `QuickVaultCore` 模块中，无需额外导入。

---

## 🔑 常用常量 / Common Constants

### UserDefaults 键
```swift
// 语言设置
AppConstants.UserDefaultsKeys.appLanguage

// 安全设置
AppConstants.UserDefaultsKeys.biometricEnabled
AppConstants.UserDefaultsKeys.autoLockTimeout

// 失败尝试
AppConstants.UserDefaultsKeys.failedAttempts
AppConstants.UserDefaultsKeys.lastFailedAttempt
```

### 钥匙串键
```swift
AppConstants.Keychain.masterPasswordKey
AppConstants.Keychain.biometricPasswordKey
AppConstants.Keychain.encryptionKeyKey
```

### 日志记录
```swift
let logger = Logger(
  subsystem: AppConstants.Logger.subsystem,
  category: AppConstants.Logger.Category.auth  // 或 .crypto, .storage 等
)
```

### 系统图标
```swift
// 通用
Image(systemName: AppConstants.SystemIcon.checkmark)
Image(systemName: AppConstants.SystemIcon.error)
Image(systemName: AppConstants.SystemIcon.close)

// 项目类型
Image(systemName: AppConstants.SystemIcon.textDocument)
Image(systemName: AppConstants.SystemIcon.image)
Image(systemName: AppConstants.SystemIcon.file)

// 操作
Image(systemName: AppConstants.SystemIcon.edit)
Image(systemName: AppConstants.SystemIcon.delete)
Image(systemName: AppConstants.SystemIcon.share)
```

### 通知
```swift
NotificationCenter.default.post(
  name: AppConstants.Notification.authStateChanged,
  object: nil
)

NotificationCenter.default.addObserver(
  forName: AppConstants.Notification.itemCreated,
  object: nil,
  queue: .main
) { notification in
  // 处理通知
}
```

---

## 🌐 本地化字符串 / Localization

### 认证 Authentication
```swift
// 标题
LocalizationKeys.Auth.welcomeTitle.localized
LocalizationKeys.Auth.loginTitle.localized

// 按钮
LocalizationKeys.Auth.loginButton.localized
LocalizationKeys.Auth.changeButton.localized

// 错误
LocalizationKeys.Auth.Error.passwordIncorrect.localized
LocalizationKeys.Auth.Error.biometricFailed.localized

// 带参数
LocalizationKeys.Auth.Error.rateLimited.localized(seconds)
```

### 项目 Items
```swift
// 类型
LocalizationKeys.Items.ItemType.text.localized
LocalizationKeys.Items.ItemType.image.localized
LocalizationKeys.Items.ItemType.file.localized

// 列表
LocalizationKeys.Items.title.localized
LocalizationKeys.Items.searchPlaceholder.localized
LocalizationKeys.Items.empty.localized

// 详情
LocalizationKeys.Items.Detail.edit.localized
LocalizationKeys.Items.Detail.delete.localized
LocalizationKeys.Items.Detail.content.localized

// 创建
LocalizationKeys.Items.Create.title.localized
LocalizationKeys.Items.Create.button.localized

// 标签
LocalizationKeys.Items.Tags.placeholder.localized
LocalizationKeys.Items.Tags.add.localized
```

### 设置 Settings
```swift
LocalizationKeys.Settings.title.localized
LocalizationKeys.Settings.Security.title.localized
LocalizationKeys.Settings.Security.autolock.localized
LocalizationKeys.Settings.Security.ClearData.title.localized
LocalizationKeys.Settings.Language.title.localized
```

### 通用 Common
```swift
LocalizationKeys.Common.ok.localized
LocalizationKeys.Common.cancel.localized
LocalizationKeys.Common.save.localized
LocalizationKeys.Common.delete.localized
LocalizationKeys.Common.confirm.localized
```

---

## 🔢 数值常量 / Numeric Constants

### 加密 Crypto
```swift
AppConstants.Crypto.keySize              // 32 (AES-256)
AppConstants.Crypto.pbkdf2Iterations     // 100,000
AppConstants.Crypto.saltSize             // 16
AppConstants.Crypto.nonceSize            // 12
```

### 验证 Validation
```swift
AppConstants.Validation.minPasswordLength  // 8
AppConstants.Validation.maxPasswordLength  // 128
AppConstants.Validation.maxTagLength       // 20
AppConstants.Validation.maxImageCount      // 20
AppConstants.Validation.maxFileCount       // 10
AppConstants.Validation.maxFileSize        // 50 MB
```

### 自动锁定 Auto Lock
```swift
AppConstants.AutoLock.immediately        // 0
AppConstants.AutoLock.thirtySeconds      // 30
AppConstants.AutoLock.oneMinute          // 60
AppConstants.AutoLock.fiveMinutes        // 300
AppConstants.AutoLock.fifteenMinutes     // 900
AppConstants.AutoLock.never              // -1
AppConstants.AutoLock.defaultTimeout     // 60
```

### 速率限制 Rate Limiting
```swift
AppConstants.RateLimit.maxFailedAttempts  // 5
AppConstants.RateLimit.lockoutDuration    // 300 (5 分钟)
```

### 水印 Watermark
```swift
AppConstants.Watermark.defaultOpacity     // 0.5
AppConstants.Watermark.Spacing.dense      // 50.0
AppConstants.Watermark.Spacing.normal     // 100.0
AppConstants.Watermark.Spacing.sparse     // 150.0
```

---

## 📁 CoreData

### 实体名称
```swift
AppConstants.CoreData.modelName           // "QuickVault"
AppConstants.CoreData.storeFileName       // "QuickVault.sqlite"

AppConstants.CoreData.Entity.item         // "Item"
AppConstants.CoreData.Entity.textContent  // "TextContent"
AppConstants.CoreData.Entity.imageContent // "ImageContent"
AppConstants.CoreData.Entity.fileContent  // "FileContent"
```

---

## 🛠 工具方法 / Utility Methods

### 文件路径
```swift
let docs = AppConstants.FilePath.documentsDirectory()
let appSupport = AppConstants.FilePath.applicationSupportDirectory()
let storeURL = AppConstants.FilePath.coreDataStoreURL()
```

### Bundle ID
```swift
AppConstants.BundleID.quickVault  // "com.codans.quickvault"
AppConstants.BundleID.quickHold   // "com.codans.quickhold"
```

### 应用链接
```swift
AppConstants.AppURL.photoPC       // PhotoPC App Store 链接
AppConstants.AppURL.foxVault      // FoxVault App Store 链接
```

---

## 💡 最佳实践 / Best Practices

### ✅ 推荐
```swift
// 使用常量
let timeout = AppConstants.AutoLock.fiveMinutes
let key = AppConstants.UserDefaultsKeys.biometricEnabled
let icon = AppConstants.SystemIcon.checkmark
let text = LocalizationKeys.Items.title.localized

// 验证
guard password.count >= AppConstants.Validation.minPasswordLength else {
  throw AuthenticationError.passwordTooShort
}
```

### ❌ 避免
```swift
// 硬编码字符串
let timeout = 300
let key = "com.quickvault.biometricEnabled"
let icon = "checkmark.circle.fill"
let text = "items.title".localized

// 魔法数字
guard password.count >= 8 else {
  throw AuthenticationError.passwordTooShort
}
```

---

## 🔍 查找工具 / Find Tool

运行以下命令查找项目中的硬编码字符串：

```bash
./scripts/find_hardcoded_strings.sh
```

这将扫描并报告：
- UserDefaults 键
- 本地化键
- SF Symbols 图标
- 通知名称
- Logger 子系统
- 钥匙串键
- 魔法数字

---

## 📚 完整文档 / Full Documentation

- [CONSTANTS_GUIDE.md](CONSTANTS_GUIDE.md) - 详细使用指南
- [CONSTANTS_MIGRATION_PLAN.md](CONSTANTS_MIGRATION_PLAN.md) - 迁移计划
- [CONSTANTS_IMPLEMENTATION_SUMMARY.md](CONSTANTS_IMPLEMENTATION_SUMMARY.md) - 实施总结

---

**版本**: 1.0.0  
**更新日期**: 2026-01-15
