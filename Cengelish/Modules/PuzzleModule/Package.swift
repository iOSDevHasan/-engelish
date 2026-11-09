// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "PuzzleModule",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "PuzzleModuleInterface", targets: ["PuzzleModuleInterface"]),
    .library(name: "PuzzleModule", targets: ["PuzzleModule"]),
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
    .package(path: "../PaywallModule"),
    .package(path: "../SettingsModule"),
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "PuzzleModuleInterface",
      path: "InterfaceSources"
    ),
    .target(
      name: "PuzzleModule",
      dependencies: [
        "PuzzleModuleInterface",
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "UserDataKit", package: "UserDataKit"),
        .product(name: "PurchaseKit", package: "PurchaseKit"),
        .product(name: "PuzzleKit", package: "PuzzleKit"),
        .product(name: "WordKit", package: "WordKit"),
        .product(name: "PaywallModuleInterface", package: "PaywallModule"),
        .product(name: "SettingsModuleInterface", package: "SettingsModule"),
        // jarvis:products
      ],
      path: "Sources",
      swiftSettings: [
        .unsafeFlags(["-enable-testing"])
      ]
    ),
    .testTarget(
      name: "PuzzleModuleTests",
      dependencies: [
        "PuzzleModule",
        "PuzzleModuleInterface",
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "UserDataKit", package: "UserDataKit"),
        .product(name: "PurchaseKit", package: "PurchaseKit"),
        .product(name: "PuzzleKit", package: "PuzzleKit"),
        .product(name: "WordKit", package: "WordKit"),
        .product(name: "PaywallModuleInterface", package: "PaywallModule"),
        .product(name: "SettingsModuleInterface", package: "SettingsModule"),
      ],
      path: "Tests"
    ),
  ]
)
