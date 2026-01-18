//
//  CloudSyncMonitor.swift
//  QuickHold
//
//  监控 iCloud 同步状态
//

import SwiftUI
import CoreData
import Combine

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
}
