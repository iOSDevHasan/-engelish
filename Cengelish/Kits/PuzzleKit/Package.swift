// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "PuzzleKit",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "PuzzleKit", targets: ["PuzzleKit"])
  ],
  dependencies: [
    .package(path: "../../AppCore/ContentKit"),
    .package(path: "../../AppCore/DesignKit"),
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "PuzzleKit",
      dependencies: [
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        // jarvis:products
      ],
      path: "Sources"
    ),
    .testTarget(
      name: "PuzzleKitTests",
      dependencies: ["PuzzleKit"],
      path: "Tests"
    ),
  ]
)
