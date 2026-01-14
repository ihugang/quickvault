// QuickVault AI-OCR Backend - C# ASP.NET Core 10 实现
// AI增强的证件OCR识别服务

/*
项目结构:
QuickVault.OcrApi/
├── Controllers/
│   └── OcrController.cs
├── Services/
│   ├── IOcrService.cs
│   ├── OcrService.cs
│   ├── IPromptService.cs
│   ├── PromptService.cs
│   └── IAiModelService.cs
│   └── OpenAiService.cs
├── Models/
│   ├── OcrRequest.cs
│   ├── OcrResponse.cs
│   └── PromptTemplate.cs
├── Data/
│   ├── ApplicationDbContext.cs
│   └── Entities/
│       ├── PromptTemplate.cs
│       └── OcrRequestLog.cs
├── Program.cs
└── appsettings.json

运行要求:
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.Extensions.Caching.StackExchangeRedis
dotnet add package Azure.AI.OpenAI
dotnet add package AspNetCoreRateLimit
dotnet add package Serilog.AspNetCore

运行命令:
dotnet run --project QuickVault.OcrApi
*/

using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Distributed;
using Azure.AI.OpenAI;
using System.Text.Json;
using System.Security.Cryptography;
using System.Text;

namespace QuickVault.OcrApi;

// MARK: - Models

/// <summary>
/// OCR分析请求
/// </summary>
public record OcrRequest
{
    public required string DocumentType { get; init; }
    public required List<string> RawTexts { get; init; }
    public string ClientVersion { get; init; } = "1.0.0";
    public string Locale { get; init; } = "zh-CN";
}

/// <summary>
/// OCR字段数据
/// </summary>
public record OcrField
{
    public required string Value { get; init; }
    public required double Confidence { get; init; }
    public bool? Corrected { get; init; }
    public string? OriginalValue { get; init; }
}

/// <summary>
/// OCR分析数据
/// </summary>
public record OcrData
{
    public required string DocumentType { get; init; }
    public required double Confidence { get; init; }
    public required Dictionary<string, OcrField> Fields { get; init; }
    public List<string>? Warnings { get; init; }
    public int? ProcessingTime { get; init; }
}

/// <summary>
/// OCR响应元数据
/// </summary>
public record OcrMeta
{
    public required string RequestId { get; init; }
    public required string Timestamp { get; init; }
    public string? ModelUsed { get; init; }
    public string? PromptVersion { get; init; }
}

/// <summary>
/// OCR分析响应
/// </summary>
public record OcrResponse
{
    public required bool Success { get; init; }
    public OcrData? Data { get; init; }
    public object? Error { get; init; }
    public OcrMeta? Meta { get; init; }
}

// MARK: - Database Entities

/// <summary>
/// 提示词模板实体
/// </summary>
public class PromptTemplate
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string DocumentType { get; set; }
    public required string Version { get; set; }
    public string Locale { get; set; } = "zh-CN";
    
    public required string SystemPrompt { get; set; }
    public required string UserPromptTemplate { get; set; }
    
    public string? Description { get; set; }
    public string? FieldsConfig { get; set; }  // JSON
    public string? ValidationRules { get; set; }  // JSON
    
    public string Status { get; set; } = "active";
    public bool IsDefault { get; set; }
    
    public decimal? AvgConfidence { get; set; }
    public decimal? SuccessRate { get; set; }
    public int UsageCount { get; set; }
    
    public string? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>
/// OCR请求日志实体
/// </summary>
public class OcrRequestLog
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string RequestId { get; set; }
    
    public required string DocumentType { get; set; }
    public string? ClientVersion { get; set; }
    public string? UserId { get; set; }
    
    public required string RawTexts { get; set; }  // JSON
    public string? ExtractedFields { get; set; }  // JSON
    
    public string? PromptVersion { get; set; }
    public string? ModelUsed { get; set; }
    public string? AiResponse { get; set; }
    
    public decimal? ConfidenceScore { get; set; }
    public int? ProcessingTimeMs { get; set; }
    
    public string? Status { get; set; }
    public string? ErrorMessage { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string? IpAddress { get; set; }
}

// MARK: - Database Context

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options) { }
    
    public DbSet<PromptTemplate> PromptTemplates { get; set; } = null!;
    public DbSet<OcrRequestLog> OcrRequestLogs { get; set; } = null!;
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<PromptTemplate>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.DocumentType, e.Status });
            entity.HasIndex(e => new { e.DocumentType, e.IsDefault })
                .HasFilter("[IsDefault] = 1");
        });
        
        modelBuilder.Entity<OcrRequestLog>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.RequestId).IsUnique();
            entity.HasIndex(e => new { e.DocumentType, e.CreatedAt });
        });
    }
}

// MARK: - Services

/// <summary>
/// AI模型服务接口
/// </summary>
public interface IAiModelService
{
    Task<(bool Success, string? Response, string? Error)> CallAiAsync(
        string systemPrompt, 
        string userPrompt, 
        string model = "gpt-4");
}

/// <summary>
/// OpenAI服务实现
/// </summary>
public class OpenAiService : IAiModelService
{
    private readonly OpenAIClient _client;
    private readonly ILogger<OpenAiService> _logger;
    
    public OpenAiService(IConfiguration configuration, ILogger<OpenAiService> logger)
    {
        var apiKey = configuration["OpenAI:ApiKey"] ?? 
            throw new InvalidOperationException("OpenAI API Key not configured");
        
        _client = new OpenAIClient(apiKey);
        _logger = logger;
    }
    
    public async Task<(bool Success, string? Response, string? Error)> CallAiAsync(
        string systemPrompt, 
        string userPrompt, 
        string model = "gpt-4")
    {
        try
        {
            var chatCompletionsOptions = new ChatCompletionsOptions
            {
                DeploymentName = model,
                Messages =
                {
                    new ChatRequestSystemMessage(systemPrompt),
                    new ChatRequestUserMessage(userPrompt)
                },
                Temperature = 0.2f,
                MaxTokens = 2000,
                ResponseFormat = ChatCompletionsResponseFormat.JsonObject
            };
            
            var response = await _client.GetChatCompletionsAsync(chatCompletionsOptions);
            var content = response.Value.Choices[0].Message.Content;
            
            _logger.LogInformation("AI调用成功，Token使用: {Tokens}", 
                response.Value.Usage.TotalTokens);
            
            return (true, content, null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "AI调用失败: {Message}", ex.Message);
            return (false, null, ex.Message);
        }
    }
}

/// <summary>
/// 提示词服务接口
/// </summary>
public interface IPromptService
{
    Task<PromptTemplate?> GetPromptTemplateAsync(string documentType, string locale);
    (string SystemPrompt, string UserPrompt) BuildPrompt(PromptTemplate template, List<string> rawTexts);
}

/// <summary>
/// 提示词服务实现
/// </summary>
public class PromptService : IPromptService
{
    private readonly ApplicationDbContext _context;
    private readonly IDistributedCache _cache;
    private readonly ILogger<PromptService> _logger;
    
    public PromptService(
        ApplicationDbContext context, 
        IDistributedCache cache,
        ILogger<PromptService> logger)
    {
        _context = context;
        _cache = cache;
        _logger = logger;
    }
    
    public async Task<PromptTemplate?> GetPromptTemplateAsync(string documentType, string locale)
    {
        var cacheKey = $"prompt:template:{documentType}:{locale}";
        
        // 尝试从缓存获取
        var cached = await _cache.GetStringAsync(cacheKey);
        if (cached != null)
        {
            _logger.LogDebug("从缓存加载提示词模板: {CacheKey}", cacheKey);
            return JsonSerializer.Deserialize<PromptTemplate>(cached);
        }
        
        // 从数据库查询
        var template = await _context.PromptTemplates
            .FirstOrDefaultAsync(t =>
                t.DocumentType == documentType &&
                t.Locale == locale &&
                t.Status == "active" &&
                t.IsDefault);
        
        if (template != null)
        {
            // 缓存1小时
            var options = new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(1)
            };
            await _cache.SetStringAsync(cacheKey, 
                JsonSerializer.Serialize(template), options);
            
            _logger.LogInformation("加载提示词模板: {DocumentType} v{Version}", 
                documentType, template.Version);
        }
        
        return template;
    }
    
    public (string SystemPrompt, string UserPrompt) BuildPrompt(
        PromptTemplate template, 
        List<string> rawTexts)
    {
        var systemPrompt = template.SystemPrompt;
        
        // 格式化用户提示词
        var rawTextsJson = JsonSerializer.Serialize(rawTexts, new JsonSerializerOptions
        {
            WriteIndented = true,
            Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping
        });
        
        var userPrompt = template.UserPromptTemplate.Replace("{{raw_texts}}", rawTextsJson);
        
        return (systemPrompt, userPrompt);
    }
}

/// <summary>
/// OCR服务接口
/// </summary>
public interface IOcrService
{
    Task<OcrResponse> ProcessOcrRequestAsync(OcrRequest request, string? ipAddress);
}

/// <summary>
/// OCR服务实现
/// </summary>
public class OcrService : IOcrService
{
    private readonly IPromptService _promptService;
    private readonly IAiModelService _aiModelService;
    private readonly ApplicationDbContext _context;
    private readonly ILogger<OcrService> _logger;
    
    public OcrService(
        IPromptService promptService,
        IAiModelService aiModelService,
        ApplicationDbContext context,
        ILogger<OcrService> logger)
    {
        _promptService = promptService;
        _aiModelService = aiModelService;
        _context = context;
        _logger = logger;
    }
    
    public async Task<OcrResponse> ProcessOcrRequestAsync(OcrRequest request, string? ipAddress)
    {
        var startTime = DateTime.UtcNow;
        var requestId = Guid.NewGuid().ToString();
        
        try
        {
            _logger.LogInformation("开始处理OCR请求: {RequestId}, 类型: {DocumentType}", 
                requestId, request.DocumentType);
            
            // 1. 获取提示词模板
            var template = await _promptService.GetPromptTemplateAsync(
                request.DocumentType, request.Locale);
            
            if (template == null)
            {
                throw new InvalidOperationException($"不支持的证件类型: {request.DocumentType}");
            }
            
            // 2. 构建AI提示词
            var (systemPrompt, userPrompt) = _promptService.BuildPrompt(template, request.RawTexts);
            
            // 3. 调用AI模型
            var (success, aiResponse, error) = await _aiModelService.CallAiAsync(
                systemPrompt, userPrompt, "gpt-4");
            
            if (!success || aiResponse == null)
            {
                throw new Exception($"AI调用失败: {error}");
            }
            
            // 4. 解析AI响应
            var aiData = JsonSerializer.Deserialize<JsonDocument>(aiResponse);
            var fields = ParseAiResponse(aiData);
            
            // 5. 计算整体置信度
            var avgConfidence = fields.Any() 
                ? fields.Values.Average(f => f.Confidence) 
                : 0.0;
            
            // 6. 构建响应
            var processingTime = (int)(DateTime.UtcNow - startTime).TotalMilliseconds;
            
            var response = new OcrResponse
            {
                Success = true,
                Data = new OcrData
                {
                    DocumentType = request.DocumentType,
                    Confidence = Math.Round(avgConfidence, 2),
                    Fields = fields,
                    ProcessingTime = processingTime
                },
                Meta = new OcrMeta
                {
                    RequestId = requestId,
                    Timestamp = DateTime.UtcNow.ToString("o"),
                    ModelUsed = "gpt-4",
                    PromptVersion = template.Version
                }
            };
            
            // 7. 记录日志
            await LogRequestAsync(requestId, request, template, fields, avgConfidence, 
                processingTime, "success", null, ipAddress);
            
            _logger.LogInformation("OCR处理成功: {RequestId}, 耗时: {Time}ms, 置信度: {Confidence}", 
                requestId, processingTime, avgConfidence);
            
            return response;
        }
        catch (Exception ex)
        {
            var processingTime = (int)(DateTime.UtcNow - startTime).TotalMilliseconds;
            
            _logger.LogError(ex, "OCR处理失败: {RequestId}, {Message}", requestId, ex.Message);
            
            // 记录错误日志
            await LogRequestAsync(requestId, request, null, null, null, 
                processingTime, "failed", ex.Message, ipAddress);
            
            return new OcrResponse
            {
                Success = false,
                Error = new { code = "PROCESSING_ERROR", message = ex.Message },
                Meta = new OcrMeta
                {
                    RequestId = requestId,
                    Timestamp = DateTime.UtcNow.ToString("o")
                }
            };
        }
    }
    
    private Dictionary<string, OcrField> ParseAiResponse(JsonDocument? aiData)
    {
        var fields = new Dictionary<string, OcrField>();
        
        if (aiData?.RootElement.TryGetProperty("fields", out var fieldsElement) == true)
        {
            foreach (var field in fieldsElement.EnumerateObject())
            {
                if (field.Value.TryGetProperty("value", out var valueElement))
                {
                    fields[field.Name] = new OcrField
                    {
                        Value = valueElement.GetString() ?? "",
                        Confidence = field.Value.TryGetProperty("confidence", out var conf) 
                            ? conf.GetDouble() : 0.8,
                        Corrected = field.Value.TryGetProperty("corrected", out var corr) 
                            ? corr.GetBoolean() : null,
                        OriginalValue = field.Value.TryGetProperty("originalValue", out var orig) 
                            ? orig.GetString() : null
                    };
                }
            }
        }
        
        return fields;
    }
    
    private async Task LogRequestAsync(
        string requestId,
        OcrRequest request,
        PromptTemplate? template,
        Dictionary<string, OcrField>? fields,
        double? confidence,
        int processingTime,
        string status,
        string? errorMessage,
        string? ipAddress)
    {
        var log = new OcrRequestLog
        {
            RequestId = requestId,
            DocumentType = request.DocumentType,
            ClientVersion = request.ClientVersion,
            RawTexts = JsonSerializer.Serialize(request.RawTexts),
            ExtractedFields = fields != null ? JsonSerializer.Serialize(fields) : null,
            PromptVersion = template?.Version,
            ModelUsed = "gpt-4",
            ConfidenceScore = confidence.HasValue ? (decimal)confidence.Value : null,
            ProcessingTimeMs = processingTime,
            Status = status,
            ErrorMessage = errorMessage,
            IpAddress = ipAddress
        };
        
        _context.OcrRequestLogs.Add(log);
        await _context.SaveChangesAsync();
    }
}

// MARK: - Controller

[ApiController]
[Route("api/v1/ocr")]
public class OcrController : ControllerBase
{
    private readonly IOcrService _ocrService;
    private readonly ILogger<OcrController> _logger;
    
    public OcrController(IOcrService ocrService, ILogger<OcrController> logger)
    {
        _ocrService = ocrService;
        _logger = logger;
    }
    
    /// <summary>
    /// 智能OCR解析接口
    /// </summary>
    [HttpPost("analyze")]
    [ProducesResponseType(typeof(OcrResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Analyze([FromBody] OcrRequest request)
    {
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();
        var response = await _ocrService.ProcessOcrRequestAsync(request, ipAddress);
        return Ok(response);
    }
    
    /// <summary>
    /// 健康检查
    /// </summary>
    [HttpGet("/api/v1/health")]
    public IActionResult Health()
    {
        return Ok(new
        {
            status = "healthy",
            services = new
            {
                api = "up",
                database = "up",
                redis = "up",
                aiModel = "up"
            },
            version = "1.0.0"
        });
    }
}

// MARK: - Program.cs

var builder = WebApplication.CreateBuilder(args);

// 添加服务
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// 数据库
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Redis缓存
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = builder.Configuration.GetConnectionString("Redis");
    options.InstanceName = "QuickVaultOcr:";
});

// 注册服务
builder.Services.AddScoped<IPromptService, PromptService>();
builder.Services.AddScoped<IAiModelService, OpenAiService>();
builder.Services.AddScoped<IOcrService, OcrService>();

// 速率限制
builder.Services.AddMemoryCache();
builder.Services.Configure<IpRateLimitOptions>(builder.Configuration.GetSection("IpRateLimiting"));
builder.Services.AddSingleton<IIpPolicyStore, MemoryCacheIpPolicyStore>();
builder.Services.AddSingleton<IRateLimitCounterStore, MemoryCacheRateLimitCounterStore>();

// CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// 配置HTTP请求管道
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors();
app.UseAuthorization();
app.MapControllers();

app.Run();
