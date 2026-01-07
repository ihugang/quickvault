# Implementation Plan: QuickVault macOS / 实施计划：随取 macOS

## Overview / 概述

This implementation plan breaks down the QuickVault macOS application into discrete, incremental tasks. Each task builds on previous work and includes testing to validate correctness early. The plan follows a bottom-up approach: core services → data layer → business logic → UI → integration.

本实施计划将随取 macOS 应用程序分解为离散的增量任务。每个任务都建立在之前的工作基础上，并包含测试以尽早验证正确性。该计划遵循自下而上的方法：核心服务 → 数据层 → 业务逻辑 → UI → 集成。

## Tasks / 任务

-   [x] 1. Project Setup and Core Infrastructure / 项目设置和核心基础设施

    -   Create Xcode project with SwiftUI + CoreData template / 使用 SwiftUI + CoreData 模板创建 Xcode 项目
    -   Configure project for menu bar app (LSUIElement = true) / 配置项目为菜单栏应用（LSUIElement = true）
    -   Add SwiftCheck dependency for property-based testing / 添加 SwiftCheck 依赖用于基于属性的测试
    -   Set up CoreData model with Card, CardField, CardAttachment entities / 设置 CoreData 模型，包含 Card、CardField、CardAttachment 实体
    -   Configure app entitlements for Keychain access / 配置应用权限以访问钥匙串
    -   _Requirements: 12.1, 16.2_

-   [x] 2. Implement Keychain Service / 实现钥匙串服务

    -   [x] 2.1 Create KeychainService protocol and implementation / 创建 KeychainService 协议和实现

        -   Implement save, load, delete, exists methods / 实现 save、load、delete、exists 方法
        -   Handle Keychain errors gracefully / 优雅地处理钥匙串错误
        -   _Requirements: 10.2_

    -   [ ]\* 2.2 Write unit tests for Keychain operations / 编写钥匙串操作的单元测试
        -   Test saving and loading data / 测试保存和加载数据
        -   Test error handling / 测试错误处理
        -   _Requirements: 10.2_

-   [x] 3. Implement Crypto Service / 实现加密服务

    -   [x] 3.1 Create CryptoService protocol and implementation / 创建 CryptoService 协议和实现

        -   Implement AES-GCM encryption and decryption / 实现 AES-GCM 加密和解密
        -   Implement PBKDF2 key derivation (100,000 iterations) / 实现 PBKDF2 密钥派生（100,000 次迭代）
        -   Implement salt generation / 实现盐值生成
        -   Add file encryption methods for attachments / 添加附件的文件加密方法
        -   _Requirements: 10.1, 10.4, 10.5_

    -   [ ]\* 3.2 Write property test for encryption round trip / 编写加密往返的属性测试

        -   **Property 21: Field Encryption Round Trip** / **属性 21：字段加密往返**
        -   **Validates: Requirements 10.1, 10.5** / **验证：需求 10.1, 10.5**

    -   [ ]\* 3.3 Write property test for key derivation determinism / 编写密钥派生确定性的属性测试

        -   **Property 22: Key Derivation Determinism** / **属性 22：密钥派生确定性**
        -   **Validates: Requirements 10.4** / **验证：需求 10.4**

    -   [ ]\* 3.4 Write property test for attachment file encryption / 编写附件文件加密的属性测试
        -   **Property 41: Attachment File Encryption** / **属性 41：附件文件加密**
        -   **Validates: Requirements 5.2** / **验证：需求 5.2**

-   [x] 4. Implement Authentication Service / 实现认证服务

    -   [x] 4.1 Create AuthenticationService protocol and implementation / 创建 AuthenticationService 协议和实现

        -   Implement Touch ID authentication using LocalAuthentication / 使用 LocalAuthentication 实现触控 ID 认证
        -   Implement master password authentication / 实现主密码认证
        -   Implement password setup and change / 实现密码设置和更改
        -   Implement lock/unlock state management / 实现锁定/解锁状态管理
        -   Implement failed attempt tracking with 30-second delay / 实现失败尝试跟踪及 30 秒延迟
        -   _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7_

    -   [x]\* 4.2 Write property test for authentication state transition / 编写认证状态转换的属性测试

        -   **Property 23: Authentication State Transition** / **属性 23：认证状态转换**
        -   **Validates: Requirements 11.4** / **验证：需求 11.4**

    -   [x]\* 4.3 Write property test for password change / 编写密码更改的属性测试

        -   **Property 27: Password Change Authentication** / **属性 27：密码更改认证**
        -   **Validates: Requirements 13.4** / **验证：需求 13.4**

    -   [x]\* 4.4 Write unit tests for failed attempt rate limiting / 编写失败尝试速率限制的单元测试
        -   Test 3 failed attempts trigger delay / 测试 3 次失败尝试触发延迟
        -   _Requirements: 11.5_

-   [x] 5. Checkpoint - Core Services Complete / 检查点 - 核心服务完成

    -   Ensure all tests pass, ask the user if questions arise. / 确保所有测试通过，如有问题请询问用户。

-   [x] 6. Implement Card Service / 实现卡片服务

    -   [x] 6.1 Create CardService protocol and implementation / 创建 CardService 协议和实现

        -   Implement createCard with field encryption / 实现带字段加密的 createCard
        -   Implement updateCard with timestamp update / 实现带时间戳更新的 updateCard
        -   Implement deleteCard with cascade delete / 实现带级联删除的 deleteCard
        -   Implement fetchAllCards with decryption / 实现带解密的 fetchAllCards
        -   Implement searchCards with field matching / 实现带字段匹配的 searchCards
        -   Implement togglePin / 实现 togglePin
        -   _Requirements: 1.1, 1.2, 1.3, 1.6, 6.2_

    -   [x]\* 6.2 Write property test for card creation completeness / 编写卡片创建完整性的属性测试

        -   **Property 1: Card Creation Completeness** / **属性 1：卡片创建完整性**
        -   **Validates: Requirements 1.1, 1.5** / **验证：需求 1.1, 1.5**

    -   [x]\* 6.3 Write property test for card update timestamp / 编写卡片更新时间戳的属性测试

        -   **Property 2: Card Update Timestamp** / **属性 2：卡片更新时间戳**
        -   **Validates: Requirements 1.2** / **验证：需求 1.2**

    -   [x]\* 6.4 Write property test for card deletion completeness / 编写卡片删除完整性的属性测试

        -   **Property 3: Card Deletion Completeness** / **属性 3：卡片删除完整性**
        -   **Validates: Requirements 1.3** / **验证：需求 1.3**

    -   [x]\* 6.5 Write property test for pin toggle consistency / 编写置顶切换一致性的属性测试

        -   **Property 4: Pin Toggle Consistency** / **属性 4：置顶切换一致性**
        -   **Validates: Requirements 1.6** / **验证：需求 1.6**

    -   [x]\* 6.6 Write property test for search matches / 编写搜索匹配的属性测试
        -   **Property 14: Search Matches Title and Fields** / **属性 14：搜索匹配标题和字段**
        -   **Validates: Requirements 6.2** / **验证：需求 6.2**

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

        -   Implement phone number validation (Chinese mobile/landline) / 实现电话号码验证（中国手机/座机）
        -   Implement tax ID validation (18-char unified social credit code) / 实现税号验证（18 位统一社会信用代码）
        -   Implement required field validation / 实现必填字段验证
        -   Implement password length validation / 实现密码长度验证
        -   _Requirements: 2.4, 3.4, 21.1, 21.2, 21.3, 22.3_

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
        -   **Property 40: Password Minimum Length** / **属性 40：密码最小长度**
        -   **Validates: Requirements 22.3** / **验证：需求 22.3**

-   [ ] 9. Implement Attachment Service / 实现附件服务

    -   [ ] 9.1 Create AttachmentService protocol and implementation / 创建 AttachmentService 协议和实现

        -   Implement addAttachment with encryption and size validation / 实现带加密和大小验证的 addAttachment
        -   Implement deleteAttachment / 实现 deleteAttachment
        -   Implement copyAttachmentToDesktop with duplicate handling / 实现带重复处理的 copyAttachmentToDesktop
        -   Implement thumbnail generation for images / 实现图片缩略图生成
        -   _Requirements: 5.1, 5.2, 5.3, 5.4, 5.6_

    -   [ ]\* 9.2 Write property test for attachment file size limit / 编写附件文件大小限制的属性测试

        -   **Property 42: Attachment File Size Limit** / **属性 42：附件文件大小限制**
        -   **Validates: Requirements 5.3** / **验证：需求 5.3**

    -   [ ]\* 9.3 Write property test for attachment copy round trip / 编写附件复制往返的属性测试

        -   **Property 43: Attachment Copy to Desktop Round Trip** / **属性 43：附件复制到桌面往返**
        -   **Validates: Requirements 5.4** / **验证：需求 5.4**

    -   [ ]\* 9.4 Write property test for attachment deletion / 编写附件删除的属性测试
        -   **Property 44: Attachment Deletion Completeness** / **属性 44：附件删除完整性**
        -   **Validates: Requirements 5.6** / **验证：需求 5.6**

-   [ ] 10. Checkpoint - Data Layer Complete / 检查点 - 数据层完成

    -   Ensure all tests pass, ask the user if questions arise. / 确保所有测试通过，如有问题请询问用户。

-   [ ] 11. Implement View Models / 实现视图模型

    -   [ ] 11.1 Create CardViewModel / 创建 CardViewModel

        -   Implement card loading and filtering / 实现卡片加载和过滤
        -   Implement search functionality / 实现搜索功能
        -   Implement group filtering / 实现分组过滤
        -   Implement copy operations (card and field) / 实现复制操作（卡片和字段）
        -   _Requirements: 6.1, 6.2, 7.1, 7.2, 15.2_

    -   [ ]\* 11.2 Write property test for group filtering / 编写分组过滤的属性测试

        -   **Property 31: Group Filtering** / **属性 31：分组过滤**
        -   **Validates: Requirements 15.2** / **验证：需求 15.2**

    -   [ ]\* 11.3 Write property test for copy operations / 编写复制操作的属性测试

        -   **Property 17: Copy Entire Card Format** / **属性 17：复制整卡格式**
        -   **Property 18: Copy Individual Field** / **属性 18：复制单个字段**
        -   **Validates: Requirements 7.1, 7.2, 7.4** / **验证：需求 7.1, 7.2, 7.4**

    -   [ ] 11.4 Create AuthViewModel / 创建 AuthViewModel

        -   Implement authentication flow / 实现认证流程
        -   Implement lock/unlock actions / 实现锁定/解锁操作
        -   _Requirements: 11.1, 11.7_

    -   [ ] 11.5 Create DashboardViewModel / 创建 DashboardViewModel

        -   Implement card selection and editing / 实现卡片选择和编辑
        -   Implement CRUD operations / 实现 CRUD 操作
        -   _Requirements: 9.2, 9.3_

    -   [ ] 11.6 Create SettingsViewModel / 创建 SettingsViewModel

        -   Implement settings persistence / 实现设置持久化
        -   _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

    -   [ ]\* 11.7 Write property test for settings persistence / 编写设置持久化的属性测试
        -   **Property 26: Settings Persistence** / **属性 26：设置持久化**
        -   **Validates: Requirements 13.2, 13.3, 13.5** / **验证：需求 13.2, 13.3, 13.5**

-   [ ] 12. Implement Menu Bar Manager / 实现菜单栏管理器

    -   [ ] 12.1 Create MenuBarManager / 创建 MenuBarManager

        -   Set up NSStatusItem in menu bar / 在菜单栏设置 NSStatusItem
        -   Implement icon updates for lock state / 实现锁定状态的图标更新
        -   Implement global keyboard shortcut / 实现全局键盘快捷键
        -   _Requirements: 8.1, 8.7, 8.8_

    -   [ ] 12.2 Implement hierarchical menu building / 实现层级菜单构建

        -   Build group submenus (Personal, Company) / 构建分组子菜单（个人、公司）
        -   Build card submenus with copy options / 构建带复制选项的卡片子菜单
        -   Add "Open Dashboard" menu item / 添加"打开仪表板"菜单项
        -   Add Settings, Lock, Quit menu items / 添加设置、锁定、退出菜单项
        -   _Requirements: 8.2, 8.3, 8.4, 8.5, 8.6_

    -   [ ] 12.3 Implement attachment menu items / 实现附件菜单项

        -   Display attachments in card submenus / 在卡片子菜单中显示附件
        -   Implement click action to copy to desktop / 实现点击操作复制到桌面
        -   _Requirements: 5.4, 5.7_

    -   [ ]\* 12.4 Write unit test for menu structure / 编写菜单结构的单元测试

        -   Test group submenus are created / 测试分组子菜单已创建
        -   Test card items appear in correct groups / 测试卡片项出现在正确的分组中
        -   _Requirements: 8.3, 8.4_

    -   [ ]\* 12.5 Write property test for lock state icon update / 编写锁定状态图标更新的属性测试
        -   **Property 20: Lock State Icon Update** / **属性 20：锁定状态图标更新**
        -   **Validates: Requirements 8.9** / **验证：需求 8.9**

-   [ ] 13. Implement Dashboard Window / 实现仪表板窗口

    -   [ ] 13.1 Create Dashboard SwiftUI views / 创建仪表板 SwiftUI 视图

        -   Create search bar view / 创建搜索栏视图
        -   Create card list view with group filter / 创建带分组过滤的卡片列表视图
        -   Create card editor view / 创建卡片编辑器视图
        -   Create attachment preview view / 创建附件预览视图
        -   _Requirements: 9.2, 9.3, 9.4, 9.5, 9.6, 5.5_

    -   [ ] 13.2 Implement DashboardWindowManager / 实现 DashboardWindowManager

        -   Create and manage NSWindow / 创建和管理 NSWindow
        -   Implement show/hide functionality / 实现显示/隐藏功能
        -   _Requirements: 9.1, 9.7_

    -   [ ]\* 13.3 Write unit tests for Dashboard UI / 编写仪表板 UI 的单元测试
        -   Test card editor saves changes / 测试卡片编辑器保存更改
        -   Test attachment preview displays / 测试附件预览显示
        -   _Requirements: 9.3, 5.5_

-   [ ] 14. Implement Auto-Lock Manager / 实现自动锁定管理器

    -   [ ] 14.1 Create AutoLockManager / 创建 AutoLockManager

        -   Implement idle timer with configurable timeout / 实现可配置超时的空闲计时器
        -   Implement system sleep observer / 实现系统休眠观察器
        -   Implement user switch observer / 实现用户切换观察器
        -   Trigger lock on timeout or system events / 在超时或系统事件时触发锁定
        -   _Requirements: 12.1, 12.2, 12.3, 12.4_

    -   [ ]\* 14.2 Write unit tests for auto-lock triggers / 编写自动锁定触发的单元测试

        -   Test idle timeout triggers lock / 测试空闲超时触发锁定
        -   Test system sleep triggers lock / 测试系统休眠触发锁定
        -   _Requirements: 12.1, 12.2_

    -   [ ]\* 14.3 Write property test for locked state hides content / 编写锁定状态隐藏内容的属性测试
        -   **Property 25: Locked State Hides Content** / **属性 25：锁定状态隐藏内容**
        -   **Validates: Requirements 12.5** / **验证：需求 12.5**

-   [ ] 15. Implement Initial Setup Flow / 实现初始设置流程

    -   [ ] 15.1 Create welcome screen / 创建欢迎屏幕

        -   Display welcome message / 显示欢迎消息
        -   Guide user to create master password / 引导用户创建主密码
        -   Prompt for Touch ID enablement / 提示启用触控 ID
        -   _Requirements: 22.1, 22.2, 22.4_

    -   [ ] 15.2 Create first-run detection / 创建首次运行检测

        -   Check if master password exists / 检查主密码是否存在
        -   Show welcome screen on first launch / 首次启动时显示欢迎屏幕
        -   _Requirements: 22.1, 22.5_

    -   [ ]\* 15.3 Write unit tests for setup flow / 编写设置流程的单元测试
        -   Test welcome screen appears on first launch / 测试首次启动时出现欢迎屏幕
        -   Test password creation / 测试密码创建
        -   _Requirements: 22.1, 22.2_

-   [ ] 16. Implement Settings Window / 实现设置窗口

    -   [ ] 16.1 Create Settings SwiftUI views / 创建设置 SwiftUI 视图

        -   Create auto-lock timeout setting / 创建自动锁定超时设置
        -   Create keyboard shortcut setting / 创建键盘快捷键设置
        -   Create Touch ID toggle / 创建触控 ID 切换
        -   Create password change form / 创建密码更改表单
        -   Create launch at login toggle / 创建登录时启动切换
        -   _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

    -   [ ]\* 16.2 Write unit tests for settings UI / 编写设置 UI 的单元测试
        -   Test settings are saved / 测试设置已保存
        -   Test password change flow / 测试密码更改流程
        -   _Requirements: 13.2, 13.4_

-   [ ] 17. Implement Toast Notifications / 实现提示通知

    -   [ ] 17.1 Create toast notification view / 创建提示通知视图

        -   Display toast with message / 显示带消息的提示
        -   Auto-dismiss after timeout / 超时后自动关闭
        -   _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5_

    -   [ ]\* 17.2 Write unit tests for toast notifications / 编写提示通知的单元测试
        -   Test toast appears on copy / 测试复制时出现提示
        -   Test toast auto-dismisses / 测试提示自动关闭
        -   _Requirements: 19.1, 19.5_

-   [ ] 18. Implement Keyboard Navigation / 实现键盘导航

    -   [ ] 18.1 Add keyboard shortcuts to Dashboard / 为仪表板添加键盘快捷键

        -   Tab key for focus navigation / Tab 键用于焦点导航
        -   Arrow keys for list navigation / 箭头键用于列表导航
        -   Enter key for copy action / Enter 键用于复制操作
        -   Escape key to close / Escape 键关闭
        -   _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5_

    -   [ ]\* 18.2 Write property test for keyboard navigation / 编写键盘导航的属性测试
        -   **Property 15: Keyboard Navigation Selection** / **属性 15：键盘导航选择**
        -   **Property 16: Enter Key Copies Selected Card** / **属性 16：Enter 键复制选中卡片**
        -   **Validates: Requirements 6.3, 6.4** / **验证：需求 6.3, 6.4**

-   [ ] 19. Checkpoint - UI Complete / 检查点 - UI 完成

    -   Ensure all tests pass, ask the user if questions arise. / 确保所有测试通过，如有问题请询问用户。

-   [ ] 20. Integration and Data Persistence / 集成和数据持久化

    -   [ ] 20.1 Wire all components together / 将所有组件连接在一起

        -   Connect MenuBarManager to CardViewModel / 将 MenuBarManager 连接到 CardViewModel
        -   Connect DashboardWindow to DashboardViewModel / 将 DashboardWindow 连接到 DashboardViewModel
        -   Connect AutoLockManager to AuthService / 将 AutoLockManager 连接到 AuthService
        -   Ensure all services use shared CoreData context / 确保所有服务使用共享的 CoreData 上下文
        -   _Requirements: 1.1, 1.2, 1.3_

    -   [ ]\* 20.2 Write property test for data persistence round trip / 编写数据持久化往返的属性测试

        -   **Property 28: Data Persistence Round Trip** / **属性 28：数据持久化往返**
        -   **Validates: Requirements 14.2, 14.3** / **验证：需求 14.2, 14.3**

    -   [ ]\* 20.3 Write property test for referential integrity / 编写引用完整性的属性测试

        -   **Property 29: Referential Integrity** / **属性 29：引用完整性**
        -   **Validates: Requirements 14.4** / **验证：需求 14.4**

    -   [ ]\* 20.4 Write property test for timestamp storage / 编写时间戳存储的属性测试
        -   **Property 30: Timestamp Storage** / **属性 30：时间戳存储**
        -   **Validates: Requirements 14.5** / **验证：需求 14.5**

-   [ ] 21. Implement Application Lifecycle / 实现应用程序生命周期

    -   [ ] 21.1 Implement launch at login / 实现登录时启动

        -   Use SMLoginItemSetEnabled API / 使用 SMLoginItemSetEnabled API
        -   _Requirements: 18.1_

    -   [ ] 21.2 Implement quit behavior / 实现退出行为

        -   Lock system before quitting / 退出前锁定系统
        -   Save all pending changes / 保存所有待处理的更改
        -   _Requirements: 18.3, 18.4_

    -   [ ]\* 21.3 Write property test for quit locks system / 编写退出锁定系统的属性测试

        -   **Property 37: Quit Locks System** / **属性 37：退出锁定系统**
        -   **Validates: Requirements 18.3** / **验证：需求 18.3**

    -   [ ]\* 21.4 Write property test for quit saves changes / 编写退出保存更改的属性测试
        -   **Property 38: Quit Saves Changes** / **属性 38：退出保存更改**
        -   **Validates: Requirements 18.4** / **验证：需求 18.4**

-   [ ] 22. Implement Error Handling / 实现错误处理

    -   [ ] 22.1 Add error handling throughout application / 在整个应用程序中添加错误处理

        -   Display user-friendly error messages / 显示用户友好的错误消息
        -   Log errors for debugging / 记录错误以便调试
        -   Handle database, crypto, and authentication errors / 处理数据库、加密和认证错误
        -   _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5_

    -   [ ]\* 22.2 Write unit tests for error scenarios / 编写错误场景的单元测试
        -   Test database operation failures / 测试数据库操作失败
        -   Test encryption failures / 测试加密失败
        -   Test authentication failures / 测试认证失败
        -   _Requirements: 17.1, 17.2, 17.3_

-   [ ] 23. Implement Pinned Cards and Sorting / 实现置顶卡片和排序

    -   [ ] 23.1 Implement card sorting logic / 实现卡片排序逻辑

        -   Sort pinned cards before unpinned / 置顶卡片排在未置顶卡片之前
        -   Sort by modification timestamp within each group / 在每个分组内按修改时间戳排序
        -   _Requirements: 16.2, 16.4, 16.5_

    -   [ ]\* 23.2 Write property test for pinned cards sort order / 编写置顶卡片排序顺序的属性测试

        -   **Property 34: Pinned Cards Sort Order** / **属性 34：置顶卡片排序顺序**
        -   **Validates: Requirements 16.2** / **验证：需求 16.2**

    -   [ ]\* 23.3 Write property test for pinned cards internal sort / 编写置顶卡片内部排序的属性测试

        -   **Property 35: Pinned Cards Internal Sort** / **属性 35：置顶卡片内部排序**
        -   **Validates: Requirements 16.4** / **验证：需求 16.4**

    -   [ ]\* 23.4 Write property test for unpinned cards internal sort / 编写未置顶卡片内部排序的属性测试
        -   **Property 36: Unpinned Cards Internal Sort** / **属性 36：未置顶卡片内部排序**
        -   **Validates: Requirements 16.5** / **验证：需求 16.5**

-   [ ] 24. Implement Tags and Search / 实现标签和搜索

    -   [ ] 24.1 Add tag support to cards / 为卡片添加标签支持

        -   Store tags as JSON array / 将标签存储为 JSON 数组
        -   Allow adding/removing tags / 允许添加/删除标签
        -   _Requirements: 1.7, 15.3_

    -   [ ] 24.2 Update search to include tags / 更新搜索以包含标签

        -   Match search query against tag names / 将搜索查询与标签名称匹配
        -   _Requirements: 15.4_

    -   [ ]\* 24.3 Write property test for tag storage / 编写标签存储的属性测试

        -   **Property 5: Tag Storage and Retrieval** / **属性 5：标签存储和检索**
        -   **Validates: Requirements 1.7** / **验证：需求 1.7**

    -   [ ]\* 24.4 Write property test for multiple tags / 编写多标签的属性测试

        -   **Property 32: Multiple Tags Support** / **属性 32：多标签支持**
        -   **Validates: Requirements 15.3** / **验证：需求 15.3**

    -   [ ]\* 24.5 Write property test for search matches tags / 编写搜索匹配标签的属性测试
        -   **Property 33: Search Matches Tags** / **属性 33：搜索匹配标签**
        -   **Validates: Requirements 15.4** / **验证：需求 15.4**

-   [ ] 25. Implement Optional Field Support / 实现可选字段支持

    -   [ ] 25.1 Update templates to mark optional fields / 更新模板以标记可选字段

        -   Mark postal code and notes as optional in Address template / 在地址模板中将邮编和备注标记为可选
        -   Mark notes as optional in Invoice template / 在发票模板中将备注标记为可选
        -   _Requirements: 2.2, 3.2_

    -   [ ]\* 25.2 Write property test for optional fields in address / 编写地址中可选字段的属性测试

        -   **Property 6: Optional Fields in Address Template** / **属性 6：地址模板中的可选字段**
        -   **Validates: Requirements 2.2** / **验证：需求 2.2**

    -   [ ]\* 25.3 Write property test for optional notes in invoice / 编写发票中可选备注的属性测试
        -   **Property 9: Optional Notes in Invoice Template** / **属性 9：发票模板中的可选备注**
        -   **Validates: Requirements 3.2** / **验证：需求 3.2**

-   [ ] 26. Implement Multi-line Text Support / 实现多行文本支持

    -   [ ] 26.1 Ensure text fields support newlines / 确保文本字段支持换行符

        -   Use TextEditor for multi-line content / 使用 TextEditor 处理多行内容
        -   _Requirements: 4.2_

    -   [ ]\* 26.2 Write property test for multi-line text / 编写多行文本的属性测试
        -   **Property 12: Multi-line Text Support** / **属性 12：多行文本支持**
        -   **Validates: Requirements 4.2** / **验证：需求 4.2**

-   [ ] 27. Implement Locked State Copy Prevention / 实现锁定状态复制阻止

    -   [ ] 27.1 Add lock state checks to copy operations / 为复制操作添加锁定状态检查

        -   Prevent copy when locked / 锁定时阻止复制
        -   Display error message / 显示错误消息
        -   _Requirements: 7.5_

    -   [ ]\* 27.2 Write property test for locked state prevents copy / 编写锁定状态阻止复制的属性测试
        -   **Property 19: Locked State Prevents Copy** / **属性 19：锁定状态阻止复制**
        -   **Validates: Requirements 7.5** / **验证：需求 7.5**

-   [ ] 28. Implement Manual Lock / 实现手动锁定

    -   [ ] 28.1 Add manual lock button to menu and Dashboard / 为菜单和仪表板添加手动锁定按钮

        -   Trigger immediate lock / 触发立即锁定
        -   _Requirements: 11.6, 11.7_

    -   [ ]\* 28.2 Write property test for manual lock / 编写手动锁定的属性测试
        -   **Property 24: Manual Lock Immediate** / **属性 24：手动锁定立即生效**
        -   **Validates: Requirements 11.7** / **验证：需求 11.7**

-   [ ] 29. Final Checkpoint - All Tests Pass / 最终检查点 - 所有测试通过

    -   Run all unit tests and property tests / 运行所有单元测试和属性测试
    -   Verify all 44 correctness properties pass / 验证所有 44 个正确性属性通过
    -   Ensure all requirements are covered / 确保所有需求都已覆盖
    -   Ask the user if questions arise. / 如有问题请询问用户。

-   [ ] 30. Polish and Final Integration / 完善和最终集成

    -   [ ] 30.1 Add app icon and menu bar icons / 添加应用图标和菜单栏图标

        -   Create light and dark mode variants / 创建浅色和深色模式变体
        -   Create locked/unlocked icon variants / 创建锁定/解锁图标变体
        -   _Requirements: 8.8_

    -   [ ] 30.2 Test end-to-end workflows / 测试端到端工作流程

        -   Test first-run setup / 测试首次运行设置
        -   Test creating and using cards / 测试创建和使用卡片
        -   Test attachments workflow / 测试附件工作流程
        -   Test locking and unlocking / 测试锁定和解锁
        -   Test menu bar interactions / 测试菜单栏交互
        -   Test Dashboard operations / 测试仪表板操作

    -   [ ] 30.3 Performance optimization / 性能优化

        -   Optimize search performance / 优化搜索性能
        -   Optimize encryption/decryption / 优化加密/解密
        -   Ensure smooth UI animations / 确保流畅的 UI 动画

    -   [ ] 30.4 Final code review and cleanup / 最终代码审查和清理
        -   Remove debug code / 删除调试代码
        -   Add code documentation / 添加代码文档
        -   Ensure consistent code style / 确保一致的代码风格

## Notes / 注意事项

-   Tasks marked with `*` are optional and can be skipped for faster MVP / 标记为 `*` 的任务是可选的，可以跳过以更快完成 MVP
-   Each task references specific requirements for traceability / 每个任务引用特定需求以便追溯
-   Checkpoints ensure incremental validation / 检查点确保增量验证
-   Property tests validate universal correctness properties / 属性测试验证通用正确性属性
-   Unit tests validate specific examples and edge cases / 单元测试验证特定示例和边缘情况
-   All property tests should run with minimum 100 iterations / 所有属性测试应至少运行 100 次迭代

-   [ ] 31. Implement Automatic Updates / 实现自动更新

    -   [ ] 31.1 Integrate Sparkle framework / 集成 Sparkle 框架

        -   Add Sparkle via Swift Package Manager / 通过 Swift Package Manager 添加 Sparkle
        -   Configure Info.plist with feed URL and public key / 在 Info.plist 中配置 feed URL 和公钥
        -   Generate EdDSA key pair for signing / 生成用于签名的 EdDSA 密钥对
        -   _Requirements: 23.5_

    -   [ ] 31.2 Create UpdateManager / 创建 UpdateManager

        -   Initialize SPUStandardUpdaterController / 初始化 SPUStandardUpdaterController
        -   Implement checkForUpdates method / 实现 checkForUpdates 方法
        -   Implement checkForUpdatesInBackground method / 实现 checkForUpdatesInBackground 方法
        -   Implement installUpdate method / 实现 installUpdate 方法
        -   _Requirements: 23.1, 23.4, 23.7_

    -   [ ] 31.3 Add update notification UI / 添加更新通知 UI

        -   Display update available notification / 显示更新可用通知
        -   Show release notes / 显示发行说明
        -   Provide "Install Now" and "Later" options / 提供"立即安装"和"稍后"选项
        -   _Requirements: 23.2, 23.3_

    -   [ ] 31.4 Add update settings to Settings window / 将更新设置添加到设置窗口

        -   Add toggle for automatic update checking / 添加自动更新检查的切换
        -   Add "Check for Updates Now" button / 添加"立即检查更新"按钮
        -   _Requirements: 23.6_

    -   [ ] 31.5 Implement update on launch / 实现启动时更新

        -   Check for updates in background on app launch / 应用启动时在后台检查更新
        -   _Requirements: 23.1_

    -   [ ]\* 31.6 Write unit tests for update manager / 编写更新管理器的单元测试

        -   Test update checking / 测试更新检查
        -   Test update notification / 测试更新通知
        -   _Requirements: 23.1, 23.2_

    -   [ ] 31.7 Create appcast.xml file / 创建 appcast.xml 文件

        -   Set up hosting for appcast.xml / 设置 appcast.xml 的托管
        -   Document release process / 记录发布流程
        -   _Requirements: 23.1_

    -   [ ] 31.8 Test update process / 测试更新流程
        -   Test update download and installation / 测试更新下载和安装
        -   Verify data preservation during update / 验证更新期间数据保留
        -   Test automatic restart / 测试自动重启
        -   _Requirements: 23.4, 23.8, 23.9_

-   [ ] 32. Final Testing and Release Preparation / 最终测试和发布准备

    -   [ ] 32.1 Code signing and notarization / 代码签名和公证

        -   Sign application with Developer ID / 使用 Developer ID 签名应用程序
        -   Notarize application with Apple / 向 Apple 公证应用程序
        -   Create DMG installer / 创建 DMG 安装程序

    -   [ ] 32.2 Create initial release / 创建初始版本

        -   Build release version / 构建发布版本
        -   Sign update with EdDSA key / 使用 EdDSA 密钥签名更新
        -   Upload to hosting / 上传到托管服务器
        -   Create appcast.xml entry / 创建 appcast.xml 条目

    -   [ ] 32.3 Documentation / 文档
        -   Write user guide / 编写用户指南
        -   Document update process for developers / 为开发者记录更新流程
        -   Create README / 创建 README

## Notes / 注意事项

-   Tasks marked with `*` are optional and can be skipped for faster MVP / 标记为 `*` 的任务是可选的，可以跳过以更快完成 MVP
-   Each task references specific requirements for traceability / 每个任务引用特定需求以便追溯
-   Checkpoints ensure incremental validation / 检查点确保增量验证
-   Property tests validate universal correctness properties / 属性测试验证通用正确性属性
-   Unit tests validate specific examples and edge cases / 单元测试验证特定示例和边缘情况
-   All property tests should run with minimum 100 iterations / 所有属性测试应至少运行 100 次迭代
-   Sparkle framework requires code signing and notarization for updates / Sparkle 框架需要代码签名和公证才能进行更新
