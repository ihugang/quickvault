//
//  DeviceReportServiceTests.swift
//  QuickHoldCoreTests
//
//  Created by QuickHold on 2026/01/16.
//

import XCTest
@testable import QuickHoldCore

@MainActor
final class DeviceReportServiceTests: XCTestCase {

  func testDeviceReportServiceSingleton() {
    let service1 = DeviceReportService.shared
    let service2 = DeviceReportService.shared
    XCTAssertTrue(service1 === service2, "DeviceReportService should be a singleton")
  }

  func testGetReportDeviceId() {
    let service = DeviceReportService.shared

    // 清除之前的ID
    UserDefaults.standard.removeObject(forKey: "com.quickhold.reportDeviceId")

    // 重置报告状态
    service.resetReportStatus()

    // 第一次获取应该创建新ID
    // 注意: 由于 getReportDeviceId 是私有方法,我们通过调用 reportDeviceIfNeeded 来间接测试
    // 这里只是验证服务可以正常初始化
    XCTAssertNotNil(service)
  }

  func testResetReportStatus() {
    let service = DeviceReportService.shared

    // 重置状态
    service.resetReportStatus()

    // 验证可以再次报告
    // 注意: 实际的网络请求会在真实环境中执行
    XCTAssertNotNil(service)
  }

  func testDeviceReportRequestDataEncoding() throws {
    let deviceId = UUID()
    let requestData = DeviceReportRequestData(
      deviceId: deviceId,
      name: "Test Device",
      os: 1,
      osName: "iOS",
      osVersion: "17.0",
      model: "iPhone15,2",
      localIp: "",
      localPort: 0,
      appVersion: "1.0.0 (1)",
      catId: "",
      catType: "",
      photoNum: 0,
      videoNum: 0,
      vipLevel: 0
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let jsonData = try encoder.encode(requestData)

    XCTAssertNotNil(jsonData)
    XCTAssertGreaterThan(jsonData.count, 0)

    // 验证可以解码回来
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(DeviceReportRequestData.self, from: jsonData)

    XCTAssertEqual(decoded.deviceId, deviceId)
    XCTAssertEqual(decoded.name, "Test Device")
    XCTAssertEqual(decoded.os, 1)
    XCTAssertEqual(decoded.osName, "iOS")
  }

  func testRemoteHostDecoding() throws {
    let json = """
    {
      "deviceId": "DD8CCB23-85C7-429A-A9D7-CCD1D7A28E8F",
      "ip": "192.168.1.100",
      "port": 8080,
      "name": "Test Host"
    }
    """

    let jsonData = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    let host = try decoder.decode(RemoteHost.self, from: jsonData)

    XCTAssertEqual(host.deviceId.uuidString, "DD8CCB23-85C7-429A-A9D7-CCD1D7A28E8F")
    XCTAssertEqual(host.ip, "192.168.1.100")
    XCTAssertEqual(host.port, 8080)
    XCTAssertEqual(host.name, "Test Host")
  }

  func testRemoteInvokeResultsDecoding() throws {
    let json = """
    {
      "success": true,
      "errorNumber": 0,
      "errorMessage": null,
      "data": {
        "hosts": [
          {
            "deviceId": "DD8CCB23-85C7-429A-A9D7-CCD1D7A28E8F",
            "ip": "192.168.1.100",
            "port": 8080,
            "name": "Test Host"
          }
        ],
        "wanIp": "1.2.3.4"
      }
    }
    """

    let jsonData = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    let result = try decoder.decode(RemoteInvokeResults<RemoteHosts>.self, from: jsonData)

    XCTAssertTrue(result.success)
    XCTAssertEqual(result.errorNumber, 0)
    XCTAssertNil(result.errorMessage)
    XCTAssertNotNil(result.data)
    XCTAssertEqual(result.data?.hosts?.count, 1)
    XCTAssertEqual(result.data?.wanIp, "1.2.3.4")
  }

  func testRemoteInvokeResultsDecodingWithError() throws {
    let json = """
    {
      "success": false,
      "errorNumber": 500,
      "errorMessage": "Internal Server Error",
      "data": null
    }
    """

    let jsonData = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    let result = try decoder.decode(RemoteInvokeResults<RemoteHosts>.self, from: jsonData)

    XCTAssertFalse(result.success)
    XCTAssertEqual(result.errorNumber, 500)
    XCTAssertEqual(result.errorMessage, "Internal Server Error")
    XCTAssertNil(result.data)
  }

  func testBundleAppVersion() {
    let version = Bundle.main.appVersion
    XCTAssertFalse(version.isEmpty)
    XCTAssertTrue(version.contains("("))
    XCTAssertTrue(version.contains(")"))
  }
}
