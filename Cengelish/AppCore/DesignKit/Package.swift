// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "DesignKit",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "DesignKit", targets: ["DesignKit"])
  ],
  dependencies: [
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "DesignKit",
      dependencies: [
        // jarvis:products
      ],
      path: "Sources"
    ),
    .testTarget(
      name: "DesignKitTests",
      dependencies: ["DesignKit"],
      path: "Tests"
    ),
  ]
)
