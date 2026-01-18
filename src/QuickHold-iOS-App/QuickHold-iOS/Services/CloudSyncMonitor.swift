//
//  CloudSyncMonitor.swift
//  QuickHold
//
//  监控 iCloud 同步状态和新内容通知
//

import SwiftUI
@preconcurrency import CoreData
import Combine
import QuickHoldCore
import os.log

private let syncLogger = Logger(subsystem: "com.codans.quickhold", category: "CloudSync")

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
    @Published var newItemIDs: Set<UUID> = []  // 新同步的项目 ID
    @Published var newItemCount: Int = 0        // 新项目数量

    private var cancellables = Set<AnyCancellable>()
    private var lastHistoryToken: NSPersistentHistoryToken?

    init() {
        syncLogger.info("🔧 [CloudSync] Initializing CloudSyncMonitor...")
        setupNotifications()
        loadLastHistoryToken()
        syncLogger.info("✅ [CloudSync] CloudSyncMonitor initialized")
    }

    private func setupNotifications() {
        syncLogger.info("📡 [CloudSync] Setting up notification observers...")

        // 监听 CloudKit 同步事件
        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleCloudKitEvent(notification)
            }
            .store(in: &cancellables)

        // 监听远程数据变化（其他设备同步过来的内容）
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleRemoteChange(notification)
            }
            .store(in: &cancellables)

        syncLogger.info("✅ [CloudSync] Notification observers set up successfully")
    }

    private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
            syncLogger.warning("⚠️ [CloudSync] Failed to extract event from notification")
            return
        }

        let eventType = String(describing: event.type)
        syncLogger.info("📥 [CloudSync] CloudKit event received: \(eventType)")

        switch event.type {
        case .setup:
            syncLogger.info("⚙️ [CloudSync] Setup event started")
            syncStatus = .syncing

        case .import:
            if let endDate = event.endDate {
                let duration = endDate.timeIntervalSince(event.startDate)
                syncLogger.info("✅ [CloudSync] Import completed - duration: \(String(format: "%.2f", duration))s, endDate: \(endDate)")
                syncStatus = .synced
                lastSyncDate = endDate
            } else {
                syncLogger.info("⏳ [CloudSync] Import started at: \(event.startDate)")
                syncStatus = .syncing
            }

        case .export:
            if let endDate = event.endDate {
                let duration = endDate.timeIntervalSince(event.startDate)
                syncLogger.info("✅ [CloudSync] Export completed - duration: \(String(format: "%.2f", duration))s, endDate: \(endDate)")
                syncStatus = .synced
                lastSyncDate = endDate
            } else {
                syncLogger.info("⏳ [CloudSync] Export started at: \(event.startDate)")
                syncStatus = .syncing
            }

        @unknown default:
            syncLogger.warning("⚠️ [CloudSync] Unknown event type received")
            break
        }

        if let error = event.error {
            logSyncError(error)
            syncStatus = .error
        }
    }

    private func handleRemoteChange(_ notification: Notification) {
        syncLogger.info("🔔 [CloudSync] ========== Remote Change Detected ==========")
        syncLogger.info("📥 [CloudSync] Processing remote changes from other devices...")

        Task {
            await processHistoryChanges()
        }
    }

    private func processHistoryChanges() async {
        let context = PersistenceController.shared.container.newBackgroundContext()

        // 在主线程读取当前的 token
        let currentToken = await MainActor.run { self.lastHistoryToken }

        await context.perform {
            syncLogger.info("🔍 [CloudSync] Fetching persistent history transactions...")

            // 创建历史请求
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: currentToken)

            do {
                guard let result = try context.execute(request) as? NSPersistentHistoryResult,
                      let transactions = result.result as? [NSPersistentHistoryTransaction] else {
                    syncLogger.info("ℹ️ [CloudSync] No history transactions found")
                    return
                }

                syncLogger.info("📊 [CloudSync] Found \(transactions.count) transaction(s)")

                var newItems: Set<UUID> = []
                var updatedItems = 0
                var deletedItems = 0

                for transaction in transactions {
                    // 只处理来自远程（iCloud）的更改
                    if let author = transaction.author, author != "QuickHoldApp" {
                        syncLogger.debug("📝 [CloudSync] Processing transaction from: \(author)")

                        guard let changes = transaction.changes else { continue }

                        for change in changes {
                            // 只关注 Item 实体的变化
                            guard let changedObjectID = change.changedObjectID as NSManagedObjectID?,
                                  changedObjectID.entity.name == "Item" else {
                                continue
                            }

                            switch change.changeType {
                            case .insert:
                                // 新增的项目
                                if let item = try? context.existingObject(with: changedObjectID) as? Item,
                                   let itemID = item.id {
                                    newItems.insert(itemID)
                                    syncLogger.info("🆕 [CloudSync] New item detected: \(itemID)")
                                }

                            case .update:
                                updatedItems += 1
                                syncLogger.debug("🔄 [CloudSync] Item updated: \(changedObjectID)")

                            case .delete:
                                deletedItems += 1
                                syncLogger.debug("🗑️ [CloudSync] Item deleted: \(changedObjectID)")

                            @unknown default:
                                break
                            }
                        }
                    }
                }

                // 保存新 token 和更新状态到主线程
                if let lastTransaction = transactions.last {
                    let newToken = lastTransaction.token
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        self.lastHistoryToken = newToken
                        self.saveLastHistoryToken(newToken)
                    }
                }

                // 发布到主线程
                Task { @MainActor [weak self] in
                    guard let self = self else { return }

                    if !newItems.isEmpty {
                        self.newItemIDs.formUnion(newItems)
                        self.newItemCount = self.newItemIDs.count

                        syncLogger.info("✅ [CloudSync] ========== Remote Change Summary ==========")
                        syncLogger.info("📊 [CloudSync] New items: \(newItems.count)")
                        syncLogger.info("📊 [CloudSync] Updated items: \(updatedItems)")
                        syncLogger.info("📊 [CloudSync] Deleted items: \(deletedItems)")
                        syncLogger.info("📊 [CloudSync] Total new items (cumulative): \(self.newItemCount)")
                        syncLogger.info("✅ [CloudSync] =========================================")
                    } else {
                        syncLogger.info("ℹ️ [CloudSync] No new items in this sync (updated: \(updatedItems), deleted: \(deletedItems))")
                    }
                }

            } catch {
                syncLogger.error("❌ [CloudSync] Failed to fetch persistent history: \(error.localizedDescription)")
            }
        }
    }

    private func logSyncError(_ error: Error) {
        let nsError = error as NSError
        let errorCode = nsError.code
        let errorDomain = nsError.domain

        syncLogger.error("❌ [CloudSync] ========== Sync Error ==========")
        syncLogger.error("❌ [CloudSync] Domain: \(errorDomain)")
        syncLogger.error("❌ [CloudSync] Code: \(errorCode)")
        syncLogger.error("❌ [CloudSync] Description: \(error.localizedDescription)")

        // 解析常见的 CloudKit 错误并提供建议
        if errorDomain == "CKErrorDomain" || errorDomain == "NSCocoaErrorDomain" {
            switch errorCode {
            case 3: // CKErrorNetworkUnavailable
                syncLogger.error("💡 [CloudSync] Suggestion: 网络连接不可用，请检查网络设置")
            case 9: // CKErrorNotAuthenticated
                syncLogger.error("💡 [CloudSync] Suggestion: 未登录 iCloud 账户，请在系统设置中登录")
            case 26: // CKErrorZoneNotFound
                syncLogger.error("💡 [CloudSync] Suggestion: CloudKit 区域未找到，可能需要重新初始化")
            case 112: // CKErrorServerRejectedRequest
                syncLogger.error("💡 [CloudSync] Suggestion: 服务器拒绝请求，请稍后重试")
            default:
                syncLogger.error("💡 [CloudSync] Suggestion: 请检查 iCloud 账户和网络连接状态")
            }
        }

        syncLogger.error("❌ [CloudSync] ================================")
    }

    // 手动触发同步 / Manually trigger sync
    func manualSync() {
        syncLogger.info("🔄 [CloudSync] ========== Manual Sync Triggered ==========")
        syncStatus = .syncing
        let context = PersistenceController.shared.viewContext

        // 1. 保存本地更改，触发上传到 iCloud / Save local changes to trigger export to iCloud
        if context.hasChanges {
            syncLogger.info("💾 [CloudSync] Saving local changes to trigger export...")
            do {
                try context.save()
                syncLogger.info("✅ [CloudSync] Local changes saved successfully")
            } catch {
                syncLogger.error("❌ [CloudSync] Failed to save local changes: \(error.localizedDescription)")
            }
        } else {
            syncLogger.info("ℹ️ [CloudSync] No local changes to save")
        }

        // 2. 刷新所有对象，确保显示最新数据 / Refresh all objects to ensure latest data is displayed
        syncLogger.info("🔄 [CloudSync] Refreshing all objects...")
        context.refreshAllObjects()

        // 3. 重新获取数据以触发 CloudKit 检查更新
        context.perform {
            syncLogger.info("📡 [CloudSync] Triggering CloudKit update check...")
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Item")
            fetchRequest.fetchLimit = 1
            _ = try? context.fetch(fetchRequest)
            syncLogger.info("✅ [CloudSync] Manual sync completed")
        }
    }

    /// 标记新项目为已读
    func markNewItemsAsRead() {
        syncLogger.info("✓ [CloudSync] Marking \(self.newItemIDs.count) new items as read")
        self.newItemIDs.removeAll()
        self.newItemCount = 0
    }

    /// 检查某个项目是否是新同步的
    func isNewItem(_ itemID: UUID) -> Bool {
        return newItemIDs.contains(itemID)
    }

    // MARK: - Persistent History Token Management

    private func loadLastHistoryToken() {
        guard let tokenData = UserDefaults.standard.data(forKey: "CloudSyncLastHistoryToken"),
              let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData) else {
            syncLogger.info("ℹ️ [CloudSync] No saved history token found, will process all history")
            return
        }
        lastHistoryToken = token
        syncLogger.info("✅ [CloudSync] Loaded last history token from UserDefaults")
    }

    private func saveLastHistoryToken(_ token: NSPersistentHistoryToken) {
        guard let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
            syncLogger.error("❌ [CloudSync] Failed to archive history token")
            return
        }
        UserDefaults.standard.set(tokenData, forKey: "CloudSyncLastHistoryToken")
        syncLogger.debug("💾 [CloudSync] Saved history token to UserDefaults")
    }
}
