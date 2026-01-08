// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "QuickVaultKit",

  // Platform Requirements / 平台要求
  platforms: [
    .macOS(.v14),
    .iOS(.v17)
  ],

  // Products / 产品
  products: [
    // Core business logic library / 核心业务逻辑库
    .library(
      name: "QuickVaultCore",
      targets: ["QuickVaultCore"]
    )
  ],

  // Dependencies / 依赖项
  dependencies: [
    // SwiftCheck for property-based testing
    .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0")
  ],

  // Targets / 目标
  targets: [
    // ========================================
    // Core Business Logic Target / 核心业务逻辑目标
    // ========================================
    .target(
      name: "QuickVaultCore",
      dependencies: [],
      resources: [
        .process("Models/QuickVault.xcdatamodeld")
      ],
      swiftSettings: [
        .unsafeFlags(["-strict-concurrency=complete"], .when(configuration: .debug))
      ]
    ),

    // ========================================
    // Test Target / 测试目标
    // ========================================
    .testTarget(
      name: "QuickVaultCoreTests",
      dependencies: [
        "QuickVaultCore",
        .product(name: "SwiftCheck", package: "SwiftCheck")
      ]
    )
  ]
)
