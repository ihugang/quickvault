---
name: 随取 / QuickVault
version: 0.1-MVP
platform: macOS
owner: 产品经理圆桌 · 从 Idea 到 MVP
updated_at: 2026-01-07
assumptions:
  - 用户核心诉求是「个人/公司资料的快速取用与复制」，而非复杂的长期档案管理
  - R1 仅支持 macOS，本地优先，不做账号体系与云同步
  - 用户对隐私高度敏感，默认本地加密、可快速锁定
constraints:
  - 菜单栏（Status Bar）常驻形态
  - 不依赖网络即可完整使用
  - MVP 工期控制在 2–4 周
success_metrics:
  - 北极星指标：Successful Copies / Week（成功复制次数/周）
  - 激活：首次启动 24h 内创建 ≥3 条资料并完成一次复制
---

# 一、产品概述

## 1.1 产品名称
- **中文名**：随取
- **英文名**：QuickVault

**命名解释**：
- 随取：强调“随时可取、无需寻找”的高频使用场景
- QuickVault：Quick（快速）+ Vault（安全存放），传达“轻量但可信”的心理预期

## 1.2 一句话定位
> 菜单栏里的个人资料快取工具。

## 1.3 目标用户
- 个人用户：网购填地址、报销开票、办证件
- 职场用户：公司开票信息、对公资料、合同寄送信息

## 1.4 核心价值
- **快**：菜单栏 / 快捷键呼出，秒级复制
- **准**：结构化字段，减少填错
- **稳**：本地加密，随时锁定

---

# 二、核心使用场景

1. 填写发票信息时，一键复制整段开票资料
2. 表单中只需税号/电话/地址某一字段
3. 不想在微信/备忘录/文件夹里翻资料
4. 公共场合临时使用，结束后立即锁定

---

# 三、产品形态

## 3.1 形态说明
- macOS 菜单栏（Status Bar）常驻图标
- 点击或快捷键弹出 Popover 面板
- 独立 Settings Window

## 3.2 不做什么（R1 明确不包含）
- 云同步 / 账号系统
- 团队共享
- OCR 自动识别证件

---

# 四、功能需求（R1-MVP）

## 4.1 资料卡（Card Vault）

### 资料卡类型
1. **通用文本**
   - title
   - content

2. **通讯地址模板**
   - 收件人
   - 手机号
   - 省市区
   - 详细地址
   - 邮编（可选）
   - 备注（可选）

3. **发票抬头模板**
   - 公司名称
   - 税号
   - 地址
   - 电话
   - 开户行
   - 银行账号
   - 备注

### 通用能力
- 新增 / 编辑 / 删除
- 分组：个人 / 公司
- 标签（R1 可简化为字符串数组）
- 置顶

---

## 4.2 搜索与呼出

- 菜单栏点击呼出
- 全局快捷键（建议：⌥ Space，可配置）
- 搜索框自动聚焦
- 支持标题 + 字段全文匹配
- 键盘操作：
  - ↑ ↓ 选择
  - Enter：复制整卡

---

## 4.3 复制能力

- **复制整卡**：按模板拼接为可读文本
- **复制字段**：每个字段独立复制
- 复制成功 Toast 提示

**默认整卡格式示例（发票抬头）**：
```
公司名称：XX科技有限公司
税号：913xxxxxxxxx
地址：北京市海淀区xxx
电话：010-xxxxxxx
开户行：中国银行xx支行
账号：6222 xxxx xxxx xxxx
```

---

## 4.4 安全与隐私

- 本地数据加密（at-rest）
- 解锁方式：
  - Touch ID（优先）
  - 主密码（备用）
- 自动锁定：
  - 闲置 N 分钟（默认 5 分钟）
  - 系统睡眠 / 切换用户即锁
- 手动一键锁定

**锁定状态下**：
- 不展示真实内容
- 不允许复制

---

# 五、信息架构（IA）

```
菜单栏弹窗
 ├─ 搜索框
 ├─ 分组切换（个人 / 公司 / 全部）
 ├─ 资料卡列表
 │   └─ 卡片详情
 │       ├─ 字段列表（字段名 + 值 + 复制）
 │       └─ 操作：复制整卡 / 编辑 / 置顶

设置窗口
 ├─ 安全
 ├─ 复制格式
 └─ 数据管理（R2）
```

---

# 六、技术实现草案

## 6.1 技术栈建议
- Swift + SwiftUI（UI）
- AppKit（菜单栏 / 全局快捷键）
- SQLite / CoreData
- Keychain（密钥管理）
- 数据加密：
  - SQLCipher 或
  - 字段级 AES-GCM

---

## 6.2 数据模型（简化）

```sql
CREATE TABLE card (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  grp TEXT NOT NULL,
  tags_json TEXT,
  pinned INTEGER DEFAULT 0,
  created_at INTEGER,
  updated_at INTEGER
);

CREATE TABLE card_field (
  id TEXT PRIMARY KEY,
  card_id TEXT NOT NULL,
  key TEXT NOT NULL,
  label TEXT NOT NULL,
  value_enc BLOB NOT NULL,
  ord INTEGER,
  copyable INTEGER DEFAULT 1,
  FOREIGN KEY(card_id) REFERENCES card(id)
);
```

---

# 七、Icon 与视觉资产规范

## 7.1 App Icon（App Store / Dock）
- 尺寸：1024 × 1024
- 形状：**严格正方形（不做圆角处理）**
- 风格：极简、现代、偏 Apple 工具风
- 禁止：
  - 文字
  - 复杂细节

### 方向一：安全快取（Vault）
- 几何保险库 / 盾形体
- 单一主色（蓝 / 深蓝）
- 少量高亮强调“Quick”概念

### 方向二：资料卡片盒（Card Box）
- 打开的卡片盒
- 内含 2–3 张抽象卡片
- 不出现文字，仅图形暗示“资料”

---

## 7.2 状态栏 Icon
- 背景：透明
- 适配浅色 / 深色菜单栏
- 线条简化，轮廓清晰
- 建议提供：
  - 正常态
  - 锁定态（可加小锁 / 实心化）

---

# 八、埋点与指标（R1）

```csv
event,when,props,metric
App_Launch,app start,version,DAU
Vault_Unlock_Success,unlock ok,method,unlock_rate
Vault_Unlock_Fail,unlock fail,reason,fail_rate
Card_Create,create card,type,create_rate
Card_Copy_Full,copy full,type,successful_copies
Card_Copy_Field,copy field,type|field,successful_copies
Search_Used,search,keyword_len|results,search_usage
```

> 所有埋点不记录用户内容，仅做计数与枚举

---

# 九、实施里程碑

## R1（0.1 MVP）
- 菜单栏弹窗
- 资料卡 CRUD
- 模板（地址 / 发票 / 通用）
- 搜索 + 复制
- 本地加密 + 锁定

## R2（0.2）
- 全局快捷键可配置
- 最近使用 / 置顶
- 导入导出（加密）

## R3（0.3）
- 附件（证件图片）加密
- 脱敏复制
- 更多模板

---

# 十、风险与注意事项

- ❗ 忘记密码无法找回 → 明确提示用户
- ❗ 剪贴板风险 → 后续支持自动清空
- ❗ 数据损坏 → R2 做加密备份

---

# 十一、总结

**随取 / QuickVault** 是一个典型的 macOS 原生效率工具：
- 功能克制
- 高频使用
- 强调隐私与本地优先

本文件可直接作为：
- 产品 PRD
- 设计与开发对齐文档
- MVP 交付说明

