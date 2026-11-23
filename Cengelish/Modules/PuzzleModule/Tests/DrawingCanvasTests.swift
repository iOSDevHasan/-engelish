import PencilKit
import SwiftUI
import Testing
import UIKit

@testable import PuzzleModule

@Suite("Çizim alanı: geri alınan çizgiler geri dönmez")
@MainActor
struct DrawingCanvasTests {

  /// Çizim alanının modele bildirdiği son çizim.
  private final class Reports {
    var changes: [PKDrawing] = []
  }

  @Test("Geri alınan çizgi çizim alanında kalsa da yeni çizgiyle modele dönmez")
  func undoneStrokeStaysUndone() async throws {
    let reports = Reports()
    let coordinator = DrawingCanvas.Coordinator(parent: makeCanvas(tool: .pen, reports: reports))
    let first = stroke(x: 10, at: 0)
    let undone = stroke(x: 60, at: 1)
    coordinator.commit(PKDrawing(strokes: [first, undone]))
    // Geri al: model ikinci çizgiyi kaldırır.
    coordinator.commit(PKDrawing(strokes: [first]))
    let canvas = PKCanvasView()
    // PencilKit geri alınan çizgiyi tutup yeni çizgiyle birlikte bildirir.
    canvas.drawing = PKDrawing(strokes: [first, undone, stroke(x: 60, at: 2)])

    coordinator.canvasViewDrawingDidChange(canvas)

    let result = try await latestChange(in: reports)
    #expect(result.strokes.map(\.path.creationDate) == [date(0), date(2)])
    #expect(canvas.drawing.strokes.count == 2)
  }

  @Test("Silgi yalnızca modeldeki çizgileri siler; geri alınan çizgi geri gelmez")
  func eraserIgnoresUndoneStroke() async throws {
    let reports = Reports()
    let coordinator = DrawingCanvas.Coordinator(
      parent: makeCanvas(tool: .eraser, reports: reports))
    let erased = stroke(x: 10, at: 0)
    let undone = stroke(x: 60, at: 1)
    coordinator.commit(PKDrawing(strokes: [erased, undone]))
    coordinator.commit(PKDrawing(strokes: [erased]))
    let canvas = PKCanvasView()
    canvas.drawing = PKDrawing(strokes: [undone])

    coordinator.canvasViewDrawingDidChange(canvas)

    let result = try await latestChange(in: reports)
    #expect(result.strokes.isEmpty)
    #expect(canvas.drawing.strokes.isEmpty)
  }

  // MARK: - Helpers

  private func date(_ offset: TimeInterval) -> Date {
    Date(timeIntervalSinceReferenceDate: 800_000_000 + offset)
  }

  /// Verilen x'te 30 nokta boyunda dikey bir çizgi.
  private func stroke(x: CGFloat, at offset: TimeInterval) -> PKStroke {
    let points = (0..<6).map {
      PKStrokePoint(
        location: CGPoint(x: x, y: 10 + CGFloat($0) * 6), timeOffset: Double($0) * 0.01,
        size: CGSize(width: 4, height: 4), opacity: 1, force: 1, azimuth: 0, altitude: .pi / 2)
    }
    return PKStroke(
      ink: PKInk(.pen, color: .black),
      path: PKStrokePath(controlPoints: points, creationDate: date(offset)))
  }

  private func makeCanvas(tool: DrawingTool, reports: Reports) -> DrawingCanvas {
    DrawingCanvas(
      drawing: PKDrawing(), drawingRevision: 0, contentSize: CGSize(width: 200, height: 200),
      inkRects: [], underlay: { _ in AnyView(EmptyView()) }, tool: tool, penColor: .black,
      pencilColor: .gray, widthScale: 1, colorScheme: .light, pencilOnly: false,
      allowsZoom: false, bridge: CanvasBridge(),
      onChange: { reports.changes.append($0) }, onTap: { _ in }, onStroke: { _ in })
  }

  /// Bildirim bir sonraki turda gelir; gelene kadar kısa aralıklarla bekler.
  private func latestChange(in reports: Reports) async throws -> PKDrawing {
    for _ in 0..<50 where reports.changes.isEmpty {
      try await Task.sleep(for: .milliseconds(10))
    }
    return try #require(reports.changes.last)
  }
}
