import SwiftUI

/// Ana Sayfa sekmesi.
@MainActor
public protocol HomeModuleInterface: AnyObject {
  /// Ana Sayfa ekranını oluşturur.
  func createHomeView() -> AnyView
}
