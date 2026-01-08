import Foundation
import QuickVaultCore
import UIKit

// MARK: - Attachment Errors / 附件错误

enum AttachmentError: LocalizedError {
    case fileTooLarge  // 文件过大
    case unsupportedFormat  // 不支持的格式
    case encryptionFailed  // 加密失败
    case decryptionFailed  // 解密失败
    case attachmentNotFound  // 附件未找到
    case thumbnailGenerationFailed  // 缩略图生成失败
    case databaseError(String)  // 数据库错误
    
    var errorDescription: String? {
        switch self {
        case .fileTooLarge:
            return "文件大小超过 10MB 限制 / File size exceeds 10MB limit"
        case .unsupportedFormat:
            return "不支持的文件格式 / Unsupported file format"
        case .encryptionFailed:
            return "加密附件失败 / Failed to encrypt attachment"
        case .decryptionFailed:
            return "解密附件失败 / Failed to decrypt attachment"
        case .attachmentNotFound:
            return "附件未找到 / Attachment not found"
        case .thumbnailGenerationFailed:
            return "生成缩略图失败 / Failed to generate thumbnail"
        case .databaseError(let message):
            return "数据库错误: \(message) / Database error: \(message)"
        }
    }
}

// MARK: - Attachment DTO / 附件数据传输对象

struct AttachmentDTO: Identifiable, Hashable {
    let id: UUID
    let fileName: String
    let mimeType: String
    let fileSize: Int64
    let hasWatermark: Bool
    let watermarkText: String?
    let thumbnailImage: UIImage?
    let createdAt: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AttachmentDTO, rhs: AttachmentDTO) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Attachment Service Protocol / 附件服务协议

protocol AttachmentService {
    func addAttachment(to cardId: UUID, fileData: Data, fileName: String, mimeType: String, watermarkText: String?) async throws -> AttachmentDTO
    func deleteAttachment(id: UUID) async throws
    func fetchAttachments(for cardId: UUID) async throws -> [AttachmentDTO]
    func getAttachmentData(id: UUID) async throws -> Data
    func updateWatermark(id: UUID, text: String?) async throws -> AttachmentDTO
    func shareAttachment(id: UUID) async throws -> URL
}

// MARK: - Attachment Service Implementation / 附件服务实现

class AttachmentServiceImpl: AttachmentService {
    
    // MARK: - Constants
    
    private let maxFileSize: Int64 = 10 * 1024 * 1024  // 10MB
    private let supportedImageTypes = ["image/jpeg", "image/png", "image/heic"]
    private let supportedDocumentTypes = ["application/pdf"]
    private let thumbnailSize = CGSize(width: 200, height: 200)
    
    // MARK: - Dependencies
    
    private let persistenceController: PersistenceController
    private let cryptoService: CryptoService
    private let watermarkService: WatermarkService
    
    // MARK: - Initialization
    
    init(persistenceController: PersistenceController, cryptoService: CryptoService, watermarkService: WatermarkService) {
        self.persistenceController = persistenceController
        self.cryptoService = cryptoService
        self.watermarkService = watermarkService
    }
    
    // MARK: - Add Attachment
    
    func addAttachment(to cardId: UUID, fileData: Data, fileName: String, mimeType: String, watermarkText: String?) async throws -> AttachmentDTO {
        // Validate file size
        guard fileData.count <= maxFileSize else {
            throw AttachmentError.fileTooLarge
        }
        
        // Validate file type
        let allSupportedTypes = supportedImageTypes + supportedDocumentTypes
        guard allSupportedTypes.contains(mimeType) else {
            throw AttachmentError.unsupportedFormat
        }
        
        var processedData = fileData
        var thumbnailData: Data?
        
        // Apply watermark if requested and it's an image
        if let watermarkText = watermarkText, supportedImageTypes.contains(mimeType) {
            if let image = UIImage(data: fileData),
               let watermarkedImage = watermarkService.applyWatermark(to: image, text: watermarkText, style: .default) {
                processedData = watermarkedImage.jpegData(compressionQuality: 0.9) ?? fileData
            }
        }
        
        // Generate thumbnail for images
        if supportedImageTypes.contains(mimeType) {
            thumbnailData = generateThumbnail(from: processedData)
        }
        
        // Encrypt the file data
        let encryptedData: Data
        do {
            encryptedData = try cryptoService.encryptFile(processedData)
        } catch {
            throw AttachmentError.encryptionFailed
        }
        
        // Encrypt thumbnail if exists
        var encryptedThumbnail: Data?
        if let thumbnail = thumbnailData {
            encryptedThumbnail = try? cryptoService.encryptFile(thumbnail)
        }
        
        // Save to CoreData
        let context = persistenceController.container.viewContext
        
        return try await context.perform {
            // Find the card
            let fetchRequest = Card.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", cardId as CVarArg)
            fetchRequest.fetchLimit = 1
            
            guard let card = try context.fetch(fetchRequest).first else {
                throw CardServiceError.cardNotFound
            }
            
            // Create attachment
            let attachment = CardAttachment(context: context)
            attachment.id = UUID()
            attachment.fileName = fileName
            attachment.fileType = mimeType
            attachment.encryptedData = encryptedData
            attachment.thumbnailData = encryptedThumbnail
            attachment.watermarkText = watermarkText
            attachment.fileSize = Int64(fileData.count)
            attachment.createdAt = Date()
            attachment.card = card
            
            try context.save()
            
            // Return DTO
            return AttachmentDTO(
                id: attachment.id,
                fileName: fileName,
                mimeType: mimeType,
                fileSize: Int64(fileData.count),
                hasWatermark: watermarkText != nil,
                watermarkText: watermarkText,
                thumbnailImage: thumbnailData.flatMap { UIImage(data: $0) },
                createdAt: attachment.createdAt
            )
        }
    }
    
    // MARK: - Delete Attachment
    
    func deleteAttachment(id: UUID) async throws {
        let context = persistenceController.container.viewContext
        
        try await context.perform {
            let fetchRequest = CardAttachment.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            guard let attachment = try context.fetch(fetchRequest).first else {
                throw AttachmentError.attachmentNotFound
            }
            
            context.delete(attachment)
            try context.save()
        }
    }
    
    // MARK: - Fetch Attachments
    
    func fetchAttachments(for cardId: UUID) async throws -> [AttachmentDTO] {
        let context = persistenceController.container.viewContext
        
        return try await context.perform {
            let fetchRequest = CardAttachment.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "card.id == %@", cardId as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let attachments = try context.fetch(fetchRequest)
            
            return attachments.map { attachment in
                // Decrypt thumbnail if exists
                var thumbnailImage: UIImage?
                if let encryptedThumbnail = attachment.thumbnailData {
                    if let decryptedThumbnail = try? self.cryptoService.decryptFile(encryptedThumbnail) {
                        thumbnailImage = UIImage(data: decryptedThumbnail)
                    }
                }
                
                return AttachmentDTO(
                    id: attachment.id,
                    fileName: attachment.fileName,
                    mimeType: attachment.fileType,
                    fileSize: attachment.fileSize,
                    hasWatermark: attachment.watermarkText != nil,
                    watermarkText: attachment.watermarkText,
                    thumbnailImage: thumbnailImage,
                    createdAt: attachment.createdAt
                )
            }
        }
    }
    
    // MARK: - Get Attachment Data
    
    func getAttachmentData(id: UUID) async throws -> Data {
        let context = persistenceController.container.viewContext
        
        return try await context.perform {
            let fetchRequest = CardAttachment.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            guard let attachment = try context.fetch(fetchRequest).first else {
                throw AttachmentError.attachmentNotFound
            }
            
            guard let encryptedData = attachment.encryptedData else {
                throw AttachmentError.attachmentNotFound
            }
            
            do {
                return try self.cryptoService.decryptFile(encryptedData)
            } catch {
                throw AttachmentError.decryptionFailed
            }
        }
    }
    
    // MARK: - Update Watermark
    
    func updateWatermark(id: UUID, text: String?) async throws -> AttachmentDTO {
        let context = persistenceController.container.viewContext
        
        return try await context.perform {
            let fetchRequest = CardAttachment.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            guard let attachment = try context.fetch(fetchRequest).first else {
                throw AttachmentError.attachmentNotFound
            }
            
            // Only process images
            guard self.supportedImageTypes.contains(attachment.fileType) else {
                throw AttachmentError.unsupportedFormat
            }
            
            guard let encryptedData = attachment.encryptedData else {
                throw AttachmentError.attachmentNotFound
            }
            
            // Decrypt original data
            let originalData: Data
            do {
                originalData = try self.cryptoService.decryptFile(encryptedData)
            } catch {
                throw AttachmentError.decryptionFailed
            }
            
            guard let image = UIImage(data: originalData) else {
                throw AttachmentError.decryptionFailed
            }
            
            var processedData = originalData
            
            // Apply new watermark if text provided
            if let watermarkText = text {
                if let watermarkedImage = self.watermarkService.applyWatermark(to: image, text: watermarkText, style: .default) {
                    processedData = watermarkedImage.jpegData(compressionQuality: 0.9) ?? originalData
                }
            }
            
            // Re-encrypt
            let newEncryptedData: Data
            do {
                newEncryptedData = try self.cryptoService.encryptFile(processedData)
            } catch {
                throw AttachmentError.encryptionFailed
            }
            
            // Update thumbnail
            var encryptedThumbnail: Data?
            if let thumbnailData = self.generateThumbnail(from: processedData) {
                encryptedThumbnail = try? self.cryptoService.encryptFile(thumbnailData)
            }
            
            // Update attachment
            attachment.encryptedData = newEncryptedData
            attachment.thumbnailData = encryptedThumbnail
            attachment.watermarkText = text
            
            try context.save()
            
            // Decrypt thumbnail for DTO
            var thumbnailImage: UIImage?
            if let encryptedThumbnail = encryptedThumbnail,
               let decryptedThumbnail = try? self.cryptoService.decryptFile(encryptedThumbnail) {
                thumbnailImage = UIImage(data: decryptedThumbnail)
            }
            
            return AttachmentDTO(
                id: attachment.id,
                fileName: attachment.fileName,
                mimeType: attachment.fileType,
                fileSize: attachment.fileSize,
                hasWatermark: text != nil,
                watermarkText: text,
                thumbnailImage: thumbnailImage,
                createdAt: attachment.createdAt
            )
        }
    }
    
    // MARK: - Share Attachment
    
    func shareAttachment(id: UUID) async throws -> URL {
        let data = try await getAttachmentData(id: id)
        
        let context = persistenceController.container.viewContext
        
        return try await context.perform {
            let fetchRequest = CardAttachment.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            guard let attachment = try context.fetch(fetchRequest).first else {
                throw AttachmentError.attachmentNotFound
            }
            
            // Create temporary file for sharing
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(attachment.fileName)
            
            try data.write(to: fileURL)
            
            return fileURL
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateThumbnail(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        
        let scale = min(thumbnailSize.width / image.size.width, thumbnailSize.height / image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        
        guard let thumbnail = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        
        return thumbnail.jpegData(compressionQuality: 0.7)
    }
}
