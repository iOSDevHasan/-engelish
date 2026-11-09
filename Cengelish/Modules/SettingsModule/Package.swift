// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "SettingsModule",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "SettingsModuleInterface", targets: ["SettingsModuleInterface"]),
    .library(name: "SettingsModule", targets: ["SettingsModule"]),
  ],
  dependencies: [
    .package(path: "../../Core/RouterKit"),
    .package(path: "../../Core/InjectionKit"),
    .package(path: "../../AppCore/DesignKit"),
    .package(path: "../../AppCore/ContentKit"),
    .package(path: "../../AppCore/UserDataKit"),
    .package(path: "../../AppCore/PurchaseKit"),
    .package(path: "../../Kits/PuzzleKit"),
    .package(path: "../PaywallModule"),
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "SettingsModuleInterface",
      path: "InterfaceSources"
    ),
    .target(
      name: "SettingsModule",
      dependencies: [
        "SettingsModuleInterface",
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "UserDataKit", package: "UserDataKit"),
        .product(name: "PurchaseKit", package: "PurchaseKit"),
        .product(name: "PuzzleKit", package: "PuzzleKit"),
        .product(name: "PaywallModuleInterface", package: "PaywallModule"),
        // jarvis:products
      ],
      path: "Sources",
      swiftSettings: [
        .unsafeFlags(["-enable-testing"])
      ]
    ),
    .testTarget(
      name: "SettingsModuleTests",
      dependencies: [
        "SettingsModule",
        "SettingsModuleInterface",
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "UserDataKit", package: "UserDataKit"),
        .product(name: "PurchaseKit", package: "PurchaseKit"),
        .product(name: "PuzzleKit", package: "PuzzleKit"),
        .product(name: "PaywallModuleInterface", package: "PaywallModule"),
      ],
      path: "Tests"
    ),
  ]
)
