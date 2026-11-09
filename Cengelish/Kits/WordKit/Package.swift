// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "WordKit",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "WordKit", targets: ["WordKit"])
  ],
  dependencies: [
    .package(path: "../../AppCore/ContentKit"),
    .package(path: "../../AppCore/DesignKit"),
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "WordKit",
      dependencies: [
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        // jarvis:products
      ],
      path: "Sources"
    ),
    .testTarget(
      name: "WordKitTests",
      dependencies: ["WordKit"],
      path: "Tests"
    ),
  ]
)
