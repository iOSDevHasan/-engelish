import ContentKit
import DesignKit
import PencilKit
import PuzzleKit
import SwiftUI

/// Bulmaca ekranı: ipucu çubuğu, kalemle yazılan ızgara ve araç çubuğu.
struct PuzzleView: View {
  @StateObject var viewModel: PuzzleViewModel
  @StateObject private var bridge = CanvasBridge()
  @Environment(\.colorScheme) private var scheme
  @Environment(\.horizontalSizeClass) private var sizeClass

  var body: some View {
    VStack(spacing: 10) {
      header
      if viewModel.isMissing {
        ContentUnavailableView(
          "Bulmaca bulunamadı", systemImage: "square.grid.3x3",
          description: Text("İnternete bağlanınca yeniden dene."))
      } else if let layout = viewModel.layout {
        if sizeClass == .regular {
          HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 10) {
              ClueBar(entry: viewModel.selected, onStep: viewModel.step)
              canvas(layout)
              toolbar
            }
            ClueList(layout: layout, selected: viewModel.selected, onSelect: viewModel.select)
              .frame(width: 300)
          }
          .padding(.horizontal, Metrics.gutter)
        } else {
          VStack(spacing: 10) {
            ClueBar(entry: viewModel.selected, onStep: viewModel.step)
            canvas(layout)
            Label(
              "Parmağınla ya da Apple Pencil ile yaz · iki parmakla yakınlaştır",
              systemImage: "pencil"
            )
            .font(AppFont.tiny).foregroundStyle(Palette.muted)
            toolbar
          }
          .padding(.horizontal, 12)
        }
        actions
      } else {
        ProgressView().frame(maxHeight: .infinity)
      }
    }
    .padding(.bottom, 8)
    .screenBackground()
    .task { await viewModel.load() }
    .onDisappear(perform: viewModel.pause)
    .sheet(isPresented: $viewModel.isHintSheetPresented) {
      HintSheet(viewModel: viewModel)
    }
    .sheet(isPresented: $viewModel.isThemeSheetPresented) {
      ThemeSheet(viewModel: viewModel, theme: theme)
    }
    .fullScreenCover(isPresented: $viewModel.isFocusPresented) {
      FocusView(viewModel: viewModel, theme: theme, penColor: penColor)
    }
  }

  // MARK: - Pieces

  private var header: some View {
    HStack(spacing: 10) {
      Button(action: viewModel.back) { IconCircle("chevron.left") }
        .buttonStyle(.plain)
        .accessibilityLabel("Geri")
      Spacer()
      VStack(spacing: 1) {
        Text(viewModel.title).font(AppFont.section).foregroundStyle(Palette.ink)
        Text(viewModel.subtitle).font(AppFont.tiny).foregroundStyle(Palette.muted)
      }
      Spacer()
      Label(viewModel.timerText, systemImage: "clock")
        .font(AppFont.caption.monospacedDigit())
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 8)
        .frame(height: 30)
        .background(Capsule().fill(Palette.surface))
      Button {
        viewModel.isThemeSheetPresented = true
      } label: {
        IconCircle("paintpalette", size: 34)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Bulmaca teması")
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.top, 4)
  }

  private func canvas(_ layout: CrosswordLayout) -> some View {
    DrawingCanvas(
      drawing: viewModel.drawing,
      drawingRevision: viewModel.drawingRevision,
      contentSize: CanvasMetrics.grid.size(rows: layout.rows, columns: layout.columns),
      underlay: { scale in
        AnyView(
          PuzzleGridView(
            layout: layout, theme: theme, cellSize: CanvasMetrics.gridCell * scale,
            highlighted: viewModel.highlighted, active: viewModel.activeCell,
            activeClue: viewModel.activeClue, letters: viewModel.revealedLetters,
            geometry: CanvasMetrics.grid.scaled(by: scale)))
      },
      tool: viewModel.tool,
      penColor: UIColor(penColor),
      pencilColor: UIColor(theme.pencil),
      widthScale: viewModel.settings.penWidth,
      colorScheme: scheme,
      pencilOnly: viewModel.settings.pencilOnly,
      allowsZoom: true,
      bridge: bridge,
      onChange: viewModel.drawingChanged,
      onTap: viewModel.tap(at:),
      onStroke: viewModel.strokeEnded(at:)
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityLabel("Bulmaca ızgarası. Kutulara parmakla ya da kalemle yaz.")
  }

  private var toolbar: some View {
    PuzzleToolbar(
      tool: $viewModel.tool, hintsLeft: viewModel.hintsLeft,
      leftHanded: viewModel.settings.leftHanded,
      onUndo: bridge.undo, onRedo: bridge.redo, onFocus: viewModel.openFocus,
      onHint: { viewModel.isHintSheetPresented = true }, onClear: viewModel.clearSelectedWord)
  }

  private var actions: some View {
    HStack(spacing: 10) {
      Button(action: viewModel.openAnswerKey) {
        Label("Cevap anahtarı", systemImage: "key.fill")
      }
      .buttonStyle(.chunkySecondary)
      Button("Bitirdim", action: viewModel.openAnswerKey).buttonStyle(.chunky)
    }
    .padding(.horizontal, Metrics.gutter)
    .frame(maxWidth: 640)
  }

  // MARK: - Theme

  private var theme: PuzzleTheme {
    PuzzleTheme.resolve(
      id: viewModel.settings.puzzleTheme, isDark: scheme == .dark,
      autoNight: viewModel.settings.autoNightTheme, highContrast: viewModel.settings.highContrast)
  }

  private var penColor: Color {
    PenStyle.color(id: viewModel.settings.penColor, theme: theme)
  }
}

/// Seçili kelimenin ipucu, yönü ve önceki / sonraki okları.
struct ClueBar: View {
  let entry: PuzzleEntry?
  let onStep: (Int) -> Void

  var body: some View {
    HStack(spacing: 8) {
      Button {
        onStep(-1)
      } label: {
        arrow("chevron.left")
      }
      .accessibilityLabel("Önceki kelime")
      VStack(spacing: 2) {
        HStack(spacing: 6) {
          Text(entry?.dir == .down ? "↓" : "→").foregroundStyle(Palette.clueBarArrow)
          Text(entry?.clue ?? "").lineLimit(1).minimumScaleFactor(0.7)
        }
        .font(AppFont.headline)
        Text("\(entry?.answer.count ?? 0) harf · \(entry?.dir.title ?? "")")
          .font(AppFont.tiny)
          .opacity(0.8)
      }
      .frame(maxWidth: .infinity)
      Button {
        onStep(1)
      } label: {
        arrow("chevron.right")
      }
      .accessibilityLabel("Sonraki kelime")
    }
    .foregroundStyle(.white)
    .padding(8)
    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Palette.clueBar))
    .accessibilityElement(children: .contain)
  }

  private func arrow(_ name: String) -> some View {
    Image(systemName: name).font(.system(size: 16, weight: .heavy))
      .frame(width: 38, height: 38)
      .background(Circle().fill(.white.opacity(0.18)))
  }
}

/// Kalem araçları.
struct PuzzleToolbar: View {
  @Binding var tool: DrawingTool
  let hintsLeft: Int?
  let leftHanded: Bool
  let onUndo: () -> Void
  let onRedo: () -> Void
  let onFocus: () -> Void
  let onHint: () -> Void
  let onClear: () -> Void

  var body: some View {
    HStack(spacing: 4) {
      let items = Group {
        toolButton(.pen, "pencil.tip", "Kalem")
        toolButton(.pencil, "pencil", "Kurşun")
        toolButton(.eraser, "eraser", "Silgi")
        divider
        action("arrow.uturn.backward", "Geri", onUndo)
        action("arrow.uturn.forward", "İleri", onRedo)
        divider
        action("viewfinder", "Odak", onFocus)
        action("lightbulb", "İpucu", onHint, badge: hintsLeft.map(String.init))
      }
      if leftHanded {
        HStack(spacing: 4) { items }.environment(\.layoutDirection, .rightToLeft)
      } else {
        items
      }
    }
    .padding(6)
    .frame(maxWidth: 640)
    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.surface))
    .shadow(color: Palette.cardShadow, radius: 0, y: 2)
    .contextMenu {
      Button("Seçili kelimeyi temizle", systemImage: "trash", role: .destructive, action: onClear)
    }
  }

  private var divider: some View {
    Rectangle().fill(Palette.line).frame(width: 1, height: 30)
  }

  private func toolButton(_ value: DrawingTool, _ icon: String, _ title: String) -> some View {
    Button {
      tool = value
    } label: {
      item(icon, title, isOn: tool == value)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
    .accessibilityAddTraits(tool == value ? .isSelected : [])
  }

  private func action(
    _ icon: String, _ title: String, _ perform: @escaping () -> Void, badge: String? = nil
  ) -> some View {
    Button(action: perform) {
      item(icon, title, isOn: false)
        .overlay(alignment: .topTrailing) {
          if let badge {
            Text(badge).font(.system(size: 10, weight: .black, design: .rounded))
              .foregroundStyle(Palette.goldInk)
              .frame(minWidth: 16, minHeight: 16)
              .background(Circle().fill(Palette.gold))
              .offset(x: -2, y: 0)
          }
        }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
  }

  private func item(_ icon: String, _ title: String, isOn: Bool) -> some View {
    VStack(spacing: 2) {
      Image(systemName: icon).font(.system(size: 18, weight: .semibold)).frame(height: 22)
      Text(title).font(.system(size: 9.5, weight: .heavy, design: .rounded))
    }
    .foregroundStyle(isOn ? .white : Palette.ink)
    .frame(maxWidth: .infinity, minHeight: 46)
    .background(
      RoundedRectangle(cornerRadius: 14, style: .continuous).fill(
        isOn ? Palette.buttonFill : .clear))
  }
}

/// iPad'de ızgaranın yanındaki ipucu listesi.
struct ClueList: View {
  let layout: CrosswordLayout
  let selected: PuzzleEntry?
  let onSelect: (PuzzleEntry) -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        section("Soldan sağa →", .across)
        section("Yukarıdan aşağı ↓", .down)
      }
      .padding(14)
    }
    .background(RoundedRectangle(cornerRadius: Metrics.radius).fill(Palette.surface))
  }

  private func section(_ title: String, _ dir: Direction) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Eyebrow(title)
      ForEach(layout.puzzle.entries.filter { $0.dir == dir }) { entry in
        Button {
          onSelect(entry)
        } label: {
          HStack {
            Text(entry.clue).font(AppFont.body)
            Spacer()
            Text("\(entry.answer.count)").font(AppFont.caption).foregroundStyle(Palette.muted)
          }
          .foregroundStyle(Palette.ink)
          .padding(.horizontal, 10)
          .padding(.vertical, 8)
          .background(
            RoundedRectangle(cornerRadius: 12).fill(selected == entry ? Palette.selection : .clear))
        }
        .buttonStyle(.plain)
      }
    }
  }
}
