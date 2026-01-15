//
//  PersistenceController.swift
//  QuickHold
//
//  Supports iCloud CloudKit sync for data sharing between macOS and iOS
//  支持 iCloud CloudKit 同步，用于 macOS 和 iOS 之间的数据共享
//

import CoreData

public struct PersistenceController: Sendable {
  public static let shared = PersistenceController()

  /// CloudKit container identifier - must match in both macOS and iOS apps
  /// CloudKit 容器标识符 - 必须在 macOS 和 iOS 应用中保持一致
  public static let cloudKitContainerIdentifier = QuickHoldConstants.CloudKit.containerIdentifier

  public let container: NSPersistentCloudKitContainer
  
  // nonisolated(unsafe) to suppress Swift 6 concurrency warnings
  nonisolated(unsafe) public static var preview: PersistenceController = {
    let controller = PersistenceController(inMemory: true, enableCloudKit: false)
    let context = controller.viewContext

    // Create sample Item data for previews
    let textItem = Item(context: context)
    textItem.id = UUID()
    textItem.title = "示例文本卡片"
    textItem.type = ItemType.text.rawValue
    textItem.tags = ["示例", "文本"]
    textItem.isPinned = true
    textItem.createdAt = Date()
    textItem.updatedAt = Date()
    
    let textContent = TextContent(context: context)
    textContent.id = UUID()
    if let sampleData = "这是一个示例文本内容。\n可以包含多行文字。".data(using: .utf8) {
      textContent.encryptedContent = sampleData // Preview uses unencrypted data
    }
    textContent.item = textItem
    
    let imageItem = Item(context: context)
    imageItem.id = UUID()
    imageItem.title = "示例图片卡片"
    imageItem.type = ItemType.image.rawValue
    imageItem.tags = ["示例", "图片"]
    imageItem.isPinned = false
    imageItem.createdAt = Date()
    imageItem.updatedAt = Date()

    do {
      try context.save()
    } catch {
      fatalError("Failed to save preview data: \(error)")
    }

    return controller
  }()

  public init(inMemory: Bool = false, enableCloudKit: Bool = true) {
    // Load model from the package bundle
    guard let modelURL = Bundle.module.url(forResource: "QuickHold", withExtension: "momd"),
          let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
      fatalError("Failed to load Core Data model from bundle")
    }

    container = NSPersistentCloudKitContainer(name: "QuickHold", managedObjectModel: managedObjectModel)

    // Configure store description for CloudKit
    guard let description = container.persistentStoreDescriptions.first else {
      fatalError("Failed to get persistent store description")
    }
    
    if inMemory {
      description.url = URL(fileURLWithPath: "/dev/null")
      description.cloudKitContainerOptions = nil
    } else if enableCloudKit {
      // Configure CloudKit container options
      let cloudKitOptions = NSPersistentCloudKitContainerOptions(
        containerIdentifier: Self.cloudKitContainerIdentifier
      )
      description.cloudKitContainerOptions = cloudKitOptions
      
      // Enable history tracking for CloudKit sync
      description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
      description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    }

    container.loadPersistentStores { description, error in
      if let error = error {
        fatalError("Failed to load Core Data stack: \(error)")
      }
    }

    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
    
    // Set query generation to track changes
    try? container.viewContext.setQueryGenerationFrom(.current)
  }

  public var viewContext: NSManagedObjectContext {
    container.viewContext
  }
}
