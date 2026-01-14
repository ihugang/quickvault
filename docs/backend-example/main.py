# AI-OCR Backend Implementation (Python FastAPI)
# QuickVault后端服务 - AI增强OCR解析

"""
运行要求:
pip install fastapi uvicorn sqlalchemy psycopg2-binary redis openai anthropic pydantic python-dotenv

运行命令:
uvicorn main:app --reload --host 0.0.0.0 --port 8000
"""

from fastapi import FastAPI, HTTPException, Depends, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum
import hashlib
import json
import os
import time
from functools import lru_cache

# AI模型客户端
import openai
# import anthropic  # 如需使用Claude

# 数据库和缓存
from sqlalchemy import create_engine, Column, String, Float, Integer, Boolean, DateTime, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.dialects.postgresql import JSONB, UUID
import redis
import uuid

# MARK: - 应用初始化

app = FastAPI(
    title="QuickVault AI-OCR API",
    description="AI增强的证件OCR识别服务",
    version="1.0.0"
)

# CORS配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生产环境需限制具体域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 数据库配置
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:pass@localhost/quickvault")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Redis缓存
redis_client = redis.Redis(
    host=os.getenv("REDIS_HOST", "localhost"),
    port=int(os.getenv("REDIS_PORT", 6379)),
    db=0,
    decode_responses=True
)

# OpenAI配置
openai.api_key = os.getenv("OPENAI_API_KEY", "")
openai.api_base = os.getenv("OPENAI_API_BASE", "https://api.openai.com/v1")

# MARK: - 数据模型

class DocumentTypeEnum(str, Enum):
    ID_CARD = "idCard"
    PASSPORT = "passport"
    DRIVERS_LICENSE = "driversLicense"
    BUSINESS_LICENSE = "businessLicense"

class PromptTemplate(Base):
    """提示词模板表"""
    __tablename__ = "prompt_templates"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    document_type = Column(String(50), nullable=False)
    version = Column(String(20), nullable=False)
    locale = Column(String(10), default="zh-CN")
    
    system_prompt = Column(Text, nullable=False)
    user_prompt_template = Column(Text, nullable=False)
    
    description = Column(Text)
    fields_config = Column(JSONB)
    validation_rules = Column(JSONB)
    
    status = Column(String(20), default="active")
    is_default = Column(Boolean, default=False)
    
    avg_confidence = Column(Float)
    success_rate = Column(Float)
    usage_count = Column(Integer, default=0)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class OCRRequestLog(Base):
    """OCR请求日志表"""
    __tablename__ = "ocr_request_logs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    request_id = Column(String(100), unique=True, nullable=False)
    
    document_type = Column(String(50), nullable=False)
    client_version = Column(String(20))
    user_id = Column(String(100))
    
    raw_texts = Column(JSONB, nullable=False)
    extracted_fields = Column(JSONB)
    
    prompt_version = Column(String(20))
    model_used = Column(String(50))
    ai_response = Column(Text)
    
    confidence_score = Column(Float)
    processing_time_ms = Column(Integer)
    
    status = Column(String(20))
    error_message = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow)

# 创建表
Base.metadata.create_all(bind=engine)

# MARK: - Pydantic模型

class OcrField(BaseModel):
    value: str
    confidence: float = Field(ge=0.0, le=1.0)
    corrected: Optional[bool] = None
    originalValue: Optional[str] = None

class OcrRequest(BaseModel):
    documentType: DocumentTypeEnum
    rawTexts: List[str]
    imageUrl: Optional[str] = None
    clientVersion: str = "1.0.0"
    locale: str = "zh-CN"

class OcrData(BaseModel):
    documentType: str
    confidence: float
    fields: Dict[str, OcrField]
    warnings: Optional[List[str]] = None
    processingTime: Optional[int] = None

class OcrMeta(BaseModel):
    requestId: str
    timestamp: str
    modelUsed: Optional[str] = None
    promptVersion: Optional[str] = None

class OcrResponse(BaseModel):
    success: bool
    data: Optional[OcrData] = None
    error: Optional[Dict[str, Any]] = None
    meta: Optional[OcrMeta] = None

# MARK: - 依赖注入

def get_db():
    """数据库会话"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

async def verify_api_key(authorization: str = Header(...)):
    """验证API Key"""
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="无效的认证头")
    
    api_key = authorization.replace("Bearer ", "")
    expected_key = os.getenv("API_KEY", "your-secret-key-here")
    
    if api_key != expected_key:
        raise HTTPException(status_code=401, detail="API Key无效")
    
    return api_key

# MARK: - 核心服务

class PromptService:
    """提示词管理服务"""
    
    @staticmethod
    def get_prompt_template(
        document_type: str,
        locale: str,
        db: Session
    ) -> Optional[PromptTemplate]:
        """获取提示词模板（带缓存）"""
        cache_key = f"prompt:template:{document_type}:{locale}"
        
        # 尝试从缓存获取
        cached = redis_client.get(cache_key)
        if cached:
            data = json.loads(cached)
            template = PromptTemplate(**data)
            return template
        
        # 从数据库查询
        template = db.query(PromptTemplate).filter(
            PromptTemplate.document_type == document_type,
            PromptTemplate.locale == locale,
            PromptTemplate.status == "active",
            PromptTemplate.is_default == True
        ).first()
        
        if template:
            # 缓存1小时
            redis_client.setex(
                cache_key,
                3600,
                json.dumps({
                    "system_prompt": template.system_prompt,
                    "user_prompt_template": template.user_prompt_template,
                    "version": template.version,
                    "fields_config": template.fields_config
                })
            )
        
        return template
    
    @staticmethod
    def build_ai_prompt(
        template: PromptTemplate,
        raw_texts: List[str]
    ) -> tuple[str, str]:
        """构建AI提示词"""
        system_prompt = template.system_prompt
        
        # 格式化用户提示词
        raw_texts_json = json.dumps(raw_texts, ensure_ascii=False, indent=2)
        user_prompt = template.user_prompt_template.replace(
            "{{raw_texts}}",
            raw_texts_json
        )
        
        return system_prompt, user_prompt

class AIService:
    """AI模型调用服务"""
    
    @staticmethod
    async def call_openai(
        system_prompt: str,
        user_prompt: str,
        model: str = "gpt-4-turbo-preview"
    ) -> Dict[str, Any]:
        """调用OpenAI API"""
        try:
            response = openai.ChatCompletion.create(
                model=model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.2,
                max_tokens=2000,
                response_format={"type": "json_object"}  # 强制JSON输出
            )
            
            content = response.choices[0].message.content
            result = json.loads(content)
            
            return {
                "success": True,
                "data": result,
                "model": model,
                "usage": response.usage._asdict()
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    @staticmethod
    def parse_ai_response(
        ai_data: Dict[str, Any],
        document_type: str
    ) -> tuple[Dict[str, OcrField], List[str]]:
        """解析AI响应"""
        fields = {}
        warnings = []
        
        # 提取字段
        if "fields" in ai_data:
            for key, value in ai_data["fields"].items():
                if isinstance(value, dict) and "value" in value:
                    fields[key] = OcrField(
                        value=value["value"],
                        confidence=value.get("confidence", 0.8),
                        corrected=value.get("corrected"),
                        originalValue=value.get("originalValue")
                    )
        
        # 提取警告
        if "warnings" in ai_data:
            warnings = ai_data.get("warnings", [])
        elif "corrections" in ai_data:
            # 从纠错信息生成警告
            for correction in ai_data.get("corrections", []):
                warnings.append(
                    f"{correction['field']}: {correction['original']} → {correction['corrected']}"
                )
        
        return fields, warnings

class OCRService:
    """OCR处理服务"""
    
    @staticmethod
    async def process_ocr_request(
        request: OcrRequest,
        db: Session
    ) -> OcrResponse:
        """处理OCR请求"""
        start_time = time.time()
        request_id = str(uuid.uuid4())
        
        try:
            # 1. 获取提示词模板
            template = PromptService.get_prompt_template(
                request.documentType.value,
                request.locale,
                db
            )
            
            if not template:
                raise HTTPException(
                    status_code=400,
                    detail=f"不支持的证件类型: {request.documentType}"
                )
            
            # 2. 构建AI提示词
            system_prompt, user_prompt = PromptService.build_ai_prompt(
                template,
                request.rawTexts
            )
            
            # 3. 调用AI模型
            ai_result = await AIService.call_openai(
                system_prompt,
                user_prompt,
                model="gpt-4-turbo-preview"
            )
            
            if not ai_result["success"]:
                raise Exception(ai_result["error"])
            
            # 4. 解析AI响应
            fields, warnings = AIService.parse_ai_response(
                ai_result["data"],
                request.documentType.value
            )
            
            # 5. 计算整体置信度
            if fields:
                avg_confidence = sum(f.confidence for f in fields.values()) / len(fields)
            else:
                avg_confidence = 0.0
            
            # 6. 构建响应
            processing_time = int((time.time() - start_time) * 1000)
            
            response = OcrResponse(
                success=True,
                data=OcrData(
                    documentType=request.documentType.value,
                    confidence=round(avg_confidence, 2),
                    fields=fields,
                    warnings=warnings if warnings else None,
                    processingTime=processing_time
                ),
                meta=OcrMeta(
                    requestId=request_id,
                    timestamp=datetime.utcnow().isoformat() + "Z",
                    modelUsed=ai_result.get("model"),
                    promptVersion=template.version
                )
            )
            
            # 7. 记录日志
            log = OCRRequestLog(
                request_id=request_id,
                document_type=request.documentType.value,
                client_version=request.clientVersion,
                raw_texts=request.rawTexts,
                extracted_fields={k: v.dict() for k, v in fields.items()},
                prompt_version=template.version,
                model_used=ai_result.get("model"),
                ai_response=json.dumps(ai_result["data"]),
                confidence_score=avg_confidence,
                processing_time_ms=processing_time,
                status="success"
            )
            db.add(log)
            
            # 更新模板使用统计
            template.usage_count += 1
            
            db.commit()
            
            return response
            
        except Exception as e:
            # 记录错误日志
            error_log = OCRRequestLog(
                request_id=request_id,
                document_type=request.documentType.value,
                client_version=request.clientVersion,
                raw_texts=request.rawTexts,
                status="failed",
                error_message=str(e),
                processing_time_ms=int((time.time() - start_time) * 1000)
            )
            db.add(error_log)
            db.commit()
            
            raise HTTPException(
                status_code=500,
                detail=f"OCR处理失败: {str(e)}"
            )

# MARK: - API路由

@app.post("/api/v1/ocr/analyze", response_model=OcrResponse)
async def analyze_ocr(
    request: OcrRequest,
    db: Session = Depends(get_db),
    api_key: str = Depends(verify_api_key)
):
    """
    智能OCR解析接口
    
    通过AI模型增强OCR识别准确率，自动纠正常见错误
    """
    return await OCRService.process_ocr_request(request, db)

@app.get("/api/v1/ocr/document-types")
async def get_document_types(db: Session = Depends(get_db)):
    """获取支持的证件类型"""
    templates = db.query(PromptTemplate).filter(
        PromptTemplate.status == "active",
        PromptTemplate.is_default == True
    ).all()
    
    types = []
    for t in templates:
        types.append({
            "id": t.document_type,
            "name": DocumentTypeEnum(t.document_type).name,
            "fields": list(t.fields_config.get("required", [])) + list(t.fields_config.get("optional", [])),
            "currentPromptVersion": t.version
        })
    
    return {
        "success": True,
        "data": {"types": types}
    }

@app.get("/api/v1/health")
async def health_check():
    """健康检查"""
    services = {
        "api": "up",
        "database": "up" if engine else "down",
        "redis": "up" if redis_client.ping() else "down",
        "aiModel": "up"  # 实际应检查API可用性
    }
    
    all_healthy = all(status == "up" for status in services.values())
    
    return {
        "status": "healthy" if all_healthy else "degraded",
        "services": services,
        "version": "1.0.0"
    }

@app.get("/")
async def root():
    """API根路径"""
    return {
        "service": "QuickVault AI-OCR API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/api/v1/health"
    }

# MARK: - 数据初始化

@app.on_event("startup")
async def startup_event():
    """应用启动时初始化数据"""
    db = SessionLocal()
    
    # 检查是否已有提示词模板
    existing = db.query(PromptTemplate).filter(
        PromptTemplate.document_type == "driversLicense",
        PromptTemplate.is_default == True
    ).first()
    
    if not existing:
        # 初始化驾驶证提示词模板
        template = PromptTemplate(
            document_type="driversLicense",
            version="v2.0.0",
            locale="zh-CN",
            system_prompt="""你是一个专业的中国驾驶证OCR文本解析专家。你的任务是从可能包含错误的OCR文本中准确提取驾驶证信息。

常见OCR错误：
- "姓名"可能被识别为"糕名"、"性名"
- "证"可能被识别为"証"
- 字母X可能被识别为"乂"
- 数字0可能被识别为字母O

提取字段：name, licenseNumber, gender, nationality, birthDate, address, issueDate, validFrom, validUntil, licenseClass

输出JSON格式，只包含确定识别出的字段。""",
            user_prompt_template="""请从以下OCR识别的文本中提取驾驶证信息：

OCR文本：
{{raw_texts}}

输出JSON格式：
{
  "fields": {
    "name": {"value": "...", "confidence": 0.95},
    "licenseNumber": {"value": "...", "confidence": 0.98}
  }
}""",
            description="驾驶证识别v2.0",
            fields_config={
                "required": ["name", "licenseNumber", "birthDate"],
                "optional": ["gender", "nationality", "address", "issueDate", "validFrom", "validUntil", "licenseClass"]
            },
            validation_rules={
                "licenseNumber": {
                    "pattern": "^\\d{17}[0-9Xx]$|^\\d{12}$"
                },
                "gender": {
                    "enum": ["男", "女"]
                }
            },
            is_default=True,
            status="active"
        )
        db.add(template)
        db.commit()
        print("✅ 初始化驾驶证提示词模板完成")
    
    db.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
