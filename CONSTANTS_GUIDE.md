# Constants Management / 常量管理

## 概述 / Overview

为了提高代码的可维护性、类型安全性和可读性，QuickVault 项目现在采用集中管理的常量系统。所有常量字符串都集中定义在 `QuickVaultKit/Sources/QuickVaultCore/Constants/` 目录下。

To improve code maintainability, type safety, and readability, QuickVault now uses a centralized constants system. All constant strings are defined in `QuickVaultKit/Sources/QuickVaultCore/Constants/`.

## 文件结构 / File Structure

### AppConstants.swift
包含应用级别的常量，包括：
- **Bundle IDs** - 应用包标识符
- **Logger** - 日志子系统和分类
- **Keychain** - 钥匙串键名
- **UserDefaults Keys** - 用户默认设置键
- **Notification Names** - 通知名称
- **System Icons** - SF Symbols 图标名称
- **CoreData** - Core Data 实体和模型名称
- **Crypto** - 加密相关常量
- **Validation** - 验证规则常量
- **Auto Lock** - 自动锁定超时值
- **Rate Limiting** - 速率限制配置
- **File Paths** - 文件路径辅助方法
- **Watermark** - 水印相关常量
- **App URLs** - 应用链接

### LocalizationKeys.swift
包含所有本地化字符串键，按功能分组：
- **Authentication** - 认证相关
- **Items** - 项目管理
- **Settings** - 设置界面
- **Watermark** - 水印功能
- **Export** - 导出功能
- **OCR** - OCR 识别
- **Common** - 通用字符串

## 使用方法 / Usage

### 1. 使用 AppConstants

#### 之前 / Before:
```swift
private let logger = Logger(subsystem: "com.codans.quickvault", category: "AuthService")
private let autoLockKey = "com.quickvault.autoLockTimeout"
let timeout = 300
```

#### 之后 / After:
```swift
private let logger = Logger(
  subsystem: AppConstants.Logger.subsystem, 
  category: AppConstants.Logger.Category.auth
)
private let autoLockKey = AppConstants.UserDefaultsKeys.autoLockTimeout
let timeout = AppConstants.AutoLock.fiveMinutes
```

### 2. 使用 LocalizationKeys

#### 之前 / Before:
```swift
Text(localizationManager.localizedString("items.type.text"))
Button("auth.change.password") { }
let errorKey = "auth.error.password.incorrect"
```

#### 之后 / After:
```swift
Text(localizationManager.localizedString(LocalizationKeys.Items.ItemType.text))
Button(LocalizationKeys.Auth.changePassword.localized) { }
let errorKey = LocalizationKeys.Auth.Error.passwordIncorrect
```

### 3. 使用 String Extension

提供了便捷的字符串扩展方法：

```swift
// 简单本地化
let title = LocalizationKeys.Items.title.localized

// 带参数的本地化
let message = LocalizationKeys.Auth.Error.rateLimited.localized(seconds)

// 或者使用字符串字面量（但不推荐，降低类型安全性）
let text = "items.empty".localized
```

### 4. 系统图标

#### 之前 / Before:
```swift
Image(systemName: "checkmark.circle.fill")
Image(systemName: "xmark.circle.fill")
Image(systemName: "doc.text.fill")
```

#### 之后 / After:
```swift
Image(systemName: AppConstants.SystemIcon.checkmark)
Image(systemName: AppConstants.SystemIcon.close)
Image(systemName: AppConstants.SystemIcon.textDocument)
```

### 5. UserDefaults 键

#### 之前 / Before:
```swift
UserDefaults.standard.set(value, forKey: "app_language")
UserDefaults.standard.bool(forKey: "com.quickvault.biometricEnabled")
```

#### 之后 / After:
```swift
UserDefaults.standard.set(value, forKey: AppConstants.UserDefaultsKeys.appLanguage)
UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.biometricEnabled)
```

### 6. 通知名称

#### 之前 / Before:
```swift
let name = Notification.Name("com.quickvault.authStateChanged")
NotificationCenter.default.post(name: name, object: nil)
```

#### 之后 / After:
```swift
NotificationCenter.default.post(
  name: AppConstants.Notification.authStateChanged, 
  object: nil
)
```

## 优势 / Benefits

1. **类型安全** - 编译时检查，避免拼写错误
   - Type Safety - Compile-time checking, avoiding typos

2. **自动完成** - IDE 提供智能提示
   - Auto-completion - IDE provides intelligent suggestions

3. **易于重构** - 修改常量只需在一处更改
   - Easy Refactoring - Change constants in one place only

4. **文档化** - 代码即文档，清晰展示所有可用常量
   - Self-documenting - Code serves as documentation

5. **可维护性** - 集中管理，便于查找和更新
   - Maintainability - Centralized management, easy to find and update

6. **减少魔法字符串** - 消除硬编码字符串
   - Fewer Magic Strings - Eliminates hardcoded strings

## 最佳实践 / Best Practices

### ✅ 推荐 / Recommended

```swift
// 使用常量
let icon = AppConstants.SystemIcon.textDocument
let key = LocalizationKeys.Items.title

// 分组相关常量
enum Security {
  static let minPasswordLength = 8
  static let maxAttempts = 5
}
```

### ❌ 避免 / Avoid

```swift
// 硬编码字符串
let icon = "doc.text.fill"
let key = "items.title"

// 直接使用魔法数字
if attempts > 5 { }
if password.count < 8 { }
```

## 迁移指南 / Migration Guide

### 步骤 / Steps

1. **识别硬编码字符串** - 查找项目中的字符串字面量
   - Identify hardcoded strings in the project

2. **检查是否已定义** - 在常量文件中查找对应的常量
   - Check if constant already exists

3. **添加新常量**（如需要）- 在适当的枚举中添加
   - Add new constant if needed

4. **替换使用** - 用常量替换硬编码字符串
   - Replace usage with constant

5. **测试** - 确保功能正常
   - Test to ensure functionality works

### 示例迁移 / Example Migration

```swift
// 1. 发现硬编码字符串
// Found hardcoded string
Button("Save") { }

// 2. 添加到 LocalizationKeys（如不存在）
// Add to LocalizationKeys if not exists
public enum Common {
  public static let save = "common.save"
}

// 3. 替换使用
// Replace usage
Button(LocalizationKeys.Common.save.localized) { }
```

## 添加新常量 / Adding New Constants

### 应用常量 / App Constants

```swift
// 在 AppConstants.swift 中添加
extension AppConstants {
  enum MyFeature {
    static let myConstant = "value"
    static let myNumber = 42
  }
}
```

### 本地化键 / Localization Keys

```swift
// 在 LocalizationKeys.swift 中添加
extension LocalizationKeys {
  enum MyFeature {
    static let title = "myfeature.title"
    static let description = "myfeature.description"
  }
}
```

## 注意事项 / Notes

1. **保持一致性** - 使用相同的命名约定
   - Maintain Consistency - Use consistent naming conventions

2. **合理分组** - 按功能模块组织常量
   - Logical Grouping - Organize by functional modules

3. **避免过度嵌套** - 保持层级简洁
   - Avoid Over-nesting - Keep hierarchy simple

4. **文档注释** - 为复杂常量添加注释
   - Document - Add comments for complex constants

5. **向后兼容** - 修改现有常量时要谨慎
   - Backward Compatibility - Be careful when changing existing constants

## 相关文件 / Related Files

- `src/QuickVaultKit/Sources/QuickVaultCore/Constants/AppConstants.swift`
- `src/QuickVaultKit/Sources/QuickVaultCore/Constants/LocalizationKeys.swift`
- `src/QuickVaultKit/Sources/QuickVaultCore/Services/AuthenticationService.swift`
- `src/QuickVaultKit/Sources/QuickVaultCore/Models/ItemType.swift`
- `src/QuickVault-iOS-App/QuickVault-iOS/Services/AutoLockManager.swift`

## 更新日期 / Last Updated

2026-01-15
