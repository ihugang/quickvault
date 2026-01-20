//
//  DeviceReportService.swift
//  QuickHold
//
//  Created by QuickHold on 2026/01/16.
//
//  设备报告服务 - 向云端报告设备信息

import CoreData
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Device Report API

enum DeviceReportAPI {
  private static let baseURL = URL(string: "https://api.apiandlogs.com/api")!
  public static let applicationId = UUID(uuidString: "DD8CCB23-85C7-429A-A9D7-CCD1D7A28E8F")!

  static func reportDevice(_ payload: DeviceReportRequestData) async throws -> RemoteInvokeResults<RemoteHosts> {
    let url = baseURL.appendingPathComponent("Device/ReportDevice")
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(applicationId.uuidString, forHTTPHeaderField: "X-Application-Id")

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    request.httpBody = try encoder.encode(payload)

    if let body = request.httpBody,
       let jsonString = String(data: body, encoding: .utf8)
    {
      print("🌐 [DeviceReport] 请求: \(url.absoluteString)")
      print("   body: \(jsonString)")
    }

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode)
    else {
      throw DeviceReportError.serverError
    }

    if let raw = String(data: data, encoding: .utf8) {
      print("🔁 [DeviceReport] 响应(\(httpResponse.statusCode)): \(raw)")
    }

    let decoder = JSONDecoder()
    return try decoder.decode(RemoteInvokeResults<RemoteHosts>.self, from: data)
  }
}

// MARK: - Data Models

struct DeviceReportRequestData: Codable {
  let applicationId: UUID
  let deviceId: UUID
  let name: String
  let os: Int8
  let osName: String
  let osVersion: String
  let model: String
  let localIp: String
  let localPort: UInt16
  let appVersion: String
  let catId: String
  let catType: String
  let photoNum: Int32
  let videoNum: Int32
  let docNum: Int32
  let vipLevel: Int8
}

struct RemoteHost: Codable {
  let deviceId: UUID
  let ip: String
  let port: Int
  let name: String
}

struct RemoteHosts: Codable {
  let hosts: [RemoteHost]?
  let wanIp: String?
}

struct RemoteInvokeResults<T: Decodable>: Decodable {
  let success: Bool
  let errorNumber: Int32
  let errorMessage: String?
  let data: T?

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    success = (try? values.decode(Bool.self, forKey: .success)) ?? false
    errorNumber = (try? values.decode(Int32.self, forKey: .errorNumber)) ?? 0
    errorMessage = try? values.decode(String.self, forKey: .errorMessage)
    data = try? values.decode(T.self, forKey: .data)
  }

  private enum CodingKeys: String, CodingKey {
    case success = "success"
    case errorNumber = "errorNumber"
    case errorMessage = "errorMessage"
    case data = "data"
  }
}

enum DeviceReportError: LocalizedError {
  case serverError
  case networkError
  case decodingError

  var errorDescription: String? {
    switch self {
    case .serverError:
      return "服务器错误 / Server error"
    case .networkError:
      return "网络错误 / Network error"
    case .decodingError:
      return "数据解析错误 / Decoding error"
    }
  }
}

// MARK: - Device Report Service

@MainActor
public class DeviceReportService: ObservableObject {
  public static let shared = DeviceReportService()

  private let keychainService = KeychainServiceImpl()
  private let reportDeviceIdKey = QuickHoldConstants.KeychainKeys.reportDeviceId
  private let legacyUserDefaultsKey = QuickHoldConstants.UserDefaultsKeys.reportDeviceId
  private var hasReportedDevice = false
  private let persistenceController = PersistenceController.shared

  private init() {
    // Migrate from UserDefaults to Keychain if needed
    migrateDeviceIdToKeychain()
  }

  /// 报告设备信息到云端
  public func reportDeviceIfNeeded(itemCount: Int = 0) {
    guard !hasReportedDevice else { return }
    hasReportedDevice = true

    Task {
      await reportDeviceToCloud(itemCount: itemCount)
    }
  }

  /// 执行设备报告
  private func reportDeviceToCloud(itemCount: Int) async {
    let deviceId = getReportDeviceId()
    let itemCounts = await fetchItemCounts()

    #if canImport(UIKit)
    let deviceName = UIDevice.current.name
    let osName = UIDevice.current.systemName
    let osVersion = UIDevice.current.systemVersion
    let deviceModel = UIDevice.current.modelName
    let os: Int8 = 1 // iOS
    #else
    let deviceName = Host.current().localizedName ?? "Mac"
    let osName = "macOS"
    let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
    let deviceModel = "Mac"
    let os: Int8 = 3 // macOS
    #endif

    let appVersion = Bundle.main.appVersion

    let payload = DeviceReportRequestData(
      applicationId: DeviceReportAPI.applicationId,
      deviceId: deviceId,
      name: deviceName,
      os: os,
      osName: osName,
      osVersion: osVersion,
      model: deviceModel,
      localIp: "",
      localPort: 0,
      appVersion: appVersion,
      catId: "",
      catType: "",
      photoNum: itemCounts.image,
      videoNum: itemCounts.text,
      docNum: itemCounts.file,
      vipLevel: 0
    )

    do {
      let response = try await DeviceReportAPI.reportDevice(payload)
      if response.success {
        let hostCount = response.data?.hosts?.count ?? 0
        print("✅ Device report success, hosts: \(hostCount)")
      } else {
        print("⚠️ Device report failed: \(response.errorMessage ?? "unknown error")")
      }
    } catch {
      print("⚠️ Device report error: \(error.localizedDescription)")
    }
  }

  /// 获取或创建设备报告ID（从 Keychain 读取，确保重装后保持不变）
  private func getReportDeviceId() -> UUID {
    // Try to load from Keychain
    if let data = try? keychainService.load(key: reportDeviceIdKey),
       let uuidString = String(data: data, encoding: .utf8),
       let uuid = UUID(uuidString: uuidString)
    {
      return uuid
    }

    // Generate new ID and save to Keychain
    let newId = UUID()
    if let data = newId.uuidString.data(using: .utf8) {
      // Device ID should NOT be synced across devices (synchronizable: false)
      try? keychainService.save(key: reportDeviceIdKey, data: data, synchronizable: false)
    }
    return newId
  }

  /// 从 UserDefaults 迁移到 Keychain（仅执行一次）
  private func migrateDeviceIdToKeychain() {
    // Check if already in Keychain
    if keychainService.exists(key: reportDeviceIdKey) {
      return
    }

    // Try to migrate from UserDefaults
    let defaults = UserDefaults.standard
    if let stored = defaults.string(forKey: legacyUserDefaultsKey),
       let uuid = UUID(uuidString: stored),
       let data = uuid.uuidString.data(using: .utf8)
    {
      // Migrate to Keychain
      try? keychainService.save(key: reportDeviceIdKey, data: data, synchronizable: false)
      // Clean up UserDefaults
      defaults.removeObject(forKey: legacyUserDefaultsKey)
      print("✅ Migrated DeviceId from UserDefaults to Keychain")
    }
  }

  /// 重置报告状态(用于测试)
  public func resetReportStatus() {
    hasReportedDevice = false
  }

  private func fetchItemCounts() async -> (text: Int32, image: Int32, file: Int32) {
    let context = persistenceController.container.viewContext
    return await context.perform {
      let textCount = self.countItems(of: .text, in: context)
      let imageCount = self.countItems(of: .image, in: context)
      let fileCount = self.countItems(of: .file, in: context)
      return (Int32(textCount), Int32(imageCount), Int32(fileCount))
    }
  }

  nonisolated private func countItems(of type: ItemType, in context: NSManagedObjectContext) -> Int {
    let request = Item.fetchRequest()
    request.predicate = NSPredicate(format: "type == %@", type.rawValue)
    do {
      let count = try context.count(for: request)
      return count == NSNotFound ? 0 : count
    } catch {
      print("⚠️ Failed to count \(type.rawValue) items: \(error.localizedDescription)")
      return 0
    }
  }
}

// MARK: - Bundle Extension

extension Bundle {
  var appVersion: String {
    let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
    return "\(version) (\(build))"
  }
}

// MARK: - UIDevice Extension

#if canImport(UIKit)
extension UIDevice {
  var modelName: String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let modelCode = withUnsafePointer(to: &systemInfo.machine) {
      $0.withMemoryRebound(to: CChar.self, capacity: 1) {
        String(validatingUTF8: $0)
      }
    }
    return modelCode ?? "Unknown"
  }
}
#endif
