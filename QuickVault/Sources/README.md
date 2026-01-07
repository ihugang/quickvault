# QuickVault Source Code Structure

This directory contains the source code for QuickVault, organized following Swift/SwiftUI best practices.

## Directory Structure

```
Sources/
├── Core/                       # 核心业务逻辑层
│   ├── Models/                 # 数据模型
│   │   ├── Card+CoreDataClass.swift
│   │   ├── Card+CoreDataProperties.swift
│   │   ├── CardField+CoreDataClass.swift
│   │   ├── CardField+CoreDataProperties.swift
│   │   ├── CardAttachment+CoreDataClass.swift
│   │   ├── CardAttachment+CoreDataProperties.swift
│   │   ├── CardTemplate.swift  # 卡片模板定义
│   │   ├── PersistenceController.swift
│   │   └── QuickVault.xcdatamodeld/
│   │
│   ├── Services/               # 业务服务层
│   │   ├── AuthenticationService.swift  # 认证服务
│   │   ├── CardService.swift           # 卡片服务
│   │   ├── CryptoService.swift         # 加密服务
│   │   └── KeychainService.swift       # 钥匙串服务
│   │
│   └── Utilities/              # 工具类
│       ├── ValidationService.swift     # 数据验证
│       └── IconProvider.swift          # 图标提供者
│
├── Features/                   # 功能模块
│   └── App/
│       └── QuickVaultApp.swift         # 应用入口点
│
└── Views/                      # UI视图层
    └── Components/             # 可复用组件 (待实现)

```

## Architecture Layers

### 1. Core Layer (核心层)
Contains the business logic, data models, and services that are independent of UI.

**Models**: CoreData entities and data structures
- Card, CardField, CardAttachment entities
- CardTemplate definitions (Address, Invoice, General)
- PersistenceController for CoreData stack

**Services**: Business logic and external integrations
- AuthenticationService: Touch ID and password authentication
- CardService: CRUD operations for cards
- CryptoService: AES-256-GCM encryption/decryption
- KeychainService: Secure storage in macOS Keychain

**Utilities**: Helper functions and validation
- ValidationService: Phone, tax ID, field validation
- IconProvider: Icon management utilities

### 2. Features Layer (功能层)
Contains feature-specific code grouped by functionality.

**App**: Application lifecycle and configuration
- QuickVaultApp: Main app entry point with AppDelegate

### 3. Views Layer (视图层)
Contains all UI components and views (to be implemented).

**Components**: Reusable SwiftUI components
- (To be added: Menu bar views, Dashboard views, etc.)

## Design Principles

1. **Separation of Concerns**: Core business logic is independent of UI
2. **Testability**: Services use protocols for easy mocking
3. **Modularity**: Features are isolated and can be developed independently
4. **Scalability**: New features can be added without affecting existing code

## Adding New Code

- **New Model**: Add to `Core/Models/`
- **New Service**: Add to `Core/Services/` with protocol definition
- **New Utility**: Add to `Core/Utilities/`
- **New Feature**: Create subdirectory in `Features/`
- **New View**: Add to `Views/` or `Views/Components/`

## Related Documentation

- See `CLAUDE.md` in project root for comprehensive development guide
- See `.kiro/specs/quick-vault-macos/` for requirements and design docs
