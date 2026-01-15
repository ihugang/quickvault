# 文件存储架构 / File Storage Architecture

## 概述 / Overview

QuickVault 使用文件系统存储用户的文件附件，而非直接存储在数据库中。这种设计提供了更好的性能、可扩展性和跨设备同步能力。

## 存储位置 / Storage Locations

### 1. iCloud 存储（默认）/ iCloud Storage (Default)

**路径**: `iCloud Drive/QuickVault/Documents/Files/`

**特性**:
- ✅ **跨设备同步**: iOS 和 macOS 自动同步
- ✅ **共享访问**: 所有登录同一 Apple ID 的设备可访问
- ✅ **自动备份**: Apple 负责备份和恢复
- ✅ **容量灵活**: 使用 iCloud 存储空间
- ⚠️ **需要网络**: 首次下载需要网络连接

**适用场景**:
- 多设备使用（iPhone、iPad、Mac）
- 需要自动备份和同步
- iCloud 存储空间充足

### 2. 本地存储 / Local Storage

**iOS 路径**: `~/Library/Application Support/QuickVault/Files/`
**macOS 路径**: `~/Library/Application Support/QuickVault/Files/`

**特性**:
- ✅ **完全离线**: 不需要网络连接
- ✅ **私密性高**: 文件只存储在本地
- ✅ **速度快**: 无需等待云同步
- ❌ **不跨设备**: 每个设备独立存储
- ❌ **需手动备份**: 用户需自行备份数据

**适用场景**:
- 单设备使用
- 不希望使用 iCloud
- 需要完全离线访问

## 文件组织结构 / File Organization

```
iCloud Drive (或 Application Support)
└── QuickVault/
    └── Documents/ (仅 iCloud)
        └── Files/
            ├── {UUID1}.pdf
            ├── {UUID2}.jpg
            ├── {UUID3}.docx
            └── ...
```

### 文件命名规则 / File Naming Convention

- 格式: `{UUID}.{extension}`
- 示例: `123e4567-e89b-12d3-a456-426614174000.pdf`
- UUID 保证唯一性，避免文件名冲突

## 安全性 / Security

### 加密存储 / Encrypted Storage

所有文件在存储前都会使用 **AES-256-GCM** 加密：

```swift
// 保存文件时
let encryptedData = cryptoService.encrypt(originalData)
fileSystem.write(encryptedData, to: fileURL)

// 读取文件时
let encryptedData = fileSystem.read(from: fileURL)
let originalData = cryptoService.decrypt(encryptedData)
```

### 元数据保护 / Metadata Protection

数据库中存储的元数据：
- ✅ 文件路径（相对路径）
- ✅ 文件大小（加密前）
- ✅ MIME 类型
- ✅ 文件名（用于显示）
- ✅ 缩略图（加密存储）

## 跨平台共享 / Cross-Platform Sharing

### iOS ↔ macOS 同步

使用 **iCloud Documents**，iOS 和 macOS 应用可以无缝共享文件：

1. **iOS 上传文件** → iCloud 自动上传 → **macOS 自动下载**
2. **macOS 编辑** → iCloud 同步 → **iOS 自动更新**

### App Group 共享

通过 App Group (`group.com.quickvault.app`)，可以实现：
- iOS 主应用 ↔ iOS Widget
- iOS 应用 ↔ iOS 自动填充扩展
- macOS 主应用 ↔ macOS Widget

### CoreData + iCloud

数据库使用 **NSPersistentCloudKitContainer**：
- 元数据（文件路径、大小等）通过 CloudKit 同步
- 实际文件内容通过 iCloud Documents 同步
- 两者协同工作，确保数据一致性

## 配置方法 / Configuration

### 使用 iCloud 存储（推荐）

```swift
// 默认使用 iCloud
let fileStorageManager = FileStorageManager(
    cryptoService: CryptoServiceImpl.shared,
    storageLocation: .iCloud  // 默认值
)
```

### 使用本地存储

```swift
// 仅本地存储
let fileStorageManager = FileStorageManager(
    cryptoService: CryptoServiceImpl.shared,
    storageLocation: .local
)
```

### 检查 iCloud 可用性

```swift
if fileStorageManager.isICloudAvailable {
    print("✅ iCloud 可用")
} else {
    print("⚠️ iCloud 不可用，使用本地存储")
}
```

## 权限配置 / Entitlements Configuration

### iOS (QuickVault.entitlements)

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

### macOS (QuickVault.entitlements)

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

## 最佳实践 / Best Practices

### 1. 自动回退机制

如果 iCloud 不可用，FileStorageManager 会自动回退到本地存储：

```swift
private func iCloudFilesDirectory() throws -> URL {
    guard let containerURL = fileManager.url(forUbiquityContainerIdentifier: iCloudContainerIdentifier) else {
        print("⚠️ iCloud not available, falling back to local storage")
        return try localFilesDirectory()
    }
    // ...
}
```

### 2. 错误处理

```swift
do {
    let data = try fileStorageManager.readFile(relativePath: filePath)
    // 使用数据
} catch {
    // 文件可能正在从 iCloud 下载
    print("⚠️ File not available: \(error)")
    // 显示下载进度或使用缓存
}
```

### 3. 大文件处理

对于大文件（>10MB），建议：
- 使用后台下载
- 显示进度指示器
- 实现增量加载

### 4. 离线支持

- 关键文件应保留本地缓存
- 使用 `NSMetadataQuery` 监控 iCloud 下载状态
- 提供"离线可用"标记选项

## 迁移指南 / Migration Guide

### 从本地存储迁移到 iCloud

```swift
// 1. 获取所有本地文件
let localManager = FileStorageManager(cryptoService: crypto, storageLocation: .local)
let localFiles = try localManager.listAllFiles()

// 2. 复制到 iCloud
let iCloudManager = FileStorageManager(cryptoService: crypto, storageLocation: .iCloud)
for file in localFiles {
    let data = try localManager.readFile(relativePath: file)
    try iCloudManager.saveFile(data: data, fileName: file)
}

// 3. 更新数据库中的路径（如果需要）
```

## 监控和调试 / Monitoring & Debugging

### 检查存储路径

```swift
if let path = fileStorageManager.getStoragePath() {
    print("📁 Files stored at: \(path)")
}
```

### 文件系统监控

```swift
// 监控 iCloud 状态变化
NotificationCenter.default.addObserver(
    forName: NSUbiquityIdentityDidChange,
    object: nil,
    queue: .main
) { _ in
    print("🔄 iCloud account changed")
}
```

## 常见问题 / FAQ

### Q: 文件会占用多少空间？

A: 
- 文件大小 = 原始文件大小 + 加密开销（约 1-2%）
- 缩略图存储在数据库中（每个约 50KB）
- iCloud 空间与本地空间独立计算

### Q: 如何处理 iCloud 配额不足？

A: 
1. 应用会显示"存储空间不足"警告
2. 用户可以切换到本地存储模式
3. 或购买更多 iCloud 空间

### Q: 删除应用后文件会保留吗？

A:
- **本地存储**: 删除应用时一并删除
- **iCloud 存储**: 保留在 iCloud Drive 中，需手动删除

### Q: 多设备编辑冲突如何处理？

A: 
- iCloud 使用"最后写入获胜"策略
- CoreData + CloudKit 会自动处理冲突
- 建议实现冲突解决 UI（未来版本）

## 性能优化 / Performance Optimization

### 1. 延迟加载

只在需要时才从磁盘读取文件内容：

```swift
// 仅加载元数据
let files = try itemService.fetchItem(id: itemId).files

// 用户点击时才加载文件内容
let data = try fileStorageManager.readFile(relativePath: file.fileURL)
```

### 2. 缩略图缓存

缩略图存储在数据库中，无需重复生成。

### 3. 批量操作

```swift
// 批量保存文件
for file in files {
    try fileStorageManager.saveFile(data: file.data, fileName: file.name)
}
```

## 总结 / Summary

✅ **默认启用 iCloud 同步**
✅ **iOS 和 macOS 自动共享**
✅ **所有文件加密存储**
✅ **自动回退到本地存储**
✅ **支持离线访问**
✅ **无缝跨设备体验**

QuickVault 的文件存储架构兼顾了安全性、性能和用户体验，为用户提供了灵活的存储选项。
