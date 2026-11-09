// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "NotebookModule",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "NotebookModuleInterface", targets: ["NotebookModuleInterface"]),
    .library(name: "NotebookModule", targets: ["NotebookModule"]),
  ],
  dependencies: [
    .package(path: "../../Core/RouterKit"),
    .package(path: "../../Core/InjectionKit"),
    .package(path: "../../AppCore/DesignKit"),
    .package(path: "../../AppCore/ContentKit"),
    .package(path: "../../AppCore/UserDataKit"),
    .package(path: "../../Kits/WordKit"),
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "NotebookModuleInterface",
      path: "InterfaceSources"
    ),
    .target(
      name: "NotebookModule",
      dependencies: [
        "NotebookModuleInterface",
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "UserDataKit", package: "UserDataKit"),
        .product(name: "WordKit", package: "WordKit"),
        // jarvis:products
      ],
      path: "Sources",
      swiftSettings: [
        .unsafeFlags(["-enable-testing"])
      ]
    ),
    .testTarget(
      name: "NotebookModuleTests",
      dependencies: [
        "NotebookModule",
        "NotebookModuleInterface",
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "DesignKit", package: "DesignKit"),
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "UserDataKit", package: "UserDataKit"),
        .product(name: "WordKit", package: "WordKit"),
      ],
      path: "Tests"
    ),
  ]
)
