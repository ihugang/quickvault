# QuickVault iCloud CloudKit 同步指南

本文档介绍 QuickVault 如何使用 iCloud CloudKit 在 macOS 和 iOS 设备之间同步数据。

## 概述

QuickVault 使用 Apple 的 `NSPersistentCloudKitContainer` 实现数据同步，这是 Core Data 与 CloudKit 的深度集成方案。用户只需登录同一个 iCloud 账户，数据就会自动在所有设备之间同步。

## 架构

```
┌─────────────────┐     ┌─────────────────┐
│   iOS App       │     │   macOS App     │
│                 │     │                 │
│  Core Data      │     │  Core Data      │
│  (Local Store)  │     │  (Local Store)  │
└────────┬────────┘     └────────┬────────┘
         │                       │
         │    CloudKit Sync      │
         │                       │
         └───────────┬───────────┘
                     │
              ┌──────▼──────┐
              │   iCloud    │
              │  CloudKit   │
              │  Container  │
              └─────────────┘
```

## 配置

### 1. CloudKit 容器标识符

两个平台必须使用相同的 CloudKit 容器标识符：

```swift
// PersistenceController.swift
public static let cloudKitContainerIdentifier = "iCloud.com.quickvault.app"
```

### 2. Entitlements 配置

#### iOS (`QuickVault-iOS/Resources/QuickVault.entitlements`)

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.quickvault.app</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
<key>com.apple.developer.ubiquity-kvstore-identifier</key>
<string>$(TeamIdentifierPrefix)com.quickvault.app</string>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.quickvault.app</string>
</array>
```

#### macOS (`QuickVault-macOS/Resources/QuickVault.entitlements`)

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.quickvault.app</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
<key>com.apple.developer.ubiquity-kvstore-identifier</key>
<string>$(TeamIdentifierPrefix)com.quickvault.app</string>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.quickvault.app</string>
</array>
```

### 3. Xcode 项目配置

在 Xcode 中需要启用以下功能：

1. **Signing & Capabilities** → **+ Capability** → **iCloud**
2. 勾选 **CloudKit**
3. 选择或创建 CloudKit 容器：`iCloud.com.quickvault.app`
4. **+ Capability** → **App Groups**
5. 添加 App Group：`group.com.quickvault.app`

## 核心实现

### PersistenceController

```swift
import CoreData

public struct PersistenceController {
    public static let shared = PersistenceController()
    public static let cloudKitContainerIdentifier = "iCloud.com.quickvault.app"
    
    public let container: NSPersistentCloudKitContainer

    public init(inMemory: Bool = false, enableCloudKit: Bool = true) {
        // 加载 Core Data 模型
        guard let modelURL = Bundle.module.url(forResource: "QuickVault", withExtension: "momd"),
              let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load Core Data model")
        }
        
        // 使用 NSPersistentCloudKitContainer 替代 NSPersistentContainer
        container = NSPersistentCloudKitContainer(
            name: "QuickVault", 
            managedObjectModel: managedObjectModel
        )

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to get persistent store description")
        }
        
        if enableCloudKit && !inMemory {
            // 配置 CloudKit 选项
            let cloudKitOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: Self.cloudKitContainerIdentifier
            )
            description.cloudKitContainerOptions = cloudKitOptions
            
            // 启用历史追踪（CloudKit 同步必需）
            description.setOption(true as NSNumber, 
                forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, 
                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }

        // 自动合并来自其他设备的更改
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // 设置查询生成以追踪更改
        try? container.viewContext.setQueryGenerationFrom(.current)
    }
}
```

## Core Data 模型要求

CloudKit 同步对 Core Data 模型有以下要求：

### 1. 所有实体必须有唯一标识符

```xml
<attribute name="id" attributeType="UUID" usesScalarValueType="NO"/>
```

### 2. 关系必须是可选的或有默认值

```xml
<relationship name="card" optional="YES" maxCount="1" 
    deletionRule="Nullify" destinationEntity="Card"/>
```

### 3. 属性类型限制

CloudKit 支持的属性类型：
- String
- Integer (16/32/64)
- Double
- Boolean
- Date
- Binary Data
- UUID
- URI
- Transformable (需要 NSSecureUnarchiveFromData)

### 4. 不支持的特性

- Unique constraints（唯一约束）
- Deny delete rules
- Derived attributes

## 数据安全

### 加密策略

QuickVault 在同步前对敏感数据进行加密：

```
用户输入 → AES-256-GCM 加密 → Core Data → CloudKit → iCloud
```

- 字段值（`CardField.encryptedValue`）在本地加密后存储
- 附件数据（`CardAttachment.encryptedData`）同样加密存储
- 加密密钥由用户主密码派生，不会上传到 iCloud

### 密钥管理

- 加密密钥存储在设备 Keychain 中
- 每个设备需要用户输入主密码才能解密数据
- 即使 iCloud 数据被访问，没有主密码也无法解密

## 同步行为

### 自动同步

- 数据更改会自动推送到 iCloud
- 其他设备的更改会自动拉取并合并
- 支持离线使用，联网后自动同步

### 冲突解决

使用 `NSMergeByPropertyObjectTrumpMergePolicy`：
- 对象级别的属性合并
- 最新更改优先

### 同步延迟

- 通常在几秒到几分钟内完成
- 取决于网络状况和数据量
- 大型附件可能需要更长时间

## 调试

### 启用 CloudKit 日志

在 Xcode Scheme 中添加启动参数：

```
-com.apple.CoreData.CloudKitDebug 1
```

### CloudKit Dashboard

访问 [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/) 查看：
- 同步状态
- 数据记录
- 错误日志

### 常见问题

#### 1. 数据不同步

检查：
- 用户是否登录 iCloud
- 是否启用了 iCloud Drive
- 网络连接是否正常
- Entitlements 配置是否正确

#### 2. 同步冲突

- 检查 `mergePolicy` 设置
- 查看 CloudKit 日志

#### 3. 模型迁移

CloudKit 不支持轻量级迁移之外的模型更改。如需更改模型：
1. 只添加可选属性
2. 不删除或重命名属性
3. 不更改属性类型

## 测试

### 单元测试

```swift
// 禁用 CloudKit 进行测试
let controller = PersistenceController(inMemory: true, enableCloudKit: false)
```

### 集成测试

1. 在两台设备上安装应用
2. 使用同一 iCloud 账户登录
3. 在一台设备上创建数据
4. 验证另一台设备是否收到数据

## 参考资料

- [Apple: Setting Up Core Data with CloudKit](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit)
- [WWDC 2019: Using Core Data With CloudKit](https://developer.apple.com/videos/play/wwdc2019/202/)
- [WWDC 2020: Sync a Core Data Store with CloudKit](https://developer.apple.com/videos/play/wwdc2020/10650/)
- [NSPersistentCloudKitContainer Documentation](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer)
