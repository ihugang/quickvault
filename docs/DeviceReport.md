# Device Report 功能说明

## 概述

Device Report 功能用于向云端报告设备信息,帮助应用统计用户设备数据和使用情况。

## 功能特性

### 1. 自动报告
- 应用启动时自动报告一次设备信息
- 使用 `hasReportedDevice` 标志确保每次应用运行只报告一次
- 设备ID持久化存储在 UserDefaults 中

### 2. 报告内容
- **设备ID**: 唯一标识符,存储在 UserDefaults 中
- **设备名称**: iOS 设备名称或 Mac 名称
- **操作系统**: iOS (1) 或 macOS (2)
- **系统版本**: 如 "iOS 17.0" 或 "macOS 14.0"
- **设备型号**: 如 "iPhone15,2" 或 "Mac"
- **应用版本**: 如 "1.0.0 (1)"

### 3. API 配置
- **基础URL**: `https://api.apiandlogs.com/api`
- **端点**: `/Device/ReportQuickHold`
- **ApplicationId**: `DD8CCB23-85C7-429A-A9D7-CCD1D7A28E8F`
- **HTTP方法**: POST
- **Content-Type**: application/json

## 代码结构

### DeviceReportService.swift
位置: `src/QuickHoldKit/Sources/QuickHoldCore/Services/DeviceReportService.swift`

主要组件:
1. **DeviceReportAPI**: 云端API调用
2. **DeviceReportService**: 单例服务类
3. **数据模型**:
   - `DeviceReportRequestData`: 请求数据
   - `RemoteHost`: 远程主机信息
   - `RemoteHosts`: 主机列表
   - `RemoteInvokeResults`: API响应结果

### 集成方式

#### iOS 应用
在 `QuickVaultApp.swift` 的 `body` 中添加:
```swift
.onAppear {
    // 报告设备信息到云端
    Task {
        await DeviceReportService.shared.reportDeviceIfNeeded()
    }
}
```

#### macOS 应用
在 `AppDelegate.applicationDidFinishLaunching` 中添加:
```swift
// 报告设备信息到云端
Task { @MainActor in
    await DeviceReportService.shared.reportDeviceIfNeeded()
}
```

## 使用示例

### 基本使用
```swift
// 自动报告(推荐)
await DeviceReportService.shared.reportDeviceIfNeeded()

// 强制报告(用于测试)
DeviceReportService.shared.resetReportStatus()
await DeviceReportService.shared.reportDeviceIfNeeded()
```

### 自定义报告
```swift
// 报告时包含项目数量
await DeviceReportService.shared.reportDeviceIfNeeded(itemCount: 100)
```

## 数据隐私

- 不收集任何个人敏感信息
- 设备ID是随机生成的UUID,不关联真实身份
- 设备名称可能包含用户自定义名称(如"刚的 iPhone")
- 所有数据仅用于统计分析,不会用于其他用途

## 错误处理

服务会自动处理以下错误:
- 网络错误: 静默失败,不影响应用使用
- 服务器错误: 记录日志,不影响应用使用
- 解码错误: 记录日志,不影响应用使用

所有错误都会在控制台输出日志,便于调试:
```
✅ Device report success, hosts: 0
⚠️ Device report failed: unknown error
⚠️ Device report error: The Internet connection appears to be offline.
```

## 测试

### 单元测试
```swift
func testDeviceReport() async {
    let service = DeviceReportService.shared
    service.resetReportStatus()
    await service.reportDeviceIfNeeded()
    // 检查日志输出
}
```

### 手动测试
1. 运行应用
2. 查看控制台日志
3. 确认看到 "Device report success" 或错误信息

## 从 Photo2Pc 移植的改动

1. **ApplicationId**: 从 Photo2Pc 改为 QuickHold 专用ID
2. **API端点**: 从 `/Device/ReportPhotoPcPro` 改为 `/Device/ReportQuickHold`
3. **简化功能**: 移除了照片/视频数量统计(QuickHold 不是照片应用)
4. **移除依赖**: 不依赖 RevenueCat 或 VIP 管理器
5. **跨平台支持**: 同时支持 iOS 和 macOS

## 未来扩展

可以考虑添加:
1. 项目数量统计
2. 使用频率统计
3. 功能使用情况统计
4. 崩溃报告集成
