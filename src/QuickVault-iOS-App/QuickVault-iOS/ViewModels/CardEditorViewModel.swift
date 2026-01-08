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
        case idCard = "IdCard"
        case businessLicense = "BusinessLicense"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .address: return "cards.type.address".localized
            case .invoice: return "cards.type.invoice".localized
            case .generalText: return "cards.type.general".localized
            case .idCard: return "cards.type.idcard".localized
            case .businessLicense: return "cards.type.businesslicense".localized
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
            
        case .businessLicense:
            fields = [
                EditableField(id: UUID(), label: "field.license.companyname".localized, value: "", isRequired: true, isCopyable: true, order: 0),
                EditableField(id: UUID(), label: "field.license.creditcode".localized, value: "", isRequired: true, isCopyable: true, order: 1),
                EditableField(id: UUID(), label: "field.license.legalrep".localized, value: "", isRequired: true, isCopyable: true, order: 2),
                EditableField(id: UUID(), label: "field.license.capital".localized, value: "", isRequired: true, isCopyable: true, order: 3),
                EditableField(id: UUID(), label: "field.license.address".localized, value: "", isRequired: true, isCopyable: true, order: 4),
                EditableField(id: UUID(), label: "field.license.establishdate".localized, value: "", isRequired: true, isCopyable: true, order: 5),
                EditableField(id: UUID(), label: "field.license.scope".localized, value: "", isRequired: false, isCopyable: true, order: 6),
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
