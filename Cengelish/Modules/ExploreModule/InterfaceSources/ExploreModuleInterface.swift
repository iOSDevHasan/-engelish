import SwiftUI

/// Keşfet sekmesi ve paket detayı.
@MainActor
public protocol ExploreModuleInterface: AnyObject {
  /// Keşfet ekranını oluşturur.
  func createExploreView() -> AnyView
  /// Paket detay ekranını oluşturur.
  func createPackView(packId: String) -> AnyView
}
