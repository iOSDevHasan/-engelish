// swift-tools-version: 6.2
import PackageDescription

// The only package the Xcode app target links. Every Module/Kit is added here (and in
// DependencyRegistration + Exports) — jarvis' arch.py does this at the marker comments.
let package = Package(
  name: "AppComposition",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "AppComposition", targets: ["AppComposition"])
  ],
  dependencies: [
    .package(path: "../Core/InjectionKit"),
    .package(path: "../Core/RouterKit"),
    .package(path: "../Modules/HomeModule"),
    .package(path: "../AppCore/DesignKit"),
    .package(path: "../AppCore/UserDataKit"),
    .package(path: "../AppCore/PurchaseKit"),
    .package(path: "../Kits/PuzzleKit"),
    .package(path: "../Kits/WordKit"),
    .package(path: "../Modules/OnboardingModule"),
    .package(path: "../Modules/ExploreModule"),
    .package(path: "../Modules/PuzzleModule"),
    .package(path: "../Modules/NotebookModule"),
    .package(path: "../Modules/ProfileModule"),
    .package(path: "../Modules/SettingsModule"),
    .package(path: "../Modules/PaywallModule"),
    .package(path: "../AppCore/ContentKit"),
    .package(path: "../AppCore/FirebaseContentKit"),
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "AppComposition",
      dependencies: [
        .product(name: "InjectionKit", package: "InjectionKit"),
        .product(name: "RouterKit", package: "RouterKit"),
        .product(name: "RouterKitInterface", package: "RouterKit"),
        .product(name: "HomeModule", package: "HomeModule"),
        .product(name: "HomeModuleInterface", package: "HomeModule"),
        .product(name: "DesignKit", package: "DesignKit"),
        .product(name: "UserDataKit", package: "UserDataKit"),
        .product(name: "PurchaseKit", package: "PurchaseKit"),
        .product(name: "PuzzleKit", package: "PuzzleKit"),
        .product(name: "WordKit", package: "WordKit"),
        .product(name: "OnboardingModule", package: "OnboardingModule"),
        .product(name: "OnboardingModuleInterface", package: "OnboardingModule"),
        .product(name: "ExploreModule", package: "ExploreModule"),
        .product(name: "ExploreModuleInterface", package: "ExploreModule"),
        .product(name: "PuzzleModule", package: "PuzzleModule"),
        .product(name: "PuzzleModuleInterface", package: "PuzzleModule"),
        .product(name: "NotebookModule", package: "NotebookModule"),
        .product(name: "NotebookModuleInterface", package: "NotebookModule"),
        .product(name: "ProfileModule", package: "ProfileModule"),
        .product(name: "ProfileModuleInterface", package: "ProfileModule"),
        .product(name: "SettingsModule", package: "SettingsModule"),
        .product(name: "SettingsModuleInterface", package: "SettingsModule"),
        .product(name: "PaywallModule", package: "PaywallModule"),
        .product(name: "PaywallModuleInterface", package: "PaywallModule"),
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "FirebaseContentKit", package: "FirebaseContentKit"),
        // jarvis:products
      ],
      path: "Sources"
    )
  ]
)
