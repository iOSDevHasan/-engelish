import AppComposition
import SwiftUI

extension DeepLinkPath {
  static let home: Self = "home"
  /// Günün bulmacası (widget'tan açılır).
  static let daily: Self = "daily"
}

/// Maps `cengelish://<path>` URLs onto module entry points.
@MainActor
enum DeepLinkRegistration {
  static func registerAll(on navigator: AppRouter) {
    navigator.registerDeepLink(.home) { [weak navigator] _ in
      navigator?.popToRoot()
    }
    navigator.registerDeepLink(.daily) { [weak navigator] _ in
      navigator?.popToRoot()
      navigator?.push(DailyPuzzleLauncher())
    }
  }
}
