import Combine
import Foundation
import QuickHoldCore
import UIKit

/// Card detail view model / 卡片详情视图模型
@MainActor
class CardDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var card: CardDTO?
    @Published var editableFields: [EditableField] = []
    @Published var isEditing: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var toastMessage: String?
    
    // MARK: - Dependencies
    
    private let cardService: CardService
    private let cryptoService: CryptoService
    
    // MARK: - Editable Field Model
    
    struct EditableField: Identifiable {
        let id: UUID
        var label: String
        var value: String
        var isCopyable: Bool
        var order: Int16
    }
    
    // MARK: - Initialization
    
    init(cardService: CardService, cryptoService: CryptoService) {
        self.cardService = cardService
        self.cryptoService = cryptoService
    }
    
    // MARK: - Load Card
    
    func loadCard(id: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            card = try await cardService.fetchCard(id: id)
            if let card = card {
                editableFields = card.fields.map { field in
                    EditableField(
                        id: field.id,
                        label: field.label,
                        value: field.value,
                        isCopyable: field.isCopyable,
                        order: field.order
                    )
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Edit Mode
    
    func startEditing() {
        isEditing = true
    }
    
    func cancelEditing() {
        isEditing = false
        // Restore original values
        if let card = card {
            editableFields = card.fields.map { field in
                EditableField(
                    id: field.id,
                    label: field.label,
                    value: field.value,
                    isCopyable: field.isCopyable,
                    order: field.order
                )
            }
        }
    }
    
    // MARK: - Save Card
    
    func saveCard() async -> Bool {
        guard let card = card else { return false }
        
        isLoading = true
        errorMessage = nil
        
        let fieldDTOs = editableFields.map { field in
            CardFieldDTO(
                id: field.id,
                label: field.label,
                value: field.value,
                isCopyable: field.isCopyable,
                order: field.order
            )
        }
        
        do {
            let updatedCard = try await cardService.updateCard(
                id: card.id,
                title: card.title,
                group: card.group,
                fields: fieldDTOs,
                tags: card.tags
            )
            self.card = updatedCard
            isEditing = false
            toastMessage = "保存成功 / Saved successfully"
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - Copy Operations
    
    func copyCard() {
        guard let card = card else { return }
        
        let formattedText = formatCardForCopy(card)
        UIPasteboard.general.string = formattedText
        toastMessage = "已复制卡片 / Card copied"
    }
    
    func copyField(_ field: CardFieldDTO) {
        UIPasteboard.general.string = field.value
        toastMessage = "已复制 \(field.label) / \(field.label) copied"
    }
    
    func copyFieldValue(_ value: String, label: String) {
        UIPasteboard.general.string = value
        toastMessage = "已复制 \(label) / \(label) copied"
    }
    
    // MARK: - Format Card for Copy
    
    private func formatCardForCopy(_ card: CardDTO) -> String {
        var lines: [String] = []
        
        for field in card.fields.sorted(by: { $0.order < $1.order }) {
            if !field.value.isEmpty {
                lines.append("\(field.label): \(field.value)")
            }
        }
        
        return lines.joined(separator: "\n")
    }
    
    // MARK: - Delete Card
    
    func deleteCard() async -> Bool {
        guard let card = card else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await cardService.deleteCard(id: card.id)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - Clear Messages

    func clearError() {
        errorMessage = nil
    }

    func clearToast() {
        toastMessage = nil
    }

    // MARK: - Export Functions

    /// Export card as formatted text
    func exportAsText() {
        guard let card = card else { return }

        let formattedText = formatCardForCopy(card)
        UIPasteboard.general.string = formattedText
        toastMessage = "已复制到剪贴板 / Copied to clipboard"
    }

    /// Check if card has image attachments
    func hasImageAttachments(cardId: UUID) async -> Bool {
        do {
            let attachmentService = AttachmentServiceImpl.shared
            let attachments = try await attachmentService.fetchAttachments(for: cardId)
            return !attachments.isEmpty && attachments.contains { attachment in
                attachment.mimeType.contains("image")
            }
        } catch {
            return false
        }
    }

    /// Export all image attachments with watermark
    func exportImagesWithWatermark(cardId: UUID, watermarkText: String?) async {
        do {
            let attachmentService = AttachmentServiceImpl.shared
            let attachments = try await attachmentService.fetchAttachments(for: cardId)

            // Filter only image attachments
            let imageAttachments = attachments.filter { $0.mimeType.contains("image") }

            guard !imageAttachments.isEmpty else {
                toastMessage = "没有图片附件 / No image attachments"
                return
            }

            // Collect all processed image URLs
            var imageURLs: [URL] = []

            for attachment in imageAttachments {
                let url = try await attachmentService.shareAttachment(id: attachment.id, watermarkText: watermarkText)
                imageURLs.append(url)
            }

            // Present share sheet with all images
            await MainActor.run {
                let activityVC = UIActivityViewController(activityItems: imageURLs, applicationActivities: nil)

                // Add completion handler to show proper feedback based on user action
                activityVC.completionWithItemsHandler = { [weak self] activityType, completed, returnedItems, error in
                    Task { @MainActor in
                        if let error = error {
                            self?.toastMessage = "分享失败 / Share failed: \(error.localizedDescription)"
                        } else if completed {
                            self?.toastMessage = "已导出 \(imageURLs.count) 张图片 / Exported \(imageURLs.count) images"
                        }
                        // If cancelled (completed == false), don't show any message
                    }
                }

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    var presentingVC = rootVC
                    while let presented = presentingVC.presentedViewController {
                        presentingVC = presented
                    }
                    presentingVC.present(activityVC, animated: true)
                }
            }
        } catch {
            toastMessage = "导出失败 / Export failed: \(error.localizedDescription)"
        }
    }
}
