//
//  PersistenceController.swift
//  QuickVault
//

import CoreData

public struct PersistenceController {
  public static let shared = PersistenceController()

  public let container: NSPersistentContainer

  public init(inMemory: Bool = false) {
    container = NSPersistentContainer(name: "QuickVault")

    if inMemory {
      container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
    }

    container.loadPersistentStores { description, error in
      if let error = error {
        fatalError("Failed to load Core Data stack: \(error)")
      }
    }

    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
  }

  public var viewContext: NSManagedObjectContext {
    container.viewContext
  }

  // For testing
  public static var preview: PersistenceController = {
    let controller = PersistenceController(inMemory: true)
    let context = controller.viewContext

    // Create sample data for previews
    let card = Card(context: context)
    card.id = UUID()
    card.title = "Sample Card"
    card.type = "general"
    card.group = "personal"
    card.isPinned = false
    card.createdAt = Date()
    card.updatedAt = Date()

    do {
      try context.save()
    } catch {
      fatalError("Failed to save preview data: \(error)")
    }

    return controller
  }()
}
