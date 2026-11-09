import SwiftUI

/// Çengelish+ satın alma ekranı.
@MainActor
public protocol PaywallModuleInterface: AnyObject {
  /// Paywall ekranını oluşturur. `highlightProductId` verilirse o ürün seçili gelir.
  func createPaywallView(highlightProductId: String?) -> AnyView
}
