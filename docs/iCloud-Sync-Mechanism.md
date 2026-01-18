# QuickVault iCloud 同步机制与多设备密码处理说明

本说明聚焦 iOS 端的 iCloud/CloudKit 同步与主密码处理逻辑，帮助理解多设备场景下为何会出现"第二台设备需要重新初始化密码、卡片丢失"的问题，以及当前的防护机制。

---

## 📋 应用 ID 配置总览（最终版本，不应修改）

### 🔒 重要说明

以下配置已经**最终确定**，特别是 iOS 应用已上线（v1.00+），**禁止修改**任何 ID 配置，否则会导致：
- ❌ 已有用户无法访问 Keychain 数据（无法登录）
- ❌ iCloud 同步失败（数据无法跨设备同步）
- ❌ 用户数据丢失风险

---

### 📱 iOS 应用配置

| 配置项 | 值 | 位置 | 说明 |
|--------|-----|------|------|
| **App Name** | `QuickHold` | Info.plist `CFBundleDisplayName` | 用户看到的应用名称 |
| **Bundle Identifier** | `com.codans.quickvault.ios` | Xcode Project Settings | 应用唯一标识符 |
| **Team ID** | `$(TeamIdentifierPrefix)` | Apple Developer Account | 开发者团队 ID（自动填充） |
| **App ID Prefix** | `$(AppIdentifierPrefix)` | Xcode Automatic | 应用 ID 前缀（自动填充） |

**文件路径**：
- `src/QuickHold-iOS-App/QuickHold-iOS.xcodeproj/project.pbxproj`
- `src/QuickHold-iOS-App/QuickHold-iOS/Resources/Info.plist`

---

### 💻 macOS 应用配置

| 配置项 | 值 | 位置 | 说明 |
|--------|-----|------|------|
| **App Name** | `QuickVault` | Info.plist `CFBundleDisplayName` | 用户看到的应用名称 |
| **Bundle Identifier** | `com.codans.quickvault.macos` | Xcode Project Settings | 应用唯一标识符 |
| **Team ID** | `$(TeamIdentifierPrefix)` | Apple Developer Account | 开发者团队 ID（自动填充） |
| **App ID Prefix** | `$(AppIdentifierPrefix)` | Xcode Automatic | 应用 ID 前缀（自动填充） |

**文件路径**：
- `src/QuickVault-macOS-App/QuickVault-macOS.xcodeproj/project.pbxproj`
- `src/QuickVault-macOS-App/QuickVault-macOS/Resources/Info.plist`

---

### ☁️ iCloud 和跨平台配置（必须一致）

这些配置**必须在 iOS 和 macOS 两个平台完全一致**，否则无法实现跨平台数据同步：

| 配置项 | 值 | 用途 | 修改影响 |
|--------|-----|------|---------|
| **CloudKit Container** | `iCloud.com.QuickHold.app` | CoreData 通过 CloudKit 同步 | ❌ 修改后无法跨平台同步数据 |
| **App Group** | `group.com.QuickHold.app` | 应用间共享数据 | ⚠️ 修改后共享数据失效 |
| **ubiquity-kvstore** | `$(TeamIdentifierPrefix)com.QuickHold.app` | iCloud Key-Value Store | ⚠️ 修改后 KVS 数据丢失 |

**配置位置**（两个平台都需要）：
- iOS: `src/QuickHold-iOS-App/QuickHold-iOS/Resources/QuickHold.entitlements`
- macOS: `src/QuickVault-macOS-App/QuickVault-macOS/Resources/QuickVault.entitlements`

---

### 🔑 Keychain 访问组配置

| 平台 | Keychain 访问组 | 状态 | 说明 |
|------|----------------|------|------|
| **iOS** | `$(AppIdentifierPrefix)com.QuickHold.ios` | 🔒 **已上线，禁止修改** | 历史配置，与 Bundle ID 不一致但功能正常 |
| **macOS** | `$(AppIdentifierPrefix)com.codans.quickvault.macos` | ✅ 已更新 | 与 Bundle ID 一致 |

**⚠️ iOS Keychain 访问组特别说明**：

虽然 iOS 的 Keychain 访问组（`com.QuickHold.ios`）与 Bundle ID（`com.codans.quickvault.ios`）不一致，但**绝对不能修改**：

1. **功能正常** - iCloud Keychain 同步的 salt 不受访问组限制（使用 `kSecAttrSynchronizable`）
2. **破坏性更新** - 修改会导致已有用户无法读取本地 Keychain 数据
3. **数据丢失** - 主密码哈希和生物识别密码存储在旧访问组中，修改后全部丢失
4. **无法登录** - 用户升级后无法验证密码，只能重新设置（但数据无法解密）

---

### 🗂️ Keychain 服务名和存储项

**Keychain Service Name**: `com.codans.quickhold.app`

**代码常量位置**: `src/QuickHoldKit/Sources/QuickHoldCore/Constants/Consts.swift`

| Keychain Key | 同步到 iCloud？ | 存储内容 | 用途 | 修改影响 |
|--------------|---------------|---------|------|---------|
| `crypto.salt` | ✅ **是** (`synchronizable: true`) | 32 字节随机盐值 | PBKDF2 密钥派生，跨设备共享 | ❌ 修改后多设备同步失败 |
| `com.quickhold.masterPassword` | ❌ **否** (`synchronizable: false`) | 主密码 SHA-256 哈希 | 验证用户密码 | ❌ 修改后用户无法登录 |
| `com.quickhold.biometricPassword` | ❌ **否** (`synchronizable: false`) | 明文主密码 | Face ID/Touch ID 认证 | ⚠️ 修改后生物识别失效 |
| `com.quickhold.reportDeviceId` | ✅ **是** (`synchronizable: true`) | 设备唯一 UUID | 多设备报告和统计 | ⚠️ 修改后设备识别失败 |

---

### 📦 完整配置对照表

#### iOS Entitlements 配置
```xml
<!-- src/QuickHold-iOS-App/QuickHold-iOS/Resources/QuickHold.entitlements -->
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.QuickHold.app</string>
    </array>

    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>

    <key>com.apple.developer.ubiquity-kvstore-identifier</key>
    <string>$(TeamIdentifierPrefix)com.QuickHold.app</string>

    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.QuickHold.app</string>
    </array>

    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.QuickHold.ios</string>  <!-- 🔒 不要修改 -->
    </array>
</dict>
```

#### macOS Entitlements 配置
```xml
<!-- src/QuickVault-macOS-App/QuickVault-macOS/Resources/QuickVault.entitlements -->
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.QuickHold.app</string>
    </array>

    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>

    <key>com.apple.developer.ubiquity-kvstore-identifier</key>
    <string>$(TeamIdentifierPrefix)com.QuickHold.app</string>

    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.QuickHold.app</string>
    </array>

    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.codans.quickvault.macos</string>
    </array>
</dict>
```

#### 代码常量配置
```swift
// src/QuickHoldKit/Sources/QuickHoldCore/Constants/Consts.swift
public enum QuickHoldConstants {
    public enum CloudKit {
        public static let containerIdentifier = "iCloud.com.QuickHold.app"
    }

    public enum KeychainKeys {
        public static let masterPassword = "com.quickhold.masterPassword"
        public static let biometricPassword = "com.quickhold.biometricPassword"
        public static let cryptoSalt = "crypto.salt"
        public static let reportDeviceId = "com.quickhold.reportDeviceId"
    }
}
```

---

### ✅ 配置验证清单

在部署或更新应用前，请确认以下配置：

#### **跨平台同步必需配置（必须一致）**
- [ ] CloudKit Container: `iCloud.com.QuickHold.app`（iOS 和 macOS 一致）
- [ ] App Group: `group.com.QuickHold.app`（iOS 和 macOS 一致）
- [ ] ubiquity-kvstore: `$(TeamIdentifierPrefix)com.QuickHold.app`（iOS 和 macOS 一致）
- [ ] iCloud Services 包含 `CloudKit`

#### **平台特定配置**
- [ ] iOS Bundle ID: `com.codans.quickvault.ios`
- [ ] macOS Bundle ID: `com.codans.quickvault.macos`
- [ ] iOS Keychain 访问组: `$(AppIdentifierPrefix)com.QuickHold.ios` 🔒
- [ ] macOS Keychain 访问组: `$(AppIdentifierPrefix)com.codans.quickvault.macos`

#### **Keychain 存储配置**
- [ ] Salt 使用 `synchronizable: true`（可跨设备同步）
- [ ] 密码哈希使用 `synchronizable: false`（本地存储）
- [ ] 生物识别密码使用 `synchronizable: false`（本地存储）

#### **Xcode 签名配置**
- [ ] 开发团队（Team）已选择
- [ ] Capabilities 中 iCloud 已启用
- [ ] Capabilities 中 Keychain Sharing 已启用
- [ ] Capabilities 中 App Groups 已启用

---

### 🚨 配置修改警告

**以下配置绝对不能修改**（iOS 已上线）：

| 配置项 | 当前值 | 修改后果 |
|--------|-------|---------|
| iOS Bundle ID | `com.codans.quickvault.ios` | ❌ App 无法更新，必须重新上架 |
| iOS Keychain 访问组 | `com.QuickHold.ios` | ❌ 用户无法登录，数据全部丢失 |
| CloudKit Container | `iCloud.com.QuickHold.app` | ❌ 所有 iCloud 数据丢失 |
| App Group | `group.com.QuickHold.app` | ⚠️ 共享数据失效 |
| Salt Keychain Key | `crypto.salt` | ❌ 多设备同步彻底失败 |
| 密码哈希 Key | `com.quickhold.masterPassword` | ❌ 所有用户无法登录 |

**macOS 配置可修改项**（macOS 刚开始开发）：
- ⚠️ macOS Bundle ID 理论上可改，但不建议（已设置为 `com.codans.quickvault.macos`）
- ⚠️ macOS Keychain 访问组可改，但不建议（已设置为与 Bundle ID 一致）

---

## 数据与密钥流转
- **数据存储**：使用 `NSPersistentCloudKitContainer` 将 Core Data (Item 等实体) 同步到 CloudKit，字段内容在本地加密后存储。
- **加密密钥**：由用户主密码 + salt 通过 PBKDF2 派生；密钥本身不落盘。
- **salt 存储**：写入 iCloud Keychain（可同步项），用于多设备共享；主密码哈希、指纹备份密码存本地 Keychain（不可同步）。
- **文件附件**：加密后写入本地文件系统（默认非 iCloud），元数据在 Core Data 中同步。

## 应用启动流程（重要 ⭐）

### 正确的启动顺序

应用启动时必须按以下顺序初始化：

```swift
// 1. 初始化服务
let authService = AuthenticationServiceImpl(
    keychainService: keychainService,
    persistenceController: persistenceController
)

// 2. 异步检查初始状态（必须调用！）
await authService.checkInitialState()

// 3. 根据状态显示对应界面
switch authService.authenticationState {
case .initializing:
    // 显示加载界面（理论上不会出现，checkInitialState 会更新状态）
    showLoadingScreen()

case .setupRequired:
    // 显示初始化密码界面（首次设置）
    showSetupPasswordScreen()

case .locked:
    // 显示登录界面
    showLoginScreen()

case .waitingForCloudSync:
    // 显示等待 iCloud 同步界面
    showWaitingForSyncScreen()

case .unlocked:
    // 显示主界面（不应该出现在启动时）
    showMainScreen()
}
```

**⚠️ 重要**：不调用 `checkInitialState()` 会导致第二台设备误判为首次设置！

---

## 认证状态说明

| 状态 | 说明 | 何时出现 | 下一步操作 |
|------|------|---------|-----------|
| `.initializing` | 初始化中，正在检查 iCloud 状态 | App 启动时（临时状态） | 自动调用 `checkInitialState()` |
| `.setupRequired` | 需要设置主密码 | 首次启动或凭据损坏 | 用户设置密码 |
| `.locked` | 已锁定，需要登录 | 已设置密码但未解锁 | 用户登录（密码或生物识别） |
| `.waitingForCloudSync` | 等待 iCloud Keychain 同步 salt | 检测到 CloudKit 有数据但 salt 未同步 | 等待或重试 |
| `.unlocked` | 已解锁 | 用户成功认证 | 正常使用应用 |

---

## 首台设备流程（Primary Device）

1. **启动检查**：
   - `checkInitialState()` 检测 CloudKit 无数据
   - 状态设置为 `.setupRequired`

2. **设置密码**：
   - 用户设置主密码
   - `CryptoService.initializeKey` 生成新 salt
   - Salt 保存到 iCloud Keychain (`synchronizable: true`)
   - 密码哈希保存到本地 Keychain (`synchronizable: false`)

3. **数据同步**：
   - 用户添加卡片后，加密存储并通过 CloudKit 同步

---

## 第二台设备流程（Secondary Device）

### 场景 1：Salt 已同步（推荐体验）

1. **启动检查**：
   - `checkInitialState()` 检测 CloudKit 有数据
   - 检测到 salt 已从 iCloud Keychain 同步
   - 状态设置为 `.locked`

2. **用户登录**：
   - 显示登录界面（**不是**初始化界面 ✅）
   - 用户输入首台设备设置的同一密码
   - 使用同步的 salt 派生密钥
   - 解密已同步的数据，卡片出现

### 场景 2：Salt 未同步（需要等待）

1. **启动检查**：
   - `checkInitialState()` 检测 CloudKit 有数据
   - 检测到 salt 尚未从 iCloud Keychain 同步
   - 状态设置为 `.waitingForCloudSync`

2. **等待同步**：
   - 显示"等待 iCloud 同步..."界面
   - 后台自动尝试等待 salt 同步（1/2/3/4 秒阶梯等待）
   - Salt 同步成功后自动切换到 `.locked` 状态

3. **用户登录**：
   - 自动或手动刷新后显示登录界面
   - 用户输入密码登录

### 场景 3：Salt 同步超时

1. **超时处理**：
   - 等待 10 秒后仍未同步到 salt
   - 保持 `.waitingForCloudSync` 状态
   - 提示用户检查 iCloud 设置或稍后重试

2. **可能原因**：
   - iCloud Keychain 未启用
   - 网络连接问题
   - 首台设备尚未完成上传
   - iCloud 同步延迟

## 问题复现机制（已修复）
- **缺陷点**：第二台设备在 iCloud Keychain 的 salt 尚未抵达时，`initializeKey` 会生成新的 salt；随后该新 salt 同步回首台设备，导致两台设备使用不同盐值派生的密钥加密数据，互相无法解密，表现为“要求重新初始化密码/卡片丢失”。

## 防护机制（当前代码）
参考文件：
- `src/QuickHoldKit/Sources/QuickHoldCore/Services/CryptoService.swift`
- `src/QuickHoldKit/Sources/QuickHoldCore/Services/AuthenticationService.swift`
- `src/QuickHoldKit/Sources/QuickHoldCore/Models/PersistenceController.swift`

关键措施：
1. **禁止在有云数据时生成新 salt**：`initializeKey` 增加 `allowSaltGeneration`，多设备路径默认 `false`。
2. **等待 iCloud Keychain 同步 salt**：`waitForSaltSyncIfNeeded()` 按 1/2/3/4 秒阶梯等待，未拿到盐则抛出 `waitingForSync`，提示稍后重试。
3. **登录/生物识别同样等待 salt**：密码登录、指纹解锁都在初始化密钥前等待盐同步；若无盐返回“等待 iCloud 同步”。
4. **CloudKit 数据检测更耐心**：`hasExistingData()` 增加最长约 15 秒轮询（0/1/2/4/8 秒，共 5 次检测），减少"误判无数据"导致的错误路径。

## 预期用户体验
- 第二台设备首次启动时，如 iCloud 同步未完成，会看到“正在等待 iCloud 同步…”；稍后输入首台设备密码即可加载卡片。
- 不会再生成新的 salt，避免首台设备卡片“被清空”或无法解密。

## 排查与测试建议
1. 两台真机登录同一 iCloud，确保 iCloud 钥匙串已开启。
2. 首台添加卡片后，等 1–2 分钟再启动第二台；如出现“等待同步”提示，稍后重试同一密码。
3. 验证：第二台能解锁并看到卡片；首台卡片未消失且可解密。
4. 如果多次等待仍失败，检查：  
   - iCloud 钥匙串是否关闭；  
   - CloudKit 容器是否一致 (`iCloud.com.QuickHold.app` vs `iCloud.com.quickvault.app` 等名字差异)；  
   - Xcode 配置的 Team/Bundle ID 与 entitlements 是否匹配。

## 重要标识与配置（已修复 ✅）

以下配置已在 macOS 和 iOS 平台统一，确保跨平台 iCloud 同步正常工作：

### 统一配置（跨平台同步必需）

这些配置**必须在两个平台保持一致**，否则无法实现 iCloud 数据同步：

| 配置项 | 值 | 文件位置 | 作用 |
|--------|-----|---------|------|
| **CloudKit 容器** | `iCloud.com.QuickHold.app` | `*.entitlements` | CoreData 通过 CloudKit 同步 |
| **App Group** | `group.com.QuickHold.app` | `*.entitlements` | 应用间共享数据（如果需要） |
| **ubiquity-kvstore** | `$(TeamIdentifierPrefix)com.QuickHold.app` | `*.entitlements` | iCloud Key-Value Store |

**配置文件路径**：
- macOS: `src/QuickVault-macOS-App/QuickVault-macOS/Resources/QuickVault.entitlements`
- iOS: `src/QuickHold-iOS-App/QuickHold-iOS/Resources/QuickHold.entitlements`

---

### 平台特定配置

这些配置可以在两个平台不同：

#### **1. Bundle Identifier**

| 平台 | Bundle ID | 文件位置 |
|------|----------|---------|
| macOS | `com.codans.quickvault.macos` | `QuickVault-macOS.xcodeproj/project.pbxproj` |
| iOS | `com.codans.quickvault.ios` | `QuickHold-iOS.xcodeproj/project.pbxproj` |

**说明**：遵循统一命名规范 `com.codans.quickvault.<平台>`

---

#### **2. Keychain 访问组**

| 平台 | Keychain 访问组 | 状态 | 说明 |
|------|----------------|------|------|
| macOS | `$(AppIdentifierPrefix)com.codans.quickvault.macos` | ✅ 已更新 | 与 Bundle ID 一致 |
| iOS | `$(AppIdentifierPrefix)com.QuickHold.ios` | 🔒 保持不变 | 历史遗留配置 |

**⚠️ iOS Keychain 访问组特别说明**：

iOS 的 Keychain 访问组（`com.QuickHold.ios`）与 Bundle ID（`com.codans.quickvault.ios`）**不一致**。这是**历史遗留**，但**不应修改**：

**为什么不改？**
1. ✅ **功能完全正常** - 不影响 iCloud Keychain 同步（salt 正常跨设备同步）
2. ❌ **破坏性更新** - 修改后已有用户无法读取本地 Keychain 数据
3. 🔒 **数据丢失风险** - 用户升级后无法登录，主密码哈希和生物识别密码全部丢失
4. 📱 **1.00 已上线** - 已有用户数据存储在旧访问组中

**技术细节**：
- iCloud Keychain 同步的 salt 使用 `kSecAttrSynchronizable = true`，**不受访问组限制**
- 本地 Keychain 的密码哈希使用 `kSecAttrSynchronizable = false`，受访问组限制
- 修改访问组会导致应用无法读取旧访问组中的数据

---

#### **3. Keychain 服务名（kSecAttrService）**

所有 Keychain 项使用统一服务名前缀：`com.codans.quickhold.app`

**代码常量定义**：`src/QuickHoldKit/Sources/QuickHoldCore/Constants/Consts.swift`

```swift
public enum QuickHoldConstants {
  public enum KeychainKeys {
    public static let masterPassword = "com.quickhold.masterPassword"
    public static let biometricPassword = "com.quickhold.biometricPassword"
    public static let cryptoSalt = "crypto.salt"
    public static let reportDeviceId = "com.quickhold.reportDeviceId"
  }
}
```

**实际 Keychain 存储项**：

| Key | 同步到 iCloud？ | 存储内容 | 用途 |
|-----|---------------|---------|------|
| `crypto.salt` | ✅ 是 (`synchronizable: true`) | 32 字节随机盐值 | 密钥派生，跨设备共享 |
| `com.quickhold.masterPassword` | ❌ 否 (`synchronizable: false`) | 主密码的 SHA-256 哈希 | 验证用户密码 |
| `com.quickhold.biometricPassword` | ❌ 否 (`synchronizable: false`) | 明文主密码 | 生物识别后自动登录 |
| `com.quickhold.reportDeviceId` | ✅ 是 (`synchronizable: true`) | 设备唯一标识 | 多设备报告 |

---

### 配置验证清单

在部署或调试前，请确认以下配置：

#### **跨平台同步必需配置**
- ✅ CloudKit 容器标识符一致（`iCloud.com.QuickHold.app`）
- ✅ App Group 标识符一致（`group.com.QuickHold.app`）
- ✅ iCloud Services 包含 `CloudKit`
- ✅ ubiquity-kvstore 标识符一致

#### **Keychain 配置**
- ✅ Salt 使用 `synchronizable: true` 存储（可跨设备同步）
- ✅ 密码哈希使用 `synchronizable: false` 存储（本地存储，不同步）
- ✅ 生物识别密码使用 `synchronizable: false` 存储（本地存储，不同步）

#### **Bundle ID 和访问组**
- ✅ macOS Bundle ID: `com.codans.quickvault.macos`
- ✅ iOS Bundle ID: `com.codans.quickvault.ios`
- ✅ macOS Keychain 访问组: `$(AppIdentifierPrefix)com.codans.quickvault.macos`
- 🔒 iOS Keychain 访问组: `$(AppIdentifierPrefix)com.QuickHold.ios`（**已上线，不应修改**）

#### **Xcode 配置**
- ✅ 签名团队（Team）一致
- ✅ iCloud 功能已启用
- ✅ iCloud Keychain 已在设备上启用
- ✅ 设备登录同一 Apple ID

---

### 日志系统配置

为方便调试 iCloud 同步功能，已在关键代码路径添加详细日志：

#### **日志子系统和类别**

| 服务 | Subsystem | Category | 日志前缀 |
|------|-----------|----------|---------|
| 加密服务 | `com.codans.quickhold` | `CryptoService` | `[CryptoService]` |
| 认证服务 | `com.codans.quickhold` | `AuthService` | `[AuthService]` |
| Keychain 服务 | `com.codans.quickhold` | `KeychainService` | `[Keychain]` |
| 数据持久化 | `com.codans.quickhold` | `PersistenceController` | `[Persistence]` |

#### **查看日志方法**

**iOS 真机/模拟器**：
```bash
# 实时查看所有 QuickHold 日志
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.codans.quickhold"' --level debug

# 或使用 Console.app，过滤 "com.codans.quickhold"
```

**macOS 应用**：
```bash
# 实时查看日志
log stream --predicate 'subsystem == "com.codans.quickhold"' --level debug

# 查看最近 10 分钟的历史日志
log show --predicate 'subsystem == "com.codans.quickhold"' --last 10m
```

#### **关键日志标记**

日志使用表情符号标记不同状态，方便快速定位：

| 标记 | 含义 | 示例 |
|------|------|------|
| 🔐 | 加密/密钥操作 | `🔐 [CryptoService] initializeKey called` |
| ☁️ | iCloud 相关操作 | `☁️ [Keychain] Enabling iCloud Keychain sync` |
| ⏳ | 等待/轮询 | `⏳ [AuthService] Waiting for salt sync...` |
| ✅ | 操作成功 | `✅ [Keychain] Item saved successfully!` |
| ❌ | 操作失败 | `❌ [AuthService] Password validation FAILED` |
| ⚠️ | 警告 | `⚠️ [Persistence] No data found in attempt 1` |
| 💡 | 提示信息 | `💡 [AuthService] Possible reasons: iCloud Keychain disabled` |
| 🎉 | 重要成功 | `🎉 [AuthService] SUCCESS! Salt received after 2 attempts` |

---

### 配置文件快速参考

#### **macOS Entitlements**
```xml
<!-- src/QuickVault-macOS-App/QuickVault-macOS/Resources/QuickVault.entitlements -->
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.QuickHold.app</string>
</array>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.QuickHold.app</string>
</array>
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.codans.quickvault.macos</string>
</array>
```

#### **iOS Entitlements**
```xml
<!-- src/QuickHold-iOS-App/QuickHold-iOS/Resources/QuickHold.entitlements -->
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.QuickHold.app</string>
</array>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.QuickHold.app</string>
</array>
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.QuickHold.ios</string>  <!-- 历史配置，保持不变 -->
</array>
```

#### **代码常量**
```swift
// src/QuickHoldKit/Sources/QuickHoldCore/Constants/Consts.swift
public enum QuickHoldConstants {
  public enum CloudKit {
    public static let containerIdentifier = "iCloud.com.QuickHold.app"
  }
}
```
