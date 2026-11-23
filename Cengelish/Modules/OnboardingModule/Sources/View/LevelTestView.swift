import ContentKit
import DesignKit
import SwiftUI

/// Kısa seviye testi: İngilizce kelime, dört Türkçe anlam; sonunda önerilen seviye.
///
/// Alt panel olarak açılır; kökte `.appSheet(detents: [.large])` uygulanır.
struct LevelTestView: View {
  @ObservedObject var viewModel: LevelTestViewModel
  let onAccept: (CEFRLevel) -> Void
  let onClose: () -> Void
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    content
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .safeAreaInset(edge: .top, spacing: 0) {
        NavHeader("Seviye testi", leadingSymbol: "xmark", onLeading: onClose)
          .frame(maxWidth: OnboardingLayout.maxContentWidth)
          .padding(.top, 16)
          .frame(maxWidth: .infinity)
          .background(Palette.background)
      }
      .screenBackground()
      .task { await viewModel.start() }
      .animation(reduceMotion ? .easeInOut(duration: 0.2) : Motion.gentle, value: viewModel.phase)
      .animation(
        reduceMotion ? .easeInOut(duration: 0.2) : Motion.gentle, value: viewModel.askedCount
      )
      .animation(Motion.snappy, value: viewModel.selectedIndex)
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.phase {
    case .loading:
      ProgressView().tint(Palette.accent)
    case .asking:
      if let question = viewModel.question {
        QuestionPanel(viewModel: viewModel, question: question)
          .transition(.opacity)
      }
    case .finished(let level):
      ResultPanel(
        level: level, correct: viewModel.correctCount, total: viewModel.askedCount,
        onAccept: { onAccept(level) }, onClose: onClose
      )
      .transition(.opacity)
    case .unavailable:
      CenteredPanel {
        Image(systemName: "exclamationmark.magnifyingglass")
          .font(.system(size: 40, weight: .bold))
          .foregroundStyle(Palette.muted)
        Text("Test şu an hazırlanamadı. Seviyeni listeden seçebilirsin.")
          .font(AppFont.body).foregroundStyle(Palette.muted)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      } footer: {
        Button("Seviye listesine dön", action: onClose).buttonStyle(.chunky)
      }
    }
  }
}

/// İçeriği dikeyde ortalayan, sığmazsa kaydırılan ve butonları altta sabit tutan panel.
private struct CenteredPanel<Content: View, Footer: View>: View {
  @ViewBuilder let content: Content
  @ViewBuilder let footer: Footer

  var body: some View {
    ScrollView {
      VStack(spacing: 14) { content }
        .readableWidth()
        .padding(.vertical, 24)
    }
    .scrollIndicators(.hidden)
    .scrollBounceBehavior(.basedOnSize)
    .defaultScrollAnchor(.center, for: .alignment)
    .safeAreaInset(edge: .bottom, spacing: 0) {
      PinnedFooter { footer }
    }
  }
}

/// Soru, şıklar ve devam butonu; uzun içerik kaydırılır, buton altta sabit kalır.
private struct QuestionPanel: View {
  @ObservedObject var viewModel: LevelTestViewModel
  let question: LevelQuestion
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        HStack {
          Text("Soru \(viewModel.askedCount) / \(viewModel.totalQuestions)")
            .font(AppFont.caption)
            .monospacedDigit()
            .foregroundStyle(Palette.muted)
            .contentTransition(.numericText(value: Double(viewModel.askedCount)))
          Spacer()
          Pill(question.level.rawValue, tone: .accent)
        }
        ProgressBar(value: viewModel.progress, height: 6)
        VStack(alignment: .leading, spacing: 16) {
          VStack(alignment: .leading, spacing: 6) {
            Eyebrow("Bu kelimenin anlamı ne?")
            Text(question.word.en).font(AppFont.display).foregroundStyle(Palette.ink)
              .minimumScaleFactor(0.6)
              .lineLimit(1)
          }
          .padding(.top, 6)
          VStack(spacing: 10) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
              Button {
                viewModel.answer(index)
              } label: {
                optionRow(index: index, text: option)
              }
              .buttonStyle(PressScaleButtonStyle())
              .disabled(viewModel.selectedIndex != nil)
            }
          }
        }
        .id(question.id)
        .transition(questionTransition)
      }
      .readableWidth()
      .padding(.top, 8)
      .padding(.bottom, 24)
    }
    .scrollIndicators(.hidden)
    .scrollBounceBehavior(.basedOnSize)
    .safeAreaInset(edge: .bottom, spacing: 0) {
      if viewModel.selectedIndex != nil {
        PinnedFooter {
          Button(viewModel.askedCount >= viewModel.totalQuestions ? "Sonucu gör" : "Devam") {
            viewModel.next()
          }
          .buttonStyle(.chunky)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .sensoryFeedback(trigger: viewModel.selectedIndex) { _, newValue in
      guard newValue != nil else { return nil }
      return viewModel.lastAnswerCorrect == true ? .success : .error
    }
  }

  /// Yeni soru sağdan kayarak gelir; Hareketi Azalt açıksa yalnızca solar.
  private var questionTransition: AnyTransition {
    guard !reduceMotion else { return .opacity }
    return .asymmetric(
      insertion: .offset(x: 48).combined(with: .opacity),
      removal: .opacity)
  }

  /// Şık satırı; cevaptan sonra doğru şık yeşil, yanlış seçim kırmızı görünür.
  private func optionRow(index: Int, text: String) -> some View {
    let state = optionState(index)
    return HStack(spacing: 12) {
      Text(text).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
        .multilineTextAlignment(.leading)
      Spacer(minLength: 8)
      if let symbol = state.symbol {
        Image(systemName: symbol).font(.system(size: 15, weight: .black))
          .foregroundStyle(state.tint)
      }
    }
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
    .contentShape(Rectangle())
    .background(
      RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
        .fill(state.fill)
        .overlay(
          RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
            .strokeBorder(state.tint, lineWidth: 2))
    )
    .accessibilityAddTraits(viewModel.selectedIndex == index ? .isSelected : [])
  }

  /// Şıkkın renkleri ve işareti.
  private func optionState(_ index: Int) -> (fill: Color, tint: Color, symbol: String?) {
    guard let selected = viewModel.selectedIndex else {
      return (Palette.surface, Palette.line, nil)
    }
    if index == question.correctIndex { return (Palette.goodBackground, Palette.good, "checkmark") }
    if index == selected { return (Palette.badBackground, Palette.bad, "xmark") }
    return (Palette.surface, Palette.line, nil)
  }
}

/// Test sonucu ve önerilen seviye.
private struct ResultPanel: View {
  let level: CEFRLevel
  let correct: Int
  let total: Int
  let onAccept: () -> Void
  let onClose: () -> Void
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isShown = false

  var body: some View {
    CenteredPanel {
      Text(level.rawValue)
        .font(AppFont.rounded(34, weight: .black))
        .foregroundStyle(.white)
        .frame(width: 92, height: 92)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Palette.accent))
        .scaleEffect(isShown || reduceMotion ? 1 : 0.5)
        .opacity(isShown ? 1 : 0)
        .padding(.bottom, 4)
      Text("Önerilen seviye: \(level.title)").font(AppFont.title).foregroundStyle(Palette.ink)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      Text("\(total) sorudan \(correct) doğru · \(level.topics)")
        .font(AppFont.body).foregroundStyle(Palette.muted)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    } footer: {
      Button("\(level.rawValue) ile devam et", action: onAccept).buttonStyle(.chunky)
      Button("Kendim seçeceğim", action: onClose).buttonStyle(ChunkyButtonStyle(.ghost))
    }
    .sensoryFeedback(.success, trigger: isShown)
    .onAppear {
      withAnimation(reduceMotion ? .easeOut(duration: 0.25) : Motion.bouncy.delay(0.1)) {
        isShown = true
      }
    }
  }
}
