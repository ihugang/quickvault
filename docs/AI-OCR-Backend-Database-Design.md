# AI-OCR Backend 数据库逻辑设计

## 1. 设计概述

### 1.1 设计原则

1. **规范化 (Normalization)**: 核心表遵循第三范式 (3NF)，必要时为性能进行反规范化
2. **软删除 (Soft Delete)**: 使用状态字段而非硬删除，保留审计追踪
3. **审计追踪 (Audit Trail)**: 所有主表包含 CreatedAt, UpdatedAt, CreatedBy
4. **性能优化 (Performance)**: 战略性索引、大表分区
5. **灵活存储 (Flexible Schema)**: 使用 JSON 字段存储可变结构数据

### 1.2 核心职责

本系统数据库**仅管理**：

-   ✅ 提示词模板（系统提示词 + 用户提示词）
-   ✅ OCR 请求日志（包含设备信息）
-   ✅ 证件类型元数据
-   ❌ AI 模型配置（由外部系统管理）
-   ❌ Provider 管理（由外部系统管理）

### 1.3 技术栈

-   **数据库**: MS SQL Server 2022
-   **字符集**: UTF-8 (支持多语言)
-   **ORM**: Entity Framework Core 10
-   **缓存**: Redis 7+ (分布式缓存)

## 2. 实体关系图 (ERD)

### 2.1 完整 ERD

```
┌──────────────────────────────────────────────────────────────────┐
│                    AI-OCR Backend 数据架构                         │
│                                                                    │
│  核心原则：                                                         │
│  1. 提示词模板管理（多版本、多语言）                                │
│  2. 请求日志追踪（7天自动清理）                                     │
│  3. 设备信息分析（OS、版本、型号）                                  │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│  DocumentMetadata    │  ← 证件类型元数据（国家+类型）
│  ──────────────────  │
│  PK: CountryCode     │
│      + DocumentType  │
│  ──────────────────  │
│  • DisplayName       │
│  • LocalizedNames    │  (JSON)
│  • RequiredFields    │  (JSON)
│  • OptionalFields    │  (JSON)
│  • FieldLabels       │  (JSON)
│  • ValidationRules   │  (JSON)
│  • FormatExamples    │  (JSON)
│  • IsEnabled         │
│  • SupportedLocales  │
│  • CreatedAt         │
│  • UpdatedAt         │
└──────────┬───────────┘
           │
           │ 1:N (定义)
           │ CASCADE DELETE
           ↓
┌──────────────────────┐
│  PromptTemplates     │  ← AI 提示词模板（多版本）
│  ──────────────────  │
│  PK: Id (GUID)       │
│  UK: CountryCode     │
│      + DocumentType  │
│      + Version       │
│      + Locale        │
│  FK: CountryCode     │
│      + DocumentType  │
│  ──────────────────  │
│  • SystemPrompt      │  (NVARCHAR(MAX))
│  • UserPromptTemplate│  (NVARCHAR(MAX))
│  • Description       │
│  • FieldsConfig      │  (JSON)
│  • ValidationRules   │  (JSON)
│  • Status            │  (active/deprecated/testing)
│  • IsDefault         │  (每类型只能有一个)
│  • AvgConfidence     │  (系统自动更新)
│  • SuccessRate       │  (系统自动更新)
│  • UsageCount        │  (系统自动更新)
│  • CreatedBy         │
│  • CreatedAt         │
│  • UpdatedAt         │
└──────────┬───────────┘
           │
           │ 1:N (使用)
           │ NO ACTION (保留历史)
           ↓
┌──────────────────────┐
│  OcrRequestLogs      │  ← OCR 请求日志（7天自动清理）
│  ──────────────────  │
│  PK: Id (GUID)       │
│  UK: RequestId       │
│  ──────────────────  │
│  • CountryCode       │
│  • DocumentType      │
│  • ClientVersion     │
│  • UserId            │  (可选)
│  ──────────────────  │
│  设备信息:            │
│  • OsType            │  (iOS/Android/macOS)
│  • OsVersion         │  (17.2, 14.0, etc.)
│  • AppVersion        │  (1.0.0)
│  • DeviceModel       │  (iPhone 15 Pro)
│  ──────────────────  │
│  • RawTexts          │  (JSON - OCR原始文本)
│  • ExtractedFields   │  (JSON - 提取的字段)
│  • PromptVersion     │  (FK - 使用的提示词版本)
│  • ModelUsed         │  (记录外部AI模型名称)
│  • AiResponse        │  (JSON - AI原始响应)
│  • ConfidenceScore   │  (0.00-1.00)
│  • ProcessingTimeMs  │  (处理时间)
│  • Status            │  (success/failed/partial)
│  • ErrorMessage      │
│  • CreatedAt         │  (用于7天清理)
│  • IpAddress         │
└──────────────────────┘

```

### 2.2 关系详情

#### 关系 1: DocumentMetadata → PromptTemplates (1:N)

| 属性         | 值                                                                                           |
| ------------ | -------------------------------------------------------------------------------------------- |
| **关系类型** | 一对多 (One-to-Many)                                                                         |
| **外键**     | `PromptTemplates.CountryCode + DocumentType` → `DocumentMetadata.CountryCode + DocumentType` |
| **业务含义** | 一种证件类型可以有多个提示词版本（不同语言、不同版本号、不同状态）                           |
| **级联删除** | CASCADE DELETE - 删除证件类型时自动删除所有相关提示词                                        |
| **级联更新** | CASCADE UPDATE - 更新证件类型代码时自动更新提示词外键                                        |
| **示例**     | CN + driversLicense → 可以有 v1.0.0-zh-CN, v2.0.0-zh-CN, v1.0.0-en-US 等多个版本             |

**SQL 实现**:

```sql
ALTER TABLE PromptTemplates
ADD CONSTRAINT FK_Templates_Metadata
FOREIGN KEY (CountryCode, DocumentType)
REFERENCES DocumentMetadata(CountryCode, DocumentType)
ON DELETE CASCADE
ON UPDATE CASCADE;
```

#### 关系 2: PromptTemplates → OcrRequestLogs (1:N)

| 属性         | 值                                                                                                                  |
| ------------ | ------------------------------------------------------------------------------------------------------------------- |
| **关系类型** | 一对多 (One-to-Many)                                                                                                |
| **外键**     | `OcrRequestLogs.PromptVersion` → `PromptTemplates.Version` (软关联)                                                 |
| **业务含义** | 一个提示词版本可以被多次请求使用，用于追踪性能                                                                      |
| **级联删除** | NO ACTION - 保留历史日志，即使提示词被删除                                                                          |
| **级联更新** | NO ACTION - 版本号不应该被修改                                                                                      |
| **用途**     | 1. 追踪哪个版本的提示词产生了什么样的结果<br>2. 统计每个版本的成功率和平均置信度<br>3. A/B 测试不同提示词版本的效果 |

**注意**: 这是一个软关联，不使用强制外键约束，因为：

1. 日志表数据量大，外键会影响插入性能
2. 需要保留历史日志，即使提示词被删除
3. 通过应用层逻辑保证数据一致性

## 3. 表结构详细设计

### 3.1 DocumentMetadata (证件类型元数据表)

#### 表说明

**用途**: 定义系统支持的证件类型及其字段规范，作为提示词模板的元数据基础。

**特点**:

-   主键为复合主键 (CountryCode + DocumentType)
-   使用 JSON 字段存储灵活的字段配置
-   支持多语言显示名称
-   可以启用/禁用特定证件类型

#### 完整 DDL

```sql
CREATE TABLE DocumentMetadata (
    -- Primary Key (复合主键)
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    CountryCode NVARCHAR(10) NOT NULL,
    DocumentType NVARCHAR(50) NOT NULL,

    -- Display Information (显示信息)
    DisplayName NVARCHAR(200) NOT NULL,
    -- 例如: "中国驾驶证 / CN Driver's License"

    LocalizedNames NVARCHAR(MAX),
    -- JSON 格式: {"en": "Driver's License", "zh-CN": "驾驶证", "ja": "運転免許証"}

    Icon NVARCHAR(500),
    -- 图标 URL 或 base64 编码

    -- Field Definitions (字段定义)
    RequiredFields NVARCHAR(MAX) NOT NULL,
    -- JSON 数组: ["name", "licenseNumber", "birthDate"]

    OptionalFields NVARCHAR(MAX),
    -- JSON 数组: ["address", "issueDate", "expiryDate"]

    FieldLabels NVARCHAR(MAX),
    -- JSON 对象: {"name": {"en": "Full Name", "zh-CN": "姓名"}}

    -- Validation Rules (验证规则)
    ValidationRules NVARCHAR(MAX),
    -- JSON 对象: {"licenseNumber": {"pattern": "^\\d{18}$", "message": "格式错误"}}

    FormatExamples NVARCHAR(MAX),
    -- JSON 对象: {"birthDate": "YYYY-MM-DD", "licenseNumber": "610102197501163541"}

    -- Status (状态)
    IsEnabled BIT DEFAULT 1,
    -- 是否启用此证件类型 (1=启用, 0=禁用)

    SupportedLocales NVARCHAR(500),
    -- 支持的语言列表: "en,zh-CN,ja,ko"

    -- Audit (审计字段)
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),

    -- Constraints (约束)
    CONSTRAINT UQ_Document_Metadata UNIQUE(CountryCode, DocumentType),
    CONSTRAINT CK_CountryCode CHECK (LEN(CountryCode) >= 2 AND LEN(CountryCode) <= 10),
    CONSTRAINT CK_DocumentType CHECK (LEN(DocumentType) >= 2 AND LEN(DocumentType) <= 50),
    CONSTRAINT CK_DisplayName CHECK (LEN(DisplayName) > 0)
);

-- Indexes (索引)
CREATE INDEX IX_Metadata_Enabled
    ON DocumentMetadata(IsEnabled)
    WHERE IsEnabled = 1;
    -- 过滤索引：只索引启用的证件类型

CREATE INDEX IX_Metadata_Country
    ON DocumentMetadata(CountryCode);
    -- 按国家查询

CREATE INDEX IX_Metadata_Type
    ON DocumentMetadata(DocumentType);
    -- 按证件类型查询

-- Extended Properties (表注释)
EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'证件类型元数据表，定义系统支持的证件类型及其字段规范。每种证件类型（国家+类型）只能有一条记录。',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE',  @level1name = N'DocumentMetadata';

-- Column Comments (字段注释)
EXEC sp_addextendedproperty
    @name = N'MS_Description', @value = N'国家/地区代码，如 CN, US, JP',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE',  @level1name = N'DocumentMetadata',
    @level2type = N'COLUMN', @level2name = N'CountryCode';

EXEC sp_addextendedproperty
    @name = N'MS_Description', @value = N'证件类型，如 driversLicense, idCard, passport',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE',  @level1name = N'DocumentMetadata',
    @level2type = N'COLUMN', @level2name = N'DocumentType';
```

#### 示例数据

```sql
-- 中国驾驶证
INSERT INTO DocumentMetadata (
    CountryCode, DocumentType, DisplayName,
    RequiredFields, OptionalFields, LocalizedNames,
    FieldLabels, ValidationRules, FormatExamples,
    IsEnabled, SupportedLocales
)
VALUES (
    'CN', 'driversLicense', '中国驾驶证 / CN Driver''s License',

    -- Required Fields
    '["name","licenseNumber","birthDate"]',

    -- Optional Fields
    '["address","issueDate","validFrom","validUntil","licenseClass","gender","nationality"]',

    -- Localized Names
    '{"en":"Driver''s License","zh-CN":"驾驶证","zh-TW":"駕駛證","ja":"運転免許証"}',

    -- Field Labels
    '{
        "name": {"en":"Full Name","zh-CN":"姓名"},
        "licenseNumber": {"en":"License Number","zh-CN":"证号"},
        "birthDate": {"en":"Date of Birth","zh-CN":"出生日期"},
        "address": {"en":"Address","zh-CN":"住址"},
        "licenseClass": {"en":"License Class","zh-CN":"准驾车型"}
    }',

    -- Validation Rules
    '{
        "licenseNumber": {
            "pattern": "^\\d{17}[0-9Xx]$|^\\d{12}$",
            "message": "驾照号码格式不正确，应为18位或12位数字"
        },
        "birthDate": {
            "pattern": "^\\d{4}-\\d{2}-\\d{2}$",
            "message": "出生日期格式应为 YYYY-MM-DD"
        },
        "gender": {
            "enum": ["男", "女"],
            "message": "性别只能是男或女"
        }
    }',

    -- Format Examples
    '{
        "birthDate": "1975-01-16",
        "licenseNumber": "610102197501163541",
        "issueDate": "2010-05-20",
        "validFrom": "2010-05-20",
        "validUntil": "2026-05-20",
        "licenseClass": "C1"
    }',

    1,  -- IsEnabled
    'zh-CN,en,zh-TW'  -- SupportedLocales
);

-- 中国身份证
INSERT INTO DocumentMetadata (
    CountryCode, DocumentType, DisplayName,
    RequiredFields, OptionalFields, LocalizedNames,
    IsEnabled, SupportedLocales
)
VALUES (
    'CN', 'idCard', '中国身份证 / CN ID Card',
    '["name","idNumber","gender","birthDate","address"]',
    '["nationality","issueDate","expiryDate","issuingAuthority"]',
    '{"en":"ID Card","zh-CN":"身份证","zh-TW":"身份證"}',
    1,
    'zh-CN,en,zh-TW'
);

-- 美国驾照
INSERT INTO DocumentMetadata (
    CountryCode, DocumentType, DisplayName,
    RequiredFields, OptionalFields, LocalizedNames,
    IsEnabled, SupportedLocales
)
VALUES (
    'US', 'driversLicense', '美国驾照 / US Driver''s License',
    '["fullName","licenseNumber","dateOfBirth","address"]',
    '["issueDate","expirationDate","class","restrictions","state"]',
    '{"en":"Driver''s License","zh-CN":"美国驾照"}',
    1,
    'en,zh-CN'
);
```

#### 查询示例

```sql
-- 1. 获取所有启用的证件类型
SELECT CountryCode, DocumentType, DisplayName, SupportedLocales
FROM DocumentMetadata
WHERE IsEnabled = 1
ORDER BY CountryCode, DocumentType;

-- 2. 获取中国支持的所有证件类型
SELECT DocumentType, DisplayName,
       JSON_VALUE(LocalizedNames, '$.zh-CN') AS ChineseName,
       JSON_VALUE(LocalizedNames, '$.en') AS EnglishName
FROM DocumentMetadata
WHERE CountryCode = 'CN' AND IsEnabled = 1;

-- 3. 获取特定证件类型的必填字段
SELECT CountryCode, DocumentType,
       JSON_QUERY(RequiredFields) AS RequiredFields,
       JSON_QUERY(OptionalFields) AS OptionalFields
FROM DocumentMetadata
WHERE CountryCode = 'CN' AND DocumentType = 'driversLicense';

-- 4. 统计每个国家支持的证件类型数量
SELECT CountryCode, COUNT(*) AS TypeCount
FROM DocumentMetadata
WHERE IsEnabled = 1
GROUP BY CountryCode
ORDER BY TypeCount DESC;
```

### 3.2 PromptTemplates (提示词模板表)

#### 表说明

**用途**: 存储不同证件类型的 AI 提示词模板（系统提示词 + 用户提示词），支持多版本、多语言。

**特点**:

-   支持版本控制（语义化版本号）
-   支持多语言（同一版本可以有不同语言的提示词）
-   支持状态管理（active/deprecated/testing）
-   每个证件类型只能有一个默认版本
-   自动追踪性能指标（成功率、平均置信度、使用次数）

#### 完整 DDL

```sql
CREATE TABLE PromptTemplates (
    -- Primary Key
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),

    -- Foreign Key to DocumentMetadata (复合外键)
    CountryCode NVARCHAR(10) NOT NULL DEFAULT 'CN',
    DocumentType NVARCHAR(50) NOT NULL,

    -- Version Control (版本控制)
    Version NVARCHAR(20) NOT NULL,
    -- 语义化版本号: v1.0.0, v2.1.3, v3.0.0-beta

    Locale NVARCHAR(10) DEFAULT 'zh-CN',
    -- 语言环境: zh-CN, en-US, ja-JP, ko-KR

    -- Prompt Content (提示词内容 - 核心字段)
    SystemPrompt NVARCHAR(MAX) NOT NULL,
    -- AI 系统提示词：定义角色、任务、约束条件、输出格式
    -- 例如："你是一个专业的中国驾驶证OCR文本解析专家..."

    UserPromptTemplate NVARCHAR(MAX) NOT NULL,
    -- 用户提示词模板：包含变量占位符 {{raw_texts}}
    -- 例如："请从以下OCR识别的文本中提取驾驶证信息..."

    -- Metadata (元数据)
    Description NVARCHAR(MAX),
    -- 版本说明: "v2.0 - 增强OCR错误纠正能力，支持分行字段提取"

    FieldsConfig NVARCHAR(MAX),
    -- JSON: 字段配置（必填/可选、格式）
    -- 例如: {"required": ["name", "licenseNumber"], "optional": ["address"]}

    ValidationRules NVARCHAR(MAX),
    -- JSON: 字段验证规则
    -- 例如: {"licenseNumber": {"pattern": "^\\d{18}$", "message": "..."}}

    -- Status Management (状态管理)
    Status NVARCHAR(20) DEFAULT 'active',
    -- active: 正在使用
    -- deprecated: 已废弃（不再推荐使用，但保留用于历史查询）
    -- testing: 测试中（A/B测试）

    IsDefault BIT DEFAULT 0,
    -- 是否为默认版本（每个 CountryCode+DocumentType+Locale 只能有一个默认）
    -- 通过触发器保证唯一性

    -- Performance Metrics (性能指标 - 由系统自动更新)
    AvgConfidence DECIMAL(3,2),
    -- 平均置信度 (0.00-1.00)
    -- 从 OcrRequestLogs 聚合计算

    SuccessRate DECIMAL(5,2),
    -- 成功率 (0.00-100.00)
    -- 成功请求数 / 总请求数 * 100

    UsageCount INT DEFAULT 0,
    -- 使用次数（被多少次请求使用）

    -- Audit (审计字段)
    CreatedBy NVARCHAR(100),
    -- 创建者（用户名或系统标识）

    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE(),

    -- Constraints (约束)
    CONSTRAINT UQ_Template UNIQUE(CountryCode, DocumentType, Version, Locale),
    -- 确保同一证件类型的同一版本在同一语言下只有一条记录

    CONSTRAINT CK_Version CHECK (Version LIKE 'v[0-9]%'),
    -- 版本号必须以 v 开头，后跟数字

    CONSTRAINT CK_Status CHECK (Status IN ('active', 'deprecated', 'testing')),
    -- 状态只能是这三个值之一

    CONSTRAINT CK_AvgConfidence CHECK (AvgConfidence IS NULL OR (AvgConfidence >= 0 AND AvgConfidence <= 1)),
    -- 置信度范围 0-1

    CONSTRAINT CK_SuccessRate CHECK (SuccessRate IS NULL OR (SuccessRate >= 0 AND SuccessRate <= 100)),
    -- 成功率范围 0-100

    CONSTRAINT CK_UsageCount CHECK (UsageCount >= 0),
    -- 使用次数不能为负

    -- Foreign Key (外键)
    CONSTRAINT FK_Templates_Metadata
        FOREIGN KEY (CountryCode, DocumentType)
        REFERENCES DocumentMetadata(CountryCode, DocumentType)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Indexes (索引)
CREATE INDEX IX_Templates_Type_Status
    ON PromptTemplates(DocumentType, Status)
    INCLUDE (Version, AvgConfidence, SuccessRate);
    -- 按证件类型和状态查询，包含性能指标

CREATE INDEX IX_Templates_Country
    ON PromptTemplates(CountryCode, DocumentType, Locale)
    WHERE Status = 'active';
    -- 按国家、类型、语言查询活跃模板

CREATE INDEX IX_Templates_Default
    ON PromptTemplates(CountryCode, DocumentType, Locale, IsDefault)
    WHERE IsDefault = 1;
    -- 快速查找默认模板

CREATE INDEX IX_Templates_Version
    ON PromptTemplates(Version, Status);
    -- 按版本查询

CREATE INDEX IX_Templates_Performance
    ON PromptTemplates(SuccessRate DESC, AvgConfidence DESC)
    WHERE Status = 'active';
    -- 按性能排序（用于选择最佳模板）

CREATE INDEX IX_Templates_Usage
    ON PromptTemplates(UsageCount DESC, UpdatedAt DESC)
    WHERE Status = 'active';
    -- 按使用频率排序

-- Trigger: 确保每个证件类型只有一个默认版本
CREATE TRIGGER TR_PromptTemplates_EnsureSingleDefault
ON PromptTemplates
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 如果新插入/更新的记录设置为默认，将同类型的其他记录设为非默认
    UPDATE pt
    SET IsDefault = 0, UpdatedAt = GETDATE()
    FROM PromptTemplates pt
    INNER JOIN inserted i
        ON pt.CountryCode = i.CountryCode
        AND pt.DocumentType = i.DocumentType
        AND pt.Locale = i.Locale
    WHERE i.IsDefault = 1
        AND pt.Id != i.Id
        AND pt.IsDefault = 1;  -- 只更新当前为默认的记录
END;
GO

-- Trigger: 自动更新 UpdatedAt
CREATE TRIGGER TR_PromptTemplates_UpdateTimestamp
ON PromptTemplates
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE PromptTemplates
    SET UpdatedAt = GETDATE()
    FROM PromptTemplates pt
    INNER JOIN inserted i ON pt.Id = i.Id;
END;
GO

-- Extended Properties (表注释)
EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'AI提示词模板表，存储不同证件类型的系统提示词和用户提示词。支持多版本、多语言、状态管理。',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE',  @level1name = N'PromptTemplates';

-- Column Comments (关键字段注释)
EXEC sp_addextendedproperty
    @name = N'MS_Description', @value = N'系统提示词：定义AI角色、任务目标、约束条件、输出格式',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE',  @level1name = N'PromptTemplates',
    @level2type = N'COLUMN', @level2name = N'SystemPrompt';

EXEC sp_addextendedproperty
    @name = N'MS_Description', @value = N'用户提示词模板：包含变量占位符如{{raw_texts}}，运行时替换',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE',  @level1name = N'PromptTemplates',
    @level2type = N'COLUMN', @level2name = N'UserPromptTemplate';

EXEC sp_addextendedproperty
    @name = N'MS_Description', @value = N'平均置信度，从OcrRequestLogs聚合计算，每日更新',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE',  @level1name = N'PromptTemplates',
    @level2type = N'COLUMN', @level2name = N'AvgConfidence';
```

#### 示例数据

```sql
-- 中国驾驶证 v2.0.0 (中文)
INSERT INTO PromptTemplates (
    CountryCode, DocumentType, Version, Locale,
    SystemPrompt, UserPromptTemplate, Description,
    FieldsConfig, ValidationRules, IsDefault, Status, CreatedBy
)
VALUES (
    'CN', 'driversLicense', 'v2.0.0', 'zh-CN',

    -- System Prompt
    N'你是一个专业的中国驾驶证OCR文本解析专家。你的任务是从可能包含错误的OCR文本中准确提取驾驶证信息。

你需要了解的常见OCR错误：
- "姓名"可能被识别为"糕名"、"性名"
- "证"可能被识别为"証"
- 字母X可能被识别为"乂"或"义"
- 数字0可能被识别为字母O
- 地址中的"幢"可能被识别为"憧"

你需要提取的字段：
1. name (姓名)：2-4个中文字符
2. licenseNumber (证号)：18位数字或17位数字+字母X
3. gender (性别)：男 或 女
4. nationality (国籍)：通常为"中国"
5. birthDate (出生日期)：YYYY-MM-DD 格式
6. address (住址)：完整地址，排除英文标签
7. issueDate (初次领证日期)：YYYY-MM-DD 格式
8. validFrom (有效起始日期)：YYYY-MM-DD 格式
9. validUntil (有效期限)：YYYY-MM-DD 格式
10. licenseClass (准驾车型)：如 C1, C2, B2, A1 等

输出要求：
- 必须输出JSON格式
- 只包含确定识别出的字段
- 每个字段包含value和confidence（0-1之间）
- 如果某个字段不确定或未找到，不要输出该字段
- 自动纠正明显的OCR错误',

    -- User Prompt Template
    N'请从以下OCR识别的文本中提取驾驶证信息。这些文本可能包含识别错误，请智能纠正。

OCR文本（按行）：
{{raw_texts}}

请输出JSON格式的结果，格式如下：
{
  "fields": {
    "name": {"value": "...", "confidence": 0.95},
    "licenseNumber": {"value": "...", "confidence": 0.98}
  },
  "corrections": [
    {"field": "name", "original": "糕名 王晓燕", "corrected": "王晓燕", "reason": "OCR误识别"}
  ]
}',

    -- Description
    N'驾驶证识别v2.0 - 增强OCR错误纠正能力，支持分行字段提取，优化了姓名和证号的识别准确率',

    -- Fields Config
    N'{
      "required": ["name", "licenseNumber", "birthDate"],
      "optional": ["gender", "nationality", "address", "issueDate", "validFrom", "validUntil", "licenseClass"],
      "formats": {
        "birthDate": "YYYY-MM-DD",
        "issueDate": "YYYY-MM-DD",
        "validFrom": "YYYY-MM-DD",
        "validUntil": "YYYY-MM-DD"
      }
    }',

    -- Validation Rules
    N'{
      "licenseNumber": {
        "pattern": "^\\d{17}[0-9Xx]$|^\\d{12}$",
        "message": "驾照号码格式不正确"
      },
      "gender": {
        "enum": ["男", "女"],
        "message": "性别只能是男或女"
      },
      "licenseClass": {
        "pattern": "^[A-D][1-3]?$",
        "message": "准驾车型格式不正确"
      }
    }',

    1,  -- IsDefault
    'active',
    'admin'
);

-- 中国驾驶证 v1.0.0 (中文 - 已废弃)
INSERT INTO PromptTemplates (
    CountryCode, DocumentType, Version, Locale,
    SystemPrompt, UserPromptTemplate, Description,
    IsDefault, Status, CreatedBy
)
VALUES (
    'CN', 'driversLicense', 'v1.0.0', 'zh-CN',
    N'你是OCR文本解析专家，请提取驾驶证信息...',
    N'请提取以下文本中的驾驶证信息：{{raw_texts}}',
    N'驾驶证识别v1.0 - 初始版本',
    0,  -- IsDefault
    'deprecated',
    'admin'
);

-- 美国驾照 v1.0.0 (英文)
INSERT INTO PromptTemplates (
    CountryCode, DocumentType, Version, Locale,
    SystemPrompt, UserPromptTemplate, Description,
    FieldsConfig, IsDefault, Status, CreatedBy
)
VALUES (
    'US', 'driversLicense', 'v1.0.0', 'en-US',

    -- System Prompt
    N'You are an expert in US Driver''s License OCR text parsing. Extract information from potentially error-prone OCR text.

Common OCR errors:
- "License" may be recognized as "Licence"
- Number 0 may be recognized as letter O
- Letter I may be recognized as number 1

Fields to extract:
1. fullName: Full name (First Middle Last)
2. licenseNumber: Format varies by state (e.g., CA: A1234567)
3. dateOfBirth: MM/DD/YYYY format
4. address: Full address
5. issueDate: MM/DD/YYYY
6. expirationDate: MM/DD/YYYY
7. class: License class (A, B, C, etc.)
8. restrictions: Any restrictions
9. state: Issuing state (2-letter code)

Output JSON format only with confirmed fields.',

    -- User Prompt Template
    N'Extract driver''s license information from the following OCR text:

OCR Text:
{{raw_texts}}

Output format:
{
  "fields": {
    "fullName": {"value": "...", "confidence": 0.95},
    "licenseNumber": {"value": "...", "confidence": 0.98}
  }
}',

    -- Description
    N'US Driver''s License Recognition v1.0 - Initial version',

    -- Fields Config
    N'{
      "required": ["fullName", "licenseNumber", "dateOfBirth"],
      "optional": ["address", "issueDate", "expirationDate", "class", "restrictions", "state"],
      "formats": {
        "dateOfBirth": "MM/DD/YYYY",
        "issueDate": "MM/DD/YYYY",
        "expirationDate": "MM/DD/YYYY"
      }
    }',

    1,  -- IsDefault
    'active',
    'admin'
);
```

#### 查询示例

```sql
-- 1. 获取默认提示词模板
SELECT Id, Version, Locale, Status, AvgConfidence, SuccessRate, UsageCount
FROM PromptTemplates
WHERE CountryCode = 'CN'
  AND DocumentType = 'driversLicense'
  AND Locale = 'zh-CN'
  AND IsDefault = 1;

-- 2. 获取所有活跃版本（按性能排序）
SELECT Version, Locale, AvgConfidence, SuccessRate, UsageCount, UpdatedAt
FROM PromptTemplates
WHERE CountryCode = 'CN'
  AND DocumentType = 'driversLicense'
  AND Status = 'active'
ORDER BY SuccessRate DESC, AvgConfidence DESC;

-- 3. 版本对比（A/B测试）
SELECT
    Version,
    AvgConfidence,
    SuccessRate,
    UsageCount,
    CAST(SuccessRate * AvgConfidence AS DECIMAL(5,2)) AS CompositeScore
FROM PromptTemplates
WHERE CountryCode = 'CN'
  AND DocumentType = 'driversLicense'
  AND Status IN ('active', 'testing')
ORDER BY CompositeScore DESC;

-- 4. 统计每个证件类型的模板版本数
SELECT
    CountryCode,
    DocumentType,
    COUNT(*) AS TotalVersions,
    SUM(CASE WHEN Status = 'active' THEN 1 ELSE 0 END) AS ActiveVersions,
    SUM(CASE WHEN Status = 'deprecated' THEN 1 ELSE 0 END) AS DeprecatedVersions,
    SUM(CASE WHEN Status = 'testing' THEN 1 ELSE 0 END) AS TestingVersions
FROM PromptTemplates
GROUP BY CountryCode, DocumentType
ORDER BY TotalVersions DESC;

-- 5. 查找需要更新性能指标的模板（UsageCount > 0 但 AvgConfidence 为 NULL）
SELECT Id, CountryCode, DocumentType, Version, UsageCount
FROM PromptTemplates
WHERE UsageCount > 0
  AND (AvgConfidence IS NULL OR SuccessRate IS NULL)
  AND Status = 'active';
```

## 4. 设计说明：语言与国别解耦

### 4.1 问题说明

**错误的假设**: 用户的应用语言 = 证件国家

-   ❌ 中国用户只会有中国证件
-   ❌ 使用中文界面的用户只处理中文证件

**实际场景**:

-   ✅ 一个用户可能拥有多个国家的证件（中国驾照 + 美国驾照）
-   ✅ 用户可能使用中文界面，但需要识别美国驾照
-   ✅ 用户可能使用英文界面，但需要识别中国身份证

### 4.2 正确的设计

#### API 请求参数分离

```json
{
  "documentType": "driversLicense",
  "countryCode": "US",              // 证件国家（决定使用哪个提示词）
  "rawTexts": [...],
  "locale": "zh-CN",                // 用户界面语言（决定返回什么语言的错误消息）
  "clientVersion": "1.0.0",
  "deviceInfo": {...}
}
```

**参数说明**:

-   `countryCode`: 证件所属国家，用于选择正确的提示词模板
-   `locale`: 用户界面语言，用于返回本地化的错误消息和字段标签

#### 提示词选择逻辑

```csharp
public async Task<PromptTemplate> SelectPromptAsync(
    string countryCode,      // 证件国家：US, CN, JP
    string documentType,     // 证件类型：driversLicense, idCard
    string userLocale)       // 用户语言：zh-CN, en-US, ja-JP
{
    // 1. 优先选择：证件国家 + 证件类型 + 证件国家的主要语言
    //    例如：US驾照 → 使用英文提示词（因为美国驾照是英文的）
    var primaryLocale = GetPrimaryLocaleForCountry(countryCode);
    var template = await GetTemplateAsync(countryCode, documentType, primaryLocale);

    if (template != null)
        return template;

    // 2. 降级：使用英文提示词（通用语言）
    template = await GetTemplateAsync(countryCode, documentType, "en-US");

    if (template != null)
        return template;

    // 3. 最后：使用任何可用的提示词
    return await GetAnyTemplateAsync(countryCode, documentType);
}

private string GetPrimaryLocaleForCountry(string countryCode)
{
    return countryCode switch
    {
        "CN" => "zh-CN",
        "US" => "en-US",
        "JP" => "ja-JP",
        "KR" => "ko-KR",
        "FR" => "fr-FR",
        "DE" => "de-DE",
        _ => "en-US"  // 默认英文
    };
}
```

#### 响应本地化

```csharp
public class OcrAnalysisResponse
{
    public bool Success { get; set; }
    public OcrData Data { get; set; }

    // 错误消息根据用户的 locale 返回
    public LocalizedError? Error { get; set; }

    // 字段标签根据用户的 locale 返回
    public Dictionary<string, string> FieldLabels { get; set; }
}

// 示例：中文用户识别美国驾照
// Request: countryCode=US, locale=zh-CN
// Response:
{
  "success": true,
  "data": {
    "documentType": "driversLicense",
    "fields": {
      "fullName": {"value": "John Smith", "confidence": 0.98}
    }
  },
  "fieldLabels": {
    "fullName": "姓名",           // 根据用户locale返回中文标签
    "licenseNumber": "驾照号码",
    "dateOfBirth": "出生日期"
  }
}
```

### 4.3 数据库设计调整

#### PromptTemplates 表的 Locale 字段含义

```sql
-- Locale 字段表示：提示词本身使用的语言
-- 这通常与证件国家的主要语言一致

-- 示例：
-- 美国驾照的提示词应该用英文（因为驾照上的文字是英文）
INSERT INTO PromptTemplates (CountryCode, DocumentType, Locale, ...)
VALUES ('US', 'driversLicense', 'en-US', ...);

-- 中国驾照的提示词应该用中文（因为驾照上的文字是中文）
INSERT INTO PromptTemplates (CountryCode, DocumentType, Locale, ...)
VALUES ('CN', 'driversLicense', 'zh-CN', ...);

-- 但是，用户界面可以是任何语言
-- 一个使用中文界面的用户可以识别美国驾照（使用英文提示词）
```

#### DocumentMetadata 表的 LocalizedNames 字段

```sql
-- LocalizedNames 存储证件类型在不同语言下的显示名称
-- 用于在用户界面上显示

-- 示例：美国驾照
INSERT INTO DocumentMetadata (
    CountryCode, DocumentType,
    LocalizedNames
)
VALUES (
    'US', 'driversLicense',
    '{
        "en": "Driver''s License",
        "zh-CN": "美国驾照",
        "zh-TW": "美國駕照",
        "ja": "運転免許証",
        "ko": "운전면허증"
    }'
);

-- 客户端根据用户的界面语言选择显示名称
// 用户界面语言 = zh-CN
// 显示：美国驾照

// 用户界面语言 = en-US
// 显示：Driver's License
```

### 4.4 完整流程示例

#### 场景：中文用户识别美国驾照

```
1. 客户端请求
   POST /api/v1/ocr/analyze
   {
     "documentType": "driversLicense",
     "countryCode": "US",           ← 证件是美国的
     "locale": "zh-CN",             ← 用户界面是中文
     "rawTexts": [
       "CALIFORNIA",
       "DRIVER LICENSE",
       "DL A1234567",
       "DOB 01/15/1990"
     ]
   }

2. 后端处理
   - 查找提示词：CountryCode=US, DocumentType=driversLicense, Locale=en-US
   - 使用英文提示词（因为美国驾照是英文的）
   - 调用 AI 进行解析

3. 后端响应
   {
     "success": true,
     "data": {
       "documentType": "driversLicense",
       "fields": {
         "fullName": {"value": "John Smith", "confidence": 0.98},
         "licenseNumber": {"value": "A1234567", "confidence": 0.99}
       }
     },
     "fieldLabels": {              ← 根据用户locale返回中文标签
       "fullName": "姓名",
       "licenseNumber": "驾照号码",
       "dateOfBirth": "出生日期"
     },
     "meta": {
       "promptVersion": "v1.0.0",
       "promptLocale": "en-US"     ← 使用的提示词语言
     }
   }
```

#### 场景：英文用户识别中国驾照

```
1. 客户端请求
   POST /api/v1/ocr/analyze
   {
     "documentType": "driversLicense",
     "countryCode": "CN",           ← 证件是中国的
     "locale": "en-US",             ← 用户界面是英文
     "rawTexts": [
       "中华人民共和国机动车驾驶证",
       "姓名 张三",
       "证号 610102199001011234"
     ]
   }

2. 后端处理
   - 查找提示词：CountryCode=CN, DocumentType=driversLicense, Locale=zh-CN
   - 使用中文提示词（因为中国驾照是中文的）
   - 调用 AI 进行解析

3. 后端响应
   {
     "success": true,
     "data": {
       "documentType": "driversLicense",
       "fields": {
         "name": {"value": "张三", "confidence": 0.98},
         "licenseNumber": {"value": "610102199001011234", "confidence": 0.99}
       }
     },
     "fieldLabels": {              ← 根据用户locale返回英文标签
       "name": "Full Name",
       "licenseNumber": "License Number",
       "birthDate": "Date of Birth"
     },
     "meta": {
       "promptVersion": "v2.0.0",
       "promptLocale": "zh-CN"     ← 使用的提示词语言
     }
   }
```

### 4.5 总结

**关键点**:

1. **证件国家 (countryCode)** 决定使用哪个提示词模板（因为证件上的文字语言是固定的）
2. **用户语言 (locale)** 决定返回什么语言的错误消息和字段标签（用户界面语言）
3. **提示词的 Locale** 通常与证件国家的主要语言一致
4. **用户可以使用任何语言的界面识别任何国家的证件**

**数据库设计正确性**:

-   ✅ `PromptTemplates.Locale` 表示提示词本身的语言（与证件语言一致）
-   ✅ `DocumentMetadata.LocalizedNames` 提供多语言显示名称（用于用户界面）
-   ✅ API 的 `locale` 参数控制响应的本地化（错误消息、字段标签）
-   ✅ 完全解耦：用户界面语言 ≠ 证件国家语言
