import SwiftUI

/// Çengelish Plus ve sınav paketi satın alma ekranı.
@MainActor
public protocol PaywallModuleInterface: AnyObject {
  /// Paywall ekranını oluşturur. `highlightProductId` verilirse o ürün seçili gelir
  /// (sınav paketiyse "Sınav paketleri" sekmesi açılır); `nil` ise ömür boyu Plus seçilir.
  func createPaywallView(highlightProductId: String?) -> AnyView
}
