import Combine
import Foundation
import QuickVaultCore
import UIKit

/// Card editor view model for creating and editing cards / 卡片编辑器视图模型
@MainActor
class CardEditorViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var title: String = ""
    @Published var selectedGroup: String = "Personal"
    @Published var selectedType: CardType = .general
    @Published var fields: [EditableField] = []
    @Published var tags: [String] = []
    @Published var newTag: String = ""
    @Published var isLoading: Bool = false
    @Published var isOCRProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var validationErrors: [String: String] = [:]
    
    // MARK: - Document Photos (for OCR and attachment)
    
    @Published var frontPhoto: UIImage?
    @Published var backPhoto: UIImage?
    
    // MARK: - OCR Service
    
    private let ocrService: OCRService = OCRServiceImpl.shared
    private let attachmentService: AttachmentService
    
    // MARK: - Editable Field
    
    struct EditableField: Identifiable {
        let id: UUID
        var label: String
        var value: String
        var isRequired: Bool
        var isCopyable: Bool
        var isMultiline: Bool
        var order: Int16
        
        init(id: UUID, label: String, value: String, isRequired: Bool, isCopyable: Bool, order: Int16, isMultiline: Bool = false) {
            self.id = id
            self.label = label
            self.value = value
            self.isRequired = isRequired
            self.isCopyable = isCopyable
            self.isMultiline = isMultiline
            self.order = order
        }
    }
    
    // MARK: - Group Options
    
    let groupOptions = ["Personal", "Company"]
    var groupDisplayNames: [String] {
        ["cards.group.personal".localized, "cards.group.company".localized]
    }
    
    // MARK: - Dependencies
    
    private let cardService: CardService
    private var editingCardId: UUID?
    
    // MARK: - Computed Properties
    
    var isEditing: Bool {
        editingCardId != nil
    }
    
    var isValid: Bool {
        !title.isEmpty && checkFieldsValid()
    }
    
    // 检查字段有效性，不修改 @Published 属性
    private func checkFieldsValid() -> Bool {
        // 检查必填字段
        for field in fields where field.isRequired {
            if field.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return false
            }
        }
        
        // 检查地址卡片的电话号码
        if selectedType == .address {
            if let phoneField = fields.first(where: { $0.label == "field.phone".localized }) {
                if !phoneField.value.isEmpty && !isValidPhoneNumber(phoneField.value) {
                    return false
                }
            }
        }
        
        return true
    }
    
    // MARK: - Initialization
    
    init(cardService: CardService, attachmentService: AttachmentService? = nil) {
        self.cardService = cardService
        self.attachmentService = attachmentService ?? AttachmentServiceImpl.shared
        // 延迟初始化，避免在 init 中触发 @Published 更新
    }
    
    // MARK: - Setup for New Card
    
    func setupForNewCard(type: CardType = .address) {
        editingCardId = nil
        title = ""
        selectedGroup = "Personal"
        selectedType = type
        tags = []
        validationErrors = [:]
        setupFieldsForType(type)
    }
    
    // MARK: - Setup for Editing
    
    func setupForEditing(card: CardDTO) {
        editingCardId = card.id
        title = card.title
        selectedGroup = card.group
        selectedType = CardType(rawValue: card.type) ?? .address
        tags = card.tags
        validationErrors = [:]
        
        fields = card.fields.map { field in
            EditableField(
                id: field.id,
                label: field.label,
                value: field.value,
                isRequired: isFieldRequired(label: field.label, type: selectedType),
                isCopyable: field.isCopyable,
                order: field.order
            )
        }
    }
    
    // MARK: - Setup Fields for Type
    
    func setupFieldsForType(_ type: CardType) {
        selectedType = type
        
        switch type {
        case .address:
            fields = [
                EditableField(id: UUID(), label: "field.name".localized, value: "", isRequired: true, isCopyable: true, order: 0),
                EditableField(id: UUID(), label: "field.phone".localized, value: "", isRequired: true, isCopyable: true, order: 1),
                EditableField(id: UUID(), label: "field.province".localized, value: "", isRequired: true, isCopyable: true, order: 2),
                EditableField(id: UUID(), label: "field.city".localized, value: "", isRequired: true, isCopyable: true, order: 3),
                EditableField(id: UUID(), label: "field.district".localized, value: "", isRequired: true, isCopyable: true, order: 4),
                EditableField(id: UUID(), label: "field.address".localized, value: "", isRequired: true, isCopyable: true, order: 5),
                EditableField(id: UUID(), label: "field.postalcode".localized, value: "", isRequired: false, isCopyable: true, order: 6),
                EditableField(id: UUID(), label: "field.notes".localized, value: "", isRequired: false, isCopyable: false, order: 7),
            ]
            
        case .invoice:
            fields = [
                EditableField(id: UUID(), label: "field.companyname".localized, value: "", isRequired: true, isCopyable: true, order: 0),
                EditableField(id: UUID(), label: "field.taxid".localized, value: "", isRequired: true, isCopyable: true, order: 1),
                EditableField(id: UUID(), label: "field.address".localized, value: "", isRequired: true, isCopyable: true, order: 2),
                EditableField(id: UUID(), label: "field.phone".localized, value: "", isRequired: true, isCopyable: true, order: 3),
                EditableField(id: UUID(), label: "field.bankname".localized, value: "", isRequired: true, isCopyable: true, order: 4),
                EditableField(id: UUID(), label: "field.bankaccount".localized, value: "", isRequired: true, isCopyable: true, order: 5),
                EditableField(id: UUID(), label: "field.notes".localized, value: "", isRequired: false, isCopyable: false, order: 6),
            ]
            
        case .general:
            fields = [
                EditableField(id: UUID(), label: "field.content".localized, value: "", isRequired: true, isCopyable: true, order: 0),
            ]
            
        case .idCard:
            fields = [
                EditableField(id: UUID(), label: "field.idcard.name".localized, value: "", isRequired: true, isCopyable: true, order: 0),
                EditableField(id: UUID(), label: "field.idcard.gender".localized, value: "", isRequired: true, isCopyable: true, order: 1),
                EditableField(id: UUID(), label: "field.idcard.nationality".localized, value: "", isRequired: true, isCopyable: true, order: 2),
                EditableField(id: UUID(), label: "field.idcard.birthdate".localized, value: "", isRequired: true, isCopyable: true, order: 3),
                EditableField(id: UUID(), label: "field.idcard.number".localized, value: "", isRequired: true, isCopyable: true, order: 4),
                EditableField(id: UUID(), label: "field.idcard.address".localized, value: "", isRequired: true, isCopyable: true, order: 5),
                EditableField(id: UUID(), label: "field.idcard.issuer".localized, value: "", isRequired: false, isCopyable: true, order: 6),
                EditableField(id: UUID(), label: "field.idcard.validperiod".localized, value: "", isRequired: false, isCopyable: true, order: 7),
            ]
            
        case .passport:
            fields = [
                EditableField(id: UUID(), label: "field.passport.name".localized, value: "", isRequired: true, isCopyable: true, order: 0),
                EditableField(id: UUID(), label: "field.passport.nationality".localized, value: "", isRequired: true, isCopyable: true, order: 1),
                EditableField(id: UUID(), label: "field.passport.birthdate".localized, value: "", isRequired: true, isCopyable: true, order: 2),
                EditableField(id: UUID(), label: "field.passport.gender".localized, value: "", isRequired: true, isCopyable: true, order: 3),
                EditableField(id: UUID(), label: "field.passport.number".localized, value: "", isRequired: true, isCopyable: true, order: 4),
                EditableField(id: UUID(), label: "field.passport.issuedate".localized, value: "", isRequired: false, isCopyable: true, order: 5),
                EditableField(id: UUID(), label: "field.passport.expirydate".localized, value: "", isRequired: false, isCopyable: true, order: 6),
                EditableField(id: UUID(), label: "field.passport.issueplace".localized, value: "", isRequired: false, isCopyable: true, order: 7),
                EditableField(id: UUID(), label: "field.passport.issuer".localized, value: "", isRequired: false, isCopyable: true, order: 8),
            ]
            
        case .businessLicense:
            fields = [
                EditableField(id: UUID(), label: "field.license.companyname".localized, value: "", isRequired: true, isCopyable: true, order: 0),
                EditableField(id: UUID(), label: "field.license.companytype".localized, value: "", isRequired: false, isCopyable: true, order: 1),
                EditableField(id: UUID(), label: "field.license.creditcode".localized, value: "", isRequired: true, isCopyable: true, order: 2),
                EditableField(id: UUID(), label: "field.license.legalrep".localized, value: "", isRequired: true, isCopyable: true, order: 3),
                EditableField(id: UUID(), label: "field.license.capital".localized, value: "", isRequired: false, isCopyable: true, order: 4),
                EditableField(id: UUID(), label: "field.license.address".localized, value: "", isRequired: false, isCopyable: true, order: 5, isMultiline: true),
                EditableField(id: UUID(), label: "field.license.establishdate".localized, value: "", isRequired: false, isCopyable: true, order: 6),
                EditableField(id: UUID(), label: "field.license.businessterm".localized, value: "", isRequired: false, isCopyable: true, order: 7),
                EditableField(id: UUID(), label: "field.license.scope".localized, value: "", isRequired: false, isCopyable: true, order: 8, isMultiline: true),
            ]
            
        case .driversLicense:
            fields = [
                EditableField(id: UUID(), label: "姓名 / Name", value: "", isRequired: true, isCopyable: true, order: 0),
                EditableField(id: UUID(), label: "证号 / License No.", value: "", isRequired: true, isCopyable: true, order: 1),
                EditableField(id: UUID(), label: "性别 / Gender", value: "", isRequired: true, isCopyable: true, order: 2),
                EditableField(id: UUID(), label: "国籍 / Nationality", value: "", isRequired: false, isCopyable: true, order: 3),
                EditableField(id: UUID(), label: "出生日期 / Date of Birth", value: "", isRequired: true, isCopyable: true, order: 4),
                EditableField(id: UUID(), label: "住址 / Address", value: "", isRequired: false, isCopyable: true, order: 5),
                EditableField(id: UUID(), label: "初次领证日期 / Issue Date", value: "", isRequired: false, isCopyable: true, order: 6),
                EditableField(id: UUID(), label: "有效期限 / Valid Until", value: "", isRequired: false, isCopyable: true, order: 7),
                EditableField(id: UUID(), label: "准驾车型 / License Class", value: "", isRequired: false, isCopyable: true, order: 8),
            ]
            
        case .residencePermit:
            fields = [
                EditableField(id: UUID(), label: "姓名 / Name", value: "", isRequired: true, isCopyable: true, order: 0),
                EditableField(id: UUID(), label: "证件号码 / Permit No.", value: "", isRequired: true, isCopyable: true, order: 1),
                EditableField(id: UUID(), label: "性别 / Gender", value: "", isRequired: true, isCopyable: true, order: 2),
                EditableField(id: UUID(), label: "国籍 / Nationality", value: "", isRequired: true, isCopyable: true, order: 3),
                EditableField(id: UUID(), label: "出生日期 / Date of Birth", value: "", isRequired: true, isCopyable: true, order: 4),
                EditableField(id: UUID(), label: "签发日期 / Issue Date", value: "", isRequired: false, isCopyable: true, order: 5),
                EditableField(id: UUID(), label: "有效期至 / Expiry Date", value: "", isRequired: false, isCopyable: true, order: 6),
                EditableField(id: UUID(), label: "居留事由 / Permit Type", value: "", isRequired: false, isCopyable: true, order: 7),
            ]
            
        case .socialSecurityCard:
            fields = [
                EditableField(id: UUID(), label: "姓名 / Name", value: "", isRequired: true, isCopyable: true, order: 0),
                EditableField(id: UUID(), label: "社保卡号 / Card No.", value: "", isRequired: true, isCopyable: true, order: 1),
                EditableField(id: UUID(), label: "社会保障号码 / ID No.", value: "", isRequired: true, isCopyable: true, order: 2),
                EditableField(id: UUID(), label: "发卡日期 / Issue Date", value: "", isRequired: false, isCopyable: true, order: 3),
                EditableField(id: UUID(), label: "发卡银行 / Issuing Bank", value: "", isRequired: false, isCopyable: true, order: 4),
            ]
            
        case .bankCard:
            fields = [
                EditableField(id: UUID(), label: "卡号 / Card No.", value: "", isRequired: true, isCopyable: true, order: 0),
                EditableField(id: UUID(), label: "持卡人 / Cardholder", value: "", isRequired: true, isCopyable: true, order: 1),
                EditableField(id: UUID(), label: "开户行 / Bank", value: "", isRequired: true, isCopyable: true, order: 2),
                EditableField(id: UUID(), label: "有效期 / Expiry Date", value: "", isRequired: false, isCopyable: true, order: 3),
                EditableField(id: UUID(), label: "CVV", value: "", isRequired: false, isCopyable: true, order: 4),
                EditableField(id: UUID(), label: "备注 / Notes", value: "", isRequired: false, isCopyable: false, order: 5, isMultiline: true),
            ]
        }
    }
    
    private func isFieldRequired(label: String, type: CardType) -> Bool {
        let optionalLabels = ["field.postalcode".localized, "field.notes".localized]
        return !optionalLabels.contains(label)
    }
    
    // MARK: - Validation
    
    func validateFields() -> Bool {
        validationErrors = [:]
        var isValid = true
        
        // Validate title
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["title"] = "validation.title.required".localized
            isValid = false
        }
        
        // Validate required fields
        for field in fields where field.isRequired {
            if field.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationErrors[field.id.uuidString] = "validation.field.required".localized
                isValid = false
            }
        }
        
        // Validate phone number for address cards
        if selectedType == .address {
            if let phoneField = fields.first(where: { $0.label == "field.phone".localized }) {
                if !phoneField.value.isEmpty && !isValidPhoneNumber(phoneField.value) {
                    validationErrors[phoneField.id.uuidString] = "validation.phone.invalid".localized
                    isValid = false
                }
            }
        }
        
        // Validate tax ID for invoice cards
        if selectedType == .invoice {
            if let taxIdField = fields.first(where: { $0.label == "field.taxid".localized }) {
                if !taxIdField.value.isEmpty && !isValidTaxId(taxIdField.value) {
                    validationErrors[taxIdField.id.uuidString] = "validation.taxid.invalid".localized
                    isValid = false
                }
            }
        }
        
        return isValid
    }
    
    // MARK: - Phone Validation
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        let digits = phone.filter { $0.isNumber }
        
        // Chinese mobile: 11 digits starting with 1
        if digits.count == 11 && digits.hasPrefix("1") {
            return true
        }
        
        // Chinese landline: area code (3-4 digits) + number (7-8 digits)
        if digits.count >= 10 && digits.count <= 12 {
            return true
        }
        
        return false
    }
    
    // MARK: - Tax ID Validation
    
    private func isValidTaxId(_ taxId: String) -> Bool {
        let cleaned = taxId.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.count == 18
    }
    
    // MARK: - Tag Management
    
    func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty && !tags.contains(trimmedTag) else { return }
        tags.append(trimmedTag)
        newTag = ""
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    // MARK: - Save Card
    
    func saveCard() async -> CardDTO? {
        // 自动添加用户可能输入但未点击加号的标签
        if !newTag.isEmpty {
            addTag()
        }
        
        guard validateFields() else {
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        
        let fieldDTOs = fields.map { field in
            CardFieldDTO(
                id: field.id,
                label: field.label,
                value: field.value,
                isCopyable: field.isCopyable,
                order: field.order
            )
        }
        
        do {
            let savedCard: CardDTO
            
            if let cardId = editingCardId {
                // Update existing card
                savedCard = try await cardService.updateCard(
                    id: cardId,
                    title: title,
                    group: selectedGroup,
                    fields: fieldDTOs,
                    tags: tags
                )
                
                // Save new document photos as attachments (for editing)
                await saveDocumentPhotos(for: cardId)
            } else {
                // Create new card
                savedCard = try await cardService.createCard(
                    title: title,
                    group: selectedGroup,
                    type: selectedType.rawValue,
                    fields: fieldDTOs,
                    tags: tags
                )
                
                // Save document photos as attachments
                await saveDocumentPhotos(for: savedCard.id)
            }
            
            isLoading = false
            return savedCard
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }
    
    // MARK: - Clear Error
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - OCR Recognition
    
    /// 从图片中识别信息并自动填充表单
    /// - Parameter image: 要识别的图片
    /// - Parameter isFrontSide: 是否是正面照片（用于身份证区分正反面）
    func recognizeAndFillFromImage(_ image: UIImage, isFrontSide: Bool = true) async {
        isOCRProcessing = true
        errorMessage = nil
        
        do {
            // 使用新的 OCR API 自动检测并识别
            let result = try await ocrService.recognizeDocument(image: image)
            
            // 直接从 OCR 结果获取字段
            let ocrFields = result.toCardFields()
            
            // 根据检测到的文档类型映射到卡片类型
            let detectedCardType = mapDocumentTypeToCardType(result.documentType)
            
            // 如果自动检测的类型与当前选择的类型不匹配，提示用户
            if detectedCardType != selectedType {
                print("⚠️ 检测到的文档类型(\(detectedCardType.displayName))与当前卡片类型(\(selectedType.displayName))不匹配")
            }
            
            // 正面照片时清空所有字段，背面照片时只更新背面特有字段
            if isFrontSide {
                clearAllFields()
            }
            
            // 填充字段（带字段标准化）
            fillFieldsFromOCR(normalizeFields(ocrFields), isFrontSide: isFrontSide)
            
            // 如果标题为空，使用姓名或公司名作为标题
            if title.isEmpty {
                if let name = ocrFields["name"] ?? ocrFields["companyName"], !name.isEmpty {
                    title = name
                }
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isOCRProcessing = false
    }
    
    /// 清空所有字段值
    private func clearAllFields() {
        for i in 0..<fields.count {
            fields[i].value = ""
        }
        title = ""
    }
    
    /// 保存证件照片作为附件
    private func saveDocumentPhotos(for cardId: UUID) async {
        print("[CardEditor] saveDocumentPhotos called, frontPhoto: \(frontPhoto != nil), backPhoto: \(backPhoto != nil)")
        
        // 获取现有附件，用于删除同名旧附件
        let existingAttachments = (try? await attachmentService.fetchAttachments(for: cardId)) ?? []
        
        // 保存正面照片
        if let frontImage = frontPhoto,
           let imageData = frontImage.jpegData(compressionQuality: 0.8) {
            let fileName = selectedType.frontPhotoFileName
            print("[CardEditor] Saving front photo: \(fileName), size: \(imageData.count)")
            
            // 删除同名旧附件
            if let oldAttachment = existingAttachments.first(where: { $0.fileName == fileName }) {
                try? await attachmentService.deleteAttachment(id: oldAttachment.id)
                print("[CardEditor] Deleted old front photo: \(oldAttachment.id)")
            }
            
            do {
                let attachment = try await attachmentService.addAttachment(
                    to: cardId,
                    fileData: imageData,
                    fileName: fileName,
                    mimeType: "image/jpeg",
                    watermarkText: nil
                )
                print("[CardEditor] Front photo saved successfully: \(attachment.id)")
            } catch {
                print("[CardEditor] Failed to save front photo: \(error)")
            }
        }
        
        // 保存背面照片（如果有）
        if let backImage = backPhoto,
           let imageData = backImage.jpegData(compressionQuality: 0.8) {
            let fileName = selectedType.backPhotoFileName
            print("[CardEditor] Saving back photo: \(fileName), size: \(imageData.count)")
            
            // 删除同名旧附件
            if let oldAttachment = existingAttachments.first(where: { $0.fileName == fileName }) {
                try? await attachmentService.deleteAttachment(id: oldAttachment.id)
                print("[CardEditor] Deleted old back photo: \(oldAttachment.id)")
            }
            
            do {
                let attachment = try await attachmentService.addAttachment(
                    to: cardId,
                    fileData: imageData,
                    fileName: fileName,
                    mimeType: "image/jpeg",
                    watermarkText: nil
                )
                print("[CardEditor] Back photo saved successfully: \(attachment.id)")
            } catch {
                print("[CardEditor] Failed to save back photo: \(error)")
            }
        }
    }
    
    // MARK: - OCR Field Mapping
    
    /// 将文档类型映射到卡片类型
    private func mapDocumentTypeToCardType(_ documentType: DocumentType) -> CardType {
        switch documentType {
        case .idCard:
            return .idCard
        case .passport:
            return .passport
        case .driversLicense:
            return .driversLicense
        case .businessLicense:
            return .businessLicense
        case .residencePermit:
            return .residencePermit
        case .socialSecurityCard:
            return .socialSecurityCard
        case .bankCard:
            return .bankCard
        case .invoice:
            return .invoice
        case .unknown:
            return .general
        }
    }
    
    /// 标准化字段值（日期格式、大小写等）
    private func normalizeFields(_ fields: [String: String]) -> [String: String] {
        var normalized = fields
        
        // 标准化日期字段
        let dateKeys = ["birthDate", "issueDate", "expiryDate", "validFrom", "validUntil", "establishedDate"]
        for key in dateKeys {
            if let dateValue = normalized[key] {
                let standardized = dateValue
                    .replacingOccurrences(of: "年", with: "-")
                    .replacingOccurrences(of: "月", with: "-")
                    .replacingOccurrences(of: "日", with: "")
                normalized[key] = standardized
            }
        }
        
        // 标准化身份证号
        if let idNumber = normalized["idNumber"] {
            normalized["idNumber"] = idNumber.uppercased()
        }
        
        // 标准化护照号
        if let passportNumber = normalized["passportNumber"] {
            normalized["passportNumber"] = passportNumber.uppercased()
        }
        
        // 标准化性别
        if let gender = normalized["gender"] {
            if gender.contains("男") || gender.lowercased().contains("m") {
                normalized["gender"] = "男"
            } else if gender.contains("女") || gender.lowercased().contains("f") {
                normalized["gender"] = "女"
            }
        }
        
        return normalized
    }
    
    /// 通用的 OCR 字段填充方法
    /// - Parameters:
    ///   - ocrFields: OCR 识别的字段字典
    ///   - isFrontSide: 是否为正面照片
    private func fillFieldsFromOCR(_ ocrFields: [String: String], isFrontSide: Bool) {
        // 获取当前卡片类型的字段定义
        let templateFields = CardTemplateHelper.fields(for: selectedType)
        
        // 创建字段 key 到标签的映射
        let keyToLabelMap = Dictionary(uniqueKeysWithValues: templateFields.map { ($0.key, $0.label) })
        
        // 遍历当前字段列表
        for i in 0..<fields.count {
            let currentLabel = fields[i].label
            
            // 找到对应的字段 key
            if let matchingKey = keyToLabelMap.first(where: { $0.value == currentLabel })?.key,
               let ocrValue = ocrFields[matchingKey],
               !ocrValue.isEmpty {
                
                // 对于背面字段，如果不是正面照片才更新
                let isBackField = ["issuingAuthority", "validPeriod", "issuer"].contains(matchingKey)
                
                if isFrontSide && !isBackField {
                    // 正面照片 - 更新正面字段
                    fields[i].value = ocrValue
                } else if !isFrontSide && isBackField {
                    // 背面照片 - 只更新背面字段
                    fields[i].value = ocrValue
                } else if !isFrontSide && !isBackField {
                    // 背面照片 - 保留正面字段的现有值，不覆盖
                    continue
                } else {
                    // 其他情况 - 更新字段
                    fields[i].value = ocrValue
                }
            }
        }
    }
    
    // MARK: - Legacy Field Fill Methods (保留用于兼容性)
    
    private func fillIDCardFields(from result: IDCardOCRResult, isFrontSide: Bool = true) {
        let nameLabel = "field.idcard.name".localized
        let genderLabel = "field.idcard.gender".localized
        let nationalityLabel = "field.idcard.nationality".localized
        let birthdateLabel = "field.idcard.birthdate".localized
        let numberLabel = "field.idcard.number".localized
        let addressLabel = "field.idcard.address".localized
        let issuerLabel = "field.idcard.issuer".localized
        let validperiodLabel = "field.idcard.validperiod".localized
        
        for i in 0..<fields.count {
            let label = fields[i].label
            
            // 正面字段：姓名、性别、民族、出生日期、身份证号、住址
            if isFrontSide {
                if label == nameLabel, let value = result.name, !value.isEmpty {
                    fields[i].value = value
                }
                if label == genderLabel, let value = result.gender, !value.isEmpty {
                    fields[i].value = value
                }
                if label == nationalityLabel, let value = result.nationality, !value.isEmpty {
                    fields[i].value = value
                }
                if label == birthdateLabel, let value = result.birthDate, !value.isEmpty {
                    fields[i].value = value
                }
                if label == numberLabel, let value = result.idNumber, !value.isEmpty {
                    fields[i].value = value
                }
                if label == addressLabel, let value = result.address, !value.isEmpty {
                    fields[i].value = value
                }
            }
            
            // 背面字段：签发机关、有效期限
            if label == issuerLabel, let value = result.issuer, !value.isEmpty {
                fields[i].value = value
            }
            if label == validperiodLabel, let value = result.validPeriod, !value.isEmpty {
                fields[i].value = value
            }
        }
        
        // 如果标题为空，使用姓名作为标题（仅正面）
        if isFrontSide && title.isEmpty, let name = result.name, !name.isEmpty {
            title = name
        }
    }
    
    private func fillPassportFields(from result: PassportOCRResult) {
        let nameLabel = "field.passport.name".localized
        let nationalityLabel = "field.passport.nationality".localized
        let birthdateLabel = "field.passport.birthdate".localized
        let genderLabel = "field.passport.gender".localized
        let numberLabel = "field.passport.number".localized
        let issuedateLabel = "field.passport.issuedate".localized
        let expirydateLabel = "field.passport.expirydate".localized
        let issuerLabel = "field.passport.issuer".localized
        
        for i in 0..<fields.count {
            let label = fields[i].label
            
            if label == nameLabel, let value = result.name, !value.isEmpty {
                fields[i].value = value
            }
            if label == nationalityLabel, let value = result.nationality, !value.isEmpty {
                fields[i].value = value
            }
            if label == birthdateLabel, let value = result.birthDate, !value.isEmpty {
                fields[i].value = value
            }
            if label == genderLabel, let value = result.gender, !value.isEmpty {
                fields[i].value = value
            }
            if label == numberLabel, let value = result.passportNumber, !value.isEmpty {
                fields[i].value = value
            }
            if label == issuedateLabel, let value = result.issueDate, !value.isEmpty {
                fields[i].value = value
            }
            if label == expirydateLabel, let value = result.expiryDate, !value.isEmpty {
                fields[i].value = value
            }
            if label == issuerLabel, let value = result.issuer, !value.isEmpty {
                fields[i].value = value
            }
        }
        
        // 如果标题为空，使用姓名作为标题
        if title.isEmpty, let name = result.name, !name.isEmpty {
            title = name
        }
    }
    
    private func fillBusinessLicenseFields(from result: BusinessLicenseOCRResult) {
        let companynameLabel = "field.license.companyname".localized
        let companytypeLabel = "field.license.companytype".localized
        let creditcodeLabel = "field.license.creditcode".localized
        let legalrepLabel = "field.license.legalrep".localized
        let capitalLabel = "field.license.capital".localized
        let addressLabel = "field.license.address".localized
        let establishdateLabel = "field.license.establishdate".localized
        let businesstermLabel = "field.license.businessterm".localized
        let scopeLabel = "field.license.scope".localized
        
        for i in 0..<fields.count {
            let label = fields[i].label
            
            if label == companynameLabel, let value = result.companyName, !value.isEmpty {
                fields[i].value = value
            }
            if label == companytypeLabel, let value = result.companyType, !value.isEmpty {
                fields[i].value = value
            }
            if label == creditcodeLabel, let value = result.creditCode, !value.isEmpty {
                fields[i].value = value
            }
            if label == legalrepLabel, let value = result.legalRepresentative, !value.isEmpty {
                fields[i].value = value
            }
            if label == capitalLabel, let value = result.registeredCapital, !value.isEmpty {
                fields[i].value = value
            }
            if label == addressLabel, let value = result.address, !value.isEmpty {
                fields[i].value = value
            }
            if label == establishdateLabel, let value = result.establishedDate, !value.isEmpty {
                fields[i].value = value
            }
            if label == businesstermLabel, let value = result.businessTerm, !value.isEmpty {
                fields[i].value = value
            }
            if label == scopeLabel, let value = result.businessScope, !value.isEmpty {
                fields[i].value = value
            }
        }
        
        // 如果标题为空，使用公司名称作为标题
        if title.isEmpty, let companyName = result.companyName, !companyName.isEmpty {
            title = companyName
        }
    }
    
    /// 当前卡片类型是否支持 OCR
    var supportsOCR: Bool {
        switch selectedType {
        case .idCard, .passport, .businessLicense:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Invoice Text Parsing
    
    /// 解析粘贴的开票信息文本
    func parseInvoiceText(_ text: String) {
        let lines = text.components(separatedBy: .newlines)
        
        var companyName: String?
        var taxId: String?
        var address: String?
        var phone: String?
        var bankName: String?
        var bankAccount: String?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            // 公司名称：包含"公司"、"有限"、"集团"等关键词
            if companyName == nil {
                if trimmed.contains("公司") || trimmed.contains("有限") || trimmed.contains("集团") || trimmed.contains("企业") {
                    // 提取公司名称（去除前缀标签）
                    let name = extractValue(from: trimmed, labels: ["名称", "公司名称", "企业名称", "单位名称", "开票名称"])
                    if !name.isEmpty {
                        companyName = name
                    } else if !trimmed.hasPrefix("地址") && !trimmed.hasPrefix("开户") {
                        companyName = trimmed
                    }
                }
            }
            
            // 税号/纳税人识别号：18位数字字母组合
            if taxId == nil {
                if let match = trimmed.range(of: "[0-9A-Z]{15,20}", options: .regularExpression) {
                    let code = String(trimmed[match])
                    // 验证是否是有效的税号格式
                    if code.count >= 15 && code.count <= 20 {
                        taxId = code
                    }
                } else {
                    let extracted = extractValue(from: trimmed, labels: ["税号", "纳税人识别号", "识别号", "统一社会信用代码"])
                    if !extracted.isEmpty, let match = extracted.range(of: "[0-9A-Z]{15,20}", options: .regularExpression) {
                        taxId = String(extracted[match])
                    }
                }
            }
            
            // 地址
            if address == nil {
                let extracted = extractValue(from: trimmed, labels: ["地址", "住所", "经营地址", "注册地址", "地址电话"])
                if !extracted.isEmpty {
                    // 如果地址后面跟着电话，分离出来
                    if let phoneRange = extracted.range(of: "\\d{3,4}[-]?\\d{7,8}", options: .regularExpression) {
                        let phoneInAddress = String(extracted[phoneRange])
                        address = extracted.replacingOccurrences(of: phoneInAddress, with: "").trimmingCharacters(in: .whitespaces)
                        if phone == nil {
                            phone = phoneInAddress
                        }
                    } else {
                        address = extracted
                    }
                }
            }
            
            // 电话
            if phone == nil {
                let extracted = extractValue(from: trimmed, labels: ["电话", "联系电话", "手机", "Tel", "TEL"])
                if !extracted.isEmpty {
                    phone = extracted.replacingOccurrences(of: "：", with: "").replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespaces)
                } else if let match = trimmed.range(of: "\\d{3,4}[-]?\\d{7,8}|1[3-9]\\d{9}", options: .regularExpression) {
                    // 直接匹配电话号码格式
                    let potentialPhone = String(trimmed[match])
                    if potentialPhone.count >= 7 {
                        phone = potentialPhone
                    }
                }
            }
            
            // 开户行
            if bankName == nil {
                let extracted = extractValue(from: trimmed, labels: ["开户行", "开户银行", "银行"])
                if !extracted.isEmpty {
                    bankName = extracted
                } else if trimmed.contains("银行") && !trimmed.contains("账号") && !trimmed.contains("帐号") {
                    bankName = trimmed
                }
            }
            
            // 银行账号
            if bankAccount == nil {
                let extracted = extractValue(from: trimmed, labels: ["账号", "帐号", "银行账号", "银行帐号", "账户"])
                if !extracted.isEmpty {
                    // 提取纯数字账号
                    let digits = extracted.filter { $0.isNumber }
                    if digits.count >= 10 {
                        bankAccount = digits
                    }
                } else if let match = trimmed.range(of: "\\d{10,25}", options: .regularExpression) {
                    // 直接匹配银行账号格式（10-25位数字）
                    let potentialAccount = String(trimmed[match])
                    if potentialAccount.count >= 10 && bankAccount == nil {
                        bankAccount = potentialAccount
                    }
                }
            }
        }
        
        // 填充字段
        let companyNameLabel = "field.companyname".localized
        let taxIdLabel = "field.taxid".localized
        let addressLabel = "field.address".localized
        let phoneLabel = "field.phone".localized
        let bankNameLabel = "field.bankname".localized
        let bankAccountLabel = "field.bankaccount".localized
        
        for i in 0..<fields.count {
            let label = fields[i].label
            
            if label == companyNameLabel, let value = companyName, !value.isEmpty {
                fields[i].value = value
            }
            if label == taxIdLabel, let value = taxId, !value.isEmpty {
                fields[i].value = value
            }
            if label == addressLabel, let value = address, !value.isEmpty {
                fields[i].value = value
            }
            if label == phoneLabel, let value = phone, !value.isEmpty {
                fields[i].value = value
            }
            if label == bankNameLabel, let value = bankName, !value.isEmpty {
                fields[i].value = value
            }
            if label == bankAccountLabel, let value = bankAccount, !value.isEmpty {
                fields[i].value = value
            }
        }
        
        // 如果标题为空，使用公司名称作为标题
        if title.isEmpty, let name = companyName, !name.isEmpty {
            title = name
        }
    }
    
    /// 从文本中提取标签后的值
    private func extractValue(from text: String, labels: [String]) -> String {
        for label in labels {
            // 尝试匹配 "标签：值" 或 "标签:值" 或 "标签 值" 格式
            if text.contains(label) {
                var value = text
                // 移除标签
                if let range = text.range(of: label) {
                    value = String(text[range.upperBound...])
                }
                // 移除冒号和空格
                value = value.trimmingCharacters(in: .whitespaces)
                if value.hasPrefix("：") || value.hasPrefix(":") {
                    value = String(value.dropFirst())
                }
                return value.trimmingCharacters(in: .whitespaces)
            }
        }
        return ""
    }
}

// MARK: - CardType Extensions for UI

extension CardType {
    /// 证件正面照片的附件文件名
    var frontPhotoFileName: String {
        switch self {
        case .idCard:
            return "idcard_front.jpg"
        case .passport:
            return "passport_datapage.jpg"
        case .driversLicense:
            return "driverslicense_front.jpg"
        case .residencePermit:
            return "residencepermit_front.jpg"
        case .socialSecurityCard:
            return "socialsecuritycard.jpg"
        case .bankCard:
            return "bankcard_front.jpg"
        case .businessLicense:
            return "businesslicense.jpg"
        default:
            return "document_front.jpg"
        }
    }
    
    /// 证件背面照片的附件文件名
    var backPhotoFileName: String {
        switch self {
        case .idCard:
            return "idcard_back.jpg"
        case .driversLicense:
            return "driverslicense_back.jpg"
        case .residencePermit:
            return "residencepermit_back.jpg"
        default:
            return "document_back.jpg"
        }
    }
    
    /// 是否有背面（需要上传两张照片）
    var hasBackSide: Bool {
        switch self {
        case .idCard, .driversLicense, .residencePermit:
            return true
        case .passport, .businessLicense, .socialSecurityCard, .bankCard:
            return false
        default:
            return false
        }
    }
    
    /// 正面照片标签
    var frontPhotoLabel: String {
        switch self {
        case .idCard:
            return "ocr.idcard.front".localized
        case .passport:
            return "ocr.passport.datapage".localized
        case .businessLicense:
            return "ocr.license.photo".localized
        case .driversLicense:
            return "驾照正面 / Driver's License Front"
        case .residencePermit:
            return "居留卡正面 / Residence Permit Front"
        case .socialSecurityCard:
            return "社保卡照片 / Social Security Card Photo"
        case .bankCard:
            return "银行卡正面 / Bank Card Front"
        default:
            return "ocr.photo.front".localized
        }
    }
    
    /// 背面照片标签
    var backPhotoLabel: String {
        switch self {
        case .idCard:
            return "ocr.idcard.back".localized
        case .driversLicense:
            return "驾照背面 / Driver's License Back"
        case .residencePermit:
            return "居留卡背面 / Residence Permit Back"
        default:
            return "ocr.photo.back".localized
        }
    }
    
    /// 照片上传提示
    var photoUploadHint: String {
        switch self {
        case .idCard:
            return "ocr.hint.idcard".localized
        case .passport:
            return "ocr.hint.passport".localized
        case .businessLicense:
            return "ocr.hint.license".localized
        case .driversLicense:
            return "请拍摄驾照正反面，确保文字清晰可读 / Please take photos of both sides of the driver's license with clear text"
        case .residencePermit:
            return "请拍摄居留许可证，确保信息完整 / Please take photos of the residence permit with complete information"
        case .socialSecurityCard:
            return "请拍摄社保卡，确保卡号清晰 / Please take a photo of the social security card with clear card number"
        case .bankCard:
            return "请拍摄银行卡正面，注意保护敏感信息 / Please take a photo of the bank card front, protect sensitive information"
        default:
            return ""
        }
    }
    
    /// 附件上传提示信息
    var attachmentHints: [(label: String, required: Bool)] {
        switch self {
        case .idCard:
            return [
                ("attachment.idcard.front".localized, false),
                ("attachment.idcard.back".localized, false)
            ]
        case .passport:
            return [
                ("attachment.passport.datapage".localized, false)
            ]
        case .driversLicense:
            return [
                ("驾照正面 / Driver's License Front", false),
                ("驾照背面 / Driver's License Back", false)
            ]
        case .businessLicense:
            return [
                ("attachment.license.photo".localized, false)
            ]
        case .residencePermit:
            return [
                ("居留卡正面 / Residence Permit Front", false),
                ("居留卡背面 / Residence Permit Back", false)
            ]
        case .socialSecurityCard:
            return [
                ("社保卡照片 / Social Security Card Photo", false)
            ]
        case .bankCard:
            return [
                ("银行卡正面 / Bank Card Front", false)
            ]
        default:
            return []
        }
    }
}
