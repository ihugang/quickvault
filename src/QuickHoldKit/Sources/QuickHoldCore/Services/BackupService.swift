//
//  BackupService.swift
//  QuickHold
//
//  提供将全部卡片导出为 zip 备份、以及从备份恢复的能力。
//  备份内容保持加密状态；恢复时需要当前主密码可解密数据。
//

import Foundation
import CoreData
import ZIPFoundation

public enum BackupServiceError: LocalizedError {
  case platformNotSupported
  case invalidArchive
  case unsupportedVersion(Int)
  case missingCryptoKey
  case fileNotFound(String)

  public var errorDescription: String? {
    switch self {
    case .platformNotSupported:
      return "当前系统版本不支持压缩/解压操作，请升级系统后重试。"
    case .invalidArchive:
      return "备份文件无效或已损坏。"
    case .unsupportedVersion(let version):
      return "不支持的备份版本：\(version)"
    case .missingCryptoKey:
      return "请先解锁应用（加载主密码）后再进行备份或恢复。"
    case .fileNotFound(let name):
      return "备份中的附件缺失：\(name)"
    }
  }
}

/// 备份/恢复服务
public final class BackupService {
  private let persistenceController: PersistenceController
  private let cryptoService: CryptoService
  private let fileStorageManager: FileStorageManager
  private let fileManager = FileManager.default

  // MARK: - Models

  private struct BackupManifest: Codable {
    let version: Int
    let createdAt: Date
    let itemCount: Int
  }

  private struct BackupTextContent: Codable {
    let encryptedContent: String
  }

  private struct BackupImageContent: Codable {
    let id: UUID
    let fileName: String
    let fileSize: Int64
    let displayOrder: Int16
    let encryptedData: String
    let thumbnailData: String?
  }

  private struct BackupFileContent: Codable {
    let id: UUID
    let fileName: String
    let mimeType: String
    let displayOrder: Int16
    let fileSize: Int64
    let archiveRelativePath: String
    let thumbnailData: String?
  }

  private struct BackupItem: Codable {
    let id: UUID
    let title: String
    let type: String
    let tags: [String]
    let isPinned: Bool
    let createdAt: Date
    let updatedAt: Date
    let textContent: BackupTextContent?
    let images: [BackupImageContent]?
    let files: [BackupFileContent]?
  }

  // MARK: - Init

  public init(
    persistenceController: PersistenceController,
    cryptoService: CryptoService = CryptoServiceImpl.shared,
    storageLocation: StorageLocation = .local
  ) {
    self.persistenceController = persistenceController
    self.cryptoService = cryptoService
    self.fileStorageManager = FileStorageManager(
      cryptoService: cryptoService,
      storageLocation: storageLocation
    )
  }

  // MARK: - Export

  /// 导出全部卡片到 zip 备份
  @available(iOS 16.0, macOS 13.0, *)
  public func exportBackup(to destinationURL: URL) async throws {
    guard cryptoServiceHasKey else {
      throw BackupServiceError.missingCryptoKey
    }

    let tempRoot = fileManager.temporaryDirectory
      .appendingPathComponent("QuickHold-Backup-\(UUID().uuidString)", isDirectory: true)
    let filesDir = tempRoot.appendingPathComponent("files", isDirectory: true)

    try fileManager.createDirectory(at: filesDir, withIntermediateDirectories: true)

    let context = persistenceController.container.viewContext

    // Collect items + attachments
    let backupItems: [BackupItem] = try await context.perform {
      let fetchRequest = Item.fetchRequest()
      fetchRequest.sortDescriptors = [
        NSSortDescriptor(keyPath: \Item.updatedAt, ascending: false)
      ]
      let items = try context.fetch(fetchRequest)

      return try items.compactMap { item in
        guard let id = item.id,
              let title = item.title,
              let type = item.type else {
          return nil
        }

        var textBackup: BackupTextContent?
        var imageBackups: [BackupImageContent]?
        var fileBackups: [BackupFileContent]?

        if let textContent = item.textContent,
           let enc = textContent.encryptedContent {
          textBackup = BackupTextContent(encryptedContent: enc.base64EncodedString())
        }

        if let imageSet = item.images {
          let sorted = (imageSet.allObjects as? [ImageContent])?
            .sorted { $0.displayOrder < $1.displayOrder } ?? []
          imageBackups = try sorted.compactMap { image in
            guard let imageId = image.id,
                  let fileName = image.fileName,
                  let enc = image.encryptedData else {
              return nil
            }

            let thumb = image.thumbnailData?.base64EncodedString()
            return BackupImageContent(
              id: imageId,
              fileName: fileName,
              fileSize: image.fileSize,
              displayOrder: image.displayOrder,
              encryptedData: enc.base64EncodedString(),
              thumbnailData: thumb
            )
          }
        }

        if let fileSet = item.files {
          let sorted = (fileSet.allObjects as? [FileContent])?
            .sorted { $0.displayOrder < $1.displayOrder } ?? []
          fileBackups = try sorted.compactMap { file in
            guard let fileId = file.id,
                  let fileName = file.fileName,
                  let mimeType = file.mimeType,
                  let relativePath = file.fileURL else {
              return nil
            }

            // 直接使用磁盘上的加密文件内容，保持加密状态
            let fileURL = try self.fileStorageManager.getFileURL(relativePath: relativePath)
            let encryptedData = try Data(contentsOf: fileURL)

            let archiveName = "\(fileId.uuidString)-\(fileName)"
            let archivePath = "files/\(archiveName)"
            let destination = filesDir.appendingPathComponent(archiveName)
            try encryptedData.write(to: destination)

            let thumb = file.thumbnailData?.base64EncodedString()
            return BackupFileContent(
              id: fileId,
              fileName: fileName,
              mimeType: mimeType,
              displayOrder: file.displayOrder,
              fileSize: file.fileSize,
              archiveRelativePath: archivePath,
              thumbnailData: thumb
            )
          }
        }

        return BackupItem(
          id: id,
          title: title,
          type: type,
          tags: item.tags,
          isPinned: item.isPinned,
          createdAt: item.createdAt ?? Date(),
          updatedAt: item.updatedAt ?? Date(),
          textContent: textBackup,
          images: imageBackups,
          files: fileBackups
        )
      }
    }

    // Write manifest and payload
    let manifest = BackupManifest(
      version: 1,
      createdAt: Date(),
      itemCount: backupItems.count
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let manifestData = try encoder.encode(manifest)
    let itemsData = try encoder.encode(backupItems)

    try manifestData.write(to: tempRoot.appendingPathComponent("manifest.json"))
    try itemsData.write(to: tempRoot.appendingPathComponent("items.json"))

    // Zip temp directory
    try await zipDirectory(at: tempRoot, to: destinationURL)

    try? fileManager.removeItem(at: tempRoot)
  }

  // MARK: - Restore

  /// 从 zip 备份恢复；默认覆盖现有卡片
  @available(iOS 16.0, macOS 13.0, *)
  public func restoreBackup(from zipURL: URL, replaceExisting: Bool = true) async throws {
    guard cryptoServiceHasKey else {
      throw BackupServiceError.missingCryptoKey
    }

    let tempRoot = fileManager.temporaryDirectory
      .appendingPathComponent("QuickHold-Restore-\(UUID().uuidString)", isDirectory: true)
    try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)

    // Unzip
    do {
      try await unzipFile(at: zipURL, to: tempRoot)
    } catch {
      try? fileManager.removeItem(at: tempRoot)
      throw BackupServiceError.invalidArchive
    }

    let manifestURL = tempRoot.appendingPathComponent("manifest.json")
    let itemsURL = tempRoot.appendingPathComponent("items.json")

    guard fileManager.fileExists(atPath: manifestURL.path),
          fileManager.fileExists(atPath: itemsURL.path) else {
      try? fileManager.removeItem(at: tempRoot)
      throw BackupServiceError.invalidArchive
    }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let manifest = try decoder.decode(BackupManifest.self, from: Data(contentsOf: manifestURL))
    guard manifest.version == 1 else {
      try? fileManager.removeItem(at: tempRoot)
      throw BackupServiceError.unsupportedVersion(manifest.version)
    }

    let backupItems = try decoder.decode([BackupItem].self, from: Data(contentsOf: itemsURL))

    let context = persistenceController.container.viewContext

    try await context.perform {
      if replaceExisting {
        try self.clearExistingData(in: context)
      }

      for backup in backupItems {
        let item = Item(context: context)
        item.id = backup.id
        item.title = backup.title
        item.type = backup.type
        item.tags = backup.tags
        item.isPinned = backup.isPinned
        item.createdAt = backup.createdAt
        item.updatedAt = backup.updatedAt

        if let textBackup = backup.textContent,
           let encData = Data(base64Encoded: textBackup.encryptedContent) {
          // 先解密再按当前密钥重新加密，确保与现有密码一致
          let decrypted = try self.cryptoService.decrypt(encData)
          let textContent = TextContent(context: context)
          textContent.id = UUID()
          textContent.encryptedContent = try self.cryptoService.encrypt(decrypted)
          textContent.item = item
        }

        if let imageBackups = backup.images {
          for backupImage in imageBackups {
            guard let encData = Data(base64Encoded: backupImage.encryptedData) else {
              continue
            }
            let decrypted = try self.cryptoService.decryptFile(encData)
            let imageContent = ImageContent(context: context)
            imageContent.id = backupImage.id
            imageContent.fileName = backupImage.fileName
            imageContent.fileSize = backupImage.fileSize
            imageContent.displayOrder = backupImage.displayOrder
            imageContent.encryptedData = try self.cryptoService.encryptFile(decrypted)
            if let thumb = backupImage.thumbnailData,
               let thumbData = Data(base64Encoded: thumb) {
              let thumbDecrypted = try self.cryptoService.decryptFile(thumbData)
              imageContent.thumbnailData = try self.cryptoService.encryptFile(thumbDecrypted)
            }
            imageContent.item = item
          }
        }

        if let fileBackups = backup.files {
          for backupFile in fileBackups {
            let archivePath = tempRoot.appendingPathComponent(backupFile.archiveRelativePath)
            guard self.fileManager.fileExists(atPath: archivePath.path) else {
              throw BackupServiceError.fileNotFound(backupFile.fileName)
            }
            let encryptedData = try Data(contentsOf: archivePath)
            let decrypted = try self.cryptoService.decryptFile(encryptedData)

            let relativePath = try self.fileStorageManager.saveFile(
              data: decrypted,
              fileName: backupFile.fileName
            )

            let fileContent = FileContent(context: context)
            fileContent.id = backupFile.id
            fileContent.fileName = backupFile.fileName
            fileContent.mimeType = backupFile.mimeType
            fileContent.displayOrder = backupFile.displayOrder
            fileContent.fileSize = backupFile.fileSize
            fileContent.fileURL = relativePath

            if let thumb = backupFile.thumbnailData,
               let thumbData = Data(base64Encoded: thumb) {
              let thumbDecrypted = try self.cryptoService.decryptFile(thumbData)
              fileContent.thumbnailData = try self.cryptoService.encryptFile(thumbDecrypted)
            }

            fileContent.item = item
          }
        }
      }

      try context.save()
    }

    try? fileManager.removeItem(at: tempRoot)
  }

  // MARK: - Helpers

  private var cryptoServiceHasKey: Bool {
    // 尝试获取盐，若缺失说明密钥尚未初始化
    (try? cryptoService.getSalt()) != nil
  }

  private func clearExistingData(in context: NSManagedObjectContext) throws {
    // 删除本地文件目录
    if let storagePath = fileStorageManager.getStoragePath() {
      try? fileManager.removeItem(atPath: storagePath)
    }

    let deleteRequest = NSBatchDeleteRequest(fetchRequest: Item.fetchRequest())
    try context.execute(deleteRequest)
  }

  // MARK: - Zip/Unzip

  /// 使用 ZIPFoundation 压缩目录
  private func zipDirectory(at sourceURL: URL, to destinationURL: URL) async throws {
    try fileManager.zipItem(at: sourceURL, to: destinationURL, shouldKeepParent: false)
  }

  /// 使用 ZIPFoundation 解压文件
  private func unzipFile(at sourceURL: URL, to destinationURL: URL) async throws {
    try fileManager.unzipItem(at: sourceURL, to: destinationURL)
  }
}
