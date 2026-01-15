import CoreData
import XCTest

@testable import QuickHold

final class CardServiceTests: XCTestCase {

  var cardService: CardServiceImpl!
  var persistenceController: PersistenceController!
  var cryptoService: CryptoService!
  var keychainService: KeychainService!

  override func setUp() async throws {
    try await super.setUp()

    // Create in-memory persistence controller for testing
    persistenceController = PersistenceController(inMemory: true)

    // Setup crypto service
    keychainService = KeychainServiceImpl()
    cryptoService = CryptoServiceImpl(keychainService: keychainService)
    try cryptoService.initializeKey(password: "testPassword123", salt: nil)

    // Create card service
    cardService = CardServiceImpl(
      persistenceController: persistenceController,
      cryptoService: cryptoService
    )
  }

  override func tearDown() async throws {
    try? keychainService.delete(key: QuickHoldConstants.KeychainKeys.cryptoSalt)
    try await super.tearDown()
  }

  // MARK: - Create Tests

  func testCreateCard() async throws {
    // Create a card
    let fields = [
      CardFieldDTO(id: UUID(), label: "Name", value: "John Doe", isCopyable: true, order: 0),
      CardFieldDTO(
        id: UUID(), label: "Phone", value: "13800138000", isCopyable: true, order: 1),
    ]

    let card = try await cardService.createCard(
      title: "Test Card",
      group: "Personal",
      type: "Address",
      fields: fields,
      tags: ["test", "personal"]
    )

    XCTAssertEqual(card.title, "Test Card")
    XCTAssertEqual(card.group, "Personal")
    XCTAssertEqual(card.type, "Address")
    XCTAssertEqual(card.fields.count, 2)
    XCTAssertEqual(card.tags, ["test", "personal"])
    XCTAssertFalse(card.isPinned)
    XCTAssertNotNil(card.createdAt)
    XCTAssertNotNil(card.updatedAt)
  }

  func testCreateCardWithEmptyTags() async throws {
    let fields = [
      CardFieldDTO(id: UUID(), label: "Name", value: "John Doe", isCopyable: true, order: 0)
    ]

    let card = try await cardService.createCard(
      title: "Test Card",
      group: "Personal",
      type: "Address",
      fields: fields,
      tags: []
    )

    XCTAssertEqual(card.tags, [])
  }

  // MARK: - Update Tests

  func testUpdateCardTitle() async throws {
    // Create a card
    let fields = [
      CardFieldDTO(id: UUID(), label: "Name", value: "John Doe", isCopyable: true, order: 0)
    ]

    let card = try await cardService.createCard(
      title: "Original Title",
      group: "Personal",
      type: "Address",
      fields: fields,
      tags: []
    )

    let originalUpdatedAt = card.updatedAt

    // Wait a bit to ensure timestamp changes
    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

    // Update title
    let updatedCard = try await cardService.updateCard(
      id: card.id,
      title: "Updated Title",
      group: nil,
      fields: nil,
      tags: nil
    )

    XCTAssertEqual(updatedCard.title, "Updated Title")
    XCTAssertEqual(updatedCard.group, "Personal")
    XCTAssertGreaterThan(updatedCard.updatedAt, originalUpdatedAt)
  }

  func testUpdateCardFields() async throws {
    // Create a card
    let originalFields = [
      CardFieldDTO(id: UUID(), label: "Name", value: "John Doe", isCopyable: true, order: 0)
    ]

    let card = try await cardService.createCard(
      title: "Test Card",
      group: "Personal",
      type: "Address",
      fields: originalFields,
      tags: []
    )

    // Update fields
    let newFields = [
      CardFieldDTO(
        id: UUID(), label: "Name", value: "Jane Smith", isCopyable: true, order: 0),
      CardFieldDTO(
        id: UUID(), label: "Email", value: "jane@example.com", isCopyable: false, order: 1),
    ]

    let updatedCard = try await cardService.updateCard(
      id: card.id,
      title: nil,
      group: nil,
      fields: newFields,
      tags: nil
    )

    XCTAssertEqual(updatedCard.fields.count, 2)
    XCTAssertEqual(updatedCard.fields[0].value, "Jane Smith")
    XCTAssertEqual(updatedCard.fields[1].value, "jane@example.com")
  }

  func testUpdateCardTags() async throws {
    // Create a card
    let fields = [
      CardFieldDTO(id: UUID(), label: "Name", value: "John Doe", isCopyable: true, order: 0)
    ]

    let card = try await cardService.createCard(
      title: "Test Card",
      group: "Personal",
      type: "Address",
      fields: fields,
      tags: ["old"]
    )

    // Update tags
    let updatedCard = try await cardService.updateCard(
      id: card.id,
      title: nil,
      group: nil,
      fields: nil,
      tags: ["new", "updated"]
    )

    XCTAssertEqual(updatedCard.tags, ["new", "updated"])
  }

  // MARK: - Delete Tests

  func testDeleteCard() async throws {
    // Create a card
    let fields = [
      CardFieldDTO(id: UUID(), label: "Name", value: "John Doe", isCopyable: true, order: 0)
    ]

    let card = try await cardService.createCard(
      title: "Test Card",
      group: "Personal",
      type: "Address",
      fields: fields,
      tags: []
    )

    // Delete the card
    try await cardService.deleteCard(id: card.id)

    // Verify it's deleted
    do {
      _ = try await cardService.fetchCard(id: card.id)
      XCTFail("Should have thrown cardNotFound error")
    } catch CardServiceError.cardNotFound {
      // Expected
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testDeleteNonExistentCard() async throws {
    let nonExistentId = UUID()

    do {
      try await cardService.deleteCard(id: nonExistentId)
      XCTFail("Should have thrown cardNotFound error")
    } catch CardServiceError.cardNotFound {
      // Expected
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  // MARK: - Fetch Tests

  func testFetchAllCards() async throws {
    // Create multiple cards
    let fields = [
      CardFieldDTO(id: UUID(), label: "Name", value: "John Doe", isCopyable: true, order: 0)
    ]

    _ = try await cardService.createCard(
      title: "Card 1",
      group: "Personal",
      type: "Address",
      fields: fields,
      tags: []
    )

    _ = try await cardService.createCard(
      title: "Card 2",
      group: "Company",
      type: "Invoice",
      fields: fields,
      tags: []
    )

    // Fetch all cards
    let cards = try await cardService.fetchAllCards()

    XCTAssertEqual(cards.count, 2)
  }

  func testFetchCardById() async throws {
    // Create a card
    let fields = [
      CardFieldDTO(id: UUID(), label: "Name", value: "John Doe", isCopyable: true, order: 0)
    ]

    let createdCard = try await cardService.createCard(
      title: "Test Card",
      group: "Personal",
      type: "Address",
      fields: fields,
      tags: []
    )

    // Fetch by ID
    let fetchedCard = try await cardService.fetchCard(id: createdCard.id)

    XCTAssertEqual(fetchedCard.id, createdCard.id)
    XCTAssertEqual(fetchedCard.title, "Test Card")
  }

  // MARK: - Search Tests

  func testSearchCardsByTitle() async throws {
    // Create cards
    let fields = [
      CardFieldDTO(id: UUID(), label: "Name", value: "John Doe", isCopyable: true, order: 0)
    ]

    _ = try await cardService.createCard(
      title: "Home Address",
      group: "Personal",
      type: "Address",
      fields: fields,
      tags: []
    )

    _ = try await cardService.createCard(
      title: "Work Invoice",
      group: "Company",
      type: "Invoice",
      fields: fields,
      tags: []
    )

    // Search by title
    let results = try await cardService.searchCards(query: "Address")

    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results[0].title, "Home Address")
  }

  func testSearchCardsByFieldValue() async throws {
    // Create cards with different field values
    let fields1 = [
      CardFieldDTO(
        id: UUID(), label: "Name", value: "Alice Smith", isCopyable: true, order: 0)
    ]

    let fields2 = [
      CardFieldDTO(
        id: UUID(), label: "Name", value: "Bob Johnson", isCopyable: true, order: 0)
    ]

    _ = try await cardService.createCard(
      title: "Card 1",
      group: "Personal",
      type: "Address",
      fields: fields1,
      tags: []
    )

    _ = try await cardService.createCard(
      title: "Card 2",
      group: "Personal",
      type: "Address",
      fields: fields2,
      tags: []
    )

    // Search by field value
    let results = try await cardService.searchCards(query: "Alice")

    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results[0].title, "Card 1")
  }

  func testSearchCardsByTags() async throws {
    // Create cards with tags
    let fields = [
      CardFieldDTO(id: UUID(), label: "Name", value: "John Doe", isCopyable: true, order: 0)
    ]

    _ = try await cardService.createCard(
      title: "Card 1",
      group: "Personal",
      type: "Address",
      fields: fields,
      tags: ["important", "work"]
    )

    _ = try await cardService.createCard(
      title: "Card 2",
      group: "Personal",
      type: "Address",
      fields: fields,
      tags: ["personal", "home"]
    )

    // Search by tag
    let results = try await cardService.searchCards(query: "important")

    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results[0].title, "Card 1")
  }

  // MARK: - Pin Tests

  func testTogglePin() async throws {
    // Create a card
    let fields = [
      CardFieldDTO(id: UUID(), label: "Name", value: "John Doe", isCopyable: true, order: 0)
    ]

    let card = try await cardService.createCard(
      title: "Test Card",
      group: "Personal",
      type: "Address",
      fields: fields,
      tags: []
    )

    XCTAssertFalse(card.isPinned)

    // Toggle pin on
    let pinnedCard = try await cardService.togglePin(id: card.id)
    XCTAssertTrue(pinnedCard.isPinned)

    // Toggle pin off
    let unpinnedCard = try await cardService.togglePin(id: card.id)
    XCTAssertFalse(unpinnedCard.isPinned)
  }

  func testPinnedCardsSortFirst() async throws {
    // Create multiple cards
    let fields = [
      CardFieldDTO(id: UUID(), label: "Name", value: "John Doe", isCopyable: true, order: 0)
    ]

    let card1 = try await cardService.createCard(
      title: "Card 1",
      group: "Personal",
      type: "Address",
      fields: fields,
      tags: []
    )

    let card2 = try await cardService.createCard(
      title: "Card 2",
      group: "Personal",
      type: "Address",
      fields: fields,
      tags: []
    )

    // Pin card 2
    _ = try await cardService.togglePin(id: card2.id)

    // Fetch all cards
    let cards = try await cardService.fetchAllCards()

    // Card 2 should be first because it's pinned
    XCTAssertEqual(cards[0].id, card2.id)
    XCTAssertEqual(cards[1].id, card1.id)
  }
}
