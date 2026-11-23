import ContentKit
import DesignKit
import PencilKit
import PuzzleKit
import SwiftUI

/// Bulmaca ekranı: ipucu çubuğu, kalemle yazılan ızgara ve araç çubuğu.
///
/// Telefon, iPad (geniş) ve katlanabilir (kareye yakın, geniş) yerleşimleri vardır.
struct PuzzleView: View {
  @StateObject var viewModel: PuzzleViewModel
  @StateObject private var bridge = CanvasBridge()
  @Environment(\.colorScheme) private var scheme
  @Environment(\.horizontalSizeClass) private var sizeClass
  @State private var containerSize: CGSize = .zero

  var body: some View {
    content
      .padding(.bottom, 8)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .onGeometryChange(for: CGSize.self) {
        $0.size
      } action: {
        containerSize = $0
      }
      .onChange(of: mode, initial: true) { _, newMode in
        viewModel.setInlineFocus(newMode == .fold)
      }
      .background {
        KeyboardInput(
          isActive: viewModel.wantsKeyboard && !viewModel.isFocusPresented,
          request: viewModel.keyboardRequest, onInsert: viewModel.typeText,
          onDelete: viewModel.deleteBackward, onReturn: viewModel.keyboardReturn,
          onFocusChange: viewModel.keyboardFocusChanged
        )
        .frame(width: 1, height: 1)
        .opacity(0)
        .accessibilityHidden(true)
      }
      .screenBackground()
      .task { await viewModel.load() }
      .onDisappear(perform: viewModel.pause)
      .appBottomSheet(isPresented: hintBinding) {
        HintSheet(viewModel: viewModel)
      }
      .appBottomSheet(isPresented: $viewModel.isThemeSheetPresented) {
        ThemeSheet(viewModel: viewModel, theme: theme)
      }
      .fullScreenCover(isPresented: $viewModel.isFocusPresented) {
        FocusView(viewModel: viewModel, theme: theme, penColor: penColor)
      }
      .overlay(alignment: .bottom) { finishNudge }
      .animation(Motion.snappy, value: viewModel.finishNudge)
      .sensoryFeedback(.warning, trigger: viewModel.finishNudge?.serial) { _, new in new != nil }
      .task(id: viewModel.finishNudge?.serial) {
        guard let serial = viewModel.finishNudge?.serial else { return }
        try? await Task.sleep(for: .seconds(2.6))
        viewModel.dismissFinishNudge(serial: serial)
      }
  }

  /// Boş kutu varken "Bitirdim"e basılınca alttan çıkan uyarı balonu.
  @ViewBuilder private var finishNudge: some View {
    if let nudge = viewModel.finishNudge {
      Label(nudge.message, systemImage: "square.dashed")
        .font(AppFont.caption.weight(.heavy))
        .foregroundStyle(Palette.ink)
        .lineLimit(2)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
          Capsule().fill(Palette.surface)
            .overlay(Capsule().strokeBorder(Palette.cardBorder, lineWidth: 1))
            .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
        )
        .padding(.horizontal, Metrics.gutter)
        // Araç çubuğu ve alt butonların üstünde durur; hiçbirini örtmez.
        .padding(.bottom, 168)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .id(nudge.serial)
        .accessibilityAddTraits(.isStaticText)
        .allowsHitTesting(false)
    }
  }

  // MARK: - Layouts

  @ViewBuilder
  private var content: some View {
    if viewModel.isMissing {
      VStack(spacing: 10) {
        header
        ContentUnavailableView(
          "Bulmaca bulunamadı", systemImage: "square.grid.3x3",
          description: Text("İnternete bağlanınca yeniden dene."))
      }
    } else if let layout = viewModel.layout {
      switch mode {
      case .phone: phone(layout)
      case .tablet: tablet(layout)
      case .fold: fold(layout)
      }
    } else {
      VStack(spacing: 10) {
        header
        ProgressView().frame(maxHeight: .infinity)
      }
    }
  }

  /// Telefon: üst bar, ipucu çubuğu, ızgara, araç çubuğu ve alt butonlar.
  ///
  /// Klavye açıkken açıklama ve alt butonlar gizlenir; ızgara kalan alana sığdırılır.
  private func phone(_ layout: CrosswordLayout) -> some View {
    let keyboardUp = viewModel.isKeyboardShown
    return VStack(spacing: 10) {
      header
      VStack(spacing: 10) {
        ClueBar(entry: viewModel.selected, onStep: viewModel.step)
        canvas(layout)
        if viewModel.isCompleted {
          CompletedNote(correct: viewModel.correctCount, total: layout.puzzle.entries.count)
        } else {
          if !keyboardUp {
            hint(hintText)
          }
          toolbar(compact: false)
        }
      }
      .padding(.horizontal, 12)
      if !keyboardUp, !viewModel.isCompleted {
        actions
      }
    }
  }

  /// iPad: araçlar üst barda, ızgaranın yanında ipucu paneli.
  private func tablet(_ layout: CrosswordLayout) -> some View {
    VStack(spacing: 16) {
      tabletTopBar
      HStack(alignment: .top, spacing: 26) {
        VStack(spacing: 14) {
          ClueBar(entry: viewModel.selected, onStep: viewModel.step)
            .frame(maxWidth: 540)
          canvas(layout)
          if viewModel.isCompleted {
            CompletedNote(correct: viewModel.correctCount, total: layout.puzzle.entries.count)
              .frame(maxWidth: 540)
          } else {
            hint(
              viewModel.tool == .keyboard
                ? "Kutuya dokun ve klavyeyle yaz · tekrar dokununca yön değişir"
                : "Apple Pencil ile yaz · parmakla kaydır ve yakınlaştır")
          }
        }
        CluePanel(
          layout: layout, selected: viewModel.selected, revealed: viewModel.revealed,
          isDone: viewModel.isDone, onSelect: viewModel.select
        )
        .frame(width: 350)
      }
    }
    .padding(.horizontal, 24)
    .padding(.top, 4)
  }

  /// Katlanabilir: solda ızgara, sağda odak yazma alanı.
  private func fold(_ layout: CrosswordLayout) -> some View {
    HStack(spacing: 0) {
      VStack(spacing: 12) {
        HStack(spacing: 10) {
          backButton
          Spacer()
          Text(viewModel.title).font(AppFont.section).foregroundStyle(Palette.ink).lineLimit(1)
          Spacer()
          TimerPill(text: viewModel.timerText)
          themeButton
        }
        ClueBar(entry: viewModel.selected, onStep: viewModel.step)
        canvas(layout)
        if viewModel.isCompleted {
          CompletedNote(correct: viewModel.correctCount, total: layout.puzzle.entries.count)
        } else {
          toolbar(compact: true, showsFocus: false)
        }
      }
      .padding(.horizontal, 18)
      .padding(.top, 4)
      if !viewModel.isCompleted {
        Rectangle().fill(Palette.line).frame(width: 1).padding(.vertical, 12)
        FoldFocusPanel(viewModel: viewModel, theme: theme, penColor: penColor)
          .padding(.horizontal, 18)
      }
    }
  }

  // MARK: - Pieces

  private var header: some View {
    HStack(spacing: 10) {
      backButton
      Spacer()
      VStack(spacing: 1) {
        Text(viewModel.title).font(AppFont.section).foregroundStyle(Palette.ink)
        Text(viewModel.subtitle).font(AppFont.tiny).foregroundStyle(Palette.muted)
      }
      Spacer()
      TimerPill(text: viewModel.timerText)
      themeButton
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.top, 4)
  }

  /// iPad üst barı; dar pencerede (dikey iPad) araç çubuğu ikinci satıra iner.
  private var tabletTopBar: some View {
    ViewThatFits(in: .horizontal) {
      HStack(spacing: 12) {
        backButton
        tabletTitle
        Spacer(minLength: 8)
        if !viewModel.isCompleted {
          toolbar(compact: true).fixedSize()
        }
        tabletActions
      }
      VStack(spacing: 10) {
        HStack(spacing: 12) {
          backButton
          tabletTitle
          Spacer(minLength: 8)
          tabletActions
        }
        if !viewModel.isCompleted {
          toolbar(compact: true).fixedSize()
        }
      }
    }
  }

  private var tabletTitle: some View {
    HStack(alignment: .firstTextBaseline, spacing: 4) {
      Text(viewModel.title).font(AppFont.rounded(17, weight: .black))
        .foregroundStyle(Palette.ink)
      Text("· \(viewModel.subtitle)").font(AppFont.caption).foregroundStyle(Palette.muted)
    }
    .lineLimit(1)
  }

  private var tabletActions: some View {
    HStack(spacing: 12) {
      TimerPill(text: viewModel.timerText)
      themeButton
      if !viewModel.isCompleted {
        Button(action: viewModel.openAnswerKey) {
          Label("Anahtar", systemImage: "key.fill")
        }
        .buttonStyle(ChunkyButtonStyle(.secondary, fullWidth: false, compact: true))
        Button("Bitirdim", action: viewModel.finishTapped)
          .buttonStyle(ChunkyButtonStyle(.primary, fullWidth: false, compact: true))
          .opacity(viewModel.canFinish ? 1 : 0.5)
          .accessibilityHint(viewModel.canFinish ? "" : "Önce tüm kutuları doldur")
      }
    }
    .fixedSize()
  }

  private var backButton: some View {
    Button(action: viewModel.back) { IconCircle("chevron.left") }
      .buttonStyle(.plain)
      .accessibilityLabel("Geri")
  }

  private var themeButton: some View {
    Button {
      viewModel.isThemeSheetPresented = true
    } label: {
      IconCircle("paintpalette", size: 34)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Bulmaca teması")
  }

  private func hint(_ text: String) -> some View {
    Label(text, systemImage: viewModel.tool == .keyboard ? "keyboard" : "pencil")
      .font(AppFont.tiny).foregroundStyle(Palette.muted)
      .contentTransition(.opacity)
  }

  /// Telefondaki açıklama metni (araca göre).
  private var hintText: String {
    viewModel.tool == .keyboard
      ? "Kutuya dokun ve klavyeyle yaz · tekrar dokununca yön değişir"
      : "Parmağınla veya Apple Pencil ile yaz · iki parmakla yakınlaştır"
  }

  private func canvas(_ layout: CrosswordLayout) -> some View {
    DrawingCanvas(
      drawing: viewModel.drawing,
      drawingRevision: viewModel.drawingRevision,
      contentSize: CanvasMetrics.grid.size(rows: layout.rows, columns: layout.columns),
      inkRects: viewModel.inkRects,
      underlay: { scale in
        AnyView(
          PuzzleGridView(
            layout: layout, theme: theme, cellSize: CanvasMetrics.gridCell * scale,
            highlighted: viewModel.highlighted, active: viewModel.activeCell,
            activeClue: viewModel.activeClue, letters: viewModel.revealedLetters,
            typed: viewModel.typed, typedInk: penColor,
            geometry: CanvasMetrics.grid.scaled(by: scale)))
      },
      // Bitmiş bulmacada çizim kapalıdır; dokunuş yalnızca kelime seçer.
      tool: viewModel.isCompleted ? .keyboard : viewModel.tool,
      penColor: UIColor(penColor),
      pencilColor: UIColor(theme.pencil),
      widthScale: viewModel.settings.penWidth,
      colorScheme: scheme,
      pencilOnly: viewModel.settings.pencilOnly,
      allowsZoom: true,
      bridge: bridge,
      onChange: viewModel.drawingChanged,
      onTap: viewModel.tap(at:),
      onStroke: viewModel.strokeEnded(at:),
      onViewport: { [zoom = viewModel.zoom] in zoom.update($0) },
      onErase: viewModel.erase(at:)
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityLabel(canvasLabel)
    .overlay {
      ZoomOverlay(
        zoom: viewModel.zoom, puzzle: layout.puzzle, theme: theme,
        highlighted: viewModel.highlighted)
    }
  }

  private func toolbar(compact: Bool, showsFocus: Bool = true) -> some View {
    let onFocus: (() -> Void)? = showsFocus ? { viewModel.openFocus() } : nil
    return PuzzleToolbar(
      tool: $viewModel.tool, hintsLeft: viewModel.hintsLeft,
      leftHanded: viewModel.settings.leftHanded,
      canUndo: viewModel.canUndo, canRedo: viewModel.canRedo,
      onUndo: viewModel.undo, onRedo: viewModel.redo,
      onFocus: onFocus,
      onHint: { viewModel.isHintSheetPresented = true }, onClear: viewModel.clearSelectedWord,
      compact: compact)
  }

  private var actions: some View {
    HStack(spacing: 10) {
      Button(action: viewModel.openAnswerKey) {
        Label("Cevap anahtarı", systemImage: "key.fill")
      }
      .buttonStyle(.chunkySecondary)
      Button("Bitirdim", action: viewModel.finishTapped)
        .buttonStyle(.chunky)
        .opacity(viewModel.canFinish ? 1 : 0.5)
        .accessibilityHint(viewModel.canFinish ? "" : "Önce tüm kutuları doldur")
    }
    .padding(.horizontal, Metrics.gutter)
    .frame(maxWidth: 640)
  }

  // MARK: - State

  /// Izgaranın erişilebilirlik etiketi.
  private var canvasLabel: String {
    if viewModel.isCompleted { return "Bulmaca ızgarası. Doğru cevaplar gösteriliyor." }
    return viewModel.tool == .keyboard
      ? "Bulmaca ızgarası. Kutuya dokun ve klavyeyle yaz."
      : "Bulmaca ızgarası. Kutulara parmakla ya da kalemle yaz."
  }

  private var mode: PuzzleLayoutMode {
    PuzzleLayoutMode.resolve(size: containerSize, isRegularWidth: sizeClass == .regular)
  }

  /// İpucu paneli; tam ekran odak modu açıkken odak ekranından gösterilir.
  private var hintBinding: Binding<Bool> {
    Binding(
      get: { viewModel.isHintSheetPresented && !viewModel.isFocusPresented },
      set: { viewModel.isHintSheetPresented = $0 })
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

/// Bitmiş bulmacada araç çubuğunun yerinde duran bilgi kartı.
struct CompletedNote: View {
  /// Doğru işaretlenen kelime sayısı.
  let correct: Int
  /// Toplam kelime sayısı.
  let total: Int

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "checkmark.seal.fill")
        .font(.system(size: 26, weight: .semibold))
        .foregroundStyle(Palette.good)
      VStack(alignment: .leading, spacing: 2) {
        Text("Bu bulmacayı bitirdin")
          .font(AppFont.headline).foregroundStyle(Palette.ink)
        Text("Doğru cevaplar gösteriliyor · \(correct)/\(total) kelime doğru")
          .font(AppFont.caption).foregroundStyle(Palette.muted)
      }
      Spacer(minLength: 0)
    }
    .padding(14)
    .frame(maxWidth: 640)
    .background(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(Palette.surface)
        .shadow(color: Palette.cardShadow, radius: 0, y: 2)
    )
    .accessibilityElement(children: .combine)
  }
}

/// Sayaç kapsülü.
struct TimerPill: View {
  let text: String

  var body: some View {
    Label(text, systemImage: "clock")
      .font(AppFont.caption.monospacedDigit())
      .foregroundStyle(Palette.ink)
      .padding(.horizontal, 10)
      .frame(height: 30)
      .background(Capsule().fill(Palette.surface2))
      .accessibilityLabel("Süre \(text)")
  }
}

/// Seçili kelimenin ipucu, yönü ve önceki / sonraki okları.
///
/// Kelime değişince ipucu yumuşakça yer değiştirir (Hareketi Azalt'ta sadece saydamlık).
struct ClueBar: View {
  let entry: PuzzleEntry?
  let onStep: (Int) -> Void
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    HStack(spacing: 8) {
      Button {
        onStep(-1)
      } label: {
        arrow("chevron.left")
      }
      .accessibilityLabel("Önceki kelime")
      ZStack {
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
        .id(entry?.id)
        .transition(
          reduceMotion
            ? AnyTransition.opacity
            : AnyTransition(.blurReplace).combined(with: .scale(scale: 0.92)))
      }
      .frame(maxWidth: .infinity)
      .clipped()
      .animation(reduceMotion ? .easeOut(duration: 0.15) : Motion.snappy, value: entry?.id)
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

/// Kalem araçları. `compact` sürümü sadece ikon gösterir (odak modu, iPad üst barı).
struct PuzzleToolbar: View {
  @Binding var tool: DrawingTool
  let hintsLeft: Int?
  let leftHanded: Bool
  /// Geri al / yinele butonları etkin mi.
  var canUndo = true
  var canRedo = true
  let onUndo: () -> Void
  let onRedo: () -> Void
  /// Odak modu eylemi; `nil` ise buton gösterilmez.
  let onFocus: (() -> Void)?
  let onHint: () -> Void
  let onClear: () -> Void
  /// Sadece ikonlu, dar sürüm.
  var compact = false

  var body: some View {
    HStack(spacing: compact ? 2 : 4) {
      let items = Group {
        toolButton(.pen, "pencil.tip", "Kalem")
        toolButton(.pencil, "pencil", "Kurşun")
        toolButton(.eraser, "eraser", "Silgi")
        toolButton(.keyboard, "keyboard", "Klavye")
        divider
        action("arrow.uturn.backward", "Geri", onUndo).disabled(!canUndo)
        action("arrow.uturn.forward", "İleri", onRedo).disabled(!canRedo)
        divider
        if let onFocus {
          action("viewfinder", "Odak", onFocus)
        }
        action("lightbulb", "İpucu", onHint, badge: hintsLeft.map(String.init))
      }
      if leftHanded {
        HStack(spacing: compact ? 2 : 4) { items }.environment(\.layoutDirection, .rightToLeft)
      } else {
        items
      }
    }
    .padding(compact ? 5 : 6)
    .frame(maxWidth: compact ? nil : 640)
    // Gölge yalnızca zemine: içerikteki ikon ve yazılar çift görünmesin.
    .background(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(Palette.surface)
        .shadow(color: Palette.cardShadow, radius: 0, y: 2)
    )
    .sensoryFeedback(.selection, trigger: tool)
    .contextMenu {
      Button("Seçili kelimeyi temizle", systemImage: "trash", role: .destructive, action: onClear)
    }
  }

  private var divider: some View {
    Rectangle().fill(Palette.line).frame(width: 1, height: compact ? 26 : 30)
  }

  private func toolButton(_ value: DrawingTool, _ icon: String, _ title: String) -> some View {
    Button {
      withAnimation(Motion.snappy) { tool = value }
    } label: {
      item(icon, title, isOn: tool == value)
    }
    .buttonStyle(PressScaleButtonStyle())
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
    .buttonStyle(ToolbarActionStyle())
    .accessibilityLabel(title)
  }

  @ViewBuilder
  private func item(_ icon: String, _ title: String, isOn: Bool) -> some View {
    let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
    if compact {
      Image(systemName: icon).font(.system(size: 18, weight: .semibold))
        .foregroundStyle(isOn ? .white : Palette.ink)
        .frame(width: 42, height: 40)
        .background(shape.fill(isOn ? Palette.buttonFill : .clear))
        .contentShape(shape)
    } else {
      VStack(spacing: 2) {
        Image(systemName: icon).font(.system(size: 18, weight: .semibold)).frame(height: 22)
        Text(title).font(.system(size: 9.5, weight: .heavy, design: .rounded))
      }
      .foregroundStyle(isOn ? .white : Palette.ink)
      .frame(maxWidth: .infinity, minHeight: 46)
      .background(shape.fill(isOn ? Palette.buttonFill : .clear))
      .contentShape(shape)
    }
  }
}

/// Araç çubuğu eylem butonu: basınca hafif küçülür, kullanılamazken soluk görünür.
private struct ToolbarActionStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(isEnabled ? 1 : 0.35)
      .scaleEffect(configuration.isPressed ? 0.92 : 1)
      .animation(Motion.snappy, value: configuration.isPressed)
  }
}
