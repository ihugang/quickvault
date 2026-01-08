# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

QuickVault (随取) 是一个跨平台的安全信息管理应用，支持 **macOS** 和 **iOS**。应用采用本地优先架构，所有敏感数据使用 AES-256-GCM 加密，支持 Touch ID/Face ID 和主密码认证。

QuickVault is a cross-platform secure information management application supporting **macOS** and **iOS**. It uses a local-first architecture with AES-256-GCM encryption for all sensitive data, supporting Touch ID/Face ID and master password authentication.

### Platform Features / 平台特性

- **macOS**: 菜单栏应用，快速访问，全局热键 (Command+Shift+V)
- **iOS**: Tab Bar 导航，图片水印功能，Face ID/Touch ID 认证

### Code Sharing Strategy / 代码共享策略

- **Shared/Core**: 核心业务逻辑和数据层（Services, Models, Utilities）- 100% 共享
- **macOS/**: macOS 特定 UI 和功能（AppKit, 菜单栏管理）
- **iOS/**: iOS 特定 UI 和功能（SwiftUI, 水印服务）

## Build & Development Commands

### 在 Xcode 中开发（推荐）/ Development in Xcode (Recommended)

Xcode 原生支持 Swift Package Manager 项目，可以直接打开 `Package.swift` 进行开发：

```bash
# 用 Xcode 打开项目 / Open project in Xcode
open -a Xcode Package.swift

# 或双击 Package.swift 文件 / Or double-click Package.swift
```

#### Xcode 中的操作 / Working in Xcode

1. **选择运行目标 / Select Target**:
   - 点击 Xcode 顶部的 Scheme 选择器
   - macOS: 选择 `QuickVault-macOS` → `My Mac`
   - iOS: 选择 `QuickVault-iOS` → iPhone/iPad 模拟器或真机

2. **设置项目属性 / Project Settings**:
   - 在左侧导航栏点击 **QuickVault** 项目（蓝色图标）
   - 选择对应的 **Target**（QuickVault-macOS 或 QuickVault-iOS）
   - **General** 标签页:
     - Deployment Info → 最低 iOS/macOS 版本
     - App Icons and Launch Screen
     - Bundle Identifier, Version, Build
   - **Signing & Capabilities** 标签页:
     - Automatically manage signing（自动管理签名）
     - Team（开发者账号）
     - Capabilities（如 Keychain Sharing、AutoFill）

3. **构建和运行 / Build & Run**:
   - `⌘R`: 运行当前 Scheme
   - `⌘B`: 仅构建
   - `⌘U`: 运行测试
   - `⌘.`: 停止运行

4. **查看和编辑资源文件 / View & Edit Resources**:
   - App Icon: `iOS/Resources/Assets.xcassets/AppIcon.appiconset`
   - Entitlements: `iOS/Resources/QuickVault.entitlements`
   - Info.plist: `iOS/Resources/Info.plist`

### 命令行构建（可选）/ Command Line Build (Optional)

```bash
# Build macOS version / 构建 macOS 版本
swift build -c release --product QuickVault-macOS

# Build for iOS (requires Xcode with iOS SDK) / 构建 iOS 版本（需要 Xcode 和 iOS SDK）
# iOS 版本建议在 Xcode 中编译以获得完整的工具链支持

# Clean build artifacts / 清理构建产物
swift package clean
```

### Testing
```bash
# Run all shared core tests / 运行所有共享核心测试
swift test --filter QuickVaultCoreTests

# Run specific test suite / 运行特定测试套件
swift test --filter KeychainServiceTests
swift test --filter CryptoServiceTests
swift test --filter CardServiceTests
swift test --filter AuthenticationServiceTests

# Generate code coverage / 生成代码覆盖率
swift test --enable-code-coverage
```

### Running
```bash
# Run macOS application / 运行 macOS 应用
swift run QuickVault-macOS

# Or open in Xcode for both platforms / 或在 Xcode 中打开以支持两个平台
open -a Xcode Package.swift
```

## Architecture Overview

### Core Architectural Pattern: MVVM + Service Layer

QuickVault 采用 **MVVM (Model-View-ViewModel)** 架构,配合独立的服务层处理业务逻辑。这种分层设计确保了关注点分离和可测试性。

```
Menu Bar (AppKit) ←→ ViewModels ←→ Services ←→ CoreData + Keychain
```

### Key Architectural Principles

1. **Field-Level Encryption**: 所有敏感字段值在存储前使用 AES-GCM 加密,卡片标题和元数据不加密(用于搜索性能)
2. **Local-First**: 无网络通信,所有数据本地存储
3. **Security by Default**: 认证失败自动锁定,系统休眠/用户切换时立即锁定
4. **Service Abstraction**: 每个服务通过 protocol 定义接口,便于测试和替换实现

### Service Layer Structure

#### CryptoService (`QuickVault/Sources/Services/CryptoService.swift`)
- **职责**: AES-256-GCM 加密/解密,PBKDF2 密钥派生(100,000 迭代)
- **关键方法**:
  - `encrypt(_:)` / `decrypt(_:)`: 字符串字段加密
  - `encryptFile(_:)` / `decryptFile(_:)`: 文件附件加密
  - `deriveKey(from:salt:)`: 从主密码派生加密密钥
- **依赖**: KeychainService (存储盐值和密钥)

#### KeychainService (`QuickVault/Sources/Services/KeychainService.swift`)
- **职责**: macOS Keychain 安全存储(加密密钥、盐值、密码哈希)
- **关键方法**: `save(key:data:)`, `load(key:)`, `delete(key:)`, `exists(key:)`

#### AuthenticationService (`QuickVault/Sources/Services/AuthenticationService.swift`)
- **职责**: Touch ID 和主密码认证,锁定状态管理
- **关键特性**:
  - Touch ID 作为主要认证方式,主密码作为备选
  - 连续失败 3 次后强制 30 秒延迟
  - 系统休眠/用户切换时自动锁定

#### CardService (`QuickVault/Sources/Services/CardService.swift`)
- **职责**: 卡片 CRUD 操作,字段加密/解密,搜索和过滤
- **关键特性**:
  - 创建卡片时自动加密字段值
  - 搜索时解密字段值进行匹配
  - 支持三种卡片类型: General (通用)、Address (地址)、Invoice (发票)

### Data Model (CoreData)

#### Entities
- **Card**: 卡片主实体(id, title, type, group, isPinned, tagsJSON, createdAt, updatedAt)
- **CardField**: 字段实体(id, key, label, encryptedValue, order, isCopyable)
- **CardAttachment**: 附件实体(id, fileName, fileType, fileSize, encryptedData, thumbnailData)

#### Relationships
```
Card (1) ←→ (N) CardField
Card (1) ←→ (N) CardAttachment
```

#### CoreData Location
- Model: `QuickVault/Sources/Models/QuickVault.xcdatamodeld/`
- Generated classes: `QuickVault/Sources/Models/Card+CoreDataClass.swift` 等
- PersistenceController: `QuickVault/Sources/Models/PersistenceController.swift`

### Card Templates

#### Address Template (地址模板)
```swift
Fields: recipient(收件人), phone(手机号), province(省), city(市),
        district(区), address(详细地址), postalCode(邮编)*, notes(备注)*
        (* = optional)
Validation: 手机号格式(11位以1开头)
```

#### Invoice Template (发票模板)
```swift
Fields: companyName(公司名称), taxId(税号), address(地址), phone(电话),
        bankName(开户行), bankAccount(银行账号), notes(备注)*
Validation: 税号格式(18位统一社会信用代码)
```

#### General Text Template (通用文本模板)
```swift
Fields: content(内容)
Features: 支持多行文本,直接复制内容(不带标签)
```

## Testing Strategy

### 双重测试方法: Unit Tests + Property-Based Tests

项目使用 **SwiftCheck** 进行基于属性的测试,配合传统的单元测试,确保全面覆盖:

- **Unit Tests**: 验证特定场景、边缘情况、错误处理
- **Property Tests**: 验证通用属性(如加密往返、时间戳单调性、引用完整性)

### Property Test Configuration
- **最小迭代次数**: 每个属性测试 100 次
- **标记格式**: `// Feature: quick-vault-macos, Property N: [description]`
- **覆盖目标**: 核心业务逻辑 90%+,安全功能 100%

### Key Properties to Test
参见 `.kiro/specs/quick-vault-macos/design.md` 中的 44 个正确性属性,包括:
- Property 21: 字段加密往返(加密后解密应得到原值)
- Property 3: 卡片删除完整性(删除后卡片和字段均不存在)
- Property 28: 数据持久化往返(保存、重启后数据完整)
- Property 29: 引用完整性(无孤立字段)

## Security Considerations

### Encryption Details
- **算法**: AES-256-GCM (CryptoKit)
- **密钥派生**: PBKDF2-HMAC-SHA256, 100,000 iterations
- **盐值**: 32-byte 随机盐,存储于 Keychain
- **密钥存储**: macOS Keychain (`kSecClassGenericPassword`)

### What's Encrypted
- ✅ 所有 CardField 的 `encryptedValue`
- ✅ 所有 CardAttachment 的 `encryptedData` 和 `thumbnailData`
- ❌ Card.title (用于搜索性能)
- ❌ Card.type, Card.group (元数据)

### Threat Model
**防护**: 未授权访问数据库文件、锁定时的内存转储、离线攻击
**不防护**: 键盘记录恶意软件、解锁系统的物理访问、Keychain 被攻破

## Common Development Patterns

### Adding a New Card Template
1. 在 `CardService` 中定义字段结构(参考 `AddressTemplate` / `InvoiceTemplate`)
2. 添加验证逻辑(电话号码、税号等格式验证)
3. 实现 `formatForCopy()` 方法定义复制输出格式
4. 更新 UI 中的模板选择器

### Adding a New Service
1. 定义 `protocol` 接口(如 `protocol MyService { ... }`)
2. 实现类继承 `ObservableObject`(如果需要 UI 响应)
3. 在 `init()` 中注入依赖服务
4. 为 protocol 创建对应的单元测试和属性测试

### Working with Encrypted Fields
```swift
// Save encrypted field
let encryptedValue = try cryptoService.encrypt(fieldValue)
cardField.encryptedValue = encryptedValue

// Read encrypted field
let decryptedValue = try cryptoService.decrypt(cardField.encryptedValue)
```

### Testing with In-Memory CoreData
```swift
let controller = PersistenceController(inMemory: true)
let context = controller.viewContext
// Create test data...
```

## Project Structure

```
QuickVault/
├── Shared/                          # 共享代码（macOS + iOS）
│   └── Core/
│       ├── Models/                  # 数据模型（100% 共享）
│       │   ├── QuickVault.xcdatamodeld/  # CoreData schema
│       │   ├── Card+CoreDataClass.swift
│       │   ├── Card+CoreDataProperties.swift
│       │   ├── CardField+CoreDataClass.swift
│       │   ├── CardField+CoreDataProperties.swift
│       │   ├── CardAttachment+CoreDataClass.swift
│       │   ├── CardAttachment+CoreDataProperties.swift
│       │   ├── CardTemplate.swift   # 卡片模板定义
│       │   └── PersistenceController.swift
│       ├── Services/                # 核心业务服务（100% 共享）
│       │   ├── AuthenticationService.swift  # Touch ID/Face ID + password
│       │   ├── CardService.swift            # Card CRUD operations
│       │   ├── CryptoService.swift          # AES-256-GCM encryption
│       │   └── KeychainService.swift        # Keychain access
│       └── Utilities/               # 工具类（共享）
│           └── ValidationService.swift      # 数据验证
│
├── macOS/                           # macOS 特定代码
│   ├── Sources/
│   │   ├── App/
│   │   │   ├── QuickVaultApp.swift          # macOS App entry point
│   │   │   ├── MenuBarManager.swift         # 菜单栏管理
│   │   │   ├── CardEditorView.swift         # 卡片编辑视图
│   │   │   ├── CardEditorWindowController.swift  # NSWindow 控制器
│   │   │   └── IconProvider.swift           # macOS 图标提供者
│   │   └── Views/                   # macOS UI 视图
│   │       ├── SetupView.swift
│   │       ├── MenuBarIconView.swift
│   │       └── Components/          # 可复用 UI 组件
│   │           ├── CardTypePickerView.swift
│   │           ├── TagInputView.swift
│   │           └── StyledTextField.swift
│   └── Resources/
│       ├── Info.plist
│       ├── QuickVault.entitlements  # Keychain, file access
│       └── Assets.xcassets/         # macOS 图标资源
│
├── iOS/                             # iOS 特定代码
│   ├── Sources/
│   │   ├── App/
│   │   │   └── QuickVaultApp.swift          # iOS App entry point
│   │   ├── Views/                   # iOS UI 视图（待实现）
│   │   │   ├── Screens/             # 主要屏幕
│   │   │   └── Components/          # 可复用组件
│   │   ├── ViewModels/              # MVVM ViewModels（待实现）
│   │   └── Services/
│   │       └── WatermarkService.swift       # 图片水印（iOS 特有）
│   └── Resources/
│       ├── Info.plist
│       ├── QuickVault.entitlements
│       └── Assets.xcassets/         # iOS 图标资源
│
├── Tests/                           # 测试文件
│   ├── Shared/                      # 共享代码测试
│   │   ├── QuickVaultTests.swift
│   │   ├── KeychainServiceTests.swift
│   │   ├── CryptoServiceTests.swift
│   │   ├── CardServiceTests.swift
│   │   ├── CardTemplateTests.swift
│   │   ├── ValidationServiceTests.swift
│   │   └── AuthenticationServiceTests.swift
│   ├── macOS/                       # macOS 特定测试（待添加）
│   └── iOS/                         # iOS 特定测试（待添加）
│
├── .kiro/specs/                     # 设计文档
│   ├── quick-vault-macos/           # macOS 版本需求和设计
│   │   ├── requirements.md          # 23 requirements
│   │   ├── design.md                # Architecture, 44 properties
│   │   └── tasks.md                 # 开发任务跟踪
│   └── quick-vault-ios/             # iOS 版本需求和设计
│       ├── requirements.md          # 23 requirements
│       ├── design.md                # Architecture, 39 properties
│       └── tasks.md                 # 开发任务跟踪
│
├── Package.swift                    # SPM manifest（多 target 配置）
├── CLAUDE.md                        # 本文件
└── README.md
```

## Design Documents Location

完整的需求和设计文档位于 `.kiro/specs/` 目录：

### macOS 版本设计文档
- **requirements.md**: 23 个用户需求（中英双语），包含验收标准
- **design.md**: 架构设计、44 个正确性属性、测试策略、错误处理
- **tasks.md**: 开发任务跟踪

### iOS 版本设计文档
- **requirements.md**: 23 个用户需求（中英双语），包含验收标准
- **design.md**: 架构设计、39 个正确性属性、水印功能设计
- **tasks.md**: 开发任务跟踪

实现新功能时，应参考这些文档确保符合原始需求和架构设计。

## Important Notes

### Entitlements Required
- `com.apple.security.app-sandbox`: YES
- `com.apple.security.keychain`: YES (Keychain access)
- `com.apple.security.files.user-selected.read-write`: YES (for attachments)

### Menu Bar Behavior
- 应用启动时调用 `NSApp.setActivationPolicy(.accessory)` 隐藏 Dock 图标
- 仅在菜单栏显示图标,根据锁定状态切换图标(locked/unlocked)

### Auto-Lock Triggers
- 空闲 5 分钟(可配置)
- macOS 系统休眠(`NSWorkspace.willSleepNotification`)
- 用户切换(`NSWorkspace.sessionDidResignActiveNotification`)

### Dependencies (Package.swift)
- **SwiftCheck** (≥0.12.0): Property-based testing（共享测试）
- **Sparkle** (≥2.5.0): Automatic updates（仅 macOS）

### Platforms / 平台
- **macOS**: 14.0+ (Sonoma)
- **iOS**: 17.0+

## Localization

应用使用中英双语:
- 所有用户可见的错误消息格式: `"中文 / English"`
- 字段标签使用中文(收件人、手机号、税号等)
- 代码注释和文档使用中英混合

## Performance Expectations

- Card creation: < 100ms
- Search (1000 cards): < 50ms
- Unlock (with Touch ID): < 500ms
- Popover open: < 100ms

### Optimization Strategies
- 延迟解密: 仅在显示时解密字段
- 缓存: 解锁期间缓存解密值
- CoreData 索引: title, type, group
