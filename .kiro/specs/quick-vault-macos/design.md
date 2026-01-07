# Design Document / 设计文档

## Overview / 概述

QuickVault is a macOS menu bar application built with SwiftUI and CoreData that provides secure, encrypted storage and quick access to personal and business information. The application follows a local-first architecture with field-level encryption, Touch ID/password authentication, and automatic locking mechanisms.

随取是一款使用 SwiftUI 和 CoreData 构建的 macOS 菜单栏应用程序，提供安全的加密存储和对个人及企业信息的快速访问。应用程序采用本地优先架构，具有字段级加密、触控 ID/密码认证和自动锁定机制。

### Technology Stack / 技术栈

-   **UI Framework / UI 框架**: SwiftUI
-   **Data Persistence / 数据持久化**: CoreData with SQLite backend / CoreData 配合 SQLite 后端
-   **Encryption / 加密**: CryptoKit (AES-GCM) for field-level encryption / CryptoKit (AES-GCM) 用于字段级加密
-   **Secure Storage / 安全存储**: Keychain for encryption keys / 钥匙串用于存储加密密钥
-   **Authentication / 认证**: LocalAuthentication framework (Touch ID + password) / LocalAuthentication 框架（触控 ID + 密码）
-   **Menu Bar / 菜单栏**: AppKit integration via NSStatusBar / 通过 NSStatusBar 集成 AppKit
-   **Auto-Update / 自动更新**: Sparkle framework for automatic updates / Sparkle 框架用于自动更新

---

## Architecture / 架构

### High-Level Architecture / 高层架构

```
┌─────────────────────────────────────────────────────────┐
│                    Menu Bar (AppKit)                     │
│                      菜单栏 (AppKit)                      │
│  ┌──────────────────┐  ┌──────────────────┐            │
│  │  NSMenu (Cards)  │  │ Open Dashboard   │            │
│  │  菜单（卡片）     │  │  打开仪表板       │            │
│  │  - Personal ▸    │  │                  │            │
│  │  - Company ▸     │  │                  │            │
│  │  - Settings      │  │                  │            │
│  │  - Lock          │  │                  │            │
│  └──────────────────┘  └──────────────────┘            │
└────────────┬───────────────────────┬────────────────────┘
             │                       │
             │                       │
┌────────────▼────────────┐  ┌──────▼─────────────────────┐
│   Quick Menu Access     │  │  Dashboard Window          │
│   快速菜单访问           │  │  仪表板窗口                 │
│  ┌──────────────────┐   │  │  ┌──────────────────────┐ │
│  │ Card Submenus    │   │  │  │  Search View         │ │
│  │ 卡片子菜单        │   │  │  │  搜索视图             │ │
│  │ - Card Title     │   │  │  └──────────────────────┘ │
│  │   ▸ Copy All     │   │  │  ┌──────────────────────┐ │
│  │   ▸ Copy Field1  │   │  │  │  Card List           │ │
│  │   ▸ Copy Field2  │   │  │  │  卡片列表             │ │
│  └──────────────────┘   │  │  │  - Group Filter      │ │
└─────────────────────────┘  │  │  - Pin/Unpin         │ │
                             │  └──────────────────────┘ │
                             │  ┌──────────────────────┐ │
                             │  │  Card Editor         │ │
                             │  │  卡片编辑器           │ │
                             │  │  - Field Editor      │ │
                             │  │  - Template Selector │ │
                             │  └──────────────────────┘ │
                             └────────────────────────────┘
                                          │
┌─────────────────────────────────────────▼──────────────┐
│                  View Models (MVVM)                      │
│                  视图模型 (MVVM)                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │CardViewModel │  │ AuthViewModel│  │ SettingsVM    │  │
│  │ 卡片视图模型  │  │ 认证视图模型  │  │ 设置视图模型  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│  ┌──────────────┐  ┌──────────────┐                     │
│  │MenuViewModel │  │DashboardVM   │                     │
│  │ 菜单视图模型  │  │ 仪表板视图模型│                     │
│  └──────────────┘  └──────────────┘                     │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                  Service Layer                           │
│                    服务层                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │CardService   │  │CryptoService │  │ AuthService  │  │
│  │ 卡片服务      │  │ 加密服务      │  │ 认证服务      │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              CoreData Stack                              │
│              CoreData 栈                                  │
│  ┌──────────────┐  ┌──────────────┐                     │
│  │ Card Entity  │  │ Field Entity │                     │
│  │  卡片实体     │  │  字段实体     │                     │
│  └──────────────┘  └──────────────┘                     │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│         SQLite Database + Keychain                       │
│         SQLite 数据库 + 钥匙串                            │
└─────────────────────────────────────────────────────────┘
```

### Architecture Principles / 架构原则

1. **MVVM Pattern / MVVM 模式**: Separation of UI, business logic, and data / UI、业务逻辑和数据分离
2. **Local-First / 本地优先**: All data stored locally, no network dependency / 所有数据本地存储，无网络依赖
3. **Security by Default / 默认安全**: All sensitive data encrypted at rest / 所有敏感数据静态加密
4. **Single Responsibility / 单一职责**: Each service handles one concern / 每个服务处理一个关注点

---

## Components and Interfaces / 组件和接口

### 1. Menu Bar Manager / 菜单栏管理器

**Responsibility / 职责**: Manages the macOS menu bar icon and hierarchical menu with groups and cards / 管理 macOS 菜单栏图标和包含分组和卡片的层级菜单

```swift
class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    @Published var isLocked: Bool = true

    func setupMenuBar()
    func buildMenu(cards: [Card])
    func buildGroupSubmenu(group: CardGroup, cards: [Card]) -> NSMenu
    func buildCardSubmenu(card: Card) -> NSMenu
    func updateIcon(locked: Bool)
    func showDashboard()
}
```

**Key Features / 关键特性**:

-   Creates NSStatusItem in menu bar / 在菜单栏创建 NSStatusItem
-   Builds hierarchical NSMenu with groups and cards / 构建包含分组和卡片的层级 NSMenu
-   Creates submenus for each group (Personal, Company) / 为每个分组创建子菜单（个人、公司）
-   Creates card-specific submenus with copy options / 为每张卡片创建包含复制选项的子菜单
-   Updates icon based on lock state / 根据锁定状态更新图标
-   Handles global keyboard shortcut / 处理全局键盘快捷键
-   Opens Dashboard window on demand / 按需打开仪表板窗口

**Menu Structure / 菜单结构**:

```
QuickVault
├── Personal ▸
│   ├── Card 1 ▸
│   │   ├── Copy All
│   │   ├── Copy Field 1
│   │   └── Copy Field 2
│   └── Card 2 ▸
│       └── ...
├── Company ▸
│   └── ...
├── ───────────
├── Open Dashboard...
├── Settings...
├── Lock
└── Quit
```

---

### 2. Authentication Service / 认证服务

**Responsibility / 职责**: Handles user authentication via Touch ID and master password / 通过触控 ID 和主密码处理用户认证

```swift
protocol AuthenticationService {
    func authenticate() async throws -> Bool
    func authenticateWithTouchID() async throws -> Bool
    func authenticateWithPassword(_ password: String) async throws -> Bool
    func setupMasterPassword(_ password: String) async throws
    func changeMasterPassword(old: String, new: String) async throws
    func lock()
    var isLocked: Bool { get }
}

class AuthService: AuthenticationService {
    private let context = LAContext()
    private let keychainService: KeychainService

    // Implementation
}
```

**Key Features / 关键特性**:

-   Touch ID biometric authentication / 触控 ID 生物识别认证
-   Master password fallback / 主密码备用方案
-   Failed attempt tracking with delay / 失败尝试跟踪及延迟
-   Lock state management / 锁定状态管理

---

### 3. Crypto Service / 加密服务

**Responsibility / 职责**: Provides encryption and decryption for sensitive field data / 为敏感字段数据提供加密和解密

```swift
protocol CryptoService {
    func encrypt(_ data: String) throws -> Data
    func decrypt(_ data: Data) throws -> String
    func deriveKey(from password: String, salt: Data) throws -> SymmetricKey
    func generateSalt() -> Data
}

class CryptoServiceImpl: CryptoService {
    private var encryptionKey: SymmetricKey?

    func encrypt(_ data: String) throws -> Data {
        guard let key = encryptionKey else {
            throw CryptoError.keyNotAvailable
        }
        let dataToEncrypt = Data(data.utf8)
        let sealedBox = try AES.GCM.seal(dataToEncrypt, using: key)
        return sealedBox.combined!
    }

    func decrypt(_ data: Data) throws -> String {
        guard let key = encryptionKey else {
            throw CryptoError.keyNotAvailable
        }
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return String(data: decryptedData, encoding: .utf8)!
    }
}
```

**Key Features / 关键特性**:

-   AES-GCM encryption for field values / 字段值的 AES-GCM 加密
-   Key derivation from master password using PBKDF2 / 使用 PBKDF2 从主密码派生密钥
-   Salt generation and storage / 盐值生成和存储
-   Secure key storage in Keychain / 在钥匙串中安全存储密钥

---

### 4. Keychain Service / 钥匙串服务

**Responsibility / 职责**: Manages secure storage of encryption keys and master password hash / 管理加密密钥和主密码哈希的安全存储

```swift
protocol KeychainService {
    func save(key: String, data: Data) throws
    func load(key: String) throws -> Data
    func delete(key: String) throws
    func exists(key: String) -> Bool
}

class KeychainServiceImpl: KeychainService {
    private let service = "com.quickvault.app"

    func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    // Other methods...
}
```

**Key Features / 关键特性**:

-   Stores encryption key derived from master password / 存储从主密码派生的加密密钥
-   Stores password salt / 存储密码盐值
-   Stores master password hash for verification / 存储主密码哈希用于验证
-   Secure deletion on password change / 密码更改时安全删除

---

### 5. Card Service / 卡片服务

**Responsibility / 职责**: Business logic for card CRUD operations / 卡片 CRUD 操作的业务逻辑

```swift
protocol CardService {
    func createCard(type: CardType, title: String, group: CardGroup, fields: [CardFieldData]) async throws -> Card
    func updateCard(_ card: Card, fields: [CardFieldData]) async throws
    func deleteCard(_ card: Card) async throws
    func fetchAllCards() async throws -> [Card]
    func searchCards(query: String) async throws -> [Card]
    func togglePin(_ card: Card) async throws
}

class CardServiceImpl: CardService {
    private let context: NSManagedObjectContext
    private let cryptoService: CryptoService

    func createCard(type: CardType, title: String, group: CardGroup, fields: [CardFieldData]) async throws -> Card {
        let card = Card(context: context)
        card.id = UUID()
        card.title = title
        card.type = type.rawValue
        card.group = group.rawValue
        card.createdAt = Date()
        card.updatedAt = Date()
        card.isPinned = false

        for (index, fieldData) in fields.enumerated() {
            let field = CardField(context: context)
            field.id = UUID()
            field.key = fieldData.key
            field.label = fieldData.label
            field.encryptedValue = try cryptoService.encrypt(fieldData.value)
            field.order = Int16(index)
            field.card = card
        }

        try context.save()
        return card
    }

    // Other methods...
}
```

**Key Features / 关键特性**:

-   Encrypts field values before saving / 保存前加密字段值
-   Decrypts field values when loading / 加载时解密字段值
-   Handles card templates (Address, Invoice, General) / 处理卡片模板（地址、发票、通用）
-   Search across titles, tags, and decrypted field values / 跨标题、标签和解密字段值搜索

---

### 6. Card View Model / 卡片视图模型

**Responsibility / 职责**: Manages UI state and user interactions for cards / 管理卡片的 UI 状态和用户交互

```swift
@MainActor
class CardViewModel: ObservableObject {
    @Published var cards: [Card] = []
    @Published var filteredCards: [Card] = []
    @Published var searchQuery: String = ""
    @Published var selectedGroup: CardGroup = .all
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let cardService: CardService
    private let authService: AuthenticationService

    func loadCards() async
    func createCard(type: CardType, title: String, group: CardGroup, fields: [CardFieldData]) async
    func updateCard(_ card: Card, fields: [CardFieldData]) async
    func deleteCard(_ card: Card) async
    func togglePin(_ card: Card) async
    func copyCard(_ card: Card)
    func copyField(_ field: CardField)
    func filterCards()
}
```

**Key Features / 关键特性**:

-   Reactive UI updates via @Published properties / 通过 @Published 属性实现响应式 UI 更新
-   Search filtering with real-time updates / 实时更新的搜索过滤
-   Group filtering / 分组过滤
-   Copy operations with clipboard integration / 与剪贴板集成的复制操作

---

### 7. Dashboard Window Manager / 仪表板窗口管理器

**Responsibility / 职责**: Manages the Dashboard window for comprehensive card management / 管理用于全面卡片管理的仪表板窗口

```swift
class DashboardWindowManager: ObservableObject {
    private var window: NSWindow?
    @Published var isVisible: Bool = false

    func showDashboard()
    func hideDashboard()
    func setupWindow()
}

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var cards: [Card] = []
    @Published var selectedCard: Card?
    @Published var searchQuery: String = ""
    @Published var selectedGroup: CardGroup = .all
    @Published var isEditing: Bool = false

    private let cardService: CardService

    func loadCards() async
    func selectCard(_ card: Card)
    func startEditing()
    func saveCard() async
    func cancelEditing()
    func deleteSelectedCard() async
}
```

**Key Features / 关键特性**:

-   Dedicated window for card management / 专用的卡片管理窗口
-   Full CRUD operations interface / 完整的 CRUD 操作界面
-   Search and filter capabilities / 搜索和过滤功能
-   Card editor with template support / 支持模板的卡片编辑器
-   Group filtering and organization / 分组过滤和组织
-   Pin/unpin functionality / 置顶/取消置顶功能

---

### 8. Auto-Lock Manager / 自动锁定管理器

**Responsibility / 职责**: Monitors user activity and system events to trigger automatic locking / 监控用户活动和系统事件以触发自动锁定

```swift
class AutoLockManager: ObservableObject {
    @Published var lockTimeout: TimeInterval = 300 // 5 minutes
    private var idleTimer: Timer?
    private let authService: AuthenticationService

    func startMonitoring()
    func stopMonitoring()
    func resetIdleTimer()
    func handleSystemSleep()
    func handleUserSwitch()

    private func setupSystemEventObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSystemSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleUserSwitch),
            name: NSWorkspace.sessionDidResignActiveNotification,
            object: nil
        )
    }
}
```

**Key Features / 关键特性**:

-   Idle timer with configurable timeout / 可配置超时的空闲计时器
-   System sleep detection / 系统休眠检测
-   User switch detection / 用户切换检测
-   Automatic lock trigger / 自动锁定触发

---

### 9. Settings Manager / 设置管理器

**Responsibility / 职责**: Manages application settings and preferences / 管理应用程序设置和偏好

```swift
class SettingsManager: ObservableObject {
    @AppStorage("autoLockTimeout") var autoLockTimeout: Int = 300
    @AppStorage("globalShortcut") var globalShortcut: String = "⌥Space"
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("touchIDEnabled") var touchIDEnabled: Bool = true

    func updateAutoLockTimeout(_ seconds: Int)
    func updateGlobalShortcut(_ shortcut: String)
    func toggleLaunchAtLogin()
    func toggleTouchID()
}
```

**Key Features / 关键特性**:

-   UserDefaults integration via @AppStorage / 通过 @AppStorage 集成 UserDefaults
-   Launch at login configuration / 登录时启动配置
-   Global shortcut customization / 全局快捷键自定义
-   Auto-lock timeout configuration / 自动锁定超时配置

---

## Data Models / 数据模型

### CoreData Entities / CoreData 实体

#### Card Entity / 卡片实体

```swift
@objc(Card)
public class Card: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var type: String // "general", "address", "invoice"
    @NSManaged public var group: String // "personal", "company"
    @NSManaged public var tagsJSON: String? // JSON array of tags
    @NSManaged public var isPinned: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var fields: NSSet? // Relationship to CardField
    @NSManaged public var attachments: NSSet? // Relationship to CardAttachment
}
```

#### CardField Entity / 卡片字段实体

```swift
@objc(CardField)
public class CardField: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var key: String // Field identifier (e.g., "phone", "taxId")
    @NSManaged public var label: String // Display label (e.g., "电话号码", "税号")
    @NSManaged public var encryptedValue: Data // AES-GCM encrypted field value
    @NSManaged public var order: Int16 // Display order
    @NSManaged public var isCopyable: Bool
    @NSManaged public var card: Card? // Relationship to Card
}
```

#### CardAttachment Entity / 卡片附件实体

```swift
@objc(CardAttachment)
public class CardAttachment: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var fileName: String // Original file name
    @NSManaged public var fileType: String // MIME type (e.g., "image/png", "application/pdf")
    @NSManaged public var fileSize: Int64 // File size in bytes
    @NSManaged public var encryptedData: Data // AES-GCM encrypted file data
    @NSManaged public var thumbnailData: Data? // Encrypted thumbnail for preview
    @NSManaged public var createdAt: Date
    @NSManaged public var card: Card? // Relationship to Card
}
```

### Attachment Service / 附件服务

    @NSManaged public var encryptedValue: Data // AES-GCM encrypted field value
    @NSManaged public var order: Int16 // Display order
    @NSManaged public var isCopyable: Bool
    @NSManaged public var card: Card? // Relationship to Card

}

````

### Card Templates / 卡片模板

#### Address Template / 地址模板

```swift
struct AddressTemplate {
    static let fields: [FieldDefinition] = [
        FieldDefinition(key: "recipient", label: "收件人", required: true),
        FieldDefinition(key: "phone", label: "手机号", required: true),
        FieldDefinition(key: "province", label: "省", required: true),
        FieldDefinition(key: "city", label: "市", required: true),
        FieldDefinition(key: "district", label: "区", required: true),
        FieldDefinition(key: "address", label: "详细地址", required: true),
        FieldDefinition(key: "postalCode", label: "邮编", required: false),
        FieldDefinition(key: "notes", label: "备注", required: false)
    ]

    static func formatForCopy(fields: [String: String]) -> String {
        """
        收件人：\(fields["recipient"] ?? "")
        手机号：\(fields["phone"] ?? "")
        地址：\(fields["province"] ?? "")\(fields["city"] ?? "")\(fields["district"] ?? "")\(fields["address"] ?? "")
        邮编：\(fields["postalCode"] ?? "")
        备注：\(fields["notes"] ?? "")
        """
    }
}
```

#### Invoice Template / 发票模板

```swift
struct InvoiceTemplate {
    static let fields: [FieldDefinition] = [
        FieldDefinition(key: "companyName", label: "公司名称", required: true),
        FieldDefinition(key: "taxId", label: "税号", required: true),
        FieldDefinition(key: "address", label: "地址", required: true),
        FieldDefinition(key: "phone", label: "电话", required: true),
        FieldDefinition(key: "bankName", label: "开户行", required: true),
        FieldDefinition(key: "bankAccount", label: "银行账号", required: true),
        FieldDefinition(key: "notes", label: "备注", required: false)
    ]

    static func formatForCopy(fields: [String: String]) -> String {
        """
        公司名称：\(fields["companyName"] ?? "")
        税号：\(fields["taxId"] ?? "")
        地址：\(fields["address"] ?? "")
        电话：\(fields["phone"] ?? "")
        开户行：\(fields["bankName"] ?? "")
        账号：\(fields["bankAccount"] ?? "")
        备注：\(fields["notes"] ?? "")
        """
    }
}
```

#### General Text Template / 通用文本模板

```swift
struct GeneralTextTemplate {
    static let fields: [FieldDefinition] = [
        FieldDefinition(key: "content", label: "内容", required: true)
    ]

    static func formatForCopy(fields: [String: String]) -> String {
        fields["content"] ?? ""
    }
}
```

---

## Correctness Properties / 正确性属性

### What are Correctness Properties? / 什么是正确性属性？

A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

属性是在系统的所有有效执行中都应该成立的特征或行为——本质上是关于系统应该做什么的正式声明。属性是人类可读规范和机器可验证正确性保证之间的桥梁。

### Property 1: Card Creation Completeness / 属性 1：卡片创建完整性

_For any_ card creation request with valid title, type, and group, the created card should have a unique ID, the specified title, type, group, and both creation and modification timestamps set to the current time.

*对于任何*具有有效标题、类型和分组的卡片创建请求，创建的卡片应具有唯一 ID、指定的标题、类型、分组，以及设置为当前时间的创建和修改时间戳。

**Validates: Requirements 1.1, 1.5**

### Property 2: Card Update Timestamp / 属性 2：卡片更新时间戳

_For any_ existing card, when fields are updated, the modification timestamp should be greater than the original timestamp and the updated fields should reflect the new values.

*对于任何*现有卡片，当字段更新时，修改时间戳应大于原始时间戳，且更新的字段应反映新值。

**Validates: Requirements 1.2**

### Property 3: Card Deletion Completeness / 属性 3：卡片删除完整性

_For any_ card with associated fields, after deletion, neither the card nor any of its fields should exist in the encrypted storage.

*对于任何*具有关联字段的卡片，删除后，该卡片及其任何字段都不应存在于加密存储中。

**Validates: Requirements 1.3**

### Property 4: Pin Toggle Consistency / 属性 4：置顶切换一致性

_For any_ card, toggling the pin status twice should return the card to its original pin state.

*对于任何*卡片，两次切换置顶状态应使卡片返回到其原始置顶状态。

**Validates: Requirements 1.6**

### Property 5: Tag Storage and Retrieval / 属性 5：标签存储和检索

_For any_ card with tags added, retrieving the card should return all the tags that were added.

*对于任何*添加了标签的卡片，检索该卡片应返回所有已添加的标签。

**Validates: Requirements 1.7**

### Property 6: Optional Fields in Address Template / 属性 6：地址模板中的可选字段

_For any_ address template card, it should be possible to create and save the card without providing postal code or notes fields.

*对于任何*地址模板卡片，应该可以在不提供邮编或备注字段的情况下创建和保存该卡片。

**Validates: Requirements 2.2**

### Property 7: Address Format Contains Labels / 属性 7：地址格式包含标签

_For any_ address template card, the formatted copy output should contain all field labels (收件人, 手机号, 地址, 邮编, 备注) and their corresponding values.

*对于任何*地址模板卡片，格式化的复制输出应包含所有字段标签（收件人、手机号、地址、邮编、备注）及其对应的值。

**Validates: Requirements 2.3**

### Property 8: Phone Number Validation / 属性 8：电话号码验证

_For any_ string that does not match Chinese mobile (11 digits starting with 1) or landline patterns, attempting to save it as a phone number should be rejected with a validation error.

*对于任何*不匹配中国手机号（以 1 开头的 11 位数字）或座机模式的字符串，尝试将其保存为电话号码应被拒绝并返回验证错误。

**Validates: Requirements 2.4**

### Property 9: Optional Notes in Invoice Template / 属性 9：发票模板中的可选备注

_For any_ invoice template card, it should be possible to create and save the card without providing the notes field.

*对于任何*发票模板卡片，应该可以在不提供备注字段的情况下创建和保存该卡片。

**Validates: Requirements 3.2**

### Property 10: Invoice Format Contains Labels / 属性 10：发票格式包含标签

_For any_ invoice template card, the formatted copy output should contain all field labels (公司名称, 税号, 地址, 电话, 开户行, 账号, 备注) and their corresponding values.

*对于任何*发票模板卡片，格式化的复制输出应包含所有字段标签（公司名称、税号、地址、电话、开户行、账号、备注）及其对应的值。

**Validates: Requirements 3.3**

### Property 11: Tax ID Validation / 属性 11：税号验证

_For any_ string that does not match the Chinese unified social credit code pattern (18 characters alphanumeric), attempting to save it as a tax ID should be rejected with a validation error.

*对于任何*不匹配中国统一社会信用代码模式（18 位字母数字）的字符串，尝试将其保存为税号应被拒绝并返回验证错误。

**Validates: Requirements 3.4**

### Property 12: Multi-line Text Support / 属性 12：多行文本支持

_For any_ general text card with content containing newline characters, saving and retrieving the card should preserve all newline characters.

*对于任何*包含换行符的通用文本卡片，保存和检索该卡片应保留所有换行符。

**Validates: Requirements 4.2**

### Property 13: General Text Copy Direct / 属性 13：通用文本直接复制

_For any_ general text card, copying the card should return only the content field value without any additional formatting or labels.

*对于任何*通用文本卡片，复制该卡片应仅返回内容字段值，不包含任何额外的格式或标签。

**Validates: Requirements 4.3**

### Property 14: Search Matches Title and Fields / 属性 14：搜索匹配标题和字段

_For any_ search query and card collection, the filtered results should include all cards where the query matches either the card title or any decrypted field value (case-insensitive).

*对于任何*搜索查询和卡片集合，过滤结果应包括所有查询匹配卡片标题或任何解密字段值（不区分大小写）的卡片。

**Validates: Requirements 5.2**

### Property 15: Keyboard Navigation Selection / 属性 15：键盘导航选择

_For any_ card list with N cards, pressing the down arrow key N-1 times from the first card should select the last card, and pressing up arrow key N-1 times from the last card should select the first card.

*对于任何*包含 N 张卡片的卡片列表，从第一张卡片按下箭头键 N-1 次应选择最后一张卡片，从最后一张卡片按上箭头键 N-1 次应选择第一张卡片。

**Validates: Requirements 5.3**

### Property 16: Enter Key Copies Selected Card / 属性 16：Enter 键复制选中卡片

_For any_ selected card in the list, pressing Enter should copy the entire formatted card content to the clipboard.

*对于*列表中任何选中的卡片，按 Enter 键应将整个格式化的卡片内容复制到剪贴板。

**Validates: Requirements 5.4**

### Property 17: Copy Entire Card Format / 属性 17：复制整卡格式

_For any_ card with multiple fields, copying the entire card should produce formatted text where each field appears on a separate line with its label.

*对于任何*具有多个字段的卡片，复制整个卡片应生成格式化文本，其中每个字段及其标签显示在单独的行上。

**Validates: Requirements 6.1, 6.4**

### Property 18: Copy Individual Field / 属性 18：复制单个字段

_For any_ card field, copying that field individually should copy only the field value to the clipboard without the label or any other fields.

*对于任何*卡片字段，单独复制该字段应仅将字段值复制到剪贴板，不包含标签或任何其他字段。

**Validates: Requirements 6.2**

### Property 19: Locked State Prevents Copy / 属性 19：锁定状态阻止复制

_For any_ card or field, when the system is in locked state, all copy operations should fail and return an error indicating the system is locked.

*对于任何*卡片或字段，当系统处于锁定状态时，所有复制操作应失败并返回指示系统已锁定的错误。

**Validates: Requirements 6.5**

### Property 20: Lock State Icon Update / 属性 20：锁定状态图标更新

_For any_ lock state transition (locked to unlocked or unlocked to locked), the menu bar icon should update to reflect the current state.

*对于任何*锁定状态转换（锁定到解锁或解锁到锁定），菜单栏图标应更新以反映当前状态。

**Validates: Requirements 7.5**

### Property 21: Field Encryption Round Trip / 属性 21：字段加密往返

_For any_ card field value, encrypting then decrypting the value should produce the original value.

*对于任何*卡片字段值，加密然后解密该值应产生原始值。

**Validates: Requirements 8.1, 8.5**

### Property 22: Key Derivation Determinism / 属性 22：密钥派生确定性

_For any_ master password and salt, deriving the encryption key twice with the same inputs should produce identical keys.

*对于任何*主密码和盐值，使用相同输入两次派生加密密钥应产生相同的密钥。

**Validates: Requirements 8.4**

### Property 23: Authentication State Transition / 属性 23：认证状态转换

_For any_ locked system, successful authentication should transition the system to unlocked state and allow data access.

*对于任何*锁定的系统，成功认证应将系统转换为解锁状态并允许数据访问。

**Validates: Requirements 9.4**

### Property 24: Manual Lock Immediate / 属性 24：手动锁定立即生效

_For any_ unlocked system, clicking the manual lock button should immediately transition to locked state and hide all card content.

*对于任何*解锁的系统，点击手动锁定按钮应立即转换为锁定状态并隐藏所有卡片内容。

**Validates: Requirements 9.7**

### Property 25: Locked State Hides Content / 属性 25：锁定状态隐藏内容

_For any_ card collection, when the system is in locked state, the popover should not display any card titles, field values, or sensitive information.

*对于任何*卡片集合，当系统处于锁定状态时，弹出面板不应显示任何卡片标题、字段值或敏感信息。

**Validates: Requirements 10.5**

### Property 26: Settings Persistence / 属性 26：设置持久化

_For any_ settings change (auto-lock timeout, keyboard shortcut, Touch ID toggle), after saving and restarting the application, the settings should retain the changed values.

*对于任何*设置更改（自动锁定超时、键盘快捷键、触控 ID 切换），保存并重启应用程序后，设置应保留更改的值。

**Validates: Requirements 11.2, 11.3, 11.5**

### Property 27: Password Change Authentication / 属性 27：密码更改认证

_For any_ valid old password and new password, after changing the master password, the old password should no longer authenticate and the new password should successfully authenticate.

*对于任何*有效的旧密码和新密码，更改主密码后，旧密码应不再能够认证，新密码应成功认证。

**Validates: Requirements 11.4**

### Property 28: Data Persistence Round Trip / 属性 28：数据持久化往返

_For any_ card created with fields, after saving, closing the application, and restarting, the card and all its fields should be retrievable with identical values.

*对于任何*创建的带字段的卡片，保存、关闭应用程序并重启后，该卡片及其所有字段应可检索且值相同。

**Validates: Requirements 12.2, 12.3**

### Property 29: Referential Integrity / 属性 29：引用完整性

_For any_ database state, there should be no orphaned fields (fields without a parent card) in the encrypted storage.

*对于任何*数据库状态，加密存储中不应存在孤立字段（没有父卡片的字段）。

**Validates: Requirements 12.4**

### Property 30: Timestamp Storage / 属性 30：时间戳存储

_For any_ card, both creation timestamp and modification timestamp should be stored and retrievable as valid Date objects.

*对于任何*卡片，创建时间戳和修改时间戳都应被存储并可作为有效的 Date 对象检索。

**Validates: Requirements 12.5**

### Property 31: Group Filtering / 属性 31：分组过滤

_For any_ card collection with cards in both Personal and Company groups, filtering by Personal should return only Personal cards, and filtering by Company should return only Company cards.

*对于任何*包含个人和公司分组卡片的卡片集合，按个人过滤应仅返回个人卡片，按公司过滤应仅返回公司卡片。

**Validates: Requirements 13.2**

### Property 32: Multiple Tags Support / 属性 32：多标签支持

_For any_ card, it should be possible to add multiple distinct tags, and all added tags should be retrievable.

*对于任何*卡片，应该可以添加多个不同的标签，并且所有添加的标签都应可检索。

**Validates: Requirements 13.3**

### Property 33: Search Matches Tags / 属性 33：搜索匹配标签

_For any_ search query, cards with tags that contain the query string should appear in the search results.

*对于任何*搜索查询，具有包含查询字符串的标签的卡片应出现在搜索结果中。

**Validates: Requirements 13.4**

### Property 34: Pinned Cards Sort Order / 属性 34：置顶卡片排序顺序

_For any_ card list with both pinned and unpinned cards, all pinned cards should appear before all unpinned cards in the display order.

*对于任何*包含置顶和未置顶卡片的卡片列表，所有置顶卡片应在显示顺序中出现在所有未置顶卡片之前。

**Validates: Requirements 14.2**

### Property 35: Pinned Cards Internal Sort / 属性 35：置顶卡片内部排序

_For any_ collection of pinned cards, they should be sorted by modification timestamp in descending order (most recently updated first).

*对于任何*置顶卡片集合，它们应按修改时间戳降序排序（最近更新的在前）。

**Validates: Requirements 14.4**

### Property 36: Unpinned Cards Internal Sort / 属性 36：未置顶卡片内部排序

_For any_ collection of unpinned cards, they should be sorted by modification timestamp in descending order (most recently updated first).

*对于任何*未置顶卡片集合，它们应按修改时间戳降序排序（最近更新的在前）。

**Validates: Requirements 14.5**

### Property 37: Quit Locks System / 属性 37：退出锁定系统

_For any_ unlocked system, initiating application quit should transition the system to locked state before the application closes.

*对于任何*解锁的系统，启动应用程序退出应在应用程序关闭前将系统转换为锁定状态。

**Validates: Requirements 16.3**

### Property 38: Quit Saves Changes / 属性 38：退出保存更改

_For any_ unsaved changes to cards, quitting the application should persist all changes before closing, and restarting should show the changes.

*对于任何*未保存的卡片更改，退出应用程序应在关闭前持久化所有更改，重启后应显示这些更改。

**Validates: Requirements 16.4**

### Property 39: Required Field Validation / 属性 39：必填字段验证

_For any_ card template with required fields, attempting to save a card with any required field empty should be rejected with a validation error.

*对于任何*具有必填字段的卡片模板，尝试保存任何必填字段为空的卡片应被拒绝并返回验证错误。

**Validates: Requirements 19.1**

### Property 40: Password Minimum Length / 属性 40：密码最小长度

_For any_ password string with fewer than 8 characters, attempting to set it as the master password should be rejected with a validation error.

*对于任何*少于 8 个字符的密码字符串，尝试将其设置为主密码应被拒绝并返回验证错误。

**Validates: Requirements 20.3**

### Property 41: Attachment File Encryption / 属性 41：附件文件加密

*For any* file attached to a card, the stored data should be encrypted and decrypting then re-encrypting should produce equivalent encrypted data.

*对于任何*附加到卡片的文件，存储的数据应被加密，解密后重新加密应产生等效的加密数据。

**Validates: Requirements 5.2**

### Property 42: Attachment File Size Limit / 属性 42：附件文件大小限制

*For any* file larger than 10MB, attempting to attach it to a card should be rejected with a file size error.

*对于任何*大于 10MB 的文件，尝试将其附加到卡片应被拒绝并返回文件大小错误。

**Validates: Requirements 5.3**

### Property 43: Attachment Copy to Desktop Round Trip / 属性 43：附件复制到桌面往返

*For any* file attached to a card, copying the attachment to desktop should produce a file with identical content to the original file.

*对于任何*附加到卡片的文件，将附件复制到桌面应产生与原始文件内容相同的文件。

**Validates: Requirements 5.4**

### Property 44: Attachment Deletion Completeness / 属性 44：附件删除完整性

*For any* attachment added to a card, after deletion, the attachment should not exist in the encrypted storage and should not be associated with the card.

*对于任何*添加到卡片的附件，删除后，该附件不应存在于加密存储中，也不应与卡片关联。

**Validates: Requirements 5.6**

---

## Error Handling / 错误处理

### Error Types / 错误类型

```swift
enum QuickVaultError: LocalizedError {
    // Crypto Errors
    case encryptionFailed
    case decryptionFailed
    case keyDerivationFailed
    case keyNotAvailable

    // Authentication Errors
    case authenticationFailed(reason: String)
    case touchIDNotAvailable
    case touchIDFailed
    case passwordIncorrect
    case tooManyFailedAttempts

    // Validation Errors
    case invalidPhoneNumber
    case invalidTaxID
    case requiredFieldEmpty(fieldName: String)
    case passwordTooShort

    // Attachment Errors
    case fileTooLarge
    case unsupportedFileType
    case attachmentNotFound
    case fileReadFailed
    case fileWriteFailed
    case invalidPhoneNumber
    case invalidTaxID
    case requiredFieldEmpty(fieldName: String)
    case passwordTooShort

    // Database Errors
    case databaseOperationFailed(operation: String)
    case cardNotFound
    case fieldNotFound

    // Keychain Errors
    case keychainSaveFailed
    case keychainLoadFailed
    case keychainNotAvailable

    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "加密失败 / Encryption failed"
        case .decryptionFailed:
            return "解密失败 / Decryption failed"
        case .authenticationFailed(let reason):
            return "认证失败: \(reason) / Authentication failed: \(reason)"
        case .invalidPhoneNumber:
            return "无效的电话号码格式 / Invalid phone number format"
        case .invalidTaxID:
            return "无效的税号格式 / Invalid tax ID format"
        case .requiredFieldEmpty(let fieldName):
            return "\(fieldName) 不能为空 / \(fieldName) cannot be empty"
        case .passwordTooShort:
            return "密码至少需要 8 个字符 / Password must be at least 8 characters"
        case .databaseOperationFailed(let operation):
            return "数据库操作失败: \(operation) / Database operation failed: \(operation)"
        // ... other cases
        }
    }
}
```

### Error Handling Strategy / 错误处理策略

1. **User-Facing Errors / 面向用户的错误**: Display localized error messages in toast notifications or alert dialogs / 在提示通知或警告对话框中显示本地化错误消息

2. **Logging / 日志记录**: Log all errors with context for debugging / 记录所有带上下文的错误以便调试

3. **Graceful Degradation / 优雅降级**:

    - If Touch ID fails, fall back to password / 如果触控 ID 失败，回退到密码
    - If Keychain unavailable, use password-only mode / 如果钥匙串不可用，使用仅密码模式

4. **Data Protection / 数据保护**: Never expose decrypted data in error messages / 永远不要在错误消息中暴露解密数据

---

## Testing Strategy / 测试策略

### Dual Testing Approach / 双重测试方法

QuickVault will use both unit tests and property-based tests to ensure comprehensive coverage:

随取将使用单元测试和基于属性的测试来确保全面覆盖：

-   **Unit Tests / 单元测试**: Verify specific examples, edge cases, and error conditions / 验证特定示例、边缘情况和错误条件
-   **Property Tests / 属性测试**: Verify universal properties across all inputs / 验证所有输入的通用属性

### Property-Based Testing Framework / 基于属性的测试框架

We will use **swift-check** (Swift port of QuickCheck) for property-based testing.

我们将使用 **swift-check**（QuickCheck 的 Swift 移植版）进行基于属性的测试。

Installation / 安装:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0")
]
```

### Property Test Configuration / 属性测试配置

-   **Minimum iterations / 最小迭代次数**: 100 per property test / 每个属性测试 100 次
-   **Test tagging / 测试标记**: Each property test must reference its design document property / 每个属性测试必须引用其设计文档属性
-   **Tag format / 标记格式**: `// Feature: quick-vault-macos, Property N: [property description]`

### Example Property Test / 属性测试示例

```swift
import XCTest
import SwiftCheck
@testable import QuickVault

class CardServicePropertyTests: XCTestCase {

    // Feature: quick-vault-macos, Property 21: Field Encryption Round Trip
    func testFieldEncryptionRoundTrip() {
        property("Encrypting then decrypting any field value produces original value") <- forAll { (value: String) in
            let cryptoService = CryptoServiceImpl()
            try! cryptoService.initializeKey(password: "testpassword123")

            let encrypted = try! cryptoService.encrypt(value)
            let decrypted = try! cryptoService.decrypt(encrypted)

            return decrypted == value
        }.withSize(100)
    }

    // Feature: quick-vault-macos, Property 3: Card Deletion Completeness
    func testCardDeletionCompleteness() {
        property("After deleting a card, neither card nor fields exist in storage") <- forAll { (title: String, fieldCount: Positive<Int>) in
            let context = createTestContext()
            let cardService = CardServiceImpl(context: context, cryptoService: mockCryptoService)

            // Create card with fields
            let fields = (0..<fieldCount.getPositive).map { i in
                CardFieldData(key: "field\(i)", label: "Field \(i)", value: "value\(i)")
            }
            let card = try! cardService.createCard(type: .general, title: title, group: .personal, fields: fields)
            let cardId = card.id

            // Delete card
            try! cardService.deleteCard(card)

            // Verify card and fields don't exist
            let fetchRequest: NSFetchRequest<Card> = Card.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", cardId as CVarArg)
            let results = try! context.fetch(fetchRequest)

            return results.isEmpty
        }.withSize(100)
    }
}
```

### Unit Test Examples / 单元测试示例

```swift
class CardServiceUnitTests: XCTestCase {

    func testCreateAddressCard() {
        // Test creating a specific address card
        let cardService = CardServiceImpl(context: testContext, cryptoService: mockCryptoService)
        let fields = [
            CardFieldData(key: "recipient", label: "收件人", value: "张三"),
            CardFieldData(key: "phone", label: "手机号", value: "13800138000"),
            CardFieldData(key: "address", label: "地址", value: "北京市海淀区")
        ]

        let card = try! cardService.createCard(type: .address, title: "家庭地址", group: .personal, fields: fields)

        XCTAssertEqual(card.title, "家庭地址")
        XCTAssertEqual(card.type, "address")
        XCTAssertEqual(card.fields?.count, 3)
    }

    func testInvalidPhoneNumberRejected() {
        // Test that invalid phone numbers are rejected
        let cardService = CardServiceImpl(context: testContext, cryptoService: mockCryptoService)
        let fields = [
            CardFieldData(key: "phone", label: "手机号", value: "123") // Invalid
        ]

        XCTAssertThrowsError(try cardService.createCard(type: .address, title: "Test", group: .personal, fields: fields)) { error in
            XCTAssertEqual(error as? QuickVaultError, .invalidPhoneNumber)
        }
    }
}
```

### Test Coverage Goals / 测试覆盖目标

-   **Core business logic / 核心业务逻辑**: 90%+ coverage / 90%+ 覆盖率
-   **UI components / UI 组件**: Focus on interaction logic, not visual appearance / 专注于交互逻辑，而非视觉外观
-   **Error paths / 错误路径**: All error cases should have tests / 所有错误情况都应有测试
-   **Security features / 安全功能**: 100% coverage for encryption, authentication, locking / 加密、认证、锁定 100% 覆盖率

---

## Security Considerations / 安全考虑

### Encryption Details / 加密详情

-   **Algorithm / 算法**: AES-256-GCM
-   **Key Derivation / 密钥派生**: PBKDF2 with 100,000 iterations / PBKDF2 使用 100,000 次迭代
-   **Salt / 盐值**: 32-byte random salt per user / 每用户 32 字节随机盐值
-   **Storage / 存储**: Encryption key stored in macOS Keychain / 加密密钥存储在 macOS 钥匙串中

### Threat Model / 威胁模型

**Protected Against / 防护对象**:

-   Unauthorized access to SQLite database file / 未经授权访问 SQLite 数据库文件
-   Memory dumps while application is locked / 应用程序锁定时的内存转储
-   Clipboard snooping (future: auto-clear clipboard) / 剪贴板窥探（未来：自动清除剪贴板）

**Not Protected Against / 不防护对象**:

-   Malware with keylogger capabilities / 具有键盘记录功能的恶意软件
-   Physical access to unlocked system / 对解锁系统的物理访问
-   macOS Keychain compromise / macOS 钥匙串被攻破

### Data at Rest / 静态数据

-   All field values encrypted / 所有字段值加密
-   Card titles and metadata NOT encrypted (for search performance) / 卡片标题和元数据不加密（为了搜索性能）
-   Database file permissions: 0600 (owner read/write only) / 数据库文件权限：0600（仅所有者读/写）

### Data in Transit / 传输中的数据

-   No network communication / 无网络通信
-   Clipboard data is plaintext (user responsibility) / 剪贴板数据为明文（用户责任）

---

## Performance Considerations / 性能考虑

### Expected Performance / 预期性能

-   **Card creation / 卡片创建**: < 100ms
-   **Search / 搜索**: < 50ms for 1000 cards / 1000 张卡片 < 50ms
-   **Unlock / 解锁**: < 500ms (including Touch ID) / < 500ms（包括触控 ID）
-   **Popover open / 弹出面板打开**: < 100ms

### Optimization Strategies / 优化策略

1. **Lazy Loading / 延迟加载**: Only decrypt fields when displayed / 仅在显示时解密字段
2. **Caching / 缓存**: Cache decrypted values while unlocked / 解锁时缓存解密值
3. **Indexing / 索引**: CoreData indexes on title, type, group / CoreData 在标题、类型、分组上建立索引
4. **Batch Operations / 批量操作**: Use batch updates for multiple card operations / 对多个卡片操作使用批量更新

---

## Future Enhancements (Out of Scope for R1) / 未来增强（R1 范围外）

-   **R2**: Import/Export with encryption / 加密导入/导出
-   **R2**: Attachment support (encrypted images) / 附件支持（加密图片）
-   **R3**: Auto-clear clipboard after N seconds / N 秒后自动清除剪贴板
-   **R3**: Biometric re-authentication for sensitive cards / 敏感卡片的生物识别重新认证
-   **R3**: iCloud sync with end-to-end encryption / 端到端加密的 iCloud 同步
````

**Responsibility / 职责**: Manages encrypted file attachments for cards / 管理卡片的加密文件附件

```swift
protocol AttachmentService {
    func addAttachment(to card: Card, fileURL: URL) async throws -> CardAttachment
    func deleteAttachment(_ attachment: CardAttachment) async throws
    func copyAttachmentToDesktop(_ attachment: CardAttachment) async throws -> URL
    func generateThumbnail(for attachment: CardAttachment) async throws -> NSImage
}

class AttachmentServiceImpl: AttachmentService {
    private let context: NSManagedObjectContext
    private let cryptoService: CryptoService
    private let maxFileSize: Int64 = 10 * 1024 * 1024 // 10MB

    func addAttachment(to card: Card, fileURL: URL) async throws -> CardAttachment {
        // Validate file size
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        guard let fileSize = fileAttributes[.size] as? Int64, fileSize <= maxFileSize else {
            throw QuickVaultError.fileTooLarge
        }

        // Read and encrypt file data
        let fileData = try Data(contentsOf: fileURL)
        let encryptedData = try cryptoService.encryptFile(fileData)

        // Create attachment
        let attachment = CardAttachment(context: context)
        attachment.id = UUID()
        attachment.fileName = fileURL.lastPathComponent
        attachment.fileType = fileURL.mimeType()
        attachment.fileSize = fileSize
        attachment.encryptedData = encryptedData
        attachment.createdAt = Date()
        attachment.card = card

        // Generate and encrypt thumbnail for images
        if fileURL.isImage {
            let thumbnail = try await generateThumbnail(from: fileData)
            attachment.thumbnailData = try cryptoService.encryptFile(thumbnail)
        }

        try context.save()
        return attachment
    }

    func copyAttachmentToDesktop(_ attachment: CardAttachment) async throws -> URL {
        // Decrypt file data
        let decryptedData = try cryptoService.decryptFile(attachment.encryptedData)

        // Create unique filename on desktop
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
        var destinationURL = desktopURL.appendingPathComponent(attachment.fileName)

        // Handle duplicate filenames
        var counter = 1
        while FileManager.default.fileExists(atPath: destinationURL.path) {
            let nameWithoutExt = (attachment.fileName as NSString).deletingPathExtension
            let ext = (attachment.fileName as NSString).pathExtension
            let newName = "\(nameWithoutExt)_\(counter).\(ext)"
            destinationURL = desktopURL.appendingPathComponent(newName)
            counter += 1
        }

        // Write to desktop
        try decryptedData.write(to: destinationURL)

        return destinationURL
    }
}
```

**Key Features / 关键特性**:

-   File encryption before storage / 存储前文件加密
-   File size validation (10MB limit) / 文件大小验证（10MB 限制）
-   Thumbnail generation for images / 图片缩略图生成
-   Copy to desktop with duplicate handling / 复制到桌面并处理重复文件名
-   Support for PNG, JPEG, PDF formats / 支持 PNG、JPEG、PDF 格式

---

### 10. Update Manager / 更新管理器

**Responsibility / 职责**: Manages automatic update checking and installation using Sparkle framework / 使用 Sparkle 框架管理自动更新检查和安装

```swift
import Sparkle

class UpdateManager: ObservableObject {
    private let updaterController: SPUStandardUpdaterController
    @Published var updateAvailable: Bool = false
    @Published var updateInfo: SPUAppcastItem?

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates()
    func checkForUpdatesInBackground()
    func installUpdate()
    func skipThisVersion()
    func configureAutomaticChecks(enabled: Bool)
}
```

**Key Features / 关键特性**:

-   Automatic update checking on launch / 启动时自动检查更新
-   Background update checks (daily) / 后台更新检查（每天）
-   Update notification with release notes / 带发行说明的更新通知
-   Signature verification for security / 签名验证以确保安全
-   User control over update installation / 用户控制更新安装
-   Automatic application restart after update / 更新后自动重启应用程序
-   Data preservation during updates / 更新期间保留数据

**Sparkle Configuration / Sparkle 配置**:

```xml
<!-- Info.plist -->
<key>SUFeedURL</key>
<string>https://your-domain.com/appcast.xml</string>
<key>SUPublicEDKey</key>
<string>your-public-ed25519-key</string>
<key>SUEnableAutomaticChecks</key>
<true/>
<key>SUScheduledCheckInterval</key>
<integer>86400</integer> <!-- 24 hours -->
```

**Appcast XML Format / Appcast XML 格式**:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>QuickVault Updates</title>
        <item>
            <title>Version 1.1.0</title>
            <sparkle:version>1.1.0</sparkle:version>
            <sparkle:releaseNotesLink>https://your-domain.com/release-notes/1.1.0.html</sparkle:releaseNotesLink>
            <pubDate>Mon, 07 Jan 2026 10:00:00 +0000</pubDate>
            <enclosure
                url="https://your-domain.com/downloads/QuickVault-1.1.0.zip"
                sparkle:edSignature="signature-here"
                length="12345678"
                type="application/octet-stream" />
        </item>
    </channel>
</rss>
```

---
