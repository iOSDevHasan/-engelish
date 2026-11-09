// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "OnboardingModule",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "OnboardingModuleInterface", targets: ["OnboardingModuleInterface"]),
    .library(name: "OnboardingModule", targets: ["OnboardingModule"]),
  ],
  dependencies: [
    .package(path: "../../Core/RouterKit"),
    .package(path: "../../Core/InjectionKit"),
    .package(path: "../../AppCore/DesignKit"),
    .package(path: "../../AppCore/ContentKit"),
    .package(path: "../../AppCore/UserDataKit"),
    .package(path: "../../Kits/PuzzleKit"),
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "OnboardingModuleInterface",
      path: "InterfaceSources"
    ),
    .target(
      name: "OnboardingModule",
      dependencies: [
        "OnboardingModuleInterface",
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "DesignKit", package: "DesignKit"),
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
      name: "OnboardingModuleTests",
      dependencies: [
        "OnboardingModule",
        "OnboardingModuleInterface",
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "UserDataKit", package: "UserDataKit"),
        .product(name: "PuzzleKit", package: "PuzzleKit"),
      ],
      path: "Tests"
    ),
  ]
)
