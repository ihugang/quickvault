// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "QuickVault",

  // Platform Requirements / 平台要求
  // Minimum macOS version: 14.0 (Sonoma) for modern SwiftUI features
  // 最小 macOS 版本: 14.0 (Sonoma) 以支持现代 SwiftUI 特性
  platforms: [
    .macOS(.v14)
  ],

  // Products / 产品
  products: [
    .executable(
      name: "QuickVault",
      targets: ["QuickVault"]
    )
  ],

  // Dependencies / 依赖项
  dependencies: [
    // SwiftCheck for property-based testing
    .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0"),
    // Sparkle for automatic updates
    .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.5.0"),
  ],

  // Targets / 目标
  targets: [
    .executableTarget(
      name: "QuickVault",
      dependencies: [
        .product(name: "Sparkle", package: "Sparkle")
      ],
      path: "QuickVault/Sources",
      resources: [
        .process("../Resources")
      ],
      swiftSettings: [
        // Enable strict concurrency checking / 启用严格并发检查
        .unsafeFlags(["-strict-concurrency=complete"], .when(configuration: .debug))
      ]
    ),
    .testTarget(
      name: "QuickVaultTests",
      dependencies: [
        "QuickVault",
        .product(name: "SwiftCheck", package: "SwiftCheck"),
      ],
      path: "QuickVault/Tests"
    ),
  ]
)
