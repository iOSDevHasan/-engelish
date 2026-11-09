import CoreGraphics
import Testing
@testable import PuzzleModule

@Suite("Puzzle canvas math")
struct PuzzleViewModelTests {

  @Test("Odak kutuları 5 harfe kadar tek satır, daha uzun kelimede iki satır")
  func focusRows() {
    #expect(CanvasMetrics.focusPerRow(5) == 5)
    #expect(CanvasMetrics.focusPerRow(8) == 4)
    #expect(CanvasMetrics.focusSize(count: 8).height > CanvasMetrics.focusSize(count: 4).height)
  }

  @Test("Dönüşüm kaynak dikdörtgenin merkezini hedefin merkezine taşır")
  func transformMapsCenters() {
    let from = CGRect(x: 0, y: 0, width: 100, height: 100)
    let to = CGRect(x: 200, y: 50, width: 60, height: 60)
    let t = StrokeMath.transform(from: from, to: to)
    let center = CGPoint(x: from.midX, y: from.midY).applying(t)
    #expect(abs(center.x - to.midX) < 0.001)
    #expect(abs(center.y - to.midY) < 0.001)
  }

  @Test("Izgara geometrisi noktayı doğru kutuya yerleştirir")
  func gridHitTest() {
    let geometry = CanvasMetrics.grid
    let rect = geometry.rect(for: .init(row: 2, col: 3))
    let hit = geometry.point(at: CGPoint(x: rect.midX, y: rect.midY), rows: 7, columns: 7)
    #expect(hit == .init(row: 2, col: 3))
  }
}
