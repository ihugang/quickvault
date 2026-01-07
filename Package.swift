// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "QuickVault",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .executable(
      name: "QuickVault",
      targets: ["QuickVault"]
    )
  ],
  dependencies: [
    // SwiftCheck for property-based testing
    .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0"),
    // Sparkle for automatic updates
    .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.5.0"),
  ],
  targets: [
    .executableTarget(
      name: "QuickVault",
      dependencies: [
        .product(name: "Sparkle", package: "Sparkle")
      ],
      path: "QuickVault/Sources"
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
