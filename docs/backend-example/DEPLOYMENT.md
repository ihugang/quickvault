# QuickVault AI-OCR 后端部署指南

## 快速开始

### 1. 环境要求

```bash
Python 3.11+
PostgreSQL 14+
Redis 7+
```

### 2. 安装依赖

```bash
cd docs/backend-example
pip install -r requirements.txt
```

### 3. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 文件，填入实际配置
```

### 4. 初始化数据库

```bash
# 创建数据库
createdb quickvault_ocr

# 运行迁移（自动创建表）
python main.py
```

### 5. 启动服务

```bash
# 开发模式
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# 生产模式
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

### 6. 验证服务

```bash
# 健康检查
curl http://localhost:8000/api/v1/health

# 查看API文档
open http://localhost:8000/docs
```

---

## Docker部署

### 1. 构建镜像

```bash
docker build -t quickvault-ocr-api:latest .
```

### 2. Docker Compose启动

```bash
docker-compose up -d
```

### 3. 查看日志

```bash
docker-compose logs -f api
```

---

## 生产环境部署

### 方案1: AWS ECS + RDS + ElastiCache

```yaml
架构:
- ECS Fargate: 运行API服务
- RDS PostgreSQL: 数据库
- ElastiCache Redis: 缓存
- ALB: 负载均衡
- CloudWatch: 监控日志
```

### 方案2: Kubernetes

```bash
# 部署到K8s集群
kubectl apply -f k8s/
```

### 方案3: Serverless (AWS Lambda)

```bash
# 使用Mangum适配器
pip install mangum
# 部署到Lambda
serverless deploy
```

---

## 性能优化

### 1. 数据库索引

```sql
-- 提示词模板查询优化
CREATE INDEX idx_templates_type_status ON prompt_templates(document_type, status);
CREATE INDEX idx_templates_default ON prompt_templates(document_type, is_default) WHERE is_default = true;

-- 日志查询优化
CREATE INDEX idx_logs_type_created ON ocr_request_logs(document_type, created_at);
```

### 2. Redis缓存策略

```python
# 提示词模板缓存 - 1小时
# OCR结果缓存 - 10分钟
# 证件类型配置缓存 - 24小时
```

### 3. 连接池配置

```python
# PostgreSQL连接池
POOL_SIZE = 20
MAX_OVERFLOW = 10

# Redis连接池
REDIS_MAX_CONNECTIONS = 50
```

---

## 监控告警

### 1. 关键指标

```yaml
业务指标:
  - ocr_success_rate: 识别成功率
  - avg_confidence_score: 平均置信度
  - processing_time_p95: 处理时间P95

技术指标:
  - api_latency: API延迟
  - ai_model_latency: AI模型调用延迟
  - error_rate: 错误率
  - cache_hit_rate: 缓存命中率
```

### 2. Prometheus + Grafana

```python
# 添加metrics端点
from prometheus_client import Counter, Histogram, Gauge, generate_latest

ocr_requests = Counter('ocr_requests_total', 'Total OCR requests')
ocr_errors = Counter('ocr_errors_total', 'Total OCR errors')
ocr_latency = Histogram('ocr_latency_seconds', 'OCR processing latency')

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type="text/plain")
```

---

## 安全加固

### 1. API认证增强

```python
# 使用JWT Token
from jose import jwt

# 请求签名验证
def verify_signature(request, api_secret):
    signature = hmac.new(
        api_secret.encode(),
        request.body,
        hashlib.sha256
    ).hexdigest()
    return signature == request.headers.get('X-Signature')
```

### 2. 速率限制

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.post("/api/v1/ocr/analyze")
@limiter.limit("60/minute")
async def analyze_ocr(...):
    ...
```

### 3. 数据脱敏

```python
def mask_sensitive_field(value, field_type):
    if field_type in ['idNumber', 'licenseNumber']:
        return value[:3] + '*' * (len(value) - 5) + value[-2:]
    return value
```

---

## 故障排查

### 常见问题

#### 1. AI模型超时

```python
# 增加超时时间
openai.timeout = 30

# 启用重试
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(stop=stop_after_attempt(3), wait=wait_exponential())
async def call_ai_with_retry(...):
    ...
```

#### 2. 数据库连接池耗尽

```bash
# 检查活跃连接
SELECT count(*) FROM pg_stat_activity;

# 增加连接池大小
POOL_SIZE = 50
```

#### 3. Redis内存不足

```bash
# 检查内存使用
redis-cli INFO memory

# 设置最大内存和淘汰策略
maxmemory 2gb
maxmemory-policy allkeys-lru
```

---

## 备份与恢复

### 数据库备份

```bash
# 每日自动备份
0 2 * * * pg_dump quickvault_ocr > /backup/db_$(date +\%Y\%m\%d).sql

# 恢复
psql quickvault_ocr < /backup/db_20260114.sql
```

### 提示词版本管理

```bash
# 导出提示词模板
python scripts/export_prompts.py --output prompts_v2.0.0.json

# 导入提示词模板
python scripts/import_prompts.py --input prompts_v2.0.0.json
```

---

## 成本优化

### 1. AI模型选择策略

```python
def select_ai_model(document_type, complexity):
    """根据复杂度选择模型"""
    if document_type in ['idCard'] and complexity == 'simple':
        return 'gpt-3.5-turbo'  # 便宜快速
    else:
        return 'gpt-4-turbo'  # 准确率高
```

### 2. 结果缓存

```python
def get_cache_key(raw_texts):
    """基于OCR文本生成缓存键"""
    text_hash = hashlib.md5(
        json.dumps(raw_texts, sort_keys=True).encode()
    ).hexdigest()
    return f"ocr:result:{text_hash}"
```

### 3. 批量处理

```python
@app.post("/api/v1/ocr/batch-analyze")
async def batch_analyze(requests: List[OcrRequest]):
    """批量请求共享context，降低token消耗"""
    # 合并多个请求到一个AI调用
    ...
```

---

## 扩展功能

### 1. A/B测试平台

```python
# 同时测试多个提示词版本
async def ab_test_prompts(request, versions=['v1.0', 'v2.0']):
    results = []
    for version in versions:
        result = await process_with_version(request, version)
        results.append({
            'version': version,
            'confidence': result.confidence,
            'fields': result.fields
        })
    return results
```

### 2. 自动性能评估

```python
# 定期评估提示词性能
async def evaluate_prompt_performance():
    # 使用测试集评估
    test_cases = load_test_cases()
    for case in test_cases:
        result = await process_ocr(case.input)
        accuracy = calculate_accuracy(result, case.expected)
        log_performance_metric(accuracy)
```

---

## 联系支持

- 技术文档: https://docs.quickvault.app
- API文档: https://api.quickvault.app/docs
- 问题反馈: support@quickvault.app
