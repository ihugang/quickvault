## QuickHold 产品优化 TODO（含代码模块映射）

> 说明：本文件可直接作为产品/开发协作用的待办清单，每条任务都标注了主要涉及的代码文件路径，便于分派和跟踪。

---

### 一、Phase 1（P0）—— 首启闭环 & 列表体验

#### 1. 首启引导任务化（Introduction + Welcome）

- **1.1 调整首启状态流转**
  - **目标**：从“纯介绍”改为“引导到创建资料”的任务式流程。
  - **涉及文件**：
    - `src/QuickHold-iOS-App/QuickHold-iOS/App/QuickVaultApp.swift`
    - `src/QuickHold-iOS-App/QuickHold-iOS/ViewModels/AuthViewModel.swift`
  - **子任务**：
    - [ ] 在 `QuickVaultApp` / `SimpleRootView` 中，增加用于标记“首启向导是否完成”的状态与分支。
    - [ ] 在 `AuthViewModel` 中暴露首启相关状态（例如是否已有数据、是否完成初始向导），供根视图判断跳转。

- **1.2 改造 IntroductionView 为“任务入口”**
  - **目标**：从展示安全特性，升级为“欢迎 + 开始创建资料”的步骤 1。
  - **涉及文件**：
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Auth/IntroductionView.swift`
    - 多语言文案：  
      - `src/QuickHold-iOS-App/QuickHold-iOS/Resources/zh-Hans.lproj/Localizable.strings`  
      - 及其他语言的 `Localizable.strings`
  - **子任务**：
    - [ ] 在 `IntroductionView` 底部增加“开始创建资料”等 CTA 按钮，点击后推进首启流程。
    - [ ] 更新介绍文案，让“安全说明”更简洁，突出“下一步将帮你创建常用资料”。
    - [ ] 为新按钮和文案添加本地化 key/value。

- **1.3 WelcomeView 中增加“下一步：创建资料”引导**
  - **目标**：密码/登录完成后，引导用户立即创建首批资料。
  - **涉及文件**：
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Auth/WelcomeView.swift`
    - `src/QuickHold-iOS-App/QuickHold-iOS/ViewModels/AuthViewModel.swift`
  - **子任务**：
    - [ ] 在 `WelcomeView` 中，在密码设置成功后，增加“创建第一条资料”提示或按钮。
    - [ ] 为 `AuthViewModel` 增加回调/状态，通知根视图跳转到列表并打开 `CreateItemSheet`。

- **1.4 首两条示例资料创建逻辑**
  - **目标**：帮助用户快速创建“收货地址”“发票信息”等样板资料。
  - **涉及文件**：
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Items/CreateItemSheet.swift`
    - `src/QuickHoldKit/Sources/QuickHoldCore/Services/ItemService.swift`
    - `src/QuickHoldKit/Sources/QuickHoldCore/Models/Item+CoreData*.swift`（如需增加字段）
  - **子任务**：
    - [ ] 在 `CreateItemSheet` 中实现“根据模板预填标题和内容”的方法。
    - [ ] 在首启完成时，通过 `ItemService` 创建 1–2 条示例 Text Item（如地址/发票）。
    - [ ] （可选）在 `Item` 模型中加入 `isSample` 标记字段，避免后续迁移或清理时混淆。

---

#### 2. 空列表体验（Empty State 优化）

- **2.1 调整空态 UI 和交互**
  - **目标**：在列表为空时，用清晰文案 + CTA 引导创建第一条资料。
  - **涉及文件**：
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Items/ItemListView.swift`
  - **子任务**：
    - [ ] 重写 `emptyStateView`，增加标题、副标题、示意图/图标、按钮“创建第一条资料”。
    - [ ] 点击按钮时，调用现有 `showingCreateSheet` 流程，并默认选择 `ItemType.text`。

- **2.2 空态文案国际化**
  - **涉及文件**：
    - 各语言 `Localizable.strings`
  - **子任务**：
    - [ ] 添加空态标题、副标题、按钮的本地化 key/value。
    - [ ] 检查中英文是否符合“中文 / English”格式要求。

---

#### 3. 列表快速动作（长按/滑动复制 & 分享）

- **3.1 在列表行增加快捷菜单（复制/分享/置顶）**
  - **目标**：让用户在主列表就能完成复制/分享，无需进入详情页。
  - **涉及文件**：
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Items/ItemListView.swift`
    - 以及可能存在的行视图，例如：  
      - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Items/TextItemRow.swift`  
      - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Items/ImageItemRow.swift`（如有）
  - **子任务**：
    - [ ] 在列表的每个 item 行上添加 `contextMenu` 或 `swipeActions`：复制、分享、置顶/取消置顶、删除。
    - [ ] 对文本卡片，实现“复制内容”“系统分享”；对图片卡片，实现“快速分享最近一张图（或弹出选择）”。
    - [ ] 确保操作后调用与详情页一致的分享/复制逻辑，保持行为统一。

- **3.2 抽取分享 & 复制逻辑**
  - **涉及文件**：
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Items/ItemDetailView.swift`
    - （可选）公共工具文件，如 `src/QuickHold-iOS-App/QuickHold-iOS/Views/Common/ShareHelpers.swift`
  - **子任务**：
    - [ ] 从 `ItemDetailView` 中抽取通用“复制文本”“分享文本/图片”的 helper 函数。
    - [ ] 列表行和详情页共用这些 helper，减少重复代码。

- **3.3 操作成功反馈（Toast）复用**
  - **涉及文件**：
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Common/ToastView.swift`（或类似命名）
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Items/ItemListView.swift`
  - **子任务**：
    - [ ] 在列表视图中，根据复制/分享结果，调用 `ToastView` 显示短暂提示。
    - [ ] 保证提示与 Settings 中的成功/失败 Toast 表现一致。

---

#### 4. 排序逻辑简化（围绕“最近使用”）

- **4.1 收敛排序选项**
  - **目标**：默认“置顶 + 最近修改/使用”，菜单里只保留 2–3 个简单选项。
  - **涉及文件**：
    - `src/QuickHold-iOS-App/QuickHold-iOS/ViewModels/ItemListViewModel.swift`
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Items/ItemListView.swift`
  - **子任务**：
    - [ ] 在 `SortOption` 中改造枚举值（例如：`recent`, `title`, `type`），并删除不必要选项。
    - [ ] 在 `filteredItems` 中实现“置顶优先 + 时间排序”的默认逻辑（结合 `pinnedItems` / `unpinnedItems`）。
    - [ ] 在 `ItemListView` 的排序菜单中只展示保留的选项，并更新对应本地化 key。

- **4.2（可选）记录 lastUsedAt**
  - **涉及文件**：
    - `src/QuickHoldKit/Sources/QuickHoldCore/Models/Item+CoreData*.swift`
    - `src/QuickHoldKit/Sources/QuickHoldCore/Services/ItemService.swift`
  - **子任务**：
    - [ ] 在 CoreData 实体 `Item` 中增加 `lastUsedAt` 字段，并同步到 `ItemDTO`。
    - [ ] 在复制/分享操作中，通过 `ItemService` 更新 `lastUsedAt`，供排序使用。

---

#### 5. 设置中增加“安全说明卡”

- **5.1 SettingsView 新增“你的数据如何被保护”Section**
  - **目标**：用一小段可视化内容解释加密、本地存储、自动锁定等，让用户产生“敢用感”。
  - **涉及文件**：
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Settings/SettingsView.swift`
  - **子任务**：
    - [ ] 在 Form 中新增 Section，标题类似 `settings.security.info.title`，内部用几行 Text 或自定义视图列出 3–4 条安全要点。
    - [ ] 注意与现有 Security Section（auto-lock、生物识别、改密码）视觉区隔。

- **5.2 安全文案国际化**
  - **涉及文件**：
    - `src/QuickHold-iOS-App/QuickHold-iOS/Services/LocalizationManager.swift`（逻辑不变）
    - 各语言 `Localizable.strings`
  - **子任务**：
    - [ ] 为安全说明卡新增本地化 key/value，遵循“中文 / English”格式。
    - [ ] 检查新 key 在不同语言下是否存在 fallback。

---

### 二、Phase 2（P1）—— 模板 & 轻量智能

#### 6. 常用模板层（地址、发票、通用备注）

- **6.1 在 CreateItemSheet 中加入模板入口**
  - **涉及文件**：
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Items/CreateItemSheet.swift`
  - **子任务**：
    - [ ] 在 `typeSelectionSection` 下方新增“快速模板”区，列出“收货地址”、“发票信息”、“通用备注”等选项。
    - [ ] 点击模板时：设置 `selectedType = .text`，预填 `title` + `textContent` + 初始 `tags`。

- **6.2 模板文案和字段结构**
  - **涉及文件**：
    - 各语言 `Localizable.strings`
  - **子任务**：
    - [ ] 为模板标题、描述文案增加本地化 key（例如 `template.address.title`、`template.invoice.body`）。
    - [ ] 文本内容中直接写出字段结构（如“收货人：\n电话：\n地址：\n邮编：”）。

---

#### 7. 智能标题生成

- **7.1 在创建 Text Item 时自动建议标题**
  - **涉及文件**：
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Items/CreateItemSheet.swift`
  - **子任务**：
    - [ ] 在 `textContent` 的 `onChange` 或 `createItem()` 前，若 `title` 为空，从内容首行/前若干字符截取建议标题。
    - [ ] 可选：在 UI 中用轻提示展示“已为你生成标题：xxx”，允许用户修改。

- **7.2（可选）编辑时也提供标题建议**
  - **涉及文件**：
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Items/EditItemSheet.swift`
  - **子任务**：
    - [ ] 在内容大改且标题为空时，复用同样的标题建议逻辑。

---

#### 8. 轻量标签推荐

- **8.1 根据历史标签和内容推荐 Tag**
  - **涉及文件**：
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Items/CreateItemSheet.swift`
    - `src/QuickHold-iOS-App/QuickHold-iOS/ViewModels/ItemListViewModel.swift`
  - **子任务**：
    - [ ] 在 `CreateItemSheet` 的 tags 区域下方展示推荐标签（来自 `availableTags` + 内容关键词匹配）。
    - [ ] 在 `ItemListViewModel` 中扩展 `allTags` 或新增 API，支持根据频次排序生成“常用标签”列表。
    - [ ] 定义简单关键词→标签的映射（如：包含“发票/税号/公司” → 推荐“发票”，“身份证/护照”→“证件”）。

---

### 三、Phase 3（P1，概略映射）—— 分享 & 水印

> 这一部分目前只做高层映射，等进入 Phase 3 时，可按 Phase 1/2 的粒度继续细化到子任务。

- **9.1 详情分享流程 & 多选项水印**
  - **涉及文件**：
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Items/ItemDetailView.swift`
    - `src/QuickHold-iOS-App/QuickHold-iOS/Services/WatermarkService.swift`
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Settings/SettingsView.swift`
    - `src/QuickHold-iOS-App/QuickHold-iOS/ViewModels/SettingsViewModel.swift`

- **9.2 分享记录（lastSharedAt / shareCount）**
  - **涉及文件**：
    - `src/QuickHoldKit/Sources/QuickHoldCore/Models/Item+CoreData*.swift`
    - `src/QuickHoldKit/Sources/QuickHoldCore/Services/ItemService.swift`
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Items/ItemDetailView.swift`
    - `src/QuickHold-iOS-App/QuickHold-iOS/Views/Items/ItemListView.swift`
