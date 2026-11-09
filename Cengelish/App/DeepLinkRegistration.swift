import AppComposition
import SwiftUI

extension DeepLinkPath {
  static let home: Self = "home"
}

/// Maps `cengelish://<path>` URLs onto module entry points.
@MainActor
enum DeepLinkRegistration {
  static func registerAll(on navigator: AppRouter) {
    navigator.registerDeepLink(.home) {
      HomeRootView()
    }
  }
}
