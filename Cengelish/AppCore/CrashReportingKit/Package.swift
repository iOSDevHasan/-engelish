// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "CrashReportingKit",
  platforms: [.iOS(.v18)],
  products: [
    .library(name: "CrashReportingKit", targets: ["CrashReportingKit"])
  ],
  dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "13.0.0"),
    // jarvis:packages
  ],
  targets: [
    .target(
      name: "CrashReportingKit",
      dependencies: [
        .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
        .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
        // jarvis:products
      ],
      path: "Sources"
    ),
    .testTarget(
      name: "CrashReportingKitTests",
      dependencies: ["CrashReportingKit"],
      path: "Tests"
    ),
  ]
)
