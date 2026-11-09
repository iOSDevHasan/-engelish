import ContentKit
import DesignKit
import PencilKit
import PuzzleKit
import SwiftUI

/// Odak modu: seçili kelime büyük kutularda, rahat yazmak için.
struct FocusView: View {
  @ObservedObject var viewModel: PuzzleViewModel
  let theme: PuzzleTheme
  let penColor: Color
  @StateObject private var bridge = CanvasBridge()
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    VStack(spacing: 14) {
      HStack {
        Button {
          viewModel.closeFocus()
        } label: {
          IconCircle("xmark")
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Odak modunu kapat")
        Spacer()
        Text("Odak modu").font(AppFont.section).foregroundStyle(Palette.ink)
        Spacer()
        Button {
          viewModel.closeFocus()
        } label: {
          IconCircle("square.grid.3x3")
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Izgaraya dön")
      }
      if let entry = viewModel.selected, let layout = viewModel.layout {
        HStack(spacing: 14) {
          MiniGridView(puzzle: layout.puzzle, theme: theme, cellSize: 14)
          VStack(alignment: .leading, spacing: 4) {
            Eyebrow("\(entry.dir.title) · \(entry.answer.count) harf")
            Text(entry.clue).font(AppFont.title).foregroundStyle(Palette.ink)
              .minimumScaleFactor(0.6)
            Text(crossing(entry, layout)).font(AppFont.caption).foregroundStyle(Palette.muted)
              .lineLimit(2)
          }
          Spacer(minLength: 0)
        }
        .card(padding: 12)
        DrawingCanvas(
          drawing: viewModel.focusDrawing,
          drawingRevision: viewModel.focusRevision,
          contentSize: CanvasMetrics.focusSize(count: entry.cells.count),
          underlay: { scale in AnyView(boxes(entry, scale: scale)) },
          tool: viewModel.tool,
          penColor: UIColor(penColor),
          pencilColor: UIColor(theme.pencil),
          widthScale: viewModel.settings.penWidth * 1.6,
          colorScheme: scheme,
          pencilOnly: viewModel.settings.pencilOnly,
          allowsZoom: false,
          bridge: bridge,
          onChange: viewModel.focusChanged,
          onTap: { _ in },
          onStroke: { _ in }
        )
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .card(padding: 8)
        Text("Kutunun içine rahatça yaz. Kapatınca yazdıkların ızgaraya geçer.")
          .font(AppFont.caption).foregroundStyle(Palette.muted)
        PuzzleToolbar(
          tool: $viewModel.tool, hintsLeft: viewModel.hintsLeft,
          leftHanded: viewModel.settings.leftHanded, onUndo: bridge.undo, onRedo: bridge.redo,
          onFocus: { viewModel.closeFocus() }, onHint: { viewModel.closeFocus() }, onClear: {})
        Spacer(minLength: 0)
        HStack(spacing: 10) {
          Button {
            viewModel.closeFocus(moveTo: -1)
          } label: {
            Label("Önceki", systemImage: "chevron.left")
          }
          .buttonStyle(.chunkySecondary)
          Button {
            viewModel.closeFocus(moveTo: 1)
          } label: {
            Label("Sonraki", systemImage: "chevron.right")
          }
          .buttonStyle(.chunky)
        }
      }
    }
    .padding(Metrics.gutter)
    .frame(maxWidth: 680)
    .frame(maxWidth: .infinity)
    .screenBackground()
  }

  /// Büyük yazma kutuları.
  private func boxes(_ entry: PuzzleEntry, scale: CGFloat) -> some View {
    let count = entry.cells.count
    let size = CanvasMetrics.focusSize(count: count)
    return ZStack(alignment: .topLeading) {
      Color.clear.frame(width: size.width * scale, height: size.height * scale)
      ForEach(0..<count, id: \.self) { index in
        let rect = CanvasMetrics.focusRect(index: index, count: count)
        let isRevealed = viewModel.revealed.contains(entry.cells[index])
        RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
          .fill(theme.cell)
          .overlay(
            RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
              .strokeBorder(theme.arrow.opacity(0.35), lineWidth: 2)
          )
          .overlay {
            if isRevealed, let char = entry.letter(at: entry.cells[index]) {
              Text(String(char)).font(.system(size: 54 * scale, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.keyInk.opacity(0.85))
            }
          }
          .overlay(alignment: .topLeading) {
            Text("\(index + 1)").font(.system(size: 13 * scale, weight: .bold, design: .rounded))
              .foregroundStyle(Palette.muted).padding(6 * scale)
          }
          .frame(width: rect.width * scale, height: rect.height * scale)
          .offset(x: rect.minX * scale, y: rect.minY * scale)
      }
    }
  }

  /// Kesişen kelimelerin ipuçları.
  private func crossing(_ entry: PuzzleEntry, _ layout: CrosswordLayout) -> String {
    let others = entry.cells.flatMap { layout.entries(at: $0) }.filter { $0 != entry }
    guard !others.isEmpty else { return "Kesişen kelime yok" }
    let arrow = entry.dir == .across ? "↓" : "→"
    return "Kesişen: " + others.map { "\($0.clue) \(arrow)" }.joined(separator: " · ")
  }
}
