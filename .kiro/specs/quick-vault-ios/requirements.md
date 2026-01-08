# Requirements Document / 需求文档

## Introduction / 简介

QuickVault iOS (随取 iOS) is a secure personal information management application for iOS devices. It allows users to store and quickly access personal information such as addresses, invoice details, ID photos, and business licenses. The app provides encrypted storage, biometric authentication, and a watermarking feature for sensitive document images.

随取 iOS 是一款适用于 iOS 设备的安全个人信息管理应用。它允许用户存储和快速访问个人信息，如地址、发票详情、身份证照片和营业执照。该应用提供加密存储、生物识别认证以及敏感文件图片的水印功能。

## Glossary / 术语表

-   **System**: The QuickVault iOS application / 随取 iOS 应用程序
-   **User**: The person using the application / 使用应用程序的人
-   **Card**: A structured data record containing related information / 包含相关信息的结构化数据记录
-   **Field**: An individual data element within a card / 卡片内的单个数据元素
-   **Attachment**: A file (image or PDF) associated with a card / 与卡片关联的文件（图片或 PDF）
-   **Watermark**: Text overlay added to images for security / 添加到图片上的文字水印以提供安全性
-   **Master_Password**: The primary password for accessing the system / 访问系统的主密码
-   **Biometric_Auth**: Face ID or Touch ID authentication / Face ID 或 Touch ID 认证
-   **Group**: A category for organizing cards (Personal, Company) / 用于组织卡片的类别（个人、公司）

## Requirements / 需求

### Requirement 1: Card Management / 卡片管理

**User Story:** As a user, I want to create, edit, and delete cards, so that I can manage my personal information effectively.

**作为用户，我想创建、编辑和删除卡片，以便有效管理我的个人信息。**

#### Acceptance Criteria / 验收标准

1. WHEN a user creates a new card with title, group, type, and fields, THE System SHALL save the card with encrypted field values and assign creation timestamp
2. WHEN a user updates an existing card, THE System SHALL update the card data and set the modification timestamp to current time
3. WHEN a user deletes a card, THE System SHALL remove the card and all associated fields and attachments from storage
4. WHEN a user views the card list, THE System SHALL display all cards sorted by pinned status and modification date
5. WHEN a user creates or updates a card, THE System SHALL validate all required fields are non-empty
6. WHEN a user toggles the pin status of a card, THE System SHALL update the pin status and modification timestamp
7. WHEN a user adds tags to a card, THE System SHALL store the tags and allow multiple tags per card

### Requirement 2: Address Card Template / 地址卡片模板

**User Story:** As a user, I want to store address information using a predefined template, so that I can quickly access my addresses.

**作为用户，我想使用预定义模板存储地址信息，以便快速访问我的地址。**

#### Acceptance Criteria / 验收标准

1. WHEN a user creates an address card, THE System SHALL provide fields for name, phone, province, city, district, detailed address, postal code, and notes
2. WHERE postal code and notes fields are used, THE System SHALL treat them as optional fields
3. WHEN a user copies an address card, THE System SHALL format the output with field labels and values
4. WHEN a user enters a phone number in an address card, THE System SHALL validate it matches Chinese mobile (11 digits starting with 1) or landline format (area code + number)

### Requirement 3: Invoice Card Template / 发票卡片模板

**User Story:** As a user, I want to store invoice information using a predefined template, so that I can quickly provide invoice details.

**作为用户，我想使用预定义模板存储发票信息，以便快速提供发票详情。**

#### Acceptance Criteria / 验收标准

1. WHEN a user creates an invoice card, THE System SHALL provide fields for company name, tax ID, address, phone, bank name, bank account, and notes
2. WHERE notes field is used, THE System SHALL treat it as optional
3. WHEN a user copies an invoice card, THE System SHALL format the output with field labels and values
4. WHEN a user enters a tax ID in an invoice card, THE System SHALL validate it is exactly 18 characters matching the unified social credit code format

### Requirement 4: General Text Card Template / 通用文本卡片模板

**User Story:** As a user, I want to store arbitrary text information, so that I can save any type of textual data.

**作为用户，我想存储任意文本信息，以便保存任何类型的文本数据。**

#### Acceptance Criteria / 验收标准

1. WHEN a user creates a general text card, THE System SHALL provide a single text field
2. WHEN the text field contains newline characters, THE System SHALL preserve and display them correctly
3. WHEN a user copies a general text card, THE System SHALL copy the text content directly without additional formatting

### Requirement 5: Attachment Management / 附件管理

**User Story:** As a user, I want to attach images and PDFs to cards, so that I can store related documents with my information.

**作为用户，我想为卡片添加图片和 PDF 附件，以便将相关文档与我的信息一起存储。**

#### Acceptance Criteria / 验收标准

1. WHEN a user adds an attachment to a card, THE System SHALL accept image files (JPEG, PNG, HEIC) and PDF files
2. WHEN an attachment is added, THE System SHALL encrypt the file data before storage
3. WHEN a user adds an attachment, THE System SHALL reject files larger than 10MB
4. WHEN a user views an attachment, THE System SHALL decrypt and display the file
5. WHEN a user views a card with image attachments, THE System SHALL display thumbnail previews
6. WHEN a user deletes a card, THE System SHALL delete all associated attachments
7. WHEN a user shares an attachment, THE System SHALL use iOS native share sheet

### Requirement 6: Image Watermarking / 图片水印

**User Story:** As a user, I want to add watermarks to image attachments, so that I can protect sensitive documents like ID cards and business licenses.

**作为用户，我想为图片附件添加水印，以便保护身份证和营业执照等敏感文件。**

#### Acceptance Criteria / 验收标准

1. WHEN a user adds an image attachment, THE System SHALL offer an option to add a watermark
2. WHEN a user chooses to add a watermark, THE System SHALL allow custom watermark text input
3. WHEN a watermark is applied, THE System SHALL overlay the text diagonally across the image in a semi-transparent style
4. WHEN a user shares a watermarked image, THE System SHALL include the watermark in the shared file
5. WHEN a user views a watermarked image, THE System SHALL display the watermark
6. WHEN a watermark is applied, THE System SHALL preserve the original image quality
7. WHEN a user edits a watermarked image, THE System SHALL allow changing or removing the watermark text

### Requirement 7: Search and Filter / 搜索和筛选

**User Story:** As a user, I want to search and filter my cards, so that I can quickly find the information I need.

**作为用户，我想搜索和筛选我的卡片，以便快速找到所需信息。**

#### Acceptance Criteria / 验收标准

1. WHEN a user enters a search query, THE System SHALL search card titles, field values, and tags
2. WHEN search results are displayed, THE System SHALL highlight matching cards
3. WHEN a user filters by group, THE System SHALL display only cards in the selected group
4. WHEN a user copies a card from search results, THE System SHALL copy the formatted card data to clipboard

### Requirement 8: iOS UI and Navigation / iOS 用户界面和导航

**User Story:** As a user, I want an intuitive iOS interface, so that I can easily navigate and use the app.

**作为用户，我想要直观的 iOS 界面，以便轻松导航和使用应用。**

#### Acceptance Criteria / 验收标准

1. WHEN the app launches, THE System SHALL display a tab bar with Cards, Search, and Settings tabs
2. WHEN a user taps on a card, THE System SHALL navigate to the card detail view
3. WHEN a user is viewing a card, THE System SHALL provide buttons to edit, copy, and delete
4. WHEN a user taps the add button, THE System SHALL present a card creation form
5. WHEN a user copies data, THE System SHALL show a toast notification confirming the copy
6. WHEN a user navigates between views, THE System SHALL use standard iOS navigation patterns

### Requirement 9: Biometric Authentication / 生物识别认证

**User Story:** As a user, I want to use Face ID or Touch ID to unlock the app, so that I can access my data securely and conveniently.

**作为用户，我想使用 Face ID 或 Touch ID 解锁应用，以便安全便捷地访问我的数据。**

#### Acceptance Criteria / 验收标准

1. WHEN the app launches, THE System SHALL require authentication before displaying any data
2. WHEN biometric authentication is available, THE System SHALL offer Face ID or Touch ID as the primary authentication method
3. WHEN biometric authentication fails, THE System SHALL allow password authentication as fallback
4. WHEN biometric authentication succeeds, THE System SHALL unlock the app and display the card list
5. WHEN the user enables biometric authentication in settings, THE System SHALL store the preference
6. WHEN biometric authentication fails 3 times, THE System SHALL require password authentication
7. WHEN the app enters background, THE System SHALL lock automatically

### Requirement 10: Encryption and Security / 加密和安全

**User Story:** As a user, I want my data to be encrypted, so that my sensitive information is protected.

**作为用户，我想要我的数据被加密，以便保护我的敏感信息。**

#### Acceptance Criteria / 验收标准

1. WHEN field data is stored, THE System SHALL encrypt it using AES-256-GCM
2. WHEN the master password is stored, THE System SHALL store it in iOS Keychain
3. WHEN the app is locked, THE System SHALL prevent access to any decrypted data
4. WHEN the encryption key is derived, THE System SHALL use PBKDF2 with 100,000 iterations
5. WHEN field data is encrypted, THE System SHALL use a unique salt for key derivation

### Requirement 11: Master Password Management / 主密码管理

**User Story:** As a user, I want to set and change my master password, so that I can control access to my data.

**作为用户，我想设置和更改我的主密码，以便控制对我的数据的访问。**

#### Acceptance Criteria / 验收标准

1. WHEN the app is launched for the first time, THE System SHALL prompt the user to create a master password
2. WHEN a user creates a master password, THE System SHALL require at least 8 characters
3. WHEN a user changes the master password, THE System SHALL require the old password for verification
4. WHEN a user enters an incorrect password 3 times, THE System SHALL enforce a 30-second delay before allowing another attempt
5. WHEN a user successfully authenticates, THE System SHALL reset the failed attempt counter

### Requirement 12: Auto-Lock / 自动锁定

**User Story:** As a user, I want the app to lock automatically after inactivity, so that my data is protected if I forget to lock it manually.

**作为用户，我想在不活动后应用自动锁定，以便在我忘记手动锁定时保护我的数据。**

#### Acceptance Criteria / 验收标准

1. WHEN the app is inactive for the configured timeout period, THE System SHALL lock automatically
2. WHEN the app enters background, THE System SHALL lock immediately
3. WHEN the device is locked, THE System SHALL lock the app
4. WHEN the app is locked, THE System SHALL hide all sensitive content from the app switcher

### Requirement 13: Settings / 设置

**User Story:** As a user, I want to configure app settings, so that I can customize the app behavior.

**作为用户，我想配置应用设置，以便自定义应用行为。**

#### Acceptance Criteria / 验收标准

1. WHEN a user opens settings, THE System SHALL display options for auto-lock timeout, biometric authentication, and password change
2. WHEN a user changes the auto-lock timeout, THE System SHALL save the preference
3. WHEN a user toggles biometric authentication, THE System SHALL save the preference
4. WHEN a user changes the password, THE System SHALL require old password verification
5. WHEN a user changes settings, THE System SHALL persist the changes across app restarts

### Requirement 14: Data Persistence / 数据持久化

**User Story:** As a system, I want to persist data reliably, so that user data is not lost.

**作为系统，我想可靠地持久化数据，以便用户数据不会丢失。**

#### Acceptance Criteria / 验收标准

1. WHEN data is modified, THE System SHALL save changes to CoreData immediately
2. WHEN the app is terminated, THE System SHALL ensure all pending changes are saved
3. WHEN the app restarts, THE System SHALL load all saved data
4. WHEN a card is deleted, THE System SHALL ensure referential integrity by deleting associated fields and attachments
5. WHEN timestamps are stored, THE System SHALL use UTC timezone

### Requirement 15: Card Organization / 卡片组织

**User Story:** As a user, I want to organize my cards using groups and tags, so that I can categorize my information.

**作为用户，我想使用分组和标签组织我的卡片，以便对我的信息进行分类。**

#### Acceptance Criteria / 验收标准

1. WHEN a user creates a card, THE System SHALL allow selection of group (Personal or Company)
2. WHEN a user filters by group, THE System SHALL display only cards in that group
3. WHEN a user adds tags to a card, THE System SHALL allow multiple tags
4. WHEN a user searches by tag, THE System SHALL return cards with matching tags

### Requirement 16: Card Sorting / 卡片排序

**User Story:** As a user, I want my cards to be sorted intelligently, so that I can access frequently used cards quickly.

**作为用户，我想智能排序我的卡片，以便快速访问常用卡片。**

#### Acceptance Criteria / 验收标准

1. WHEN cards are displayed, THE System SHALL sort pinned cards before unpinned cards
2. WHEN cards are displayed, THE System SHALL sort by modification timestamp within each pin group
3. WHEN a card is pinned, THE System SHALL move it to the top of the list
4. WHEN multiple cards are pinned, THE System SHALL sort them by modification timestamp (most recent first)
5. WHEN multiple cards are unpinned, THE System SHALL sort them by modification timestamp (most recent first)

### Requirement 17: Error Handling / 错误处理

**User Story:** As a user, I want clear error messages, so that I understand what went wrong and how to fix it.

**作为用户，我想要清晰的错误消息，以便了解出了什么问题以及如何修复。**

#### Acceptance Criteria / 验收标准

1. WHEN a database operation fails, THE System SHALL display a user-friendly error message
2. WHEN encryption or decryption fails, THE System SHALL display an error and prevent data corruption
3. WHEN authentication fails, THE System SHALL display the reason for failure
4. WHEN file operations fail, THE System SHALL display an error message
5. WHEN errors occur, THE System SHALL log them for debugging purposes

### Requirement 18: Copy Operations / 复制操作

**User Story:** As a user, I want to copy card data to the clipboard, so that I can paste it into other applications.

**作为用户，我想将卡片数据复制到剪贴板，以便粘贴到其他应用程序中。**

#### Acceptance Criteria / 验收标准

1. WHEN a user copies an entire card, THE System SHALL format all fields with labels and copy to clipboard
2. WHEN a user copies a single field, THE System SHALL copy only the field value to clipboard
3. WHEN a copy operation succeeds, THE System SHALL display a toast notification
4. WHEN the app is locked, THE System SHALL prevent copy operations

### Requirement 19: Toast Notifications / 提示通知

**User Story:** As a user, I want visual feedback for actions, so that I know my actions were successful.

**作为用户，我想要操作的视觉反馈，以便知道我的操作成功了。**

#### Acceptance Criteria / 验收标准

1. WHEN a user copies data, THE System SHALL display a toast notification
2. WHEN a user saves a card, THE System SHALL display a success toast
3. WHEN a user deletes a card, THE System SHALL display a confirmation toast
4. WHEN an error occurs, THE System SHALL display an error toast
5. WHEN a toast is displayed, THE System SHALL auto-dismiss it after 2 seconds

### Requirement 20: Accessibility / 无障碍访问

**User Story:** As a user with accessibility needs, I want the app to support VoiceOver and Dynamic Type, so that I can use the app effectively.

**作为有无障碍需求的用户，我想要应用支持 VoiceOver 和动态字体，以便有效使用应用。**

#### Acceptance Criteria / 验收标准

1. WHEN VoiceOver is enabled, THE System SHALL provide descriptive labels for all interactive elements
2. WHEN Dynamic Type is enabled, THE System SHALL scale text appropriately
3. WHEN a user navigates with VoiceOver, THE System SHALL announce state changes
4. WHEN buttons are focused, THE System SHALL provide clear action descriptions

### Requirement 21: Input Validation / 输入验证

**User Story:** As a user, I want the app to validate my input, so that I don't enter invalid data.

**作为用户，我想要应用验证我的输入，以便不输入无效数据。**

#### Acceptance Criteria / 验收标准

1. WHEN a user submits a form with empty required fields, THE System SHALL display validation errors
2. WHEN a user enters invalid phone numbers, THE System SHALL display a validation error
3. WHEN a user enters invalid tax IDs, THE System SHALL display a validation error

### Requirement 22: First-Run Experience / 首次运行体验

**User Story:** As a new user, I want a guided setup process, so that I can start using the app quickly.

**作为新用户，我想要引导式设置流程，以便快速开始使用应用。**

#### Acceptance Criteria / 验收标准

1. WHEN the app is launched for the first time, THE System SHALL display a welcome screen
2. WHEN the welcome screen is displayed, THE System SHALL guide the user to create a master password
3. WHEN the master password is created, THE System SHALL prompt the user to enable biometric authentication
4. WHEN the setup is complete, THE System SHALL navigate to the main card list

### Requirement 23: Share Extension / 分享扩展

**User Story:** As a user, I want to share attachments and card data, so that I can send information to others.

**作为用户，我想分享附件和卡片数据，以便将信息发送给他人。**

#### Acceptance Criteria / 验收标准

1. WHEN a user taps share on an attachment, THE System SHALL present the iOS share sheet
2. WHEN a user shares a watermarked image, THE System SHALL include the watermark in the shared file
3. WHEN a user shares card data, THE System SHALL format it as text
4. WHEN a user shares via AirDrop, THE System SHALL support AirDrop transfer

## Notes / 注意事项

-   All user-facing strings should be bilingual (Chinese/English) / 所有面向用户的字符串应为双语（中文/英文）
-   Security is paramount - all sensitive data must be encrypted / 安全至关重要 - 所有敏感数据必须加密
-   The app should follow iOS Human Interface Guidelines / 应用应遵循 iOS 人机界面指南
-   Watermark feature is critical for protecting sensitive documents / 水印功能对于保护敏感文件至关重要
