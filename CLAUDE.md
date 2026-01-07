# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

QuickVault (随取) 是一个安全的 macOS 菜单栏应用程序,用于快速访问和管理个人及企业信息(地址、发票、密码等)。应用采用本地优先架构,所有敏感数据使用 AES-256-GCM 加密,支持 Touch ID 和主密码认证。

QuickVault is a secure macOS menu bar application for quick access to personal and business information (addresses, invoices, credentials, etc.). It uses a local-first architecture with AES-256-GCM encryption for all sensitive data, supporting Touch ID and master password authentication.

## Build & Development Commands

### Building
```bash
# Build the project
swift build

# Build in release mode
swift build -c release

# Clean build artifacts
swift package clean
```

### Testing
```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter QuickVaultTests
swift test --filter KeychainServiceTests
swift test --filter CryptoServiceTests
swift test --filter CardServiceTests
swift test --filter AuthenticationServiceTests

# Generate code coverage
swift test --enable-code-coverage
```

### Running
```bash
# Run the application
swift run

# Or open in Xcode
open Package.swift
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
├── Sources/
│   ├── QuickVaultApp.swift          # App entry point, menu bar setup
│   ├── Models/                      # CoreData models
│   │   ├── QuickVault.xcdatamodeld/ # CoreData schema
│   │   ├── Card+CoreDataClass.swift
│   │   ├── CardField+CoreDataClass.swift
│   │   ├── CardAttachment+CoreDataClass.swift
│   │   └── PersistenceController.swift
│   ├── Services/                    # Business logic layer
│   │   ├── CryptoService.swift      # Encryption/decryption
│   │   ├── KeychainService.swift    # Keychain access
│   │   ├── AuthenticationService.swift # Touch ID + password auth
│   │   └── CardService.swift        # Card CRUD operations
│   └── Utilities/                   # Helper classes
│       └── IconProvider.swift
├── Tests/                           # Test files
│   ├── QuickVaultTests.swift
│   ├── KeychainServiceTests.swift
│   ├── CryptoServiceTests.swift
│   ├── CardServiceTests.swift
│   └── AuthenticationServiceTests.swift
├── Resources/
│   ├── Info.plist
│   ├── QuickVault.entitlements      # Keychain access, file access
│   └── Assets.xcassets/             # Icons (menu bar, locked/unlocked)
├── .kiro/specs/quick-vault-macos/   # Design documents
│   ├── requirements.md              # 23 requirements (中英双语)
│   ├── design.md                    # Architecture, 44 properties
│   └── tasks.md
├── Package.swift                    # SPM manifest
└── README.md
```

## Design Documents Location

完整的需求和设计文档位于 `.kiro/specs/quick-vault-macos/`:

- **requirements.md**: 23 个用户需求(中英双语),包含验收标准
- **design.md**: 架构设计、44 个正确性属性、测试策略、错误处理
- **tasks.md**: 开发任务跟踪

实现新功能时,应参考这些文档确保符合原始需求和架构设计。

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
- **SwiftCheck** (≥0.12.0): Property-based testing
- **Sparkle** (≥2.5.0): Automatic updates (future)

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
