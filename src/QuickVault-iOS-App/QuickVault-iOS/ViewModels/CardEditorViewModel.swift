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
    @Published var selectedType: CardType = .address
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
    
    // MARK: - Card Type
    
    enum CardType: String, CaseIterable, Identifiable {
        case address = "Address"
        case invoice = "Invoice"
        case generalText = "GeneralText"
        case idCard = "IdCard"
        case passport = "Passport"
        case businessLicense = "BusinessLicense"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .address: return "cards.type.address".localized
            case .invoice: return "cards.type.invoice".localized
            case .generalText: return "cards.type.general".localized
            case .idCard: return "cards.type.idcard".localized
            case .passport: return "cards.type.passport".localized
            case .businessLicense: return "cards.type.businesslicense".localized
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
            case .businessLicense:
                return [
                    ("attachment.license.photo".localized, false)
                ]
            default:
                return []
            }
        }
    }
    
    // MARK: - Editable Field
    
    struct EditableField: Identifiable {
        let id: UUID
        var label: String
        var value: String
        var isRequired: Bool
        var isCopyable: Bool
        var order: Int16
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
        !title.isEmpty && validateFields()
    }
    
    // MARK: - Initialization
    
    init(cardService: CardService, attachmentService: AttachmentService? = nil) {
        self.cardService = cardService
        self.attachmentService = attachmentService ?? AttachmentServiceImpl.shared
        setupFieldsForType(.address)
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
            
        case .generalText:
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
                EditableField(id: UUID(), label: "field.passport.issuer".localized, value: "", isRequired: false, isCopyable: true, order: 7),
            ]
            
        case .businessLicense:
            fields = [
                EditableField(id: UUID(), label: "field.license.companyname".localized, value: "", isRequired: true, isCopyable: true, order: 0),
                EditableField(id: UUID(), label: "field.license.companytype".localized, value: "", isRequired: false, isCopyable: true, order: 1),
                EditableField(id: UUID(), label: "field.license.creditcode".localized, value: "", isRequired: true, isCopyable: true, order: 2),
                EditableField(id: UUID(), label: "field.license.legalrep".localized, value: "", isRequired: true, isCopyable: true, order: 3),
                EditableField(id: UUID(), label: "field.license.capital".localized, value: "", isRequired: false, isCopyable: true, order: 4),
                EditableField(id: UUID(), label: "field.license.address".localized, value: "", isRequired: false, isCopyable: true, order: 5),
                EditableField(id: UUID(), label: "field.license.establishdate".localized, value: "", isRequired: false, isCopyable: true, order: 6),
                EditableField(id: UUID(), label: "field.license.businessterm".localized, value: "", isRequired: false, isCopyable: true, order: 7),
                EditableField(id: UUID(), label: "field.license.scope".localized, value: "", isRequired: false, isCopyable: true, order: 8),
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
            switch selectedType {
            case .idCard:
                // 正面照片时清空所有字段，背面照片时只更新背面特有字段
                if isFrontSide {
                    clearAllFields()
                }
                let result = try await ocrService.recognizeIDCard(image: image)
                fillIDCardFields(from: result, isFrontSide: isFrontSide)
                
            case .passport:
                clearAllFields()
                let result = try await ocrService.recognizePassport(image: image)
                fillPassportFields(from: result)
                
            case .businessLicense:
                clearAllFields()
                let result = try await ocrService.recognizeBusinessLicense(image: image)
                fillBusinessLicenseFields(from: result)
                
            default:
                break
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
}
