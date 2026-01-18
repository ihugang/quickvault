//
//  CloudSyncMonitor.swift
//  QuickHold
//
//  监控 iCloud 同步状态
//

import SwiftUI
import CoreData
import Combine
import QuickHoldCore

enum CloudSyncStatus {
    case synced       // 已同步
    case syncing      // 同步中
    case notSynced    // 未同步
    case error        // 同步错误
}

@MainActor
class CloudSyncMonitor: ObservableObject {
    static let shared = CloudSyncMonitor()
    
    @Published var syncStatus: CloudSyncStatus = .synced
    @Published var lastSyncDate: Date?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        // 监听 CloudKit 导入通知
        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleCloudKitEvent(notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
            return
        }

        switch event.type {
        case .setup:
            syncStatus = .syncing
        case .import:
            if event.endDate != nil {
                syncStatus = .synced
                lastSyncDate = event.endDate
            } else {
                syncStatus = .syncing
            }
        case .export:
            if event.endDate != nil {
                syncStatus = .synced
                lastSyncDate = event.endDate
            } else {
                syncStatus = .syncing
            }
        @unknown default:
            break
        }

        if let error = event.error {
            print("❌ CloudKit sync error: \(error)")
            syncStatus = .error
        }
    }

    // 手动触发同步 / Manually trigger sync
    func manualSync() {
        syncStatus = .syncing
        let context = PersistenceController.shared.viewContext

        // 1. 保存本地更改，触发上传到 iCloud / Save local changes to trigger export to iCloud
        if context.hasChanges {
            try? context.save()
        }

        // 2. 刷新所有对象，确保显示最新数据 / Refresh all objects to ensure latest data is displayed
        // CloudKit 会自动处理下载，我们只需要刷新 context
        // CloudKit handles download automatically, we just need to refresh the context
        context.refreshAllObjects()

        // 3. 重新获取数据以触发 CloudKit 检查更新
        // Re-fetch data to trigger CloudKit to check for updates
        context.perform {
            // 执行一个空的 fetch 来触发 CloudKit 检查
            // Perform an empty fetch to trigger CloudKit check
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Item")
            fetchRequest.fetchLimit = 1
            _ = try? context.fetch(fetchRequest)
        }
    }
}
