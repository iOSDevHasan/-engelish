import ContentKit
import FirebaseContentKit

/// Uzak içerik kaynağını kurar. Firebase yapılandırılmadıysa gömülü içerikle çalışılır.
enum RemoteContentFactory {
  /// Kullanılabilir uzak kaynak; yoksa nil.
  @MainActor
  static func make() -> RemoteContentSource? {
    FirebaseBootstrap.isConfigured ? FirebaseContentSource() : nil
  }
}
