import Combine
import CoreData
import Foundation

// MARK: - Card Service Errors / 卡片服务错误

enum CardServiceError: LocalizedError {
  case cardNotFound  // 卡片未找到
  case encryptionFailed  // 加密失败
  case decryptionFailed  // 解密失败
  case invalidData  // 无效数据
  case databaseError(String)  // 数据库错误

  var errorDescription: String? {
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

struct CardDTO {
  let id: UUID
  let title: String
  let group: String
  let type: String
  let fields: [CardFieldDTO]
  let isPinned: Bool
  let tags: [String]
  let createdAt: Date
  let updatedAt: Date
}

struct CardFieldDTO {
  let id: UUID
  let label: String
  let value: String
  let isCopyable: Bool
  let order: Int16
}

// MARK: - Card Service Protocol / 卡片服务协议

protocol CardService {
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

class CardServiceImpl: CardService {

  private let persistenceController: PersistenceController
  private let cryptoService: CryptoService
  private let context: NSManagedObjectContext

  init(persistenceController: PersistenceController, cryptoService: CryptoService) {
    self.persistenceController = persistenceController
    self.cryptoService = cryptoService
    self.context = persistenceController.container.viewContext
  }

  // MARK: - Create

  func createCard(
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

  func updateCard(
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

  func deleteCard(id: UUID) async throws {
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

  func fetchAllCards() async throws -> [CardDTO] {
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

  func fetchCard(id: UUID) async throws -> CardDTO {
    return try await context.perform {
      guard let card = try self.fetchCardEntity(id: id) else {
        throw CardServiceError.cardNotFound
      }

      return try self.convertToDTO(card)
    }
  }

  // MARK: - Search

  func searchCards(query: String) async throws -> [CardDTO] {
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

  func togglePin(id: UUID) async throws -> CardDTO {
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
