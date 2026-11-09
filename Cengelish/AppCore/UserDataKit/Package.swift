// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "UserDataKit",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "UserDataKit", targets: ["UserDataKit"])
  ],
  dependencies: [
    .package(path: "../DesignKit")
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "UserDataKit",
      dependencies: [
        .product(name: "DesignKit", package: "DesignKit")
        // jarvis:products
      ],
      path: "Sources"
    ),
    .testTarget(
      name: "UserDataKitTests",
      dependencies: ["UserDataKit"],
      path: "Tests"
    ),
  ]
)
