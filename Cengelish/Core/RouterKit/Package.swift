// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "RouterKit",
  platforms: [
    .iOS(.v15)
  ],
  products: [
    .library(
      name: "RouterKitInterface",
      targets: ["RouterKitInterface"]
    ),
    .library(
      name: "RouterKit",
      targets: ["RouterKit"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/johnpatrickmorgan/NavigationBackport.git", from: "0.9.0")
  ],
  targets: [
    .target(
      name: "RouterKitInterface",
      path: "InterfaceSources"
    ),
    .target(
      name: "RouterKit",
      dependencies: [
        "RouterKitInterface",
        .product(name: "NavigationBackport", package: "NavigationBackport"),
      ],
      path: "Sources",
      swiftSettings: [
        .unsafeFlags(["-enable-testing"])
      ]
    ),
    .testTarget(
      name: "RouterKitTests",
      dependencies: ["RouterKit", "RouterKitInterface"],
      path: "Tests"
    ),
  ]
)
