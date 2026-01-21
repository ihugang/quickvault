// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "QuickHoldKit",

  // Platform Requirements / 平台要求
  platforms: [
    .macOS(.v14),
    .iOS(.v16)
  ],

  // Products / 产品
  products: [
    // Core business logic library / 核心业务逻辑库
    .library(
      name: "QuickHoldCore",
      targets: ["QuickHoldCore"]
    )
  ],

  // Dependencies / 依赖项
  dependencies: [
    // SwiftCheck for property-based testing
    .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0"),
    // ZIPFoundation for cross-platform zip/unzip support
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0")
  ],

  // Targets / 目标
  targets: [
    // ========================================
    // Core Business Logic Target / 核心业务逻辑目标
    // ========================================
    .target(
      name: "QuickHoldCore",
      dependencies: [
        .product(name: "ZIPFoundation", package: "ZIPFoundation")
      ],
      resources: [
        .process("Models/QuickHold.xcdatamodeld")
      ],
      swiftSettings: [
        .unsafeFlags(["-strict-concurrency=complete"], .when(configuration: .debug))
      ]
    ),

    // ========================================
    // Test Target / 测试目标
    // ========================================
    .testTarget(
      name: "QuickHoldCoreTests",
      dependencies: [
        "QuickHoldCore",
        .product(name: "SwiftCheck", package: "SwiftCheck")
      ]
    )
  ]
)
