# QuickVault 架构迁移指南

从 **单一 SPM 项目** 迁移到 **Package + App Project** 架构

## ✅ 迁移已完成!

整个项目已成功从单一 Swift Package Manager 项目迁移到模块化的 Xcode Workspace 架构。

## 当前架构

```
QuickVault/
├── src/                                # 所有源代码
│   ├── QuickVault.xcworkspace          # ✅ 已完成：Workspace（统一管理）
│   │
│   ├── QuickVaultKit/                  # ✅ 已完成：Swift Package（核心业务 SDK）
│   │   ├── Package.swift
│   │   ├── Sources/QuickVaultCore/
│   │   │   ├── Models/                 # CoreData, Templates
│   │   │   ├── Services/               # Crypto, Auth, Card, Keychain
│   │   │   └── Utilities/              # Validation
│   │   └── Tests/QuickVaultCoreTests/
│   │
│   ├── QuickVault-macOS-App/           # ✅ 已完成：macOS App Project
│   │   ├── project.yml                 # XcodeGen 配置
│   │   ├── QuickVault-macOS.xcodeproj  # 生成的 Xcode 项目
│   │   ├── QuickVault-macOS/
│   │   │   ├── App/                    # MenuBarManager, QuickVaultApp
│   │   │   ├── Views/                  # macOS UI 视图
│   │   │   └── Resources/              # Assets, Info.plist
│   │   └── QuickVault-macOSTests/
│   │
│   └── QuickVault-iOS-App/             # ✅ 已完成：iOS App Project
│       ├── project.yml                 # XcodeGen 配置
│       ├── QuickVault-iOS.xcodeproj    # 生成的 Xcode 项目
│       ├── QuickVault-iOS/
│       │   ├── App/                    # QuickVaultApp
│       │   ├── Services/               # WatermarkService (iOS 特有)
│       │   └── Resources/              # Assets, Info.plist
│       └── QuickVault-iOSTests/
│
├── .kiro/                              # 设计文档和需求
├── CLAUDE.md                           # 开发指南
├── MIGRATION_GUIDE.md                  # 本文档
├── REFACTOR_SUMMARY.md                 # 重构总结
└── README.md                           # 项目说明
```

## 如何使用

### 1. 打开 Workspace

```bash
open src/QuickVault.xcworkspace
```

### 2. 构建 macOS 应用

在 Xcode 中:
1. 选择 Scheme: **QuickVault-macOS**
2. 选择目标: **My Mac**
3. 按 `⌘R` 运行或 `⌘B` 构建

或使用命令行:
```bash
xcodebuild -workspace src/QuickVault.xcworkspace -scheme QuickVault-macOS build
```

### 3. 构建 iOS 应用

在 Xcode 中:
1. 选择 Scheme: **QuickVault-iOS**
2. 选择目标: iPhone/iPad 模拟器
3. 按 `⌘R` 运行或 `⌘B` 构建

或使用命令行:
```bash
xcodebuild -workspace src/QuickVault.xcworkspace -scheme QuickVault-iOS \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### 4. 重新生成 Xcode 项目 (如需修改配置)

如果修改了 `project.yml` 配置文件:

```bash
# macOS 项目
cd src/QuickVault-macOS-App
xcodegen generate

# iOS 项目
cd src/QuickVault-iOS-App
xcodegen generate
```

## 迁移完成清单

- ✅ QuickVaultKit Package 创建并验证构建
- ✅ macOS Xcode 项目生成 (使用 XcodeGen)
- ✅ macOS 源代码迁移到新项目结构
- ✅ macOS 项目构建成功
- ✅ iOS Xcode 项目生成 (使用 XcodeGen)
- ✅ iOS 源代码迁移到新项目结构
- ✅ iOS 项目构建成功
- ✅ Xcode Workspace 创建并配置
- ✅ 所有项目在 Workspace 中正常工作

## 已完成的工作

### ✅ QuickVaultKit Package（核心 SDK）

- ✅ 创建 `QuickVaultKit/Package.swift`
- ✅ 迁移所有共享代码到 `Sources/QuickVaultCore/`
- ✅ 迁移所有测试到 `Tests/QuickVaultCoreTests/`
- ✅ 验证构建成功

**验证命令**：
```bash
cd src/QuickVaultKit
swift build
swift test
```

### ✅ macOS App Project

- ✅ 使用 XcodeGen 创建 `project.yml` 配置
- ✅ 生成 `QuickVault-macOS.xcodeproj`
- ✅ 迁移 macOS 特定代码 (App, Views, Resources)
- ✅ 配置本地 QuickVaultKit 依赖
- ✅ 构建验证成功

### ✅ iOS App Project

- ✅ 使用 XcodeGen 创建 `project.yml` 配置
- ✅ 生成 `QuickVault-iOS.xcodeproj`
- ✅ 创建 iOS 特定代码 (QuickVaultApp, WatermarkService)
- ✅ 配置资源文件 (Info.plist, Assets, Entitlements)
- ✅ 配置本地 QuickVaultKit 依赖
- ✅ 构建验证成功

### ✅ Xcode Workspace

- ✅ 创建 `QuickVault.xcworkspace`
- ✅ 添加 QuickVaultKit Package
- ✅ 添加 macOS 和 iOS 项目
- ✅ 验证所有 Scheme 正常工作

## 技术细节

### QuickVaultKit（Package）
- ✅ CoreData Models
- ✅ Services (Crypto, Auth, Card, Keychain)
- ✅ Utilities (Validation)
- ✅ Card Templates
- ❌ **不包含**：UI 代码、平台特定功能

### macOS App
- ✅ MenuBarManager
- ✅ AppKit Views
- ✅ macOS 特定 UI 组件
- ✅ App 入口（QuickVaultApp.swift）
- ✅ Info.plist, Entitlements, Assets

### iOS App
- ✅ SwiftUI Views
- ✅ WatermarkService
- ✅ iOS 特定 UI 组件
- ✅ App 入口（QuickVaultApp.swift）
- ✅ Info.plist, Entitlements, Assets

## 优势

1. **清晰的职责分离**: Package 管业务，Project 管 UI
2. **独立测试**: QuickVaultKit 可以单独测试，不依赖 App
3. **更好的重用**: 未来可以创建 watchOS、tvOS App
4. **标准架构**: 符合 Apple 生态系统的最佳实践
5. **Xcode 完全支持**: 所有项目设置在 Xcode 中可见可编辑

## 下一步

选择 **方案 A**（推荐）或 **方案 B**，然后按步骤执行。

如果遇到问题，可以参考：
- `.kiro/specs/` 中的设计文档
- 原始 `macOS/` 和 `iOS/` 目录中的代码结构
