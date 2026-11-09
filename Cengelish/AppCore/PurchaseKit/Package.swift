// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "PurchaseKit",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "PurchaseKit", targets: ["PurchaseKit"])
  ],
  dependencies: [
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "PurchaseKit",
      dependencies: [
        // jarvis:products
      ],
      path: "Sources"
    ),
    .testTarget(
      name: "PurchaseKitTests",
      dependencies: ["PurchaseKit"],
      path: "Tests"
    ),
  ]
)
