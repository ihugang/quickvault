# Design Document: AI-Enhanced OCR Backend / 设计文档：AI 增强 OCR 后端

## Overview / 概述

The AI-Enhanced OCR Backend is built with ASP.NET Core 10 (C#) and follows a clean architecture pattern with clear separation of concerns. The system uses LLMs to intelligently parse OCR text and extract structured document fields without requiring image uploads.

AI 增强 OCR 后端使用 ASP.NET Core 10 (C#) 构建，遵循清晰的架构模式，关注点分离明确。系统使用 LLM 智能解析 OCR 文本并提取结构化文档字段，无需上传图片。

**Core Principle / 核心原则**: Client performs OCR locally using Vision Framework, backend only processes text data. No images are uploaded or stored, ensuring maximum privacy.

**核心原则**：客户端使用 Vision Framework 本地执行 OCR，后端仅处理文本数据。不上传或存储图片，确保最大隐私保护。

## Architecture / 架构

### Overall Architecture / 整体架构

```
┌─────────────────┐
│  iOS Client     │
│  (QuickVault)   │
│  - Vision OCR   │
└────────┬────────┘
         │ HTTPS (OCR Text Only)
         ▼
┌─────────────────────────────────────────┐
│     API Gateway (Rate Limiting)         │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│     AI-Enhanced OCR Text Parser         │
│  ┌──────────────────────────────────┐   │
│  │  1. Text Preprocessing           │   │
│  │  2. AI Analysis (LLM)            │   │
│  │  3. Result Post-processing       │   │
│  │  4. Field Validation             │   │
│  └──────────────────────────────────┘   │
└────────┬────────────────────────────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌─────────┐ ┌──────────────┐
│ Prompt  │ │   AI Model   │
│ Manager │ │   Service    │
│ (DB)    │ │  (OpenAI/    │
└─────────┘ │   Claude)    │
            └──────────────┘
```

### Layer Structure / 层次结构

```
┌─────────────────────────────────────┐
│         API Layer                   │  Controllers, Middleware
│  (ASP.NET Core Web API)             │
├─────────────────────────────────────┤
│         Application Layer           │  Services, DTOs
│  (Business Logic)                   │
├─────────────────────────────────────┤
│         Domain Layer                │  Entities, Interfaces
│  (Core Business Rules)              │
├─────────────────────────────────────┤
│         Infrastructure Layer        │  Data Access, External APIs
│  (EF Core, Redis, AI Clients)      │
└─────────────────────────────────────┘
```

### Technology Stack / 技术栈

-   **Framework**: ASP.NET Core 10 (C# 13)
-   **Database**: MS SQL Server 2022
-   **Cache**: Redis 7+
-   **ORM**: Entity Framework Core 10
-   **AI Integration**: Azure OpenAI SDK, Anthropic SDK
-   **Authentication**: JWT Bearer + API Key with HMAC signatures
-   **Rate Limiting**: AspNetCoreRateLimit
-   **Logging**: Serilog with structured logging
-   **Monitoring**: Application Insights / Prometheus
-   **Deployment**: Docker + Azure App Service / AWS ECS

## API Design / API 设计

### Core Endpoints / 核心端点

#### 1. Analyze OCR Text / 分析 OCR 文本

```http
POST /api/v1/ocr/analyze
Content-Type: application/json
Authorization: Bearer <api-key>

Request:
{
  "documentType": "driversLicense",
  "countryCode": "CN",
  "rawTexts": [
    "中华人民共和国机动车驾驶证",
    "证号 61010219750116354X",
    "糕名 王晓燕",
    "性别 女",
    "出生日期 1975-01-16"
  ],
  "clientVersion": "1.0.0",
  "locale": "zh-CN",
  "deviceInfo": {
    "osType": "iOS",
    "osVersion": "17.2",
    "appVersion": "1.0.0",
    "deviceModel": "iPhone 15 Pro"
  }
}

Response (200 OK):
{
  "success": true,
  "data": {
    "documentType": "driversLicense",
    "confidence": 0.95,
    "fields": {
      "name": {
        "value": "王晓燕",
        "confidence": 0.98,
        "corrected": true,
        "originalValue": "糕名 王晓燕"
      },
      "licenseNumber": {
        "value": "61010219750116354X",
        "confidence": 0.99,
        "corrected": false
      },
      "birthDate": {
        "value": "1975-01-16",
        "confidence": 0.97,
        "corrected": false
      },
      "gender": {
        "value": "女",
        "confidence": 0.99,
        "corrected": false
      }
    },
    "warnings": ["初次领证日期未识别，请手动补充"],
    "processingTime": 1234
  },
  "meta": {
    "requestId": "uuid-xxx-xxx",
    "timestamp": "2026-01-14T10:30:00Z",
    "modelUsed": "gpt-4-turbo",
    "promptVersion": "v2.3.1"
  }
}
```

#### 2. Batch Analysis / 批量分析

```http
POST /api/v1/ocr/batch-analyze

Request:
{
  "documents": [
    {
      "id": "doc-1",
      "documentType": "idCard",
      "countryCode": "CN",
      "rawTexts": [...]
    },
    {
      "id": "doc-2",
      "documentType": "passport",
      "countryCode": "CN",
      "rawTexts": [...]
    }
  ]
}

Response:
{
  "success": true,
  "results": [
    {
      "id": "doc-1",
      "status": "success",
      "data": {...}
    },
    {
      "id": "doc-2",
      "status": "failed",
      "error": {...}
    }
  ]
}
```

#### 3. Get Supported Document Types / 获取支持的证件类型

```http
GET /api/v1/ocr/document-types?countryCode=CN

Response:
{
  "success": true,
  "data": {
    "types": [
      {
        "id": "idCard",
        "countryCode": "CN",
        "name": "身份证 / ID Card",
        "fields": ["name", "idNumber", "gender", "birthDate", "address"],
        "currentPromptVersion": "v2.1.0"
      },
      {
        "id": "driversLicense",
        "countryCode": "CN",
        "name": "驾驶证 / Driver's License",
        "fields": ["name", "licenseNumber", "gender", "birthDate"],
        "currentPromptVersion": "v1.8.3"
      }
    ]
  }
}
```

#### 4. Health Check / 健康检查

```http
GET /api/v1/health

Response:
{
  "status": "healthy",
  "services": {
    "api": "up",
    "database": "up",
    "aiModel": "up",
    "redis": "up"
  },
  "version": "1.0.0"
}
```

## Components and Interfaces / 组件和接口

### Core Services / 核心服务

#### IOcrAnalysisService

```csharp
public interface IOcrAnalysisService
{
    Task<OcrAnalysisResult> AnalyzeAsync(
        OcrAnalysisRequest request,
        CancellationToken cancellationToken = default);

    Task<BatchOcrAnalysisResult> AnalyzeBatchAsync(
        BatchOcrAnalysisRequest request,
        CancellationToken cancellationToken = default);
}
```

#### IPromptTemplateService

```csharp
public interface IPromptTemplateService
{
    Task<PromptTemplate> GetTemplateAsync(
        string countryCode,
        string documentType,
        string? locale = null);

    Task<PromptTemplate> CreateTemplateAsync(PromptTemplate template);
    Task<PromptTemplate> UpdateTemplateAsync(Guid id, PromptTemplate template);
    Task<bool> DeleteTemplateAsync(Guid id);
    Task<IEnumerable<PromptTemplate>> GetAllTemplatesAsync(string? documentType = null);
}
```

#### IAiModelService

```csharp
public interface IAiModelService
{
    Task<AiResponse> GenerateAsync(
        AiRequest request,
        CancellationToken cancellationToken = default);

    Task<bool> IsAvailableAsync(string modelName);
    Task<AiModelConfig> GetModelConfigAsync(string modelName);
}
```

#### ILogCleanupService

```csharp
public interface ILogCleanupService
{
    Task<int> CleanupOldLogsAsync(int retentionDays = 7);
    Task ScheduleDailyCleanupAsync(TimeSpan executionTime);
}
```
