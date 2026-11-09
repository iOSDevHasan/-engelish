// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "HomeModule",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "HomeModuleInterface", targets: ["HomeModuleInterface"]),
    .library(name: "HomeModule", targets: ["HomeModule"]),
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
    .package(path: "../ExploreModule"),
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "HomeModuleInterface",
      path: "InterfaceSources"
    ),
    .target(
      name: "HomeModule",
      dependencies: [
        "HomeModuleInterface",
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "UserDataKit", package: "UserDataKit"),
        .product(name: "PurchaseKit", package: "PurchaseKit"),
        .product(name: "PuzzleKit", package: "PuzzleKit"),
        .product(name: "WordKit", package: "WordKit"),
        .product(name: "PuzzleModuleInterface", package: "PuzzleModule"),
        .product(name: "ExploreModuleInterface", package: "ExploreModule"),
        // jarvis:products
      ],
      path: "Sources",
      swiftSettings: [
        .unsafeFlags(["-enable-testing"])
      ]
    ),
    .testTarget(
      name: "HomeModuleTests",
      dependencies: [
        "HomeModule",
        "HomeModuleInterface",
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "UserDataKit", package: "UserDataKit"),
        .product(name: "PurchaseKit", package: "PurchaseKit"),
        .product(name: "PuzzleKit", package: "PuzzleKit"),
        .product(name: "WordKit", package: "WordKit"),
        .product(name: "PuzzleModuleInterface", package: "PuzzleModule"),
        .product(name: "ExploreModuleInterface", package: "ExploreModule"),
      ],
      path: "Tests"
    ),
  ]
)
