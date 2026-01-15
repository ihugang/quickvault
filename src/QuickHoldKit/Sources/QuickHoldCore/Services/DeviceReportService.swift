//
//  DeviceReportService.swift
//  QuickHold
//
//  Created by QuickHold on 2026/01/16.
//
//  设备报告服务 - 向云端报告设备信息

import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Device Report API

enum DeviceReportAPI {
  private static let baseURL = URL(string: "https://api.apiandlogs.com/api")!
  private static let applicationId = UUID(uuidString: "DD8CCB23-85C7-429A-A9D7-CCD1D7A28E8F")!

  static func reportDevice(_ payload: DeviceReportRequestData) async throws -> RemoteInvokeResults<RemoteHosts> {
    let url = baseURL.appendingPathComponent("Device/ReportQuickHold")
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

  private let reportDeviceIdKey = "com.quickhold.reportDeviceId"
  private var hasReportedDevice = false

  private init() {}

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
    let os: Int8 = 2 // macOS
    #endif

    let appVersion = Bundle.main.appVersion

    let payload = DeviceReportRequestData(
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
      photoNum: 0,
      videoNum: 0,
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

  /// 获取或创建设备报告ID
  private func getReportDeviceId() -> UUID {
    let defaults = UserDefaults.standard
    if let stored = defaults.string(forKey: reportDeviceIdKey),
       let uuid = UUID(uuidString: stored)
    {
      return uuid
    }
    let newId = UUID()
    defaults.set(newId.uuidString, forKey: reportDeviceIdKey)
    return newId
  }

  /// 重置报告状态(用于测试)
  public func resetReportStatus() {
    hasReportedDevice = false
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
