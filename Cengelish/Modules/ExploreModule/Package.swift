// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "ExploreModule",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "ExploreModuleInterface", targets: ["ExploreModuleInterface"]),
    .library(name: "ExploreModule", targets: ["ExploreModule"]),
  ],
  dependencies: [
    .package(path: "../../Core/RouterKit"),
    .package(path: "../../Core/InjectionKit"),
    .package(path: "../../AppCore/DesignKit"),
    .package(path: "../../AppCore/ContentKit"),
    .package(path: "../../AppCore/UserDataKit"),
    .package(path: "../../AppCore/PurchaseKit"),
    .package(path: "../../Kits/PuzzleKit"),
    .package(path: "../../Kits/WordKit"),
    .package(path: "../PuzzleModule"),
    .package(path: "../PaywallModule"),
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "ExploreModuleInterface",
      path: "InterfaceSources"
    ),
    .target(
      name: "ExploreModule",
      dependencies: [
        "ExploreModuleInterface",
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "UserDataKit", package: "UserDataKit"),
        .product(name: "PurchaseKit", package: "PurchaseKit"),
        .product(name: "PuzzleKit", package: "PuzzleKit"),
        .product(name: "WordKit", package: "WordKit"),
        .product(name: "PuzzleModuleInterface", package: "PuzzleModule"),
        .product(name: "PaywallModuleInterface", package: "PaywallModule"),
        // jarvis:products
      ],
      path: "Sources",
      swiftSettings: [
        .unsafeFlags(["-enable-testing"])
      ]
    ),
    .testTarget(
      name: "ExploreModuleTests",
      dependencies: [
        "ExploreModule",
        "ExploreModuleInterface",
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "UserDataKit", package: "UserDataKit"),
        .product(name: "PurchaseKit", package: "PurchaseKit"),
        .product(name: "PuzzleKit", package: "PuzzleKit"),
        .product(name: "WordKit", package: "WordKit"),
        .product(name: "PuzzleModuleInterface", package: "PuzzleModule"),
        .product(name: "PaywallModuleInterface", package: "PaywallModule"),
      ],
      path: "Tests"
    ),
  ]
)
