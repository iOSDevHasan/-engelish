import SwiftUI

/// Profil sekmesi, profil düzenleme ve rozetler.
@MainActor
public protocol ProfileModuleInterface: AnyObject {
  /// Profil ekranını oluşturur.
  func createProfileView() -> AnyView
}
