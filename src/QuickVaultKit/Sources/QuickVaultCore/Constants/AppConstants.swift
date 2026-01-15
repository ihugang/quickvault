import Foundation

// MARK: - App Constants / 应用常量
// 集中管理应用中的常量字符串，提高可维护性和类型安全

public enum AppConstants {
  
  // MARK: - Bundle Identifiers / 包标识符
  
  public enum BundleID {
    public static let quickVault = "com.codans.quickvault"
    public static let quickHold = "com.codans.quickhold"
  }
  
  // MARK: - Logger Subsystems / 日志子系统
  
  public enum Logger {
    public static let subsystem = BundleID.quickVault
    
    public enum Category {
      public static let auth = "AuthService"
      public static let crypto = "CryptoService"
      public static let keychain = "KeychainService"
      public static let storage = "StorageService"
      public static let item = "ItemService"
      public static let sync = "SyncService"
    }
  }
  
  // MARK: - Keychain Keys / 钥匙串键
  
  public enum Keychain {
    public static let service = BundleID.quickVault
    public static let masterPasswordKey = "\(BundleID.quickVault).masterPassword"
    public static let encryptionKeyKey = "\(BundleID.quickVault).encryptionKey"
    public static let biometricPasswordKey = "\(BundleID.quickVault).biometricPassword"
  }
  
  // MARK: - UserDefaults Keys / 用户默认设置键
  
  public enum UserDefaultsKeys {
    // Language & Localization / 语言和本地化
    public static let appLanguage = "app_language"
    public static let languageKey = "app_language"
    
    // Security / 安全
    public static let biometricEnabled = "\(BundleID.quickVault).biometricEnabled"
    public static let autoLockTimeout = "\(BundleID.quickVault).autoLockTimeout"
    public static let failedAttempts = "\(BundleID.quickVault).failedAttempts"
    public static let lastFailedAttempt = "\(BundleID.quickVault).lastFailedAttempt"
    
    // App State / 应用状态
    public static let hasSeenWelcome = "\(BundleID.quickVault).hasSeenWelcome"
    public static let lastAppVersion = "\(BundleID.quickVault).lastAppVersion"
    
    // Features / 功能
    public static let ocrEnabled = "\(BundleID.quickVault).ocrEnabled"
    public static let cloudSyncEnabled = "\(BundleID.quickVault).cloudSyncEnabled"
  }
  
  // MARK: - Notification Names / 通知名称
  
  public enum Notification {
    public static let authStateChanged = Foundation.Notification.Name("\(BundleID.quickVault).authStateChanged")
    public static let biometricChanged = Foundation.Notification.Name("\(BundleID.quickVault).biometricChanged")
    public static let languageChanged = Foundation.Notification.Name("\(BundleID.quickVault).languageChanged")
    public static let dataCleared = Foundation.Notification.Name("\(BundleID.quickVault).dataCleared")
    public static let itemCreated = Foundation.Notification.Name("\(BundleID.quickVault).itemCreated")
    public static let itemUpdated = Foundation.Notification.Name("\(BundleID.quickVault).itemUpdated")
    public static let itemDeleted = Foundation.Notification.Name("\(BundleID.quickVault).itemDeleted")
  }
  
  // MARK: - System Icon Names / 系统图标名称
  
  public enum SystemIcon {
    // General UI / 通用界面
    public static let checkmark = "checkmark.circle.fill"
    public static let error = "exclamationmark.circle.fill"
    public static let close = "xmark.circle.fill"
    public static let add = "plus.circle.fill"
    
    // Item Types / 项目类型
    public static let textDocument = "doc.text.fill"
    public static let richText = "doc.richtext.fill"
    public static let image = "photo"
    public static let file = "folder.fill"
    
    // Actions / 操作
    public static let edit = "pencil"
    public static let delete = "trash"
    public static let pin = "pin.fill"
    public static let search = "magnifyingglass"
    public static let share = "square.and.arrow.up"
    
    // Security / 安全
    public static let lock = "lock.fill"
    public static let unlock = "lock.open.fill"
    public static let biometric = "faceid"
    
    // Media / 媒体
    public static let photoBadgePlus = "photo.badge.plus"
    public static let docBadgePlus = "doc.badge.plus"
    
    // ID Cards / 证件
    public static let idCard = "person.text.rectangle"
    public static let invoice = "doc.text.fill"
    
    // Copy / 复制
    public static let copy = "doc.on.doc"
  }
  
  // MARK: - CoreData / 核心数据
  
  public enum CoreData {
    public static let modelName = "QuickVault"
    public static let storeFileName = "QuickVault.sqlite"
    
    // Entity Names / 实体名称
    public enum Entity {
      public static let item = "Item"
      public static let textContent = "TextContent"
      public static let imageContent = "ImageContent"
      public static let fileContent = "FileContent"
      public static let card = "Card"
      public static let cardField = "CardField"
      public static let cardAttachment = "CardAttachment"
    }
  }
  
  // MARK: - Crypto / 加密
  
  public enum Crypto {
    public static let keySize = 32  // AES-256 key size in bytes
    public static let pbkdf2Iterations = 100_000
    public static let saltSize = 16
    public static let nonceSize = 12  // AES-GCM nonce size
  }
  
  // MARK: - Validation / 验证
  
  public enum Validation {
    public static let minPasswordLength = 8
    public static let maxPasswordLength = 128
    public static let maxTagLength = 20
    public static let maxTitleLength = 100
    public static let maxImageCount = 20
    public static let maxFileCount = 10
    public static let maxFileSize = 50 * 1024 * 1024  // 50 MB
  }
  
  // MARK: - Auto Lock Timeouts / 自动锁定超时
  
  public enum AutoLock {
    public static let immediately = 0
    public static let thirtySeconds = 30
    public static let oneMinute = 60
    public static let fiveMinutes = 300
    public static let fifteenMinutes = 900
    public static let never = -1
    
    public static let defaultTimeout = oneMinute
    public static let briefSwitchThreshold: TimeInterval = 30
  }
  
  // MARK: - Rate Limiting / 速率限制
  
  public enum RateLimit {
    public static let maxFailedAttempts = 5
    public static let lockoutDuration: TimeInterval = 300  // 5 minutes
  }
  
  // MARK: - File Paths / 文件路径
  
  public enum FilePath {
    public static func documentsDirectory() -> URL {
      FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    public static func applicationSupportDirectory() -> URL {
      FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }
    
    public static func coreDataStoreURL() -> URL {
      applicationSupportDirectory().appendingPathComponent(CoreData.storeFileName)
    }
  }
  
  // MARK: - Watermark / 水印
  
  public enum Watermark {
    public static let defaultOpacity: Double = 0.5
    public static let minOpacity: Double = 0.1
    public static let maxOpacity: Double = 1.0
    
    public enum Spacing {
      public static let dense = 50.0
      public static let normal = 100.0
      public static let sparse = 150.0
    }
  }
  
  // MARK: - App URLs / 应用链接
  
  public enum AppURL {
    public static let photoPC = "https://apps.apple.com/app/id6738619866"
    public static let foxVault = "https://apps.apple.com/app/id6738620044"
  }
}
