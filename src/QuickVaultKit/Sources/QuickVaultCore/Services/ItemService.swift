//
//  ItemService.swift
//  QuickVault
//

import CoreData
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Item Data Transfer Object / 数据传输对象

public struct ItemDTO: Hashable, Identifiable, Sendable {
  public let id: UUID
  public let title: String
  public let type: ItemType
  public let tags: [String]
  public let isPinned: Bool
  public let createdAt: Date
  public let updatedAt: Date
  public let textContent: String?
  public let images: [ImageDTO]?

  public init(
    id: UUID,
    title: String,
    type: ItemType,
    tags: [String],
    isPinned: Bool,
    createdAt: Date,
    updatedAt: Date,
    textContent: String?,
    images: [ImageDTO]?
  ) {
    self.id = id
    self.title = title
    self.type = type
    self.tags = tags
    self.isPinned = isPinned
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.textContent = textContent
    self.images = images
  }
}

public struct ImageDTO: Hashable, Identifiable, Sendable {
  public let id: UUID
  public let fileName: String
  public let fileSize: Int64
  public let displayOrder: Int16
  public let thumbnailData: Data?

  public init(id: UUID, fileName: String, fileSize: Int64, displayOrder: Int16, thumbnailData: Data?) {
    self.id = id
    self.fileName = fileName
    self.fileSize = fileSize
    self.displayOrder = displayOrder
    self.thumbnailData = thumbnailData
  }
}

public struct ImageData: Sendable {
  public let data: Data
  public let fileName: String

  public init(data: Data, fileName: String) {
    self.data = data
    self.fileName = fileName
  }
}

// MARK: - Item Service Protocol / 服务协议

public protocol ItemService {
  // Create
  func createTextItem(title: String, content: String, tags: [String]) async throws -> ItemDTO
  func createImageItem(title: String, images: [ImageData], tags: [String]) async throws -> ItemDTO

  // Read
  func fetchAllItems() async throws -> [ItemDTO]
  func fetchItem(id: UUID) async throws -> ItemDTO
  func searchItems(query: String) async throws -> [ItemDTO]

  // Update
  func updateTextItem(id: UUID, title: String?, content: String?, tags: [String]?) async throws -> ItemDTO
  func updateImageItem(id: UUID, title: String?, tags: [String]?) async throws -> ItemDTO
  func addImages(to itemId: UUID, images: [ImageData]) async throws
  func removeImage(id: UUID) async throws

  // Delete
  func deleteItem(id: UUID) async throws

  // Other
  func togglePin(id: UUID) async throws -> ItemDTO
  
  // Share
  func getShareableText(id: UUID) async throws -> String
  func getShareableImages(id: UUID, withWatermark: Bool, watermarkText: String?) async throws -> [Data]
  func getDecryptedImage(imageId: UUID) async throws -> Data
}

// MARK: - Item Service Implementation / 服务实现

public final class ItemServiceImpl: ItemService, @unchecked Sendable {

  private let persistenceController: PersistenceController
  private var cryptoService: CryptoService {
    CryptoServiceImpl.shared
  }
  private let context: NSManagedObjectContext

  public init(persistenceController: PersistenceController, cryptoService: CryptoService? = nil) {
    self.persistenceController = persistenceController
    self.context = persistenceController.container.viewContext
  }

  // MARK: - Create

  public func createTextItem(title: String, content: String, tags: [String]) async throws -> ItemDTO {
    return try await context.perform {
      let item = Item(context: self.context)
      item.id = UUID()
      item.title = title
      item.type = ItemType.text.rawValue
      item.tags = tags
      item.isPinned = false
      item.createdAt = Date()
      item.updatedAt = Date()

      // Create text content
      let textContent = TextContent(context: self.context)
      textContent.id = UUID()
      textContent.encryptedContent = try self.cryptoService.encrypt(content)
      textContent.item = item

      try self.context.save()
      return try self.mapToDTO(item)
    }
  }

  public func createImageItem(title: String, images: [ImageData], tags: [String]) async throws -> ItemDTO {
    return try await context.perform {
      let item = Item(context: self.context)
      item.id = UUID()
      item.title = title
      item.type = ItemType.image.rawValue
      item.tags = tags
      item.isPinned = false
      item.createdAt = Date()
      item.updatedAt = Date()

      // Add images
      for (index, imageData) in images.enumerated() {
        let imageContent = ImageContent(context: self.context)
        imageContent.id = UUID()
        imageContent.fileName = imageData.fileName
        imageContent.encryptedData = try self.cryptoService.encryptFile(imageData.data)
        imageContent.fileSize = Int64(imageData.data.count)
        imageContent.displayOrder = Int16(index)
        imageContent.createdAt = Date()
        
        // Generate thumbnail
        #if canImport(UIKit)
        if let thumbnail = self.generateThumbnail(from: imageData.data) {
          imageContent.thumbnailData = try self.cryptoService.encryptFile(thumbnail)
        }
        #endif
        
        imageContent.item = item
      }

      try self.context.save()
      return try self.mapToDTO(item)
    }
  }

  // MARK: - Read

  public func fetchAllItems() async throws -> [ItemDTO] {
    return try await context.perform {
      let request = Item.fetchRequest()
      request.sortDescriptors = [
        NSSortDescriptor(keyPath: \Item.isPinned, ascending: false),
        NSSortDescriptor(keyPath: \Item.updatedAt, ascending: false)
      ]
      let items = try self.context.fetch(request)
      return try items.map { try self.mapToDTO($0) }
    }
  }

  public func fetchItem(id: UUID) async throws -> ItemDTO {
    return try await context.perform {
      let request = Item.fetchRequest()
      request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
      guard let item = try self.context.fetch(request).first else {
        throw NSError(domain: "ItemService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found"])
      }
      return try self.mapToDTO(item)
    }
  }

  public func searchItems(query: String) async throws -> [ItemDTO] {
    return try await context.perform {
      let request = Item.fetchRequest()
      
      // Search in title and tags
      let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
      let tagsPredicate = NSPredicate(format: "tagsJSON CONTAINS[cd] %@", query)
      request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, tagsPredicate])
      
      request.sortDescriptors = [
        NSSortDescriptor(keyPath: \Item.isPinned, ascending: false),
        NSSortDescriptor(keyPath: \Item.updatedAt, ascending: false)
      ]
      
      let items = try self.context.fetch(request)
      return try items.map { try self.mapToDTO($0) }
    }
  }

  // MARK: - Update

  public func updateTextItem(id: UUID, title: String?, content: String?, tags: [String]?) async throws -> ItemDTO {
    return try await context.perform {
      let request = Item.fetchRequest()
      request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
      guard let item = try self.context.fetch(request).first else {
        throw NSError(domain: "ItemService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found"])
      }

      if let title = title {
        item.title = title
      }
      
      if let tags = tags {
        item.tags = tags
      }

      if let content = content {
        if let textContent = item.textContent {
          textContent.encryptedContent = try self.cryptoService.encrypt(content)
        } else {
          let textContent = TextContent(context: self.context)
          textContent.id = UUID()
          textContent.encryptedContent = try self.cryptoService.encrypt(content)
          textContent.item = item
        }
      }

      item.updatedAt = Date()
      try self.context.save()
      return try self.mapToDTO(item)
    }
  }

  public func updateImageItem(id: UUID, title: String?, tags: [String]?) async throws -> ItemDTO {
    return try await context.perform {
      let request = Item.fetchRequest()
      request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
      guard let item = try self.context.fetch(request).first else {
        throw NSError(domain: "ItemService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found"])
      }

      if let title = title {
        item.title = title
      }
      
      if let tags = tags {
        item.tags = tags
      }

      item.updatedAt = Date()
      try self.context.save()
      return try self.mapToDTO(item)
    }
  }

  public func addImages(to itemId: UUID, images: [ImageData]) async throws {
    try await context.perform {
      let request = Item.fetchRequest()
      request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
      guard let item = try self.context.fetch(request).first else {
        throw NSError(domain: "ItemService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found"])
      }

      guard item.type == ItemType.image.rawValue else {
        throw NSError(domain: "ItemService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Cannot add images to text item"])
      }

      let currentCount = item.images?.count ?? 0

      for (index, imageData) in images.enumerated() {
        let imageContent = ImageContent(context: self.context)
        imageContent.id = UUID()
        imageContent.fileName = imageData.fileName
        imageContent.encryptedData = try self.cryptoService.encryptFile(imageData.data)
        imageContent.fileSize = Int64(imageData.data.count)
        imageContent.displayOrder = Int16(currentCount + index)
        imageContent.createdAt = Date()
        
        #if canImport(UIKit)
        if let thumbnail = self.generateThumbnail(from: imageData.data) {
          imageContent.thumbnailData = try self.cryptoService.encryptFile(thumbnail)
        }
        #endif
        
        imageContent.item = item
      }

      item.updatedAt = Date()
      try self.context.save()
    }
  }

  public func removeImage(id: UUID) async throws {
    try await context.perform {
      let request = ImageContent.fetchRequest()
      request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
      guard let imageContent = try self.context.fetch(request).first else {
        throw NSError(domain: "ItemService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Image not found"])
      }

      let item = imageContent.item
      self.context.delete(imageContent)
      item?.updatedAt = Date()
      try self.context.save()
    }
  }

  // MARK: - Delete

  public func deleteItem(id: UUID) async throws {
    try await context.perform {
      let request = Item.fetchRequest()
      request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
      guard let item = try self.context.fetch(request).first else {
        throw NSError(domain: "ItemService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found"])
      }

      self.context.delete(item)
      try self.context.save()
    }
  }

  // MARK: - Other

  public func togglePin(id: UUID) async throws -> ItemDTO {
    return try await context.perform {
      let request = Item.fetchRequest()
      request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
      guard let item = try self.context.fetch(request).first else {
        throw NSError(domain: "ItemService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found"])
      }
      
      item.isPinned.toggle()
      item.updatedAt = Date()
      try self.context.save()
      return try self.mapToDTO(item)
    }
  }
  
  // MARK: - Share
  
  public func getShareableText(id: UUID) async throws -> String {
    return try await context.perform {
      let request = Item.fetchRequest()
      request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
      guard let item = try self.context.fetch(request).first else {
        throw NSError(domain: "ItemService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found"])
      }
      
      guard item.type == ItemType.text.rawValue else {
        throw NSError(domain: "ItemService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Item is not a text type"])
      }
      
      guard let textContent = item.textContent, let encData = textContent.encryptedContent else {
        throw NSError(domain: "ItemService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Text content not found"])
      }
      
      return try self.cryptoService.decrypt(encData)
    }
  }
  
  public func getShareableImages(id: UUID, withWatermark: Bool, watermarkText: String?) async throws -> [Data] {
    return try await context.perform {
      let request = Item.fetchRequest()
      request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
      guard let item = try self.context.fetch(request).first else {
        throw NSError(domain: "ItemService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found"])
      }
      
      guard item.type == ItemType.image.rawValue else {
        throw NSError(domain: "ItemService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Item is not an image type"])
      }
      
      guard let imageSet = item.images, imageSet.count > 0 else {
        throw NSError(domain: "ItemService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No images found"])
      }
      
      let sortedImages = (imageSet.allObjects as! [ImageContent]).sorted { $0.displayOrder < $1.displayOrder }
      var results: [Data] = []
      
      for imageContent in sortedImages {
        guard let encData = imageContent.encryptedData else { continue }
        var imageData = try self.cryptoService.decryptFile(encData)
        
        // Apply watermark if requested
        #if canImport(UIKit)
        if withWatermark, let watermark = watermarkText {
          imageData = try self.applyWatermark(to: imageData, text: watermark)
        }
        #endif
        
        results.append(imageData)
      }
      
      return results
    }
  }
  
  public func getDecryptedImage(imageId: UUID) async throws -> Data {
    return try await context.perform {
      let request = ImageContent.fetchRequest()
      request.predicate = NSPredicate(format: "id == %@", imageId as CVarArg)
      guard let imageContent = try self.context.fetch(request).first,
            let encData = imageContent.encryptedData else {
        throw NSError(domain: "ItemService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Image not found"])
      }
      
      return try self.cryptoService.decryptFile(encData)
    }
  }

  // MARK: - Helpers

  private func mapToDTO(_ item: Item) throws -> ItemDTO {
    guard let itemType = ItemType(rawValue: item.type ?? "text") else {
      throw NSError(domain: "ItemService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid item type"])
    }

    var textContent: String?
    var images: [ImageDTO]?

    if itemType == .text, let tc = item.textContent, let encData = tc.encryptedContent {
      textContent = try cryptoService.decrypt(encData)
    } else if itemType == .image, let imageSet = item.images {
      let sortedImages = (imageSet.allObjects as! [ImageContent]).sorted { $0.displayOrder < $1.displayOrder }
      images = sortedImages.compactMap { img in
        guard let id = img.id,
              let fileName = img.fileName,
              let encData = img.encryptedData else {
          return nil
        }
        var thumbnailData: Data?
        if let encryptedThumbnail = img.thumbnailData {
          thumbnailData = try? cryptoService.decryptFile(encryptedThumbnail)
        }
        return ImageDTO(
          id: id,
          fileName: fileName,
          fileSize: img.fileSize,
          displayOrder: img.displayOrder,
          thumbnailData: thumbnailData
        )
      }
    }

    return ItemDTO(
      id: item.id ?? UUID(),
      title: item.title ?? "",
      type: itemType,
      tags: item.tags,
      isPinned: item.isPinned,
      createdAt: item.createdAt ?? Date(),
      updatedAt: item.updatedAt ?? Date(),
      textContent: textContent,
      images: images
    )
  }

  #if canImport(UIKit)
  private func generateThumbnail(from imageData: Data) -> Data? {
    guard let image = UIImage(data: imageData) else { return nil }
    let targetSize = CGSize(width: 200, height: 200)
    
    let widthRatio = targetSize.width / image.size.width
    let heightRatio = targetSize.height / image.size.height
    let scaleFactor = min(widthRatio, heightRatio)
    
    let scaledSize = CGSize(
      width: image.size.width * scaleFactor,
      height: image.size.height * scaleFactor
    )
    
    UIGraphicsBeginImageContextWithOptions(scaledSize, false, 1.0)
    image.draw(in: CGRect(origin: .zero, size: scaledSize))
    let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return thumbnail?.jpegData(compressionQuality: 0.7)
  }
  
  private func applyWatermark(to imageData: Data, text: String) throws -> Data {
    guard let image = UIImage(data: imageData) else {
      throw NSError(domain: "ItemService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
    }
    
    let imageSize = image.size
    UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
    
    // Draw original image
    image.draw(in: CGRect(origin: .zero, size: imageSize))
    
    // Configure watermark text
    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: min(imageSize.width, imageSize.height) * 0.05, weight: .medium),
      .foregroundColor: UIColor.white.withAlphaComponent(0.5)
    ]
    
    let textSize = text.size(withAttributes: attributes)
    let textRect = CGRect(
      x: imageSize.width - textSize.width - 20,
      y: imageSize.height - textSize.height - 20,
      width: textSize.width,
      height: textSize.height
    )
    
    // Draw watermark
    text.draw(in: textRect, withAttributes: attributes)
    
    let watermarkedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    guard let finalImage = watermarkedImage,
          let resultData = finalImage.jpegData(compressionQuality: 0.9) else {
      throw NSError(domain: "ItemService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create watermarked image"])
    }
    
    return resultData
  }
  #endif
}
