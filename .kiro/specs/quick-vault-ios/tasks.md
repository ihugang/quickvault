# Implementation Plan: QuickVault iOS / 实施计划：随取 iOS

## Overview / 概述

This implementation plan breaks down the QuickVault iOS application into discrete, incremental tasks. The plan prioritizes iOS-first development with a focus on core functionality, watermarking feature, and eventual code sharing with macOS. Each task builds on previous work and includes testing to validate correctness early.

本实施计划将随取 iOS 应用程序分解为离散的增量任务。该计划优先考虑 iOS 优先开发，重点关注核心功能、水印功能以及最终与 macOS 的代码共享。每个任务都建立在之前的工作基础上，并包含测试以尽早验证正确性。

## Tasks / 任务

-   [ ] 1. Project Setup and Core Infrastructure / 项目设置和核心基础设施

    -   Create iOS app project with SwiftUI + CoreData template / 使用 SwiftUI + CoreData 模板创建 iOS 应用项目
    -   Configure project structure (Sources/Core, Sources/Features, Sources/Views) / 配置项目结构
    -   Add SwiftCheck dependency for property-based testing / 添加 SwiftCheck 依赖用于基于属性的测试
    -   Set up CoreData model with Card, CardField, CardAttachment entities / 设置 CoreData 模型
    -   Configure app entitlements for Keychain and Face ID access / 配置应用权限
    -   Set up bilingual string resources / 设置双语字符串资源
    -   _Requirements: 14.1, 9.1_

-   [ ] 2. Implement Keychain Service / 实现钥匙串服务

    -   [ ] 2.1 Create KeychainService protocol and implementation / 创建 KeychainService 协议和实现

        -   Implement save, load, delete, exists methods / 实现 save、load、delete、exists 方法
        -   Handle Keychain errors gracefully / 优雅地处理钥匙串错误
        -   _Requirements: 10.2_

    -   [ ]\* 2.2 Write unit tests for Keychain operations / 编写钥匙串操作的单元测试
        -   Test saving and loading data / 测试保存和加载数据
        -   Test error handling / 测试错误处理
        -   _Requirements: 10.2_

-   [ ] 3. Implement Crypto Service / 实现加密服务

    -   [ ] 3.1 Create CryptoService protocol and implementation / 创建 CryptoService 协议和实现

        -   Implement AES-GCM encryption and decryption / 实现 AES-GCM 加密和解密
        -   Implement PBKDF2 key derivation (100,000 iterations) / 实现 PBKDF2 密钥派生
        -   Implement salt generation / 实现盐值生成
        -   Add file encryption methods for attachments / 添加附件的文件加密方法
        -   Add password hashing method / 添加密码哈希方法
        -   _Requirements: 10.1, 10.4, 10.5_

    -   [ ]\* 3.2 Write property test for encryption round trip / 编写加密往返的属性测试

        -   **Property 26: Field Encryption Round Trip** / **属性 26：字段加密往返**
        -   **Validates: Requirements 10.1, 10.5** / **验证：需求 10.1, 10.5**

    -   [ ]\* 3.3 Write property test for key derivation determinism / 编写密钥派生确定性的属性测试

        -   **Property 27: Key Derivation Determinism** / **属性 27：密钥派生确定性**
        -   **Validates: Requirements 10.4** / **验证：需求 10.4**

    -   [ ]\* 3.4 Write property test for attachment file encryption / 编写附件文件加密的属性测试
        -   **Property 14: Attachment Encryption Round Trip** / **属性 14：附件加密往返**
        -   **Validates: Requirements 5.2** / **验证：需求 5.2**

-   [ ] 4. Implement Authentication Service / 实现认证服务

    -   [ ] 4.1 Create AuthenticationService protocol and implementation / 创建 AuthenticationService 协议和实现

        -   Implement Face ID/Touch ID authentication using LocalAuthentication / 使用 LocalAuthentication 实现 Face ID/Touch ID 认证
        -   Implement master password authentication / 实现主密码认证
        -   Implement password setup and change / 实现密码设置和更改
        -   Implement lock/unlock state management with Combine / 使用 Combine 实现锁定/解锁状态管理
        -   Implement failed attempt tracking with 30-second delay / 实现失败尝试跟踪及 30 秒延迟
        -   _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 11.1, 11.2, 11.3, 11.4, 11.5_

    -   [ ]\* 4.2 Write property test for authentication state transition / 编写认证状态转换的属性测试

        -   **Property 23: Authentication State Transition** / **属性 23：认证状态转换**
        -   **Validates: Requirements 9.4** / **验证：需求 9.4**

    -   [ ]\* 4.3 Write property test for password change / 编写密码更改的属性测试

        -   **Property 29: Password Change Authentication** / **属性 29：密码更改认证**
        -   **Validates: Requirements 11.3** / **验证：需求 11.3**

    -   [ ]\* 4.4 Write unit tests for failed attempt rate limiting / 编写失败尝试速率限制的单元测试

        -   Test 3 failed attempts trigger delay / 测试 3 次失败尝试触发延迟
        -   _Requirements: 11.4_

    -   [ ]\* 4.5 Write property test for background lock / 编写后台锁定的属性测试
        -   **Property 25: Background Lock** / **属性 25：后台锁定**
        -   **Validates: Requirements 9.7** / **验证：需求 9.7**

-   [ ] 5. Checkpoint - Core Services Complete / 检查点 - 核心服务完成

    -   Ensure all tests pass, ask the user if questions arise. / 确保所有测试通过，如有问题请询问用户。

-   [ ] 6. Implement Card Service / 实现卡片服务

    -   [ ] 6.1 Create CardService protocol and implementation / 创建 CardService 协议和实现

        -   Implement createCard with field encryption / 实现带字段加密的 createCard
        -   Implement updateCard with timestamp update / 实现带时间戳更新的 updateCard
        -   Implement deleteCard with cascade delete / 实现带级联删除的 deleteCard
        -   Implement fetchAllCards with decryption / 实现带解密的 fetchAllCards
        -   Implement searchCards with field matching / 实现带字段匹配的 searchCards
        -   Implement togglePin / 实现 togglePin
        -   _Requirements: 1.1, 1.2, 1.3, 1.6, 7.1_

    -   [ ]\* 6.2 Write property test for card creation completeness / 编写卡片创建完整性的属性测试

        -   **Property 1: Card Creation Completeness** / **属性 1：卡片创建完整性**
        -   **Validates: Requirements 1.1, 1.5** / **验证：需求 1.1, 1.5**

    -   [ ]\* 6.3 Write property test for card update timestamp / 编写卡片更新时间戳的属性测试

        -   **Property 2: Card Update Timestamp** / **属性 2：卡片更新时间戳**
        -   **Validates: Requirements 1.2** / **验证：需求 1.2**

    -   [ ]\* 6.4 Write property test for card deletion completeness / 编写卡片删除完整性的属性测试

        -   **Property 3: Card Deletion Completeness** / **属性 3：卡片删除完整性**
        -   **Validates: Requirements 1.3** / **验证：需求 1.3**

    -   [ ]\* 6.5 Write property test for pin toggle consistency / 编写置顶切换一致性的属性测试

        -   **Property 4: Pin Toggle Consistency** / **属性 4：置顶切换一致性**
        -   **Validates: Requirements 1.6** / **验证：需求 1.6**

    -   [ ]\* 6.6 Write property test for search matches / 编写搜索匹配的属性测试
        -   **Property 21: Search Matches Title and Fields** / **属性 21：搜索匹配标题和字段**
        -   **Validates: Requirements 7.1** / **验证：需求 7.1**

-   [ ] 7. Implement Card Templates / 实现卡片模板

    -   [ ] 7.1 Create template definitions for Address, Invoice, General Text / 创建地址、发票、通用文本的模板定义

        -   Define field structures for each template / 为每个模板定义字段结构
        -   Implement format functions for copy operations / 实现复制操作的格式化函数
        -   _Requirements: 2.1, 3.1, 4.1_

    -   [ ]\* 7.2 Write property test for address format / 编写地址格式的属性测试

        -   **Property 7: Address Format Contains Labels** / **属性 7：地址格式包含标签**
        -   **Validates: Requirements 2.3** / **验证：需求 2.3**

    -   [ ]\* 7.3 Write property test for invoice format / 编写发票格式的属性测试

        -   **Property 10: Invoice Format Contains Labels** / **属性 10：发票格式包含标签**
        -   **Validates: Requirements 3.3** / **验证：需求 3.3**

    -   [ ]\* 7.4 Write property test for general text copy / 编写通用文本复制的属性测试
        -   **Property 13: General Text Copy Direct** / **属性 13：通用文本直接复制**
        -   **Validates: Requirements 4.3** / **验证：需求 4.3**

-   [ ] 8. Implement Data Validation / 实现数据验证

    -   [ ] 8.1 Create validation functions / 创建验证函数

        -   Implement phone number validation (Chinese mobile/landline) / 实现电话号码验证
        -   Implement tax ID validation (18-char unified social credit code) / 实现税号验证
        -   Implement required field validation / 实现必填字段验证
        -   Implement password length validation / 实现密码长度验证
        -   _Requirements: 2.4, 3.4, 21.1, 21.2, 21.3, 11.2_

    -   [ ]\* 8.2 Write property test for phone number validation / 编写电话号码验证的属性测试

        -   **Property 8: Phone Number Validation** / **属性 8：电话号码验证**
        -   **Validates: Requirements 2.4** / **验证：需求 2.4**

    -   [ ]\* 8.3 Write property test for tax ID validation / 编写税号验证的属性测试

        -   **Property 11: Tax ID Validation** / **属性 11：税号验证**
        -   **Validates: Requirements 3.4** / **验证：需求 3.4**

    -   [ ]\* 8.4 Write property test for required field validation / 编写必填字段验证的属性测试

        -   **Property 39: Required Field Validation** / **属性 39：必填字段验证**
        -   **Validates: Requirements 21.1** / **验证：需求 21.1**

    -   [ ]\* 8.5 Write property test for password minimum length / 编写密码最小长度的属性测试
        -   **Property 28: Password Minimum Length** / **属性 28：密码最小长度**
        -   **Validates: Requirements 11.2** / **验证：需求 11.2**

-   [ ] 9. Implement Watermark Service (iOS-Specific) / 实现水印服务（iOS 特定）

    -   [ ] 9.1 Create WatermarkService protocol and implementation / 创建 WatermarkService 协议和实现

        -   Implement watermark application using Core Graphics / 使用 Core Graphics 实现水印应用
        -   Support custom watermark text / 支持自定义水印文字
        -   Implement diagonal semi-transparent overlay / 实现对角线半透明覆盖
        -   Implement watermark removal / 实现水印移除
        -   Implement watermark update / 实现水印更新
        -   _Requirements: 6.1, 6.2, 6.3, 6.7_

    -   [ ]\* 9.2 Write property test for watermark quality preservation / 编写水印质量保持的属性测试

        -   **Property 17: Watermark Application Preserves Quality** / **属性 17：水印应用保持质量**
        -   **Validates: Requirements 6.6** / **验证：需求 6.6**

    -   [ ]\* 9.3 Write property test for watermark visibility / 编写水印可见性的属性测试

        -   **Property 18: Watermark Visibility** / **属性 18：水印可见性**
        -   **Validates: Requirements 6.5** / **验证：需求 6.5**

    -   [ ]\* 9.4 Write property test for watermark edit consistency / 编写水印编辑一致性的属性测试
        -   **Property 20: Watermark Edit Consistency** / **属性 20：水印编辑一致性**
        -   **Validates: Requirements 6.7** / **验证：需求 6.7**

-   [ ] 10. Implement Attachment Service / 实现附件服务

    -   [ ] 10.1 Create AttachmentService protocol and implementation / 创建 AttachmentService 协议和实现

        -   Implement addAttachment with encryption and size validation / 实现带加密和大小验证的 addAttachment
        -   Implement deleteAttachment / 实现 deleteAttachment
        -   Implement fetchAttachments / 实现 fetchAttachments
        -   Implement thumbnail generation for images / 实现图片缩略图生成
        -   Integrate with WatermarkService / 与 WatermarkService 集成
        -   _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

    -   [ ]\* 10.2 Write property test for attachment file size limit / 编写附件文件大小限制的属性测试

        -   **Property 15: Attachment File Size Limit** / **属性 15：附件文件大小限制**
        -   **Validates: Requirements 5.3** / **验证：需求 5.3**

    -   [ ]\* 10.3 Write property test for attachment deletion with card / 编写附件随卡片删除的属性测试
        -   **Property 16: Attachment Deletion with Card** / **属性 16：附件随卡片删除**
        -   **Validates: Requirements 5.6** / **验证：需求 5.6**

-   [ ] 11. Checkpoint - Data Layer Complete / 检查点 - 数据层完成

    -   Ensure all tests pass, ask the user if questions arise. / 确保所有测试通过，如有问题请询问用户。

-   [ ] 12. Implement View Models / 实现视图模型

    -   [ ] 12.1 Create CardListViewModel / 创建 CardListViewModel

        -   Implement card loading and filtering / 实现卡片加载和过滤
        -   Implement search functionality / 实现搜索功能
        -   Implement group filtering / 实现分组过滤
        -   Implement delete and pin operations / 实现删除和置顶操作
        -   _Requirements: 7.1, 7.2, 7.3, 15.2_

    -   [ ]\* 12.2 Write property test for group filtering / 编写分组过滤的属性测试

        -   **Property 22: Group Filter Completeness** / **属性 22：分组过滤完整性**
        -   **Validates: Requirements 7.3** / **验证：需求 7.3**

    -   [ ] 12.3 Create CardDetailViewModel / 创建 CardDetailViewModel

        -   Implement card editing / 实现卡片编辑
        -   Implement copy operations (card and field) / 实现复制操作
        -   Implement attachment management / 实现附件管理
        -   Implement watermark operations / 实现水印操作
        -   _Requirements: 18.1, 18.2, 5.4, 6.1_

    -   [ ]\* 12.4 Write property test for copy operations / 编写复制操作的属性测试

        -   **Property 36: Copy Entire Card Format** / **属性 36：复制整卡格式**
        -   **Property 37: Copy Individual Field** / **属性 37：复制单个字段**
        -   **Validates: Requirements 18.1, 18.2** / **验证：需求 18.1, 18.2**

    -   [ ] 12.5 Create AuthViewModel / 创建 AuthViewModel

        -   Implement authentication flow / 实现认证流程
        -   Implement lock/unlock actions / 实现锁定/解锁操作
        -   Implement setup flow / 实现设置流程
        -   _Requirements: 9.1, 9.4, 22.1, 22.2_

    -   [ ] 12.6 Create SettingsViewModel / 创建 SettingsViewModel
        -   Implement settings persistence / 实现设置持久化
        -   Implement password change / 实现密码更改
        -   Implement biometric toggle / 实现生物识别切换
        -   _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

-   [ ] 13. Implement Authentication Views / 实现认证视图

    -   [ ] 13.1 Create WelcomeView / 创建欢迎视图

        -   Display welcome message / 显示欢迎消息
        -   Guide user to create master password / 引导用户创建主密码
        -   Prompt for biometric enablement / 提示启用生物识别
        -   _Requirements: 22.1, 22.2, 22.3_

    -   [ ] 13.2 Create LockScreenView / 创建锁屏视图

        -   Display authentication prompt / 显示认证提示
        -   Support biometric and password authentication / 支持生物识别和密码认证
        -   Display error messages / 显示错误消息
        -   _Requirements: 9.1, 9.2, 9.3_

    -   [ ]\* 13.3 Write unit tests for authentication views / 编写认证视图的单元测试
        -   Test welcome flow / 测试欢迎流程
        -   Test lock screen authentication / 测试锁屏认证
        -   _Requirements: 22.1, 9.1_

-   [ ] 14. Implement Card List View / 实现卡片列表视图

    -   [ ] 14.1 Create CardListView / 创建 CardListView

        -   Display cards in list with thumbnails / 在列表中显示带缩略图的卡片
        -   Implement search bar / 实现搜索栏
        -   Implement group filter / 实现分组过滤
        -   Implement swipe actions (delete, pin) / 实现滑动操作（删除、置顶）
        -   Implement pull-to-refresh / 实现下拉刷新
        -   _Requirements: 8.1, 8.2, 7.1, 7.3_

    -   [ ] 14.2 Create CardRowView / 创建 CardRowView

        -   Display card title and preview / 显示卡片标题和预览
        -   Display pin indicator / 显示置顶指示器
        -   Display attachment count / 显示附件数量
        -   _Requirements: 1.4, 1.6_

    -   [ ]\* 14.3 Write unit tests for card list view / 编写卡片列表视图的单元测试
        -   Test card display / 测试卡片显示
        -   Test search functionality / 测试搜索功能
        -   _Requirements: 8.1, 7.1_

-   [ ] 15. Implement Card Detail View / 实现卡片详情视图

    -   [ ] 15.1 Create CardDetailView / 创建 CardDetailView

        -   Display card fields / 显示卡片字段
        -   Display attachments with thumbnails / 显示带缩略图的附件
        -   Implement edit mode / 实现编辑模式
        -   Implement copy buttons / 实现复制按钮
        -   _Requirements: 8.3, 5.5, 18.1, 18.2_

    -   [ ] 15.2 Create CardEditorView / 创建 CardEditorView

        -   Implement field editing / 实现字段编辑
        -   Implement template selection / 实现模板选择
        -   Implement validation / 实现验证
        -   Implement save/cancel actions / 实现保存/取消操作
        -   _Requirements: 1.1, 1.2, 21.1_

    -   [ ] 15.3 Create AttachmentView / 创建 AttachmentView

        -   Display image attachments / 显示图片附件
        -   Display PDF attachments / 显示 PDF 附件
        -   Implement watermark controls / 实现水印控制
        -   Implement share button / 实现分享按钮
        -   _Requirements: 5.4, 5.5, 6.1, 23.1_

    -   [ ]\* 15.4 Write unit tests for card detail view / 编写卡片详情视图的单元测试
        -   Test field display / 测试字段显示
        -   Test edit mode / 测试编辑模式
        -   _Requirements: 8.3, 1.2_

-   [ ] 16. Implement Settings View / 实现设置视图

    -   [ ] 16.1 Create SettingsView / 创建 SettingsView

        -   Create auto-lock timeout setting / 创建自动锁定超时设置
        -   Create biometric toggle / 创建生物识别切换
        -   Create password change form / 创建密码更改表单
        -   Display app version / 显示应用版本
        -   _Requirements: 13.1, 13.2, 13.3, 13.4_

    -   [ ]\* 16.2 Write unit tests for settings view / 编写设置视图的单元测试
        -   Test settings persistence / 测试设置持久化
        -   Test password change flow / 测试密码更改流程
        -   _Requirements: 13.2, 13.4_

-   [ ] 17. Implement Tab Bar Navigation / 实现标签栏导航

    -   [ ] 17.1 Create MainTabView / 创建 MainTabView

        -   Set up tab bar with Cards, Search, Settings tabs / 设置带卡片、搜索、设置的标签栏
        -   Implement tab navigation / 实现标签导航
        -   Apply consistent styling / 应用一致的样式
        -   _Requirements: 8.1_

    -   [ ] 17.2 Create SearchView / 创建 SearchView
        -   Implement search interface / 实现搜索界面
        -   Display search results / 显示搜索结果
        -   Implement tag filtering / 实现标签过滤
        -   _Requirements: 7.1, 15.4_

-   [ ] 18. Implement Toast Notifications / 实现提示通知

    -   [ ] 18.1 Create ToastView / 创建 ToastView

        -   Display toast with message / 显示带消息的提示
        -   Auto-dismiss after 2 seconds / 2 秒后自动关闭
        -   Support success and error styles / 支持成功和错误样式
        -   _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5_

    -   [ ]\* 18.2 Write unit tests for toast notifications / 编写提示通知的单元测试
        -   Test toast display / 测试提示显示
        -   Test auto-dismiss / 测试自动关闭
        -   _Requirements: 19.1, 19.5_

-   [ ] 19. Implement Auto-Lock Manager / 实现自动锁定管理器

    -   [ ] 19.1 Create AutoLockManager / 创建 AutoLockManager

        -   Implement inactivity timer / 实现不活动计时器
        -   Implement background observer / 实现后台观察器
        -   Implement device lock observer / 实现设备锁定观察器
        -   Trigger lock on timeout or system events / 在超时或系统事件时触发锁定
        -   _Requirements: 12.1, 12.2, 12.3_

    -   [ ]\* 19.2 Write unit tests for auto-lock triggers / 编写自动锁定触发的单元测试

        -   Test inactivity timeout / 测试不活动超时
        -   Test background lock / 测试后台锁定
        -   _Requirements: 12.1, 12.2_

    -   [ ]\* 19.3 Write property test for app switcher content hiding / 编写应用切换器内容隐藏的属性测试
        -   **Property 32: App Switcher Content Hiding** / **属性 32：应用切换器内容隐藏**
        -   **Validates: Requirements 12.4** / **验证：需求 12.4**

-   [ ] 20. Checkpoint - UI Complete / 检查点 - UI 完成

    -   Ensure all tests pass, ask the user if questions arise. / 确保所有测试通过，如有问题请询问用户。

-   [ ] 21. Implement Share Functionality / 实现分享功能

    -   [ ] 21.1 Implement share sheet integration / 实现分享表集成

        -   Share attachments via iOS share sheet / 通过 iOS 分享表分享附件
        -   Share card data as text / 将卡片数据作为文本分享
        -   Support AirDrop / 支持 AirDrop
        -   _Requirements: 23.1, 23.2, 23.3, 23.4_

    -   [ ]\* 21.2 Write property test for watermark persistence in shares / 编写分享中水印持久性的属性测试
        -   **Property 19: Watermark Persistence in Shares** / **属性 19：分享中水印持久性**
        -   **Validates: Requirements 6.4** / **验证：需求 6.4**

-   [ ] 22. Implement Card Sorting / 实现卡片排序

    -   [ ] 22.1 Implement card sorting logic / 实现卡片排序逻辑

        -   Sort pinned cards before unpinned / 置顶卡片排在未置顶卡片之前
        -   Sort by modification timestamp within each group / 在每个分组内按修改时间戳排序
        -   _Requirements: 16.1, 16.2, 16.3_

    -   [ ]\* 22.2 Write property test for pinned cards sort order / 编写置顶卡片排序顺序的属性测试

        -   **Property 33: Pinned Cards Sort Order** / **属性 33：置顶卡片排序顺序**
        -   **Validates: Requirements 16.1** / **验证：需求 16.1**

    -   [ ]\* 22.3 Write property test for pinned cards internal sort / 编写置顶卡片内部排序的属性测试

        -   **Property 34: Pinned Cards Internal Sort** / **属性 34：置顶卡片内部排序**
        -   **Validates: Requirements 16.4** / **验证：需求 16.4**

    -   [ ]\* 22.4 Write property test for unpinned cards internal sort / 编写未置顶卡片内部排序的属性测试
        -   **Property 35: Unpinned Cards Internal Sort** / **属性 35：未置顶卡片内部排序**
        -   **Validates: Requirements 16.5** / **验证：需求 16.5**

-   [ ] 23. Implement Tags and Search / 实现标签和搜索

    -   [ ] 23.1 Add tag support to cards / 为卡片添加标签支持

        -   Store tags as JSON array / 将标签存储为 JSON 数组
        -   Allow adding/removing tags / 允许添加/删除标签
        -   _Requirements: 1.7, 15.3_

    -   [ ] 23.2 Update search to include tags / 更新搜索以包含标签

        -   Match search query against tag names / 将搜索查询与标签名称匹配
        -   _Requirements: 15.4_

    -   [ ]\* 23.3 Write property test for tag storage / 编写标签存储的属性测试
        -   **Property 5: Tag Storage and Retrieval** / **属性 5：标签存储和检索**
        -   **Validates: Requirements 1.7** / **验证：需求 1.7**

-   [ ] 24. Implement Optional Field Support / 实现可选字段支持

    -   [ ] 24.1 Update templates to mark optional fields / 更新模板以标记可选字段

        -   Mark postal code and notes as optional in Address template / 在地址模板中将邮编和备注标记为可选
        -   Mark notes as optional in Invoice template / 在发票模板中将备注标记为可选
        -   _Requirements: 2.2, 3.2_

    -   [ ]\* 24.2 Write property test for optional fields in address / 编写地址中可选字段的属性测试

        -   **Property 6: Optional Fields in Address Template** / **属性 6：地址模板中的可选字段**
        -   **Validates: Requirements 2.2** / **验证：需求 2.2**

    -   [ ]\* 24.3 Write property test for optional notes in invoice / 编写发票中可选备注的属性测试
        -   **Property 9: Optional Notes in Invoice Template** / **属性 9：发票模板中的可选备注**
        -   **Validates: Requirements 3.2** / **验证：需求 3.2**

-   [ ] 25. Implement Multi-line Text Support / 实现多行文本支持

    -   [ ] 25.1 Ensure text fields support newlines / 确保文本字段支持换行符

        -   Use TextEditor for multi-line content / 使用 TextEditor 处理多行内容
        -   _Requirements: 4.2_

    -   [ ]\* 25.2 Write property test for multi-line text / 编写多行文本的属性测试
        -   **Property 12: Multi-line Text Support** / **属性 12：多行文本支持**
        -   **Validates: Requirements 4.2** / **验证：需求 4.2**

-   [ ] 26. Implement Locked State Copy Prevention / 实现锁定状态复制阻止

    -   [ ] 26.1 Add lock state checks to copy operations / 为复制操作添加锁定状态检查

        -   Prevent copy when locked / 锁定时阻止复制
        -   Display error message / 显示错误消息
        -   _Requirements: 18.4_

    -   [ ]\* 26.2 Write property test for locked state prevents copy / 编写锁定状态阻止复制的属性测试
        -   **Property 38: Locked State Prevents Copy** / **属性 38：锁定状态阻止复制**
        -   **Validates: Requirements 18.4** / **验证：需求 18.4**

-   [ ] 27. Implement Accessibility Support / 实现无障碍支持

    -   [ ] 27.1 Add VoiceOver support / 添加 VoiceOver 支持

        -   Add accessibility labels to all interactive elements / 为所有交互元素添加无障碍标签
        -   Add accessibility hints / 添加无障碍提示
        -   Announce state changes / 宣布状态变化
        -   _Requirements: 20.1, 20.3, 20.4_

    -   [ ] 27.2 Add Dynamic Type support / 添加动态字体支持
        -   Use scalable fonts / 使用可缩放字体
        -   Test with different text sizes / 使用不同文本大小测试
        -   _Requirements: 20.2_

-   [ ] 28. Implement Error Handling / 实现错误处理

    -   [ ] 28.1 Add error handling throughout application / 在整个应用程序中添加错误处理

        -   Display user-friendly error messages / 显示用户友好的错误消息
        -   Log errors for debugging / 记录错误以便调试
        -   Handle database, crypto, and authentication errors / 处理数据库、加密和认证错误
        -   _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5_

    -   [ ]\* 28.2 Write unit tests for error scenarios / 编写错误场景的单元测试
        -   Test database operation failures / 测试数据库操作失败
        -   Test encryption failures / 测试加密失败
        -   Test authentication failures / 测试认证失败
        -   _Requirements: 17.1, 17.2, 17.3_

-   [ ] 29. Final Checkpoint - All Tests Pass / 最终检查点 - 所有测试通过

    -   Run all unit tests and property tests / 运行所有单元测试和属性测试
    -   Verify all 39 correctness properties pass / 验证所有 39 个正确性属性通过
    -   Ensure all requirements are covered / 确保所有需求都已覆盖
    -   Ask the user if questions arise. / 如有问题请询问用户。

-   [ ] 30. Polish and Final Integration / 完善和最终集成

    -   [ ] 30.1 Add app icon and assets / 添加应用图标和资源

        -   Create app icon in all required sizes / 创建所有所需大小的应用图标
        -   Add SF Symbols for UI elements / 为 UI 元素添加 SF Symbols
        -   Support light and dark mode / 支持浅色和深色模式
        -   _Requirements: 8.1_

    -   [ ] 30.2 Test end-to-end workflows / 测试端到端工作流程

        -   Test first-run setup / 测试首次运行设置
        -   Test creating and using cards / 测试创建和使用卡片
        -   Test attachments and watermark workflow / 测试附件和水印工作流程
        -   Test locking and unlocking / 测试锁定和解锁
        -   Test search and filter / 测试搜索和过滤
        -   Test sharing / 测试分享

    -   [ ] 30.3 Performance optimization / 性能优化

        -   Optimize search performance / 优化搜索性能
        -   Optimize encryption/decryption / 优化加密/解密
        -   Optimize image loading and thumbnails / 优化图片加载和缩略图
        -   Ensure smooth scrolling / 确保流畅滚动

    -   [ ] 30.4 Final code review and cleanup / 最终代码审查和清理
        -   Remove debug code / 删除调试代码
        -   Add code documentation / 添加代码文档
        -   Ensure consistent code style / 确保一致的代码风格
        -   Verify bilingual strings / 验证双语字符串

-   [ ] 31. Prepare for macOS Migration / 准备 macOS 迁移

    -   [ ] 31.1 Extract shared code to Swift package / 将共享代码提取到 Swift 包

        -   Create QuickVaultCore package / 创建 QuickVaultCore 包
        -   Move CryptoService, KeychainService, AuthenticationService / 移动核心服务
        -   Move CardService and data models / 移动卡片服务和数据模型
        -   Update iOS app to use package / 更新 iOS 应用使用包
        -   _Requirements: All core services_

    -   [ ] 31.2 Document platform differences / 记录平台差异

        -   Document iOS-specific features (WatermarkService, Share Sheet) / 记录 iOS 特定功能
        -   Document macOS-specific features needed (Menu Bar, NSWindow) / 记录所需的 macOS 特定功能
        -   Create migration guide / 创建迁移指南

    -   [ ] 31.3 Test shared code on both platforms / 在两个平台上测试共享代码
        -   Run core service tests on iOS / 在 iOS 上运行核心服务测试
        -   Prepare for macOS test environment / 准备 macOS 测试环境

## Notes / 注意事项

-   Tasks marked with `*` are optional and can be skipped for faster MVP / 标记为 `*` 的任务是可选的，可以跳过以更快完成 MVP
-   Each task references specific requirements for traceability / 每个任务引用特定需求以便追溯
-   Checkpoints ensure incremental validation / 检查点确保增量验证
-   Property tests validate universal correctness properties / 属性测试验证通用正确性属性
-   Unit tests validate specific examples and edge cases / 单元测试验证特定示例和边缘情况
-   All property tests should run with minimum 100 iterations / 所有属性测试应至少运行 100 次迭代
-   Watermark feature is iOS-specific and critical for document protection / 水印功能是 iOS 特定的，对文档保护至关重要
-   Core services will be shared with macOS version after iOS completion / 核心服务将在 iOS 完成后与 macOS 版本共享
