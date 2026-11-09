// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "ProfileModule",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "ProfileModuleInterface", targets: ["ProfileModuleInterface"]),
    .library(name: "ProfileModule", targets: ["ProfileModule"]),
  ],
  dependencies: [
    .package(path: "../../Core/RouterKit"),
    .package(path: "../../Core/InjectionKit"),
    .package(path: "../../AppCore/DesignKit"),
    .package(path: "../../AppCore/ContentKit"),
    .package(path: "../../AppCore/UserDataKit"),
    .package(path: "../../AppCore/PurchaseKit"),
    .package(path: "../SettingsModule"),
    .package(path: "../PaywallModule"),
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "ProfileModuleInterface",
      path: "InterfaceSources"
    ),
    .target(
      name: "ProfileModule",
      dependencies: [
        "ProfileModuleInterface",
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "UserDataKit", package: "UserDataKit"),
        .product(name: "PurchaseKit", package: "PurchaseKit"),
        .product(name: "SettingsModuleInterface", package: "SettingsModule"),
        .product(name: "PaywallModuleInterface", package: "PaywallModule"),
        // jarvis:products
      ],
      path: "Sources",
      swiftSettings: [
        .unsafeFlags(["-enable-testing"])
      ]
    ),
    .testTarget(
      name: "ProfileModuleTests",
      dependencies: [
        "ProfileModule",
        "ProfileModuleInterface",
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "UserDataKit", package: "UserDataKit"),
        .product(name: "PurchaseKit", package: "PurchaseKit"),
        .product(name: "SettingsModuleInterface", package: "SettingsModule"),
        .product(name: "PaywallModuleInterface", package: "PaywallModule"),
      ],
      path: "Tests"
    ),
  ]
)
