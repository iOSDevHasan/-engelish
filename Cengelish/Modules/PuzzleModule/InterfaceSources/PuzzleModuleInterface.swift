import SwiftUI

/// Bulmaca çözme akışı (ızgara, odak modu, cevap anahtarı, bitiş).
@MainActor
public protocol PuzzleModuleInterface: AnyObject {
  /// Bulmaca ekranını oluşturur.
  func createPuzzleView(puzzleId: String) -> AnyView
}
