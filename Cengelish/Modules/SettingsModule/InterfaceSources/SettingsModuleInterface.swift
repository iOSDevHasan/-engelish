import SwiftUI

/// Ayarlar, görünüm, bulmaca teması ve veri ekranları.
@MainActor
public protocol SettingsModuleInterface: AnyObject {
  /// Ayarlar ekranını oluşturur.
  func createSettingsView() -> AnyView
  /// Ayarlar ekranını oluşturur; "Profili düzenle" satırı `onEditProfile` ile açılır.
  ///
  /// Ayarlar modülü Profil modülünü tanımaz (Profil zaten Ayarlar arayüzüne bağlı; tersi paket
  /// döngüsü olurdu). Profil ekranı ayarları açarken kendi düzenleme ekranını buradan verir.
  /// `nil` verilirse satır takma adı küçük bir pencerede düzenler.
  func createSettingsView(onEditProfile: (@MainActor () -> Void)?) -> AnyView
  /// Bulmaca teması ekranını oluşturur.
  func createPuzzleThemeView() -> AnyView
}

extension SettingsModuleInterface {
  /// Varsayılan: profil düzenleme kancası olmadan ayarlar ekranı.
  public func createSettingsView(onEditProfile: (@MainActor () -> Void)?) -> AnyView {
    createSettingsView()
  }
}
