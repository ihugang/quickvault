# QuickVault / 随取

A secure macOS menu bar application for quick access to personal and business information.

一款安全的 macOS 菜单栏应用程序，用于快速访问个人和企业信息。

## Features / 功能

-   🔐 **Encrypted Storage** - AES-256-GCM encryption for all sensitive data / 所有敏感数据使用 AES-256-GCM 加密
-   🔑 **Touch ID & Password** - Biometric and password authentication / 生物识别和密码认证
-   📋 **Quick Copy** - One-click copy to clipboard / 一键复制到剪贴板
-   📎 **Encrypted Attachments** - Store encrypted files (images, PDFs) / 存储加密文件（图片、PDF）
-   🔄 **Auto-Update** - Automatic updates with Sparkle / 使用 Sparkle 自动更新
-   🎯 **Menu Bar Access** - Quick access from menu bar / 从菜单栏快速访问
-   📊 **Dashboard** - Full management interface / 完整的管理界面

## Requirements / 要求

-   macOS 13.0 or later / macOS 13.0 或更高版本
-   Xcode 15.0 or later (for development) / Xcode 15.0 或更高版本（用于开发）

## Building / 构建

```bash
# Clone the repository
git clone https://github.com/yourusername/QuickVault.git
cd QuickVault

# Build with Swift Package Manager
swift build

# Or open in Xcode
open QuickVault.xcodeproj
```

## Development / 开发

This project uses:

-   SwiftUI for UI
-   CoreData for persistence
-   CryptoKit for encryption
-   Sparkle for auto-updates
-   SwiftCheck for property-based testing

本项目使用：

-   SwiftUI 构建 UI
-   CoreData 进行持久化
-   CryptoKit 进行加密
-   Sparkle 进行自动更新
-   SwiftCheck 进行基于属性的测试

## Testing / 测试

```bash
# Run all tests
swift test

# Run specific test
swift test --filter QuickVaultTests
```

## License / 许可证

Copyright © 2026. All rights reserved.

## Security / 安全

-   All field values are encrypted using AES-256-GCM / 所有字段值使用 AES-256-GCM 加密
-   Encryption keys stored in macOS Keychain / 加密密钥存储在 macOS 钥匙串中
-   Automatic locking after inactivity / 不活动后自动锁定
-   Touch ID support for quick unlock / 支持触控 ID 快速解锁

## Privacy / 隐私

-   All data stored locally / 所有数据本地存储
-   No network communication (except for updates) / 无网络通信（更新除外）
-   No telemetry or analytics / 无遥测或分析
