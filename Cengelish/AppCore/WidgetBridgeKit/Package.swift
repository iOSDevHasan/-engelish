// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "WidgetBridgeKit",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "WidgetBridgeKit", targets: ["WidgetBridgeKit"])
  ],
  dependencies: [
    .package(path: "../DesignKit")
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "WidgetBridgeKit",
      dependencies: [
        .product(name: "DesignKit", package: "DesignKit")
        // jarvis:products
      ],
      path: "Sources"
    ),
    .testTarget(
      name: "WidgetBridgeKitTests",
      dependencies: ["WidgetBridgeKit"],
      path: "Tests"
    ),
  ]
)
