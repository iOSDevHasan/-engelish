// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "PaywallModule",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "PaywallModuleInterface", targets: ["PaywallModuleInterface"]),
    .library(name: "PaywallModule", targets: ["PaywallModule"]),
  ],
  dependencies: [
    .package(path: "../../Core/RouterKit"),
    .package(path: "../../Core/InjectionKit"),
    .package(path: "../../AppCore/DesignKit"),
    .package(path: "../../AppCore/PurchaseKit"),
    .package(path: "../../AppCore/ContentKit"),
    .package(path: "../../AppCore/UserDataKit"),
    .package(path: "../../Kits/PuzzleKit"),
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "PaywallModuleInterface",
      path: "InterfaceSources"
    ),
    .target(
      name: "PaywallModule",
      dependencies: [
        "PaywallModuleInterface",
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        .product(name: "PurchaseKit", package: "PurchaseKit"),
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "UserDataKit", package: "UserDataKit"),
        .product(name: "PuzzleKit", package: "PuzzleKit"),
        // jarvis:products
      ],
      path: "Sources",
      swiftSettings: [
        .unsafeFlags(["-enable-testing"])
      ]
    ),
    .testTarget(
      name: "PaywallModuleTests",
      dependencies: [
        "PaywallModule",
        "PaywallModuleInterface",
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        .product(name: "PurchaseKit", package: "PurchaseKit"),
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "PuzzleKit", package: "PuzzleKit"),
      ],
      path: "Tests"
    ),
  ]
)
