import ContentKit
import DesignKit
import PuzzleKit
import SwiftUI

/// Cevap anahtarı ve kendi kendine işaretleme ekranı.
struct AnswerKeyView: View {
  @StateObject var viewModel: AnswerKeyViewModel
  let theme: (ColorScheme) -> PuzzleTheme
  /// Klavye harflerinin rengi (kullanıcının kalem rengi).
  var penColor: (PuzzleTheme) -> Color = { $0.pen }
  @Environment(\.colorScheme) private var scheme
  @Environment(\.displayScale) private var displayScale
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack(spacing: 0) {
      NavHeader("Cevap Anahtarı", onLeading: viewModel.back)
      ScrollViewReader { proxy in
        ScrollView {
          VStack(spacing: 14) {
            Picker("Görünüm", selection: $viewModel.mode) {
              ForEach(KeyMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .sensoryFeedback(.selection, trigger: viewModel.mode)
            grid
            if viewModel.mode == .compare {
              Text("Köşedeki küçük harfler doğru cevap. Kendi yazdığınla karşılaştır.")
                .font(AppFont.caption).foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
            }
            switch viewModel.purpose {
            case .finish: markList
            case .peek: peekNote
            }
          }
          .padding(.horizontal, Metrics.gutter)
          .padding(.bottom, 16)
          .frame(maxWidth: 640)
          .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .task(id: viewModel.incompleteAttempt) {
          // Uyarıdan sonra ilk işaretsiz kelimeye kaydırılır; alt alanın yüksekliği değişirken
          // kaydırma kaybolmasın diye bir sonraki çizime bırakılır.
          guard viewModel.incompleteAttempt > 0, let id = viewModel.firstUnmarkedId else { return }
          try? await Task.sleep(for: .milliseconds(80))
          withAnimation(reduceMotion ? nil : Motion.snappy) {
            proxy.scrollTo(Self.rowID(id), anchor: .center)
          }
        }
      }
      footer
    }
    .screenBackground()
    .sensoryFeedback(.warning, trigger: viewModel.incompleteAttempt)
  }

  // MARK: - Marking

  /// Kelime listesi: her kelime ✓ ya da ✗ ile işaretlenir.
  private var markList: some View {
    VStack(spacing: 14) {
      HStack {
        Text("Kelimelerini işaretle").font(AppFont.section).foregroundStyle(Palette.ink)
        Spacer()
        Text(viewModel.summaryText)
          .font(AppFont.caption).foregroundStyle(Palette.muted)
      }
      VStack(spacing: 8) {
        ForEach(Array(viewModel.session.puzzle.entries.enumerated()), id: \.element.id) {
          index, entry in
          MarkRow(
            entry: entry, mark: viewModel.marks[entry.id],
            needsAttention: viewModel.incompleteAttempt > 0,
            onMark: { viewModel.mark(entry, correct: $0) }
          )
          .id(Self.rowID(entry.id))
          .appearAnimation(index: index)
        }
      }
    }
  }

  /// İşaret satırının kaydırma kimliği; ızgaradaki ipucu kutuları kelime kimliğini kullandığı
  /// için ayrı bir ön ek alır.
  private static func rowID(_ entryID: String) -> String { "mark-\(entryID)" }

  /// Göz atarken gösterilen not: işaretleme "Bitirdim"den sonra yapılır.
  private var peekNote: some View {
    Label {
      Text(
        "Göz atıyorsun. Tüm kutuları doldurup \"Bitirdim\"e basınca her kelimeyi burada "
          + "doğru ya da yanlış olarak işaretleyeceksin."
      )
      .fixedSize(horizontal: false, vertical: true)
    } icon: {
      Image(systemName: "eye").foregroundStyle(Palette.accent)
    }
    .font(AppFont.caption)
    .foregroundStyle(Palette.muted)
    .frame(maxWidth: .infinity, alignment: .leading)
    .card(padding: 14)
  }

  /// Alt alan: bitirirken kalan kelime sayısı ve "Sonuçları gör"; göz atarken geri dönüş.
  @ViewBuilder private var footer: some View {
    VStack(spacing: 8) {
      switch viewModel.purpose {
      case .finish:
        if !viewModel.canFinish {
          Label(remainingText, systemImage: "hand.tap")
            .font(AppFont.caption.weight(.bold))
            .foregroundStyle(viewModel.incompleteAttempt > 0 ? Palette.bad : Palette.muted)
            .contentTransition(.numericText(value: Double(viewModel.unmarkedCount)))
            .transition(.opacity)
        }
        Button("Sonuçları gör", action: viewModel.finish)
          .buttonStyle(.chunky)
          .opacity(viewModel.canFinish ? 1 : 0.5)
          .accessibilityHint(viewModel.canFinish ? "" : remainingText)
      case .peek:
        Button("Bulmacaya dön", action: viewModel.back)
          .buttonStyle(.chunky)
      }
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.top, 6)
    .padding(.bottom, 10)
    .frame(maxWidth: 640)
    .animation(reduceMotion ? nil : Motion.snappy, value: viewModel.canFinish)
  }

  /// "3 kelimeyi daha işaretle" metni.
  private var remainingText: String {
    let count = viewModel.unmarkedCount
    return count == 1
      ? "Sonuçlar için son kelimeyi de işaretle"
      : "Sonuçlar için \(count) kelimeyi daha ✓ ya da ✗ ile işaretle"
  }

  private var grid: some View {
    GeometryReader { proxy in
      let layout = viewModel.session.layout
      let base = CanvasMetrics.grid.size(rows: layout.rows, columns: layout.columns)
      let scale = min(proxy.size.width / base.width, 1.2)
      let currentTheme = theme(scheme)
      ZStack(alignment: .topLeading) {
        PuzzleGridView(
          layout: layout, theme: currentTheme, cellSize: CanvasMetrics.gridCell * scale,
          letters: viewModel.letters, typed: viewModel.typedLetters,
          typedInk: penColor(currentTheme), geometry: CanvasMetrics.grid.scaled(by: scale))
        if viewModel.showsDrawing {
          Image(uiImage: viewModel.drawingImage(scale: displayScale))
            .resizable()
            .frame(width: base.width * scale, height: base.height * scale)
            .allowsHitTesting(false)
            .transition(.opacity)
        }
      }
      .animation(reduceMotion ? nil : Motion.snappy, value: viewModel.mode)
      .frame(width: proxy.size.width, alignment: .center)
    }
    .aspectRatio(aspect, contentMode: .fit)
    .accessibilityLabel("Cevap anahtarı ızgarası")
  }

  private var aspect: CGFloat {
    let layout = viewModel.session.layout
    let size = CanvasMetrics.grid.size(rows: layout.rows, columns: layout.columns)
    return size.width / size.height
  }
}

/// Kelime satırı: ipucu, doğru cevap ve ✓ / ✗ butonları.
///
/// İşaret değişince buton zıplar ve satır rengi yumuşakça değişir (Hareketi Azalt'ta sadece renk).
private struct MarkRow: View {
  let entry: PuzzleEntry
  let mark: Bool?
  /// İşaretlenmeden geçilmek istendi: işaretsiz satır kırmızı çerçeveyle vurgulanır.
  var needsAttention = false
  let onMark: (Bool) -> Void
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    HStack(spacing: 10) {
      VStack(alignment: .leading, spacing: 2) {
        Text(entry.answer).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
        Text("\(entry.dir == .across ? "→" : "↓") \(entry.clue)").font(AppFont.caption)
          .foregroundStyle(Palette.muted)
      }
      Spacer()
      markButton(correct: true)
      markButton(correct: false)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(
          mark == true
            ? Palette.goodBackground : mark == false ? Palette.badBackground : Palette.surface
        )
        .overlay(
          RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(borderColor, lineWidth: mark == nil && needsAttention ? 2 : 1))
    )
    .animation(reduceMotion ? .easeOut(duration: 0.15) : Motion.snappy, value: mark)
    .sensoryFeedback(.selection, trigger: mark)
  }

  /// İşaretsiz satırın çerçevesi; uyarıdan sonra kırmızı.
  private var borderColor: Color {
    guard mark == nil else { return .clear }
    return needsAttention ? Palette.bad : Palette.cardBorder
  }

  private func markButton(correct: Bool) -> some View {
    let isOn = mark == correct
    let tint = correct ? Palette.good : Palette.bad
    return Button {
      onMark(correct)
    } label: {
      Image(systemName: correct ? "checkmark" : "xmark")
        .font(.system(size: 15, weight: .black))
        .foregroundStyle(isOn ? .white : tint)
        .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? false : isOn)
        .frame(width: 40, height: 40)
        .background(Circle().fill(isOn ? tint : tint.opacity(0.12)))
        .scaleEffect(isOn && !reduceMotion ? 1.08 : 1)
    }
    .buttonStyle(PressScaleButtonStyle())
    .accessibilityLabel(correct ? "\(entry.answer) doğru" : "\(entry.answer) yanlış")
    .accessibilityAddTraits(isOn ? .isSelected : [])
  }
}
