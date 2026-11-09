// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "InjectionKit",
  platforms: [
    .iOS(.v15)
  ],
  products: [
    .library(
      name: "InjectionKit",
      targets: ["InjectionKit"]
    )
  ],
  targets: [
    .target(
      name: "InjectionKit",
      path: "Sources",
      swiftSettings: [
        .unsafeFlags(["-enable-testing"])
      ]
    ),

    .testTarget(
      name: "InjectionKitTests",
      dependencies: ["InjectionKit"],
      path: "Tests"
    ),
  ]
)
