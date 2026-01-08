import Combine
import CoreData
import Foundation

// MARK: - Card Service Errors / 卡片服务错误

public enum CardServiceError: LocalizedError {
  case cardNotFound  // 卡片未找到
  case encryptionFailed  // 加密失败
  case decryptionFailed  // 解密失败
  case invalidData  // 无效数据
  case databaseError(String)  // 数据库错误

  public var errorDescription: String? {
    switch self {
    case .cardNotFound:
      return "Card not found / 卡片未找到"
    case .encryptionFailed:
      return "Failed to encrypt card data / 加密卡片数据失败"
    case .decryptionFailed:
      return "Failed to decrypt card data / 解密卡片数据失败"
    case .invalidData:
      return "Invalid card data / 无效的卡片数据"
    case .databaseError(let message):
      return "Database error: \(message) / 数据库错误：\(message)"
    }
  }
}

// MARK: - Card Data Transfer Object / 卡片数据传输对象

public struct CardDTO: Hashable, Identifiable {
  public let id: UUID
  public let title: String
  public let group: String
  public let type: String
  public let fields: [CardFieldDTO]
  public let isPinned: Bool
  public let tags: [String]
  public let createdAt: Date
  public let updatedAt: Date

  public init(id: UUID, title: String, group: String, type: String, fields: [CardFieldDTO], isPinned: Bool, tags: [String], createdAt: Date, updatedAt: Date) {
    self.id = id
    self.title = title
    self.group = group
    self.type = type
    self.fields = fields
    self.isPinned = isPinned
    self.tags = tags
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

public struct CardFieldDTO: Hashable, Identifiable {
  public let id: UUID
  public let label: String
  public let value: String
  public let isCopyable: Bool
  public let order: Int16

  public init(id: UUID, label: String, value: String, isCopyable: Bool, order: Int16) {
    self.id = id
    self.label = label
    self.value = value
    self.isCopyable = isCopyable
    self.order = order
  }
}

// MARK: - Card Service Protocol / 卡片服务协议

public protocol CardService {
  func createCard(
    title: String,
    group: String,
    type: String,
    fields: [CardFieldDTO],
    tags: [String]
  ) async throws -> CardDTO

  func updateCard(
    id: UUID,
    title: String?,
    group: String?,
    fields: [CardFieldDTO]?,
    tags: [String]?
  ) async throws -> CardDTO

  func deleteCard(id: UUID) async throws

  func fetchAllCards() async throws -> [CardDTO]

  func fetchCard(id: UUID) async throws -> CardDTO

  func searchCards(query: String) async throws -> [CardDTO]

  func togglePin(id: UUID) async throws -> CardDTO
}

// MARK: - Card Service Implementation / 卡片服务实现

public class CardServiceImpl: CardService {

  private let persistenceController: PersistenceController
  private let cryptoService: CryptoService
  private let context: NSManagedObjectContext

  public init(persistenceController: PersistenceController, cryptoService: CryptoService) {
    self.persistenceController = persistenceController
    self.cryptoService = cryptoService
    self.context = persistenceController.container.viewContext
  }

  // MARK: - Create

  public func createCard(
    title: String,
    group: String,
    type: String,
    fields: [CardFieldDTO],
    tags: [String]
  ) async throws -> CardDTO {
    return try await context.perform {
      let card = Card(context: self.context)
      card.id = UUID()
      card.title = title
      card.group = group
      card.type = type
      card.isPinned = false
      card.createdAt = Date()
      card.updatedAt = Date()

      // Store tags as JSON string
      if let tagsData = try? JSONEncoder().encode(tags),
         let tagsString = String(data: tagsData, encoding: .utf8) {
        card.tagsJSON = tagsString
      }

      // Create and encrypt fields
      for fieldDTO in fields {
        let field = CardField(context: self.context)
        field.id = UUID()
        field.label = fieldDTO.label
        field.isCopyable = fieldDTO.isCopyable
        field.order = fieldDTO.order
        field.card = card

        // Encrypt field value
        do {
          let encryptedData = try self.cryptoService.encrypt(fieldDTO.value)
          field.encryptedValue = encryptedData
        } catch CryptoError.keyNotAvailable {
          throw CardServiceError.encryptionFailed  // Will be caught and shown to user
        } catch {
          throw CardServiceError.encryptionFailed
        }
      }

      // Save context
      do {
        try self.context.save()
      } catch {
        throw CardServiceError.databaseError(error.localizedDescription)
      }

      return try self.convertToDTO(card)
    }
  }

  // MARK: - Update

  public func updateCard(
    id: UUID,
    title: String?,
    group: String?,
    fields: [CardFieldDTO]?,
    tags: [String]?
  ) async throws -> CardDTO {
    return try await context.perform {
      guard let card = try self.fetchCardEntity(id: id) else {
        throw CardServiceError.cardNotFound
      }

      // Update basic properties
      if let title = title {
        card.title = title
      }

      if let group = group {
        card.group = group
      }

      if let tags = tags {
        if let tagsData = try? JSONEncoder().encode(tags),
           let tagsString = String(data: tagsData, encoding: .utf8) {
          card.tagsJSON = tagsString
        }
      }

      // Update fields if provided
      if let fields = fields {
        // Delete existing fields
        if let existingFields = card.fields as? Set<CardField> {
          for field in existingFields {
            self.context.delete(field)
          }
        }

        // Create new fields
        for fieldDTO in fields {
          let field = CardField(context: self.context)
          field.id = UUID()
          field.label = fieldDTO.label
          field.isCopyable = fieldDTO.isCopyable
          field.order = fieldDTO.order
          field.card = card

          // Encrypt field value
          do {
            let encryptedData = try self.cryptoService.encrypt(fieldDTO.value)
            field.encryptedValue = encryptedData
          } catch {
            throw CardServiceError.encryptionFailed
          }
        }
      }

      // Update modification timestamp
      card.updatedAt = Date()

      // Save context
      do {
        try self.context.save()
      } catch {
        throw CardServiceError.databaseError(error.localizedDescription)
      }

      return try self.convertToDTO(card)
    }
  }

  // MARK: - Delete

  public func deleteCard(id: UUID) async throws {
    try await context.perform {
      guard let card = try self.fetchCardEntity(id: id) else {
        throw CardServiceError.cardNotFound
      }

      // CoreData cascade delete will handle fields and attachments
      self.context.delete(card)

      do {
        try self.context.save()
      } catch {
        throw CardServiceError.databaseError(error.localizedDescription)
      }
    }
  }

  // MARK: - Fetch

  public func fetchAllCards() async throws -> [CardDTO] {
    return try await context.perform {
      let fetchRequest: NSFetchRequest<Card> = Card.fetchRequest()
      fetchRequest.sortDescriptors = [
        NSSortDescriptor(key: "isPinned", ascending: false),
        NSSortDescriptor(key: "updatedAt", ascending: false),
      ]

      do {
        let cards = try self.context.fetch(fetchRequest)
        return try cards.map { try self.convertToDTO($0) }
      } catch {
        throw CardServiceError.databaseError(error.localizedDescription)
      }
    }
  }

  public func fetchCard(id: UUID) async throws -> CardDTO {
    return try await context.perform {
      guard let card = try self.fetchCardEntity(id: id) else {
        throw CardServiceError.cardNotFound
      }

      return try self.convertToDTO(card)
    }
  }

  // MARK: - Search

  public func searchCards(query: String) async throws -> [CardDTO] {
    return try await context.perform {
      let fetchRequest: NSFetchRequest<Card> = Card.fetchRequest()

      // Search in title
      let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)

      fetchRequest.predicate = titlePredicate
      fetchRequest.sortDescriptors = [
        NSSortDescriptor(key: "isPinned", ascending: false),
        NSSortDescriptor(key: "updatedAt", ascending: false),
      ]

      do {
        let cards = try self.context.fetch(fetchRequest)

        // Also search in decrypted field values and tags
        let filteredCards = try cards.filter { card in
          // Check title (already matched by predicate)
          if card.title.localizedCaseInsensitiveContains(query) {
            return true
          }

          // Check tags
          if let tagsString = card.tagsJSON,
             let tagsData = tagsString.data(using: .utf8),
             let tags = try? JSONDecoder().decode([String].self, from: tagsData)
          {
            if tags.contains(where: { $0.localizedCaseInsensitiveContains(query) }) {
              return true
            }
          }

          // Check field values (need to decrypt)
          if let fields = card.fields as? Set<CardField> {
            for field in fields {
              let encryptedValue = field.encryptedValue
              if let decryptedValue = try? self.cryptoService.decrypt(encryptedValue) {
                if decryptedValue.localizedCaseInsensitiveContains(query) {
                  return true
                }
              }
            }
          }

          return false
        }

        return try filteredCards.map { try self.convertToDTO($0) }
      } catch {
        throw CardServiceError.databaseError(error.localizedDescription)
      }
    }
  }

  // MARK: - Pin

  public func togglePin(id: UUID) async throws -> CardDTO {
    return try await context.perform {
      guard let card = try self.fetchCardEntity(id: id) else {
        throw CardServiceError.cardNotFound
      }

      card.isPinned.toggle()
      card.updatedAt = Date()

      do {
        try self.context.save()
      } catch {
        throw CardServiceError.databaseError(error.localizedDescription)
      }

      return try self.convertToDTO(card)
    }
  }

  // MARK: - Helper Methods

  private func fetchCardEntity(id: UUID) throws -> Card? {
    let fetchRequest: NSFetchRequest<Card> = Card.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
    fetchRequest.fetchLimit = 1

    return try context.fetch(fetchRequest).first
  }

  private func convertToDTO(_ card: Card) throws -> CardDTO {
    // Card properties are not optional in the data model
    let id = card.id
    let title = card.title
    let group = card.group
    let type = card.type
    let createdAt = card.createdAt
    let updatedAt = card.updatedAt

    // Decrypt fields
    var fieldDTOs: [CardFieldDTO] = []
    if let fields = card.fields as? Set<CardField> {
      let sortedFields = fields.sorted { $0.order < $1.order }

      for field in sortedFields {
        let fieldId = field.id
        let label = field.label
        let encryptedValue = field.encryptedValue

        do {
          let decryptedValue = try cryptoService.decrypt(encryptedValue)
          let fieldDTO = CardFieldDTO(
            id: fieldId,
            label: label,
            value: decryptedValue,
            isCopyable: field.isCopyable,
            order: field.order
          )
          fieldDTOs.append(fieldDTO)
        } catch {
          throw CardServiceError.decryptionFailed
        }
      }
    }

    // Decode tags from JSON string
    var tags: [String] = []
    if let tagsString = card.tagsJSON,
       let tagsData = tagsString.data(using: .utf8) {
      tags = (try? JSONDecoder().decode([String].self, from: tagsData)) ?? []
    }

    return CardDTO(
      id: id,
      title: title,
      group: group,
      type: type,
      fields: fieldDTOs,
      isPinned: card.isPinned,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}
