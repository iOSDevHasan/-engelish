import ContentKit
import DesignKit
import PencilKit
import PuzzleKit
import SwiftUI

/// Odak modu: seçili kelime büyük kutularda, rahat yazmak için.
///
/// Klavye açıkken mini harita, açıklama ve kelime butonları gizlenir, kutular küçülür; böylece
/// kutular ve araç çubuğu klavyenin üstünde kalır.
struct FocusView: View {
  @ObservedObject var viewModel: PuzzleViewModel
  let theme: PuzzleTheme
  let penColor: Color
  @StateObject private var bridge = CanvasBridge()

  var body: some View {
    let keyboardUp = viewModel.isKeyboardShown
    return VStack(spacing: 14) {
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
        FocusClueHeader(
          entry: entry, layout: layout, theme: theme, active: viewModel.activeCell,
          showsMap: !keyboardUp)
        VStack(spacing: 14) {
          FocusWritingCanvas(
            viewModel: viewModel, entry: entry, theme: theme, penColor: penColor, bridge: bridge
          )
          .frame(maxWidth: .infinity)
          .frame(height: keyboardUp ? 150 : 240)
          if !keyboardUp {
            FocusHint(
              autoAdvance: viewModel.settings.autoAdvance, isKeyboard: viewModel.tool == .keyboard)
          }
        }
        .card(padding: 10)
        PuzzleToolbar(
          tool: $viewModel.tool, hintsLeft: viewModel.hintsLeft,
          leftHanded: viewModel.settings.leftHanded, canUndo: viewModel.canUndo,
          canRedo: viewModel.canRedo, onUndo: viewModel.undo, onRedo: viewModel.redo,
          onFocus: { viewModel.closeFocus() },
          onHint: { viewModel.isHintSheetPresented = true },
          onClear: viewModel.clearFocus, compact: true)
        Spacer(minLength: 0)
        if !keyboardUp {
          FocusStepButtons(labels: viewModel.neighbourLabels) {
            viewModel.closeFocus(moveTo: $0)
          }
        }
      }
    }
    .animation(Motion.snappy, value: keyboardUp)
    .padding(Metrics.gutter)
    .frame(maxWidth: 680)
    .frame(maxWidth: .infinity)
    .background {
      KeyboardInput(
        isActive: viewModel.wantsKeyboard, request: viewModel.keyboardRequest,
        onInsert: viewModel.typeText, onDelete: viewModel.deleteBackward,
        onReturn: { viewModel.closeFocus(moveTo: 1) },
        onFocusChange: viewModel.keyboardFocusChanged
      )
      .frame(width: 1, height: 1)
      .opacity(0)
      .accessibilityHidden(true)
    }
    .ignoresSafeArea(.keyboard)
    .screenBackground()
    .appBottomSheet(isPresented: hintBinding) {
      HintSheet(viewModel: viewModel)
    }
  }

  /// Odak ekranı açıkken ipucu paneli buradan gösterilir.
  private var hintBinding: Binding<Bool> {
    Binding(
      get: { viewModel.isHintSheetPresented && viewModel.isFocusPresented },
      set: { viewModel.isHintSheetPresented = $0 })
  }
}

// MARK: - Fold panel

/// Katlanabilir / bölünmüş ekranda ızgaranın sağındaki odak yazma alanı.
///
/// Buradaki yazılar ızgaraya hemen yansır (bkz. `PuzzleViewModel.focusChanged`).
struct FoldFocusPanel: View {
  @ObservedObject var viewModel: PuzzleViewModel
  let theme: PuzzleTheme
  let penColor: Color
  @StateObject private var bridge = CanvasBridge()

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Spacer(minLength: 0)
      if let entry = viewModel.selected, let layout = viewModel.layout {
        FocusClueHeader(
          entry: entry, layout: layout, theme: theme, active: viewModel.activeCell,
          showsMap: false, eyebrowPrefix: "Odak · ")
        VStack(spacing: 12) {
          FocusWritingCanvas(
            viewModel: viewModel, entry: entry, theme: theme, penColor: penColor, bridge: bridge
          )
          .frame(maxWidth: .infinity)
          .frame(height: 200)
          FocusHint(
            autoAdvance: viewModel.settings.autoAdvance, isKeyboard: viewModel.tool == .keyboard)
        }
        .card(padding: 10)
        FocusStepButtons(labels: viewModel.neighbourLabels) { viewModel.step($0) }
        Button(action: viewModel.openAnswerKey) {
          Label("Cevap anahtarı", systemImage: "key.fill")
        }
        .buttonStyle(ChunkyButtonStyle(.ghost))
      }
      Spacer(minLength: 0)
    }
  }
}

// MARK: - Pieces

/// Odak başlığı: (isteğe bağlı) mini harita, yön · harf sayısı, ipucu ve kesişen kelimeler.
struct FocusClueHeader: View {
  let entry: PuzzleEntry
  let layout: CrosswordLayout
  let theme: PuzzleTheme
  let active: GridPoint?
  let showsMap: Bool
  var eyebrowPrefix = ""

  var body: some View {
    HStack(spacing: 14) {
      if showsMap {
        MiniGridView(
          puzzle: layout.puzzle, theme: theme, cellSize: 14, highlighted: Set(entry.cells),
          active: active)
      }
      VStack(alignment: .leading, spacing: 4) {
        Eyebrow("\(eyebrowPrefix)\(entry.dir.title) · \(entry.answer.count) harf")
        Text(entry.clue).font(AppFont.title).foregroundStyle(Palette.ink)
          .minimumScaleFactor(0.6)
        Text(EntryNavigation.crossingText(entry, in: layout)).font(AppFont.caption)
          .foregroundStyle(Palette.muted)
          .lineLimit(2)
      }
      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .combine)
  }
}

/// Odak kutularının altındaki açıklama.
struct FocusHint: View {
  let autoAdvance: Bool
  /// Klavye modu açık mı.
  var isKeyboard = false

  var body: some View {
    Text(text)
      .font(AppFont.tiny).foregroundStyle(Palette.muted)
      .multilineTextAlignment(.center)
  }

  private var text: String {
    if isKeyboard { return "Kutuya dokun ve klavyeyle yaz · harf yazınca sonraki kutuya geçer" }
    return autoAdvance
      ? "Kutunun içine rahatça yaz · bitince sonraki kutuya geçer"
      : "Kutunun içine rahatça yaz · yazdıkların ızgaraya geçer"
  }
}

/// Komşu kelimelerin ipuçlarıyla önceki / sonraki butonları ("‹ Ev" / "Kuzey ›").
struct FocusStepButtons: View {
  let labels: (previous: String, next: String)
  let onStep: (Int) -> Void

  var body: some View {
    HStack(spacing: 10) {
      Button {
        onStep(-1)
      } label: {
        Label(labels.previous, systemImage: "chevron.left").lineLimit(1)
      }
      .buttonStyle(.chunkySecondary)
      .accessibilityLabel("Önceki kelime: \(labels.previous)")
      Button {
        onStep(1)
      } label: {
        Label(labels.next, systemImage: "chevron.right")
          .labelStyle(TrailingIconLabelStyle())
          .lineLimit(1)
      }
      .buttonStyle(.chunky)
      .accessibilityLabel("Sonraki kelime: \(labels.next)")
    }
  }
}

/// Odak kutularına yazılan çizim alanı (tam ekran odak modu ve yan odak alanı).
struct FocusWritingCanvas: View {
  @ObservedObject var viewModel: PuzzleViewModel
  let entry: PuzzleEntry
  let theme: PuzzleTheme
  let penColor: Color
  let bridge: CanvasBridge
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    DrawingCanvas(
      drawing: viewModel.focusDrawing,
      drawingRevision: viewModel.focusRevision,
      contentSize: CanvasMetrics.focusSize(count: entry.cells.count),
      inkRects: viewModel.focusInkRects(for: entry),
      underlay: { scale in
        AnyView(
          FocusBoxes(
            entry: entry, revealed: viewModel.revealed, typed: viewModel.typed,
            typedInk: penColor, activeIndex: viewModel.focusActiveIndex, theme: theme,
            scale: scale))
      },
      tool: viewModel.tool,
      penColor: UIColor(penColor),
      pencilColor: UIColor(theme.pencil),
      widthScale: viewModel.settings.penWidth * 1.6,
      colorScheme: scheme,
      pencilOnly: viewModel.settings.pencilOnly,
      allowsZoom: false,
      bridge: bridge,
      onChange: viewModel.focusChanged,
      onTap: viewModel.focusTap(at:),
      onStroke: viewModel.focusStrokeEnded(at:),
      onErase: viewModel.focusErase(at:)
    )
    .accessibilityLabel("Odak kutuları. \(entry.clue), \(entry.answer.count) harf.")
  }
}

/// Büyük yazma kutuları; etkin kutu vurgulanır. İpucu harfi zıplayarak, klavye harfi büyüyerek
/// belirir (Hareketi Azalt'ta sadece saydamlık).
struct FocusBoxes: View {
  let entry: PuzzleEntry
  let revealed: Set<GridPoint>
  /// Klavyeyle yazılan harfler.
  var typed: [GridPoint: Character] = [:]
  /// Klavye harflerinin rengi.
  var typedInk: Color = .primary
  let activeIndex: Int?
  let theme: PuzzleTheme
  let scale: CGFloat
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    let count = entry.cells.count
    let size = CanvasMetrics.focusSize(count: count)
    ZStack(alignment: .topLeading) {
      Color.clear.frame(width: size.width * scale, height: size.height * scale)
      ForEach(0..<count, id: \.self) { index in
        box(index: index, count: count)
      }
    }
  }

  private func box(index: Int, count: Int) -> some View {
    let rect = CanvasMetrics.focusRect(index: index, count: count)
    let cell = entry.cells[index]
    let isActive = index == activeIndex
    let shape = RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
    return
      shape
      .fill(isActive ? theme.highlight : theme.cell)
      .overlay(
        shape.strokeBorder(
          isActive ? Palette.accent : theme.arrow.opacity(0.35),
          lineWidth: isActive ? 2.5 : 2)
      )
      .overlay(alignment: .bottom) {
        Line()
          .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4 * scale, 3 * scale]))
          .foregroundStyle(Palette.lineStrong.opacity(0.8))
          .frame(height: 1)
          .padding(.horizontal, 12 * scale)
          .padding(.bottom, 18 * scale)
      }
      .overlay {
        ZStack {
          if revealed.contains(cell), let char = entry.letter(at: cell) {
            Text(String(char)).font(.system(size: 54 * scale, weight: .heavy, design: .rounded))
              .foregroundStyle(theme.keyInk.opacity(0.85))
              .transition(appear(from: 0.3))
          } else if let char = typed[cell] {
            Text(String(char)).font(AppFont.hand(size: 58 * scale))
              .foregroundStyle(typedInk)
              .id(char)
              .transition(appear(from: 0.55))
          }
        }
        .animation(
          reduceMotion ? .easeOut(duration: 0.15) : Motion.bouncy, value: revealed.contains(cell)
        )
        .animation(reduceMotion ? .easeOut(duration: 0.15) : Motion.snappy, value: typed[cell])
      }
      .overlay(alignment: .topLeading) {
        Text("\(index + 1)").font(.system(size: 13 * scale, weight: .bold, design: .rounded))
          .foregroundStyle(Palette.muted).padding(6 * scale)
      }
      .frame(width: rect.width * scale, height: rect.height * scale)
      .offset(x: rect.minX * scale, y: rect.minY * scale)
  }
}

extension FocusBoxes {
  /// Harfin beliriş geçişi; Hareketi Azalt açıksa sadece saydamlık.
  fileprivate func appear(from scale: CGFloat) -> AnyTransition {
    reduceMotion ? .opacity : .scale(scale: scale).combined(with: .opacity)
  }
}

/// Yatay kesikli taban çizgisi.
private struct Line: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.midY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
    return path
  }
}
