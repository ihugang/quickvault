//
//  FileStorageManager.swift
//  QuickVault
//
//  文件存储管理器 / File Storage Manager
//  负责管理文件在文件系统中的存储、加密和访问
//  支持 iCloud 同步和跨平台共享（iOS/macOS）
//

import Foundation

/// 存储位置类型 / Storage location type
public enum StorageLocation {
  case local        // 本地存储（不同步）/ Local storage (no sync)
  case iCloud       // iCloud Documents（跨设备同步）/ iCloud Documents (cross-device sync)
}

/// 文件存储管理器 / File Storage Manager
public class FileStorageManager {
  
  // MARK: - Properties
  
  private let cryptoService: CryptoService
  private let fileManager = FileManager.default
  private let storageLocation: StorageLocation
  
  // iCloud container identifier
  private let iCloudContainerIdentifier = "iCloud.com.quickvault.app"
  
  /// 文件存储根目录 / File storage root directory
  /// 根据配置，可能位于本地或 iCloud
  private var filesDirectory: URL {
    get throws {
      switch storageLocation {
      case .local:
        return try localFilesDirectory()
      case .iCloud:
        return try iCloudFilesDirectory()
      }
    }
  }
  
  /// 本地文件目录 / Local files directory
  /// 位于 Application Support/QuickVault/Files/
  private func localFilesDirectory() throws -> URL {
    let appSupport = try fileManager.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let quickVaultDir = appSupport.appendingPathComponent("QuickVault", isDirectory: true)
    let filesDir = quickVaultDir.appendingPathComponent("Files", isDirectory: true)
    
    // 确保目录存在 / Ensure directory exists
    if !fileManager.fileExists(atPath: filesDir.path) {
      try fileManager.createDirectory(at: filesDir, withIntermediateDirectories: true)
    }
    
    return filesDir
  }
  
  /// iCloud 文件目录 / iCloud files directory
  /// 位于 iCloud Drive/QuickVault/Library/Files/（用户不可见）
  /// iOS 和 macOS 共享此目录，但在 Files App 中隐藏
  private func iCloudFilesDirectory() throws -> URL {
    guard let containerURL = fileManager.url(forUbiquityContainerIdentifier: iCloudContainerIdentifier) else {
      // 如果 iCloud 不可用，回退到本地存储
      print("⚠️ iCloud not available, falling back to local storage")
      return try localFilesDirectory()
    }
    
    // 使用 Library 目录而非 Documents，文件不会在 Files App 中显示
    // Use Library directory instead of Documents to hide files from Files App
    let libraryDir = containerURL.appendingPathComponent("Library", isDirectory: true)
    let filesDir = libraryDir.appendingPathComponent("Files", isDirectory: true)
    
    // 确保目录存在 / Ensure directory exists
    if !fileManager.fileExists(atPath: filesDir.path) {
      try fileManager.createDirectory(at: filesDir, withIntermediateDirectories: true)
    }
    
    return filesDir
  }
  
  // MARK: - Initialization
  
  /// 初始化文件存储管理器
  /// - Parameters:
  ///   - cryptoService: 加密服务
  ///   - storageLocation: 存储位置（默认使用 iCloud）
  public init(cryptoService: CryptoService, storageLocation: StorageLocation = .iCloud) {
    self.cryptoService = cryptoService
    self.storageLocation = storageLocation
  }
  
  // MARK: - Public Methods
  
  /// 保存文件到存储目录（加密后）/ Save file to storage (encrypted)
  /// - Parameters:
  ///   - data: 原始文件数据 / Original file data
  ///   - fileName: 文件名（用于生成扩展名）/ File name (for extension)
  /// - Returns: 相对文件路径 / Relative file path
  public func saveFile(data: Data, fileName: String) throws -> String {
    // 加密文件数据 / Encrypt file data
    let encryptedData = try cryptoService.encryptFile(data)
    
    // 生成唯一文件名 / Generate unique file name
    let fileExtension = (fileName as NSString).pathExtension
    let uniqueFileName = UUID().uuidString + (fileExtension.isEmpty ? "" : ".\(fileExtension)")
    
    // 获取完整文件路径 / Get full file path
    let baseDir = try filesDirectory
    let fileURL = baseDir.appendingPathComponent(uniqueFileName)
    
    // 写入文件 / Write file
    try encryptedData.write(to: fileURL, options: .atomic)
    
    // 返回相对路径（只包含文件名）/ Return relative path (file name only)
    return uniqueFileName
  }
  
  /// 读取文件内容（解密后）/ Read file content (decrypted)
  /// - Parameter relativePath: 相对文件路径 / Relative file path
  /// - Returns: 解密后的文件数据 / Decrypted file data
  public func readFile(relativePath: String) throws -> Data {
    let baseDir = try filesDirectory
    let fileURL = baseDir.appendingPathComponent(relativePath)
    
    // 读取加密数据 / Read encrypted data
    let encryptedData = try Data(contentsOf: fileURL)
    
    // 解密 / Decrypt
    return try cryptoService.decryptFile(encryptedData)
  }
  
  /// 删除文件 / Delete file
  /// - Parameter relativePath: 相对文件路径 / Relative file path
  public func deleteFile(relativePath: String) throws {
    let baseDir = try filesDirectory
    let fileURL = baseDir.appendingPathComponent(relativePath)
    
    if fileManager.fileExists(atPath: fileURL.path) {
      try fileManager.removeItem(at: fileURL)
    }
  }
  
  /// 检查文件是否存在 / Check if file exists
  /// - Parameter relativePath: 相对文件路径 / Relative file path
  /// - Returns: 文件是否存在 / Whether file exists
  public func fileExists(relativePath: String) throws -> Bool {
    let baseDir = try filesDirectory
    let fileURL = baseDir.appendingPathComponent(relativePath)
    return fileManager.fileExists(atPath: fileURL.path)
  }
  
  /// 获取文件的实际大小 / Get actual file size
  /// - Parameter relativePath: 相对文件路径 / Relative file path
  /// - Returns: 文件大小（字节）/ File size in bytes
  public func getFileSize(relativePath: String) throws -> Int64 {
    let baseDir = try filesDirectory
    let fileURL = baseDir.appendingPathComponent(relativePath)
    let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
    return attributes[.size] as? Int64 ?? 0
  }
  
  /// 获取文件的完整 URL（用于临时访问）/ Get full file URL (for temporary access)
  /// - Parameter relativePath: 相对文件路径 / Relative file path
  /// - Returns: 完整文件 URL / Full file URL
  public func getFileURL(relativePath: String) throws -> URL {
    let baseDir = try filesDirectory
    return baseDir.appendingPathComponent(relativePath)
  }
  
  // MARK: - iCloud Utilities
  
  /// 检查 iCloud 是否可用 / Check if iCloud is available
  public var isICloudAvailable: Bool {
    return fileManager.ubiquityIdentityToken != nil
  }
  
  /// 获取当前存储位置 / Get current storage location
  public var currentStorageLocation: StorageLocation {
    return storageLocation
  }
  
  /// 获取存储目录的实际路径（用于调试）/ Get actual storage path (for debugging)
  public func getStoragePath() -> String? {
    return try? filesDirectory.path
  }
}
