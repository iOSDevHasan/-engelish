// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "ContentKit",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "ContentKit", targets: ["ContentKit"])
  ],
  dependencies: [
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "ContentKit",
      dependencies: [
        // jarvis:products
      ],
      path: "Sources",
      resources: [.copy("Resources/starter.json")]
    ),
    .testTarget(
      name: "ContentKitTests",
      dependencies: ["ContentKit"],
      path: "Tests"
    ),
  ]
)
