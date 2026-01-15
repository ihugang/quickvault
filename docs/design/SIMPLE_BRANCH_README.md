# QuickVault Simple 分支说明

## 核心思想

用户创建一系列卡片，用的时候找出来：
- **文本卡片** → 直接分享文本
- **图片卡片** → 可选加水印后分享

## 架构简化对比

### 之前（复杂）
- ❌ 10种卡片类型（通用、地址、发票、身份证、护照、驾照...）
- ❌ CardField 键值对系统
- ❌ 复杂的 OCR 识别和字段映射
- ❌ CardAttachment 作为附件

### 现在（简单）
- ✅ 只有2种：文本和图片
- ✅ 文本直接存完整内容
- ✅ 图片就是主要内容
- ✅ Tags 用于分类搜索
- ✅ 内置水印功能

## 数据模型

```
Item
├── type: "text" | "image"
├── title: String
├── tags: [String]
├── isPinned: Bool
└── 内容:
    ├── TextContent (加密文本)
    └── ImageContent[] (加密图片 + 缩略图)
```

## 核心功能

### ItemService API

```swift
// 创建
createTextItem(title, content, tags)
createImageItem(title, images, tags)

// 查找
fetchAllItems()
searchItems(query)

// 分享
getShareableText(id)
getShareableImages(id, withWatermark, watermarkText)

// 更新
updateTextItem(id, title?, content?, tags?)
updateImageItem(id, title?, tags?)
addImages(to: itemId, images)

// 其他
togglePin(id)
deleteItem(id)
```

## 使用示例

### 创建文本卡片
```swift
let item = try await itemService.createTextItem(
    title: "收货地址",
    content: """
    收件人：张三
    电话：13800138000
    地址：北京市朝阳区xxx路xxx号
    """,
    tags: ["地址", "家庭"]
)
```

### 创建图片卡片
```swift
let item = try await itemService.createImageItem(
    title: "身份证照片",
    images: [frontImage, backImage],
    tags: ["证件", "身份证"]
)
```

### 分享文本
```swift
let text = try await itemService.getShareableText(id: item.id)
UIPasteboard.general.string = text
```

### 分享图片（加水印）
```swift
let images = try await itemService.getShareableImages(
    id: item.id,
    withWatermark: true,
    watermarkText: "仅供XX使用"
)
```

## 文件结构

```
QuickVaultKit/Sources/QuickVaultCore/
├── Models/
│   ├── Item+CoreDataClass.swift
│   ├── Item+CoreDataProperties.swift
│   ├── TextContent+CoreDataClass.swift
│   ├── TextContent+CoreDataProperties.swift
│   ├── ImageContent+CoreDataClass.swift
│   ├── ImageContent+CoreDataProperties.swift
│   └── ItemType.swift
└── Services/
    ├── ItemService.swift (核心服务)
    └── ItemService+Examples.swift (使用示例)
```

## 下一步

1. ✅ 数据模型已创建
2. ✅ 服务层已实现
3. ⏳ 需要在 Xcode 中创建 CoreData 模型文件
4. ⏳ 创建 UI 视图层
5. ⏳ 测试基本功能

## 优势

- 🎯 **概念清晰**：就两种东西 - 文本和图片
- 🚀 **实现简单**：减少 80% 代码复杂度
- 💡 **易于理解**：用户不需要选择"卡片类型"
- ⚡️ **快速开发**：2-3天完成核心功能
- 🔒 **安全加密**：内容端到端加密
- 🏷️ **灵活标签**：自由分类和搜索
- 💧 **智能水印**：图片分享时可选加水印
