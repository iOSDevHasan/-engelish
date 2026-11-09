// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "FirebaseContentKit",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "FirebaseContentKit", targets: ["FirebaseContentKit"])
  ],
  dependencies: [
    .package(path: "../ContentKit"),
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "13.0.0"),
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "FirebaseContentKit",
      dependencies: [
        .product(name: "ContentKit", package: "ContentKit"),
        .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
        .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
        .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
        .product(name: "FirebaseAppCheck", package: "firebase-ios-sdk"),
        // jarvis:products
      ],
      path: "Sources"
    ),
    .testTarget(
      name: "FirebaseContentKitTests",
      dependencies: ["FirebaseContentKit"],
      path: "Tests"
    ),
  ]
)
