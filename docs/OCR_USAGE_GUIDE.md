# OCR 增强功能使用指南

## 概述

QuickVault 的 OCR 功能已经过全面优化，现在支持智能文档类型检测、多种证件识别以及自动字段填充。

## 主要改进

### 1. 扩展的卡片类型支持

现在支持以下卡片类型：

- ✅ 身份证 (ID Card)
- ✅ 护照 (Passport) - **新增**
- ✅ 驾照 (Driver's License) - **新增**
- ✅ 营业执照 (Business License)
- ✅ 居留卡 (Residence Permit) - **新增**
- ✅ 社保卡 (Social Security Card) - **新增**
- ✅ 银行卡 (Bank Card) - **新增**
- ✅ 发票 (Invoice)
- ✅ 地址 (Address)
- ✅ 通用文本 (General Text)

### 2. 智能文档类型检测

系统可以自动识别文档类型，无需用户手动指定：

```swift
// 自动检测并识别
let ocrService = OCRServiceImpl.shared
let result = try await ocrService.recognizeDocument(image: image)

print("检测到的文档类型: \(result.documentType.displayName)")
print("置信度: \(result.confidence)")
```

### 3. 结构化 OCR 结果

所有 OCR 结果都实现了统一的 `OCRResult` 协议：

```swift
protocol OCRResult {
    var documentType: DocumentType { get }
    var confidence: Double { get set }
    var rawTexts: [String] { get set }
    func toCardFields() -> [String: String]
}
```

支持的文档类型：
- `IDCardOCRResult` - 身份证
- `PassportOCRResult` - 护照
- `DriversLicenseOCRResult` - 驾照
- `BusinessLicenseOCRResult` - 营业执照

### 4. 智能字段映射

自动将 OCR 结果映射到卡片模板字段：

```swift
let mapper = OCRFieldMapper.shared

// 方式1: 基本映射
let (cardType, fields) = mapper.mapToCardFields(ocrResult)

// 方式2: 带置信度的建议
let suggestions = mapper.generateAutoFillSuggestions(ocrResult)
for (field, suggestion) in suggestions {
    print("\(field): \(suggestion.value) (置信度: \(suggestion.confidence))")
}

// 方式3: 合并多个结果（例如正反面）
let frontResult = try await ocrService.recognizeDocument(image: frontImage)
let backResult = try await ocrService.recognizeDocument(image: backImage)
let (cardType, mergedFields) = mapper.mergeOCRResults([frontResult, backResult])
```

### 5. 国家/地区规则引擎

集成了 `idpassport_rules.json` 规则，支持不同国家/地区的证件要求：

```swift
let rulesEngine = DocumentRulesEngine.shared

// 获取上传指导
if let guidance = rulesEngine.getUploadGuidance(for: "national_id", countryCode: "CN") {
    print("是否需要正面: \(guidance.frontRequired)")
    print("是否需要背面: \(guidance.backRequired)")
    print("提示: \(guidance.hint ?? "")")
}

// 检查是否需要正反面
let needsBothSides = rulesEngine.requiresBothSides(
    documentType: "national_id", 
    countryCode: "CN"
) // true - 中国身份证需要正反面

// 获取支持的国家列表
let countries = rulesEngine.getSupportedCountries()
// [("CN", "中国"), ("HK", "中国香港"), ("US", "美国"), ...]
```

## 使用示例

### 示例 1: 识别身份证

```swift
import UIKit

func recognizeIDCard(image: UIImage) async {
    let ocrService = OCRServiceImpl.shared
    let mapper = OCRFieldMapper.shared
    
    do {
        // 自动识别
        let result = try await ocrService.recognizeDocument(image: image)
        
        // 映射到卡片字段
        let (cardType, fields) = mapper.mapToCardFields(result)
        
        if cardType == .idCard {
            print("姓名: \(fields["name"] ?? "")")
            print("身份证号: \(fields["idNumber"] ?? "")")
            print("性别: \(fields["gender"] ?? "")")
            print("出生日期: \(fields["birthDate"] ?? "")")
            print("地址: \(fields["address"] ?? "")")
            
            if let issuer = fields["issuingAuthority"] {
                print("签发机关: \(issuer)")
            }
            if let validPeriod = fields["validPeriod"] {
                print("有效期: \(validPeriod)")
            }
        }
    } catch {
        print("识别失败: \(error.localizedDescription)")
    }
}
```

### 示例 2: 识别护照

```swift
func recognizePassport(image: UIImage) async {
    let ocrService = OCRServiceImpl.shared
    
    do {
        // 指定文档类型识别
        let result = try await ocrService.recognizeDocument(
            image: image, 
            expectedType: .passport
        )
        
        if let passportResult = result as? PassportOCRResult {
            print("姓名: \(passportResult.name ?? "")")
            print("护照号: \(passportResult.passportNumber ?? "")")
            print("国籍: \(passportResult.nationality ?? "")")
            print("出生日期: \(passportResult.birthDate ?? "")")
            print("有效期至: \(passportResult.expiryDate ?? "")")
        }
    } catch {
        print("识别失败: \(error)")
    }
}
```

### 示例 3: 识别驾照

```swift
func recognizeDriversLicense(image: UIImage) async {
    let ocrService = OCRServiceImpl.shared
    let mapper = OCRFieldMapper.shared
    
    do {
        let result = try await ocrService.recognizeDocument(image: image)
        
        // 生成自动填充建议
        let suggestions = mapper.generateAutoFillSuggestions(result)
        
        for (field, suggestion) in suggestions {
            if suggestion.confidence > 0.7 {
                print("高置信度字段 \(field): \(suggestion.value)")
            } else {
                print("低置信度字段 \(field): \(suggestion.value) - 建议人工确认")
            }
        }
    } catch {
        print("识别失败: \(error)")
    }
}
```

### 示例 4: 处理正反面照片

```swift
func processBothSides(frontImage: UIImage, backImage: UIImage) async {
    let ocrService = OCRServiceImpl.shared
    let mapper = OCRFieldMapper.shared
    
    do {
        // 分别识别正反面
        async let frontResult = ocrService.recognizeDocument(image: frontImage)
        async let backResult = ocrService.recognizeDocument(image: backImage)
        
        let results = try await [frontResult, backResult]
        
        // 合并结果
        let (cardType, mergedFields) = mapper.mergeOCRResults(results)
        
        print("卡片类型: \(cardType.displayName)")
        print("合并后的字段:")
        for (key, value) in mergedFields.sorted(by: { $0.key < $1.key }) {
            print("  \(key): \(value)")
        }
    } catch {
        print("识别失败: \(error)")
    }
}
```

### 示例 5: 使用规则引擎

```swift
func checkUploadRequirements(documentType: String, countryCode: String) {
    let rulesEngine = DocumentRulesEngine.shared
    
    if let guidance = rulesEngine.getUploadGuidance(
        for: documentType, 
        countryCode: countryCode
    ) {
        print("文档类型: \(documentType)")
        print("国家/地区: \(countryCode)")
        print("")
        print("上传要求:")
        print("- 正面: \(guidance.frontRequired ? "必需" : "可选")")
        print("- 背面: \(guidance.backRequired ? "必需" : guidance.backOptional ? "可选" : "不需要")")
        
        if let hint = guidance.hint {
            print("")
            print("提示: \(hint)")
        }
    }
}

// 示例调用
checkUploadRequirements(documentType: "national_id", countryCode: "CN")
// 输出:
// 文档类型: national_id
// 国家/地区: CN
// 
// 上传要求:
// - 正面: 必需
// - 背面: 必需
// 
// 提示: 中国居民身份证通常需要上传正反面：背面含签发机关与有效期限。
```

## 字段映射对照表

### 身份证 (ID Card)
| OCR 字段 | 卡片字段 | 说明 |
|---------|---------|------|
| name | name | 姓名 |
| gender | gender | 性别 |
| nationality | nationality | 民族 |
| birthDate | birthDate | 出生日期 |
| idNumber | idNumber | 身份证号 |
| address | address | 住址 |
| issuer | issuingAuthority | 签发机关 |
| validPeriod | validPeriod | 有效期 |

### 护照 (Passport)
| OCR 字段 | 卡片字段 | 说明 |
|---------|---------|------|
| name | name | 姓名 |
| passportNumber | passportNumber | 护照号 |
| nationality | nationality | 国籍 |
| gender | gender | 性别 |
| birthDate | birthDate | 出生日期 |
| birthPlace | birthPlace | 出生地 |
| issueDate | issueDate | 签发日期 |
| expiryDate | expiryDate | 有效期至 |
| issuer | issuer | 签发机关 |

### 驾照 (Driver's License)
| OCR 字段 | 卡片字段 | 说明 |
|---------|---------|------|
| name | name | 姓名 |
| licenseNumber | licenseNumber | 证号 |
| gender | gender | 性别 |
| nationality | nationality | 国籍 |
| birthDate | birthDate | 出生日期 |
| address | address | 住址 |
| issueDate | issueDate | 初次领证日期 |
| validFrom | validFrom | 有效起始日期 |
| validUntil | validUntil | 有效期限 |
| licenseClass | licenseClass | 准驾车型 |

## 最佳实践

### 1. 图片质量要求

为获得最佳 OCR 效果，请确保：
- ✅ 光线充足，避免阴影
- ✅ 对焦清晰，文字可读
- ✅ 平整无褶皱
- ✅ 完整拍摄，无裁剪
- ✅ 避免反光

### 2. 错误处理

```swift
func robustOCR(image: UIImage) async {
    let ocrService = OCRServiceImpl.shared
    
    do {
        let result = try await ocrService.recognizeDocument(image: image)
        
        // 检查置信度
        if result.confidence < 0.5 {
            print("⚠️ 识别置信度较低，建议重新拍摄")
        }
        
        // 检查关键字段
        let fields = result.toCardFields()
        if fields.isEmpty {
            print("⚠️ 未识别到有效字段")
        }
        
    } catch OCRError.invalidImage {
        print("❌ 图片无效")
    } catch OCRError.recognitionFailed(let message) {
        print("❌ 识别失败: \(message)")
    } catch {
        print("❌ 未知错误: \(error)")
    }
}
```

### 3. 用户体验优化

```swift
// 1. 显示识别进度
print("正在识别文档...")
let result = try await ocrService.recognizeDocument(image: image)
print("识别完成！")

// 2. 显示建议
let suggestions = mapper.generateAutoFillSuggestions(result)
for (field, suggestion) in suggestions where suggestion.confidence < 0.8 {
    print("⚠️ 字段 '\(field)' 的识别置信度较低，请核对")
}

// 3. 允许用户编辑
var editableFields = result.toCardFields()
// ... 用户可以修改 editableFields
```

## 技术细节

### 文档类型检测算法

系统使用关键词匹配和权重评分来检测文档类型：

1. 扫描所有识别的文本
2. 匹配预定义的关键词模式
3. 计算每种文档类型的得分
4. 选择得分最高且超过阈值的类型
5. 返回类型和置信度

### 字段后处理

自动应用以下优化：

- 日期格式标准化（YYYY年MM月DD日 → YYYY-MM-DD）
- 空白字符清理
- 字段验证（身份证号、护照号等）
- 性别标准化
- 大写转换（证件号码）

### 置信度计算

置信度基于以下因素：

- 文档类型检测匹配度
- 字段格式验证结果
- 字段内容完整性
- OCR 识别质量

## 性能优化建议

1. **并发处理**: 正反面照片可以并发识别
2. **缓存结果**: 避免重复识别同一图片
3. **异步执行**: 使用 async/await 避免阻塞 UI
4. **图片预处理**: 适当裁剪和压缩图片

## 常见问题

### Q: 如何提高识别准确率？
A: 确保图片质量，使用高置信度字段，允许用户核对和修正。

### Q: 支持哪些国家/地区的证件？
A: 查看 `idpassport_rules.json` 获取完整列表，或使用 `DocumentRulesEngine.shared.getSupportedCountries()`。

### Q: 如何添加新的文档类型？
A: 
1. 在 `DocumentType` 枚举中添加新类型
2. 创建对应的 `OCRResult` 结构体
3. 在 `OCRServiceImpl` 中实现解析逻辑
4. 在 `CardTemplate.swift` 中添加对应模板

### Q: OCR 识别失败怎么办？
A: 检查图片质量，查看错误信息，允许用户手动输入或重新拍摄。

## 总结

QuickVault 的增强 OCR 功能提供了：

- ✅ 智能文档类型检测
- ✅ 多种证件识别支持
- ✅ 自动字段映射和填充
- ✅ 国家/地区规则支持
- ✅ 高置信度评分
- ✅ 灵活的后处理优化

通过合理使用这些功能，可以大幅提升用户体验和数据录入效率。
