import SwiftUI

/// Ayarlar, görünüm, bulmaca teması ve veri ekranları.
@MainActor
public protocol SettingsModuleInterface: AnyObject {
  /// Ayarlar ekranını oluşturur.
  func createSettingsView() -> AnyView
  /// Bulmaca teması ekranını oluşturur.
  func createPuzzleThemeView() -> AnyView
}
