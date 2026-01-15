# QuickVault Configuration Guide
# QuickVault 配置指南

本文档说明如何配置 QuickVault 项目的各种属性和设置。

## 1. 平台版本配置 (Platform Version)

### 在 Package.swift 中设置

最小 macOS 版本在 `Package.swift` 中的 `platforms` 字段配置:

```swift
platforms: [
  .macOS(.v14)  // macOS 14.0 (Sonoma) 或更高版本
]
```

### 可选的版本:

```swift
.macOS(.v13)  // macOS 13.0 (Ventura)
.macOS(.v14)  // macOS 14.0 (Sonoma) - 当前设置
.macOS(.v15)  // macOS 15.0 (Sequoia)
```

**当前设置**: macOS 14.0 (Sonoma)
**原因**: 支持最新的 SwiftUI 特性和 Menu Bar 功能

---

## 2. 应用属性配置

### Info.plist 配置

关键的应用属性在 `QuickVault/Resources/Info.plist` 中配置:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- 应用基本信息 -->
    <key>CFBundleName</key>
    <string>QuickVault</string>

    <key>CFBundleDisplayName</key>
    <string>随取</string>

    <key>CFBundleIdentifier</key>
    <string>com.quickvault.app</string>

    <key>CFBundleVersion</key>
    <string>1</string>

    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>

    <!-- 隐藏 Dock 图标 (仅菜单栏应用) -->
    <key>LSUIElement</key>
    <true/>

    <!-- 最小系统版本 -->
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>

    <!-- 应用分类 -->
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>

    <!-- 支持的语言 -->
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>

    <key>CFBundleLocalizations</key>
    <array>
        <string>zh_CN</string>
        <string>en</string>
    </array>

    <!-- 版权信息 -->
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 QuickVault. All rights reserved.</string>
</dict>
</plist>
```

### 当前需要创建的 Info.plist

当前项目还没有 Info.plist,建议创建一个。

---

## 3. Entitlements 配置

### QuickVault.entitlements

权限配置在 `QuickVault/Resources/QuickVault.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- 应用沙盒 -->
    <key>com.apple.security.app-sandbox</key>
    <true/>

    <!-- Keychain 访问 -->
    <key>com.apple.security.keychain</key>
    <true/>

    <!-- 用户选择的文件读写 (附件功能) -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>

    <!-- 网络访问 (Sparkle 自动更新) -->
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

---

## 4. Swift 编译器设置

### 在 Package.swift 中配置编译选项

```swift
swiftSettings: [
  // 启用严格并发检查 (Debug 模式)
  .unsafeFlags(["-strict-concurrency=complete"], .when(configuration: .debug)),

  // 启用完整的类型检查
  .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug)),

  // 优化设置 (Release 模式)
  .unsafeFlags(["-O"], .when(configuration: .release))
]
```

---

## 5. 版本号管理

### 语义化版本 (Semantic Versioning)

QuickVault 遵循语义化版本规范:

```
MAJOR.MINOR.PATCH

例如: 0.1.0
- 0: 主版本 (Major) - 不兼容的 API 变更
- 1: 次版本 (Minor) - 向后兼容的功能新增
- 0: 补丁版本 (Patch) - 向后兼容的问题修复
```

### 在哪里更新版本号:

1. **Info.plist**: `CFBundleShortVersionString` (用户可见版本)
2. **Info.plist**: `CFBundleVersion` (构建版本号,递增整数)

---

## 6. 代码签名配置

### 开发签名

```bash
# 查看可用的签名证书
security find-identity -v -p codesigning

# 在 Xcode 中设置
# Product -> Scheme -> Edit Scheme -> Run -> Options
# 选择 Developer ID 证书
```

### 发布签名

发布到 Mac App Store 外需要:
- Developer ID Application 证书
- Developer ID Installer 证书
- 公证 (Notarization)

---

## 7. 构建配置

### Debug vs Release

**Debug 模式**:
- 启用断言 (Assertions)
- 包含调试符号
- 禁用优化
- 启用严格并发检查

**Release 模式**:
- 禁用断言
- 移除调试符号
- 启用优化 (-O)
- 代码签名和公证

### 在终端构建不同配置:

```bash
# Debug 构建
swift build

# Release 构建
swift build -c release

# 清理构建产物
swift package clean
```

---

## 8. Sparkle 自动更新配置

### 配置步骤:

1. **生成 EdDSA 密钥对**:
   ```bash
   ./generate_keys  # Sparkle 提供的工具
   ```

2. **在 Info.plist 中添加配置**:
   ```xml
   <key>SUFeedURL</key>
   <string>https://your-domain.com/appcast.xml</string>

   <key>SUPublicEDKey</key>
   <string>你的公钥</string>

   <key>SUEnableAutomaticChecks</key>
   <true/>
   ```

3. **创建 appcast.xml**:
   参考 Sparkle 文档创建更新源

---

## 9. 常见配置任务

### 修改应用名称

1. 在 `Package.swift` 中: `name: "NewName"`
2. 在 `Info.plist` 中: `CFBundleName` 和 `CFBundleDisplayName`

### 修改 Bundle Identifier

在 `Info.plist` 中修改 `CFBundleIdentifier`:
```xml
<key>CFBundleIdentifier</key>
<string>com.yourcompany.yourapp</string>
```

### 修改应用图标

1. 准备不同尺寸的图标 (16x16, 32x32, 128x128, 256x256, 512x512)
2. 放入 `Resources/Assets.xcassets/AppIcon.appiconset/`
3. 更新 `Contents.json`

### 添加语言支持

1. 创建 `.lproj` 文件夹 (如 `zh_CN.lproj`, `en.lproj`)
2. 在 `Info.plist` 中更新 `CFBundleLocalizations`

---

## 10. 当前项目配置总结

| 配置项 | 当前值 | 位置 |
|--------|--------|------|
| 最小 macOS 版本 | 14.0 (Sonoma) | Package.swift |
| Swift 工具版本 | 5.9 | Package.swift |
| Bundle Identifier | com.quickvault.app | Info.plist (待创建) |
| 应用名称 | QuickVault / 随取 | Package.swift |
| 版本号 | 0.1.0 | Info.plist (待创建) |
| 应用类型 | 菜单栏应用 (LSUIElement) | Info.plist (待创建) |
| 沙盒 | 启用 | QuickVault.entitlements |
| Keychain | 启用 | QuickVault.entitlements |

---

## 下一步

建议创建完整的 Info.plist 和 Entitlements 文件来配置应用的详细属性。

需要帮助配置其他项目属性?随时告诉我!
