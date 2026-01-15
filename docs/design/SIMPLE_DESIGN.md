# QuickVault Simple Design / 简化设计方案

## 核心理念 / Core Concept

回归最初的简单想法：用户创建卡片，需要时找出来分享

### 核心使用流程
1. **创建卡片** - 写一系列卡片保存
   - 文本卡片：标题 + 文本内容
   - 图片卡片：标题 + 图片（可多张）
   
2. **查找卡片** - 通过标题、标签搜索
   - 支持置顶重要卡片
   - 按更新时间排序
   
3. **分享内容** - 快速分享卡片内容
   - 文本卡片：直接分享文本
   - 图片卡片：可选择是否加水印后分享

## 数据模型 / Data Model

### 1. Item (核心实体)

```swift
@objc(Item)
public class Item: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var type: String  // "text" 或 "image"
    @NSManaged public var tagsJSON: String?  // JSON 数组存储标签
    @NSManaged public var isPinned: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    // 关系
    @NSManaged public var textContent: TextContent?      // type == "text" 时使用
    @NSManaged public var images: NSSet?                 // type == "image" 时使用
}
```

### 2. TextContent (文本内容)

```swift
@objc(TextContent)
public class TextContent: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var encryptedContent: Data  // AES-256-GCM 加密的文本内容
    @NSManaged public var item: Item
}
```

### 3. ImageContent (图片内容)

```swift
@objc(ImageContent)
public class ImageContent: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var fileName: String
    @NSManaged public var encryptedData: Data     // AES-256-GCM 加密的图片数据
    @NSManaged public var thumbnailData: Data?    // 加密的缩略图
    @NSManaged public var fileSize: Int64
    @NSManaged public var displayOrder: Int16     // 显示顺序
    @NSManaged public var createdAt: Date
    @NSManaged public var item: Item
}
```

## 关系图 / Relationships

```
Item (type="text")  ←→ (1:1) TextContent
Item (type="image") ←→ (1:N) ImageContent
```

## ItemType 枚举

```swift
public enum ItemType: String, CaseIterable {
    case text = "text"
    case image = "image"
    
    public var displayName: String {
        switch self {
        case .text: return "文本 / Text"
        case .image: return "图片 / Image"
        }
    }
    
    public var icon: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        }
    }
}
```

## 服务层 / Service Layer

### ItemService

```swift
public protocol ItemService {
    // 创建
    func createTextItem(title: String, content: String, tags: [String]) async throws -> ItemDTO
    func createImageItem(title: String, images: [ImageData], tags: [String]) async throws -> ItemDTO
    
    // 读取
    func fetchAllItems() async throws -> [ItemDTO]
    func fetchItem(id: UUID) async throws -> ItemDTO
    func searchItems(query: String) async throws -> [ItemDTO]
    
    // 更新
    func updateTextItem(id: UUID, title: String?, content: String?, tags: [String]?) async throws -> ItemDTO
    func updateImageItem(id: UUID, title: String?, tags: [String]?) async throws -> ItemDTO
    func addImages(to itemId: UUID, images: [ImageData]) async throws
    func removeImage(id: UUID) async throws
    
    // 删除
    func deleteItem(id: UUID) async throws
    
    // 其他
    func togglePin(id: UUID) async throws -> ItemDTO
}
```

### DTO 定义

```swift
public struct ItemDTO: Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let type: ItemType
    public let tags: [String]
    public let isPinned: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    // 根据类型，只有一个会有值
    public let textContent: String?
    public let images: [ImageDTO]?
}

public struct ImageDTO: Identifiable, Hashable {
    public let id: UUID
    public let fileName: String
    public let fileSize: Int64
    public let displayOrder: Int16
    public let thumbnailData: Data?
}

public struct ImageData {
    public let data: Data
    public let fileName: String
}
```

## 视图层 / View Layer

### 主列表视图

```
ItemListView
├── 搜索框 (搜索标题和标签)
├── 置顶的 Items (按更新时间倒序)
└── 普通 Items (按更新时间倒序)
    ├── TextItemRow 
    │   ├── 标题
    │   ├── 内容预览
    │   ├── 标签
    │   └── 操作: 分享文本、编辑、删除
    └── ImageItemRow
        ├── 标题
        ├── 缩略图网格
        ├── 标签
        └── 操作: 分享图片(选择是否加水印)、编辑、删除
```

### 详情/编辑视图

```
TextItemDetailView
├── Title TextField
├── Tags Input (多个标签)
├── Content TextEditor (支持多行文本)
└── Actions
    ├── 分享文本 (复制到剪贴板或系统分享)
    ├── 置顶/取消置顶
    └── 删除

ImageItemDetailView
├── Title TextField
├── Tags Input (多个标签)
├── Image Grid (显示所有图片)
│   ├── 点击放大查看
│   ├── 长按删除
│   └── 拖动排序
└── Actions
    ├── 分享图片
    │   ├── 选择: 无水印
    │   └── 选择: 添加水印 (输入水印文字)
    ├── 添加更多图片
    ├── 置顶/取消置顶
    └── 删除
```

## 对比现有设计 / Comparison

### 现有设计
- 10种卡片类型（通用文本、地址、发票、身份证、护照等）
- CardField 存储键值对
- CardAttachment 作为附件
- 复杂的 OCR 和字段映射

### 简化设计
- ✅ 只有2种类型：文本和图片
- ✅ 文本直接存储完整内容，不再拆分字段
- ✅ 图片就是主要内容，不是附件
- ✅ 保留 tags 功能用于分类和搜索
- ✅ 移除所有 OCR 相关功能
- ✅ 更直观的用户体验

## 迁移策略 / Migration Strategy

如果需要从现有数据迁移：

1. **Card.type == "general"** → TextItem
   - title → title
   - fields 合并为 textContent
   
2. **其他 Card types** → TextItem
   - title → title  
   - fields 格式化为文本 → textContent
   - attachments → 如果有图片，可创建对应的 ImageItem

3. **纯附件的 Cards** → ImageItem
   - attachments → images

## 下一步 / Next Steps

1. 创建新的 CoreData 模型（QuickVaultSimple.xcdatamodeld）
2. 实现 ItemService
3. 创建简化的 UI 视图
4. 测试基本功能
5. （可选）实现数据迁移工具

---

**核心优势**：
- 🎯 概念清晰：就是文本和图片两种东西
- 🚀 实现简单：减少 80% 的代码复杂度
- 💡 易于理解：用户不需要选择"卡片类型"
- ⚡️ 快速开发：2-3天即可完成核心功能
