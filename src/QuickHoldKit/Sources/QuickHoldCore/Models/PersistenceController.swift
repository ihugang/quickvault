//
//  PersistenceController.swift
//  QuickHold
//
//  Supports iCloud CloudKit sync for data sharing between macOS and iOS
//  支持 iCloud CloudKit 同步，用于 macOS 和 iOS 之间的数据共享
//

import CoreData
import os.log

private let persistenceLogger = Logger(subsystem: "com.codans.quickhold", category: "PersistenceController")

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
    persistenceLogger.info("🏗️ [Persistence] ========== PersistenceController INIT START ==========")
    persistenceLogger.info("📊 [Persistence] inMemory: \(inMemory), enableCloudKit: \(enableCloudKit)")

    // Load model from the package bundle
    persistenceLogger.info("📦 [Persistence] Loading Core Data model from bundle...")
    guard let modelURL = Bundle.module.url(forResource: "QuickHold", withExtension: "momd"),
          let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
      persistenceLogger.error("❌ [Persistence] FATAL: Failed to load Core Data model from bundle")
      fatalError("Failed to load Core Data model from bundle")
    }
    persistenceLogger.info("✅ [Persistence] Core Data model loaded successfully")

    persistenceLogger.info("🗄️ [Persistence] Creating NSPersistentCloudKitContainer...")
    container = NSPersistentCloudKitContainer(name: "QuickHold", managedObjectModel: managedObjectModel)

    // Configure store description for CloudKit
    persistenceLogger.info("⚙️ [Persistence] Configuring persistent store description...")
    guard let description = container.persistentStoreDescriptions.first else {
      persistenceLogger.error("❌ [Persistence] FATAL: Failed to get persistent store description")
      fatalError("Failed to get persistent store description")
    }

    if inMemory {
      persistenceLogger.warning("⚠️ [Persistence] Using IN-MEMORY store (testing mode)")
      description.url = URL(fileURLWithPath: "/dev/null")
      description.cloudKitContainerOptions = nil
    } else if enableCloudKit {
      // Configure CloudKit container options
      persistenceLogger.info("☁️ [Persistence] Enabling CloudKit sync...")
      persistenceLogger.info("📦 [Persistence] CloudKit container: \(Self.cloudKitContainerIdentifier)")

      let cloudKitOptions = NSPersistentCloudKitContainerOptions(
        containerIdentifier: Self.cloudKitContainerIdentifier
      )
      description.cloudKitContainerOptions = cloudKitOptions

      // Enable history tracking for CloudKit sync
      persistenceLogger.info("📚 [Persistence] Enabling persistent history tracking...")
      description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
      description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
      persistenceLogger.info("✅ [Persistence] CloudKit configuration completed")
    } else {
      persistenceLogger.info("ℹ️ [Persistence] CloudKit disabled, using local-only storage")
    }

    persistenceLogger.info("⏳ [Persistence] Loading persistent stores...")
    container.loadPersistentStores { description, error in
      if let error = error {
        persistenceLogger.error("❌ [Persistence] FATAL: Failed to load Core Data stack: \(error.localizedDescription)")
        fatalError("Failed to load Core Data stack: \(error)")
      }
      persistenceLogger.info("✅ [Persistence] Persistent store loaded: \(description)")
    }

    persistenceLogger.info("⚙️ [Persistence] Configuring view context...")
    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
    persistenceLogger.info("✅ [Persistence] View context merge policy set")

    // Set query generation to track changes
    persistenceLogger.info("🔄 [Persistence] Setting query generation...")
    try? container.viewContext.setQueryGenerationFrom(.current)

    persistenceLogger.info("✅ [Persistence] ========== PersistenceController INIT COMPLETE ==========")
  }

  public var viewContext: NSManagedObjectContext {
    container.viewContext
  }

  /// Check if there is any existing data in CloudKit
  /// 检查 CloudKit 中是否有现有数据
  public func hasExistingData() async -> Bool {
    persistenceLogger.info("☁️ [Persistence] ========== hasExistingData START ==========")
    persistenceLogger.info("📊 [Persistence] Creating background context for data check...")

    let context = container.newBackgroundContext()
    let delays: [UInt64] = [0, 1_000_000_000, 2_000_000_000, 4_000_000_000, 8_000_000_000]
    let delaySeconds = [0, 1, 2, 4, 8]

    persistenceLogger.info("⏱️ [Persistence] Will poll up to \(delays.count) times with delays: \(delaySeconds) seconds")
    persistenceLogger.info("💡 [Persistence] Total maximum wait time: ~15 seconds")

    for (index, delay) in delays.enumerated() {
      if delay > 0 {
        persistenceLogger.info("⏳ [Persistence] Attempt \(index + 1)/\(delays.count): Waiting \(delaySeconds[index]) second(s) before checking...")
        try? await Task.sleep(nanoseconds: delay)
      } else {
        persistenceLogger.info("🔍 [Persistence] Attempt \(index + 1)/\(delays.count): Checking immediately...")
      }

      let hasData = await context.perform {
        persistenceLogger.debug("📥 [Persistence] Fetching Item count from CoreData...")
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Item")
        fetchRequest.fetchLimit = 1

        do {
          let count = try context.count(for: fetchRequest)
          persistenceLogger.info("📊 [Persistence] Item count: \(count)")
          return count > 0
        } catch {
          persistenceLogger.error("❌ [Persistence] Failed to fetch Item count: \(error.localizedDescription)")
          return false
        }
      }

      if hasData {
        persistenceLogger.info("🎉 [Persistence] SUCCESS! Found existing data after attempt \(index + 1)")
        persistenceLogger.info("✅ [Persistence] ========== hasExistingData = TRUE ==========")
        return true
      }
      persistenceLogger.warning("⚠️ [Persistence] No data found in attempt \(index + 1)")
    }

    persistenceLogger.warning("⚠️ [Persistence] No existing data found after \(delays.count) attempts")
    persistenceLogger.info("💡 [Persistence] This is likely a first-time setup or CloudKit hasn't synced yet")
    persistenceLogger.info("❌ [Persistence] ========== hasExistingData = FALSE ==========")
    return false
  }
}
