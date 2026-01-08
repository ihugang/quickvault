import Combine
import Foundation
import QuickVaultCore

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
    @Published var errorMessage: String?
    @Published var validationErrors: [String: String] = [:]
    
    // MARK: - Card Type
    
    enum CardType: String, CaseIterable, Identifiable {
        case address = "Address"
        case invoice = "Invoice"
        case generalText = "GeneralText"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .address: return "地址 / Address"
            case .invoice: return "发票 / Invoice"
            case .generalText: return "通用文本 / General Text"
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
    let groupDisplayNames = ["个人 / Personal", "公司 / Company"]
    
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
    
    init(cardService: CardService) {
        self.cardService = cardService
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
                EditableField(id: UUID(), label: "姓名 / Name", value: "", isRequired: true, isCopyable: true, order: 0),
                EditableField(id: UUID(), label: "电话 / Phone", value: "", isRequired: true, isCopyable: true, order: 1),
                EditableField(id: UUID(), label: "省份 / Province", value: "", isRequired: true, isCopyable: true, order: 2),
                EditableField(id: UUID(), label: "城市 / City", value: "", isRequired: true, isCopyable: true, order: 3),
                EditableField(id: UUID(), label: "区县 / District", value: "", isRequired: true, isCopyable: true, order: 4),
                EditableField(id: UUID(), label: "详细地址 / Address", value: "", isRequired: true, isCopyable: true, order: 5),
                EditableField(id: UUID(), label: "邮编 / Postal Code", value: "", isRequired: false, isCopyable: true, order: 6),
                EditableField(id: UUID(), label: "备注 / Notes", value: "", isRequired: false, isCopyable: false, order: 7),
            ]
            
        case .invoice:
            fields = [
                EditableField(id: UUID(), label: "公司名称 / Company Name", value: "", isRequired: true, isCopyable: true, order: 0),
                EditableField(id: UUID(), label: "税号 / Tax ID", value: "", isRequired: true, isCopyable: true, order: 1),
                EditableField(id: UUID(), label: "地址 / Address", value: "", isRequired: true, isCopyable: true, order: 2),
                EditableField(id: UUID(), label: "电话 / Phone", value: "", isRequired: true, isCopyable: true, order: 3),
                EditableField(id: UUID(), label: "开户银行 / Bank Name", value: "", isRequired: true, isCopyable: true, order: 4),
                EditableField(id: UUID(), label: "银行账号 / Bank Account", value: "", isRequired: true, isCopyable: true, order: 5),
                EditableField(id: UUID(), label: "备注 / Notes", value: "", isRequired: false, isCopyable: false, order: 6),
            ]
            
        case .generalText:
            fields = [
                EditableField(id: UUID(), label: "内容 / Content", value: "", isRequired: true, isCopyable: true, order: 0),
            ]
        }
    }
    
    private func isFieldRequired(label: String, type: CardType) -> Bool {
        let optionalLabels = ["邮编 / Postal Code", "备注 / Notes"]
        return !optionalLabels.contains(label)
    }
    
    // MARK: - Validation
    
    func validateFields() -> Bool {
        validationErrors = [:]
        var isValid = true
        
        // Validate title
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["title"] = "标题不能为空 / Title is required"
            isValid = false
        }
        
        // Validate required fields
        for field in fields where field.isRequired {
            if field.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationErrors[field.id.uuidString] = "\(field.label) 不能为空 / \(field.label) is required"
                isValid = false
            }
        }
        
        // Validate phone number for address cards
        if selectedType == .address {
            if let phoneField = fields.first(where: { $0.label.contains("电话") || $0.label.contains("Phone") }) {
                if !phoneField.value.isEmpty && !isValidPhoneNumber(phoneField.value) {
                    validationErrors[phoneField.id.uuidString] = "电话格式无效 / Invalid phone format"
                    isValid = false
                }
            }
        }
        
        // Validate tax ID for invoice cards
        if selectedType == .invoice {
            if let taxIdField = fields.first(where: { $0.label.contains("税号") || $0.label.contains("Tax ID") }) {
                if !taxIdField.value.isEmpty && !isValidTaxId(taxIdField.value) {
                    validationErrors[taxIdField.id.uuidString] = "税号必须为18位 / Tax ID must be 18 characters"
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
            } else {
                // Create new card
                savedCard = try await cardService.createCard(
                    title: title,
                    group: selectedGroup,
                    type: selectedType.rawValue,
                    fields: fieldDTOs,
                    tags: tags
                )
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
}
