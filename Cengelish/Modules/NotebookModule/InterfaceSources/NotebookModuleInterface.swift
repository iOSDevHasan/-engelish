import SwiftUI

/// Kelime Defterim sekmesi.
@MainActor
public protocol NotebookModuleInterface: AnyObject {
  /// Kelime Defterim ekranını oluşturur.
  func createNotebookView() -> AnyView
}
