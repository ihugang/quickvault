# Design Document / 设计文档

## Overview / 概述

QuickVault iOS is a secure personal information management app built with SwiftUI and CoreData. The architecture follows MVVM pattern with a service layer for business logic. Core services (Crypto, Keychain, Authentication) are shared with the macOS version, while UI and platform-specific features are iOS-optimized.

随取 iOS 是使用 SwiftUI 和 CoreData 构建的安全个人信息管理应用。架构遵循 MVVM 模式，业务逻辑使用服务层。核心服务（加密、钥匙串、认证）与 macOS 版本共享，而 UI 和平台特定功能针对 iOS 优化。

## Architecture / 架构

### Layer Structure / 层次结构

```
┌─────────────────────────────────────┐
│         SwiftUI Views               │  Presentation Layer
│  (Cards, Detail, Settings, Auth)   │
├─────────────────────────────────────┤
│         View Models                 │  Presentation Logic
│  (CardViewModel, AuthViewModel)     │
├─────────────────────────────────────┤
│         Services                    │  Business Logic
│  (Card, Auth, Crypto, Watermark)   │
├─────────────────────────────────────┤
│      CoreData + Keychain            │  Data Layer
│  (Persistence, Secure Storage)      │
└─────────────────────────────────────┘
```

### Key Design Decisions / 关键设计决策

1. **Shared Core**: Crypto, Keychain, and Authentication services are platform-agnostic
2. **SwiftUI First**: Pure SwiftUI for all UI components
3. **MVVM Pattern**: Clear separation between views and business logic
4. **CoreData**: Local persistence with encryption at field level
5. **Combine**: Reactive state management for authentication and data updates

## Components and Interfaces / 组件和接口

### Core Services (Shared with macOS) / 核心服务（与 macOS 共享）

#### CryptoService

```swift
protocol CryptoService {
    func encrypt(_ data: String) throws -> Data
    func decrypt(_ data: Data) throws -> String
    func encryptFile(_ data: Data) throws -> Data
    func decryptFile(_ data: Data) throws -> Data
    func deriveKey(from password: String, salt: Data) throws -> SymmetricKey
    func generateSalt() -> Data
    func hashPassword(_ password: String) -> String
}
```

#### KeychainService

```swift
protocol KeychainService {
    func save(_ data: Data, forKey key: String) throws
    func load(forKey key: String) throws -> Data
    func delete(forKey key: String) throws
    func exists(forKey key: String) -> Bool
}
```

#### AuthenticationService

```swift
protocol AuthenticationService {
    var authenticationState: AuthenticationState { get }
    func setupMasterPassword(_ password: String) async throws
    func authenticateWithPassword(_ password: String) async throws
    func authenticateWithBiometric() async throws
    func changePassword(oldPassword: String, newPassword: String) async throws
    func lock()
}
```

### iOS-Specific Services / iOS 特定服务

#### WatermarkService

```swift
protocol WatermarkService {
    func applyWatermark(to image: UIImage, text: String, style: WatermarkStyle) -> UIImage
    func removeWatermark(from attachment: CardAttachment) async throws
    func updateWatermark(for attachment: CardAttachment, text: String) async throws
}

struct WatermarkStyle {
    let fontSize: CGFloat
    let opacity: CGFloat
    let angle: CGFloat
    let color: UIColor
}
```

#### CardService

```swift
protocol CardService {
    func createCard(title: String, group: String, cardType: String,
                   fields: [CardFieldDTO], tags: [String]) async throws -> CardDTO
    func updateCard(id: UUID, title: String?, group: String?,
                   fields: [CardFieldDTO]?, tags: [String]?) async throws -> CardDTO
    func deleteCard(id: UUID) async throws
    func fetchAllCards() async throws -> [CardDTO]
    func searchCards(query: String) async throws -> [CardDTO]
    func togglePin(id: UUID) async throws -> CardDTO
}
```

#### AttachmentService

```swift
protocol AttachmentService {
    func addAttachment(to cardId: UUID, fileData: Data,
                      fileName: String, mimeType: String) async throws -> AttachmentDTO
    func deleteAttachment(id: UUID) async throws
    func fetchAttachments(for cardId: UUID) async throws -> [AttachmentDTO]
    func shareAttachment(id: UUID) async throws -> URL
}
```

### View Models / 视图模型

#### CardListViewModel

```swift
class CardListViewModel: ObservableObject {
    @Published var cards: [CardDTO] = []
    @Published var filteredCards: [CardDTO] = []
    @Published var selectedGroup: CardGroup?
    @Published var searchQuery: String = ""

    func loadCards() async
    func filterByGroup(_ group: CardGroup)
    func search(_ query: String)
    func deleteCard(_ id: UUID) async
    func togglePin(_ id: UUID) async
}
```

#### CardDetailViewModel

```swift
class CardDetailViewModel: ObservableObject {
    @Published var card: CardDTO
    @Published var attachments: [AttachmentDTO] = []
    @Published var isEditing: Bool = false

    func saveCard() async throws
    func copyCard()
    func copyField(_ field: CardFieldDTO)
    func addAttachment(_ data: Data, fileName: String) async throws
    func applyWatermark(to attachmentId: UUID, text: String) async throws
}
```

#### AuthViewModel

```swift
class AuthViewModel: ObservableObject {
    @Published var authState: AuthenticationState = .locked
    @Published var showingSetup: Bool = false

    func authenticate(with password: String) async throws
    func authenticateWithBiometric() async throws
    func setupPassword(_ password: String) async throws
    func lock()
}
```

## Data Models / 数据模型

### CoreData Entities / CoreData 实体

#### Card

```
- id: UUID
- title: String
- group: String (Personal/Company)
- cardType: String (Address/Invoice/GeneralText)
- isPinned: Bool
- tags: Data (JSON array)
- createdAt: Date
- modifiedAt: Date
- fields: [CardField]
- attachments: [CardAttachment]
```

#### CardField

```
- id: UUID
- label: String
- encryptedValue: Data
- isRequired: Bool
- displayOrder: Int16
- card: Card
```

#### CardAttachment

```
- id: UUID
- fileName: String
- mimeType: String
- encryptedData: Data
- thumbnailData: Data?
- watermarkText: String?
- fileSize: Int64
- createdAt: Date
- card: Card
```

### Data Transfer Objects / 数据传输对象

```swift
struct CardDTO {
    let id: UUID
    let title: String
    let group: String
    let cardType: String
    let fields: [CardFieldDTO]
    let isPinned: Bool
    let tags: [String]
    let createdAt: Date
    let modifiedAt: Date
}

struct CardFieldDTO {
    let id: UUID
    let label: String
    let value: String
    let isRequired: Bool
    let displayOrder: Int16
}

struct AttachmentDTO {
    let id: UUID
    let fileName: String
    let mimeType: String
    let fileSize: Int64
    let hasWatermark: Bool
    let watermarkText: String?
    let thumbnailImage: UIImage?
}
```

## Correctness Properties / 正确性属性

_A property is a characteristic or behavior that should hold true across all valid executions of a system. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees._

_属性是在系统的所有有效执行中都应该成立的特征或行为。属性是人类可读规范和机器可验证正确性保证之间的桥梁。_

### Card Management Properties / 卡片管理属性

**Property 1: Card Creation Completeness**
_For any_ valid card data (title, group, type, fields), creating a card should result in a stored card with all fields encrypted and timestamps set.
**Validates: Requirements 1.1, 1.5**

**Property 2: Card Update Timestamp**
_For any_ existing card, updating any field should result in the modifiedAt timestamp being greater than the previous value.
**Validates: Requirements 1.2**

**Property 3: Card Deletion Completeness**
_For any_ card with attachments and fields, deleting the card should remove the card and all associated data from storage.
**Validates: Requirements 1.3**

**Property 4: Pin Toggle Consistency**
_For any_ card, toggling pin twice should return the card to its original pin state.
**Validates: Requirements 1.6**

**Property 5: Tag Storage and Retrieval**
_For any_ set of tags, storing them with a card and then retrieving the card should return the same tags.
**Validates: Requirements 1.7**

### Template Properties / 模板属性

**Property 6: Optional Fields in Address Template**
_For any_ address card with empty postal code or notes, the card should be created successfully.
**Validates: Requirements 2.2**

**Property 7: Address Format Contains Labels**
_For any_ address card, the formatted copy output should contain all field labels.
**Validates: Requirements 2.3**

**Property 8: Phone Number Validation**
_For any_ string that is not a valid Chinese mobile or landline number, validation should reject it.
**Validates: Requirements 2.4**

**Property 9: Optional Notes in Invoice Template**
_For any_ invoice card with empty notes, the card should be created successfully.
**Validates: Requirements 3.2**

**Property 10: Invoice Format Contains Labels**
_For any_ invoice card, the formatted copy output should contain all field labels.
**Validates: Requirements 3.3**

**Property 11: Tax ID Validation**
_For any_ string that is not exactly 18 characters, tax ID validation should reject it.
**Validates: Requirements 3.4**

**Property 12: Multi-line Text Support**
_For any_ text containing newline characters, storing and retrieving should preserve the newlines.
**Validates: Requirements 4.2**

**Property 13: General Text Copy Direct**
_For any_ general text card, copying should return the text content without additional formatting.
**Validates: Requirements 4.3**

### Attachment Properties / 附件属性

**Property 14: Attachment Encryption Round Trip**
_For any_ file data, encrypting then decrypting should produce the original data.
**Validates: Requirements 5.2**

**Property 15: Attachment File Size Limit**
_For any_ file larger than 10MB, adding as attachment should be rejected.
**Validates: Requirements 5.3**

**Property 16: Attachment Deletion with Card**
_For any_ card with attachments, deleting the card should delete all attachments.
**Validates: Requirements 5.6**

### Watermark Properties / 水印属性

**Property 17: Watermark Application Preserves Quality**
_For any_ image, applying a watermark should not reduce the image resolution or quality significantly.
**Validates: Requirements 6.6**

**Property 18: Watermark Visibility**
_For any_ watermarked image, the watermark text should be visible when the image is viewed.
**Validates: Requirements 6.5**

**Property 19: Watermark Persistence in Shares**
_For any_ watermarked image, sharing the image should include the watermark in the shared file.
**Validates: Requirements 6.4**

**Property 20: Watermark Edit Consistency**
_For any_ watermarked image, changing the watermark text should replace the old watermark with the new one.
**Validates: Requirements 6.7**

### Search Properties / 搜索属性

**Property 21: Search Matches Title and Fields**
_For any_ search query, all returned cards should contain the query in title, fields, or tags.
**Validates: Requirements 7.1**

**Property 22: Group Filter Completeness**
_For any_ group filter, all returned cards should belong to the selected group.
**Validates: Requirements 7.3**

### Authentication Properties / 认证属性

**Property 23: Authentication State Transition**
_For any_ authentication state, valid transitions should be: setupRequired → unlocked, locked → unlocked, unlocked → locked.
**Validates: Requirements 9.4**

**Property 24: Biometric Fallback**
_For any_ failed biometric authentication, password authentication should be available as fallback.
**Validates: Requirements 9.3**

**Property 25: Background Lock**
_For any_ app state, entering background should transition to locked state.
**Validates: Requirements 9.7**

### Encryption Properties / 加密属性

**Property 26: Field Encryption Round Trip**
_For any_ field value, encrypting then decrypting should produce the original value.
**Validates: Requirements 10.1, 10.5**

**Property 27: Key Derivation Determinism**
_For any_ password and salt, deriving the key twice should produce the same key.
**Validates: Requirements 10.4**

### Password Properties / 密码属性

**Property 28: Password Minimum Length**
_For any_ password shorter than 8 characters, password creation should be rejected.
**Validates: Requirements 11.2**

**Property 29: Password Change Authentication**
_For any_ password change attempt, the old password must be verified before allowing the change.
**Validates: Requirements 11.3**

**Property 30: Failed Attempt Rate Limiting**
_For any_ sequence of 3 failed authentication attempts, the 4th attempt should be delayed by 30 seconds.
**Validates: Requirements 11.4**

### Auto-Lock Properties / 自动锁定属性

**Property 31: Inactivity Lock**
_For any_ configured timeout period, inactivity exceeding that period should trigger auto-lock.
**Validates: Requirements 12.1**

**Property 32: App Switcher Content Hiding**
_For any_ locked state, the app switcher should not display sensitive content.
**Validates: Requirements 12.4**

### Sorting Properties / 排序属性

**Property 33: Pinned Cards Sort Order**
_For any_ card list, all pinned cards should appear before all unpinned cards.
**Validates: Requirements 16.1**

**Property 34: Pinned Cards Internal Sort**
_For any_ set of pinned cards, they should be sorted by modification timestamp (most recent first).
**Validates: Requirements 16.4**

**Property 35: Unpinned Cards Internal Sort**
_For any_ set of unpinned cards, they should be sorted by modification timestamp (most recent first).
**Validates: Requirements 16.5**

### Copy Properties / 复制属性

**Property 36: Copy Entire Card Format**
_For any_ card, copying the entire card should format all fields with labels.
**Validates: Requirements 18.1**

**Property 37: Copy Individual Field**
_For any_ field, copying should copy only the field value without the label.
**Validates: Requirements 18.2**

**Property 38: Locked State Prevents Copy**
_For any_ locked state, copy operations should be prevented.
**Validates: Requirements 18.4**

### Validation Properties / 验证属性

**Property 39: Required Field Validation**
_For any_ card with empty required fields, submission should be rejected.
**Validates: Requirements 21.1**

## Error Handling / 错误处理

### Error Types / 错误类型

```swift
enum AppError: LocalizedError {
    case authentication(AuthenticationError)
    case card(CardServiceError)
    case attachment(AttachmentError)
    case watermark(WatermarkError)
    case validation(ValidationError)
    case database(String)

    var errorDescription: String? {
        // Bilingual error messages
    }
}
```

### Error Handling Strategy / 错误处理策略

1. **User-Facing Errors**: Display toast notifications with bilingual messages
2. **Logging**: Log all errors with context for debugging
3. **Recovery**: Provide actionable recovery options where possible
4. **Data Integrity**: Never allow partial writes that could corrupt data

## Testing Strategy / 测试策略

### Unit Tests / 单元测试

-   Test specific examples and edge cases
-   Test error conditions
-   Test UI component behavior
-   Mock services for isolated testing

### Property-Based Tests / 基于属性的测试

-   Use SwiftCheck for property-based testing
-   Minimum 100 iterations per property test
-   Test universal properties across all inputs
-   Tag each test with property number and requirements

### Test Organization / 测试组织

```
QuickVault/Tests/
├── Services/
│   ├── CryptoServiceTests.swift
│   ├── AuthenticationServiceTests.swift
│   ├── CardServiceTests.swift
│   ├── WatermarkServiceTests.swift
│   └── AttachmentServiceTests.swift
├── ViewModels/
│   ├── CardListViewModelTests.swift
│   ├── CardDetailViewModelTests.swift
│   └── AuthViewModelTests.swift
└── Integration/
    └── EndToEndTests.swift
```

### Testing Requirements / 测试要求

-   Each correctness property must have a corresponding property-based test
-   Property tests must run with minimum 100 iterations
-   Each test must reference its design property using format:
    `// Feature: quick-vault-ios, Property N: [property text]`
-   Both unit tests and property tests are required for comprehensive coverage

## iOS-Specific Considerations / iOS 特定考虑

### UI Design / UI 设计

-   Follow iOS Human Interface Guidelines
-   Use native iOS components (Tab Bar, Navigation Bar, Share Sheet)
-   Support Dark Mode
-   Support Dynamic Type for accessibility
-   Use SF Symbols for icons

### Platform Features / 平台特性

-   Face ID / Touch ID via LocalAuthentication
-   Background app refresh for auto-lock
-   App lifecycle management (foreground/background transitions)
-   Share Extension for sharing attachments
-   Photo Library integration for adding images

### Performance / 性能

-   Lazy loading for card list
-   Image thumbnail generation for fast scrolling
-   Background encryption/decryption for large files
-   CoreData batch operations for efficiency

### Security / 安全

-   Keychain for master password storage
-   Data Protection API for file encryption
-   Secure enclave for biometric authentication
-   Memory wiping for sensitive data
-   Screenshot prevention in locked state

## Implementation Notes / 实现注意事项

1. **Code Sharing**: Core services (Crypto, Keychain, Auth) should be in a shared Swift package
2. **SwiftUI**: Use @StateObject, @ObservedObject, and @EnvironmentObject appropriately
3. **Combine**: Use publishers for reactive state management
4. **Async/Await**: Use modern concurrency for all async operations
5. **Localization**: All strings in bilingual format from the start
6. **Watermarking**: Use Core Graphics for efficient image manipulation
7. **Testing**: Write tests alongside implementation, not after

## Migration Path to macOS / 迁移到 macOS 的路径

After iOS implementation is complete:

1. **Extract Shared Code**: Move Core services to a shared Swift package
2. **Platform-Specific UI**: Create macOS-specific views (Menu Bar, NSWindow)
3. **Adapt Services**: Adjust platform-specific services (Watermark uses AppKit)
4. **Testing**: Run shared service tests on both platforms
5. **Feature Parity**: Ensure both platforms have equivalent functionality

## Next Steps / 后续步骤

1. Review and approve this design document
2. Create implementation task list (tasks.md)
3. Begin iOS implementation starting with core services
4. Implement watermark service (iOS-specific)
5. Build UI layer with SwiftUI
6. Comprehensive testing
7. Extract shared code for macOS migration
