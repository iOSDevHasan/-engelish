import ContentKit
import DesignKit
import SwiftUI

/// Kısa seviye testi: İngilizce kelime, dört Türkçe anlam; sonunda önerilen seviye.
struct LevelTestView: View {
  @ObservedObject var viewModel: LevelTestViewModel
  let onAccept: (CEFRLevel) -> Void
  let onClose: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      NavHeader("Seviye testi", leadingSymbol: "xmark", onLeading: onClose)
      content
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 16)
        .frame(maxWidth: 560, maxHeight: .infinity, alignment: .top)
        .frame(maxWidth: .infinity)
    }
    .screenBackground()
    .task { await viewModel.start() }
    .animation(.snappy, value: viewModel.askedCount)
    .animation(.snappy, value: viewModel.selectedIndex)
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.phase {
    case .loading:
      ProgressView().tint(Palette.accent).frame(maxHeight: .infinity)
    case .asking:
      if let question = viewModel.question {
        QuestionPanel(viewModel: viewModel, question: question)
      }
    case .finished(let level):
      ResultPanel(
        level: level, correct: viewModel.correctCount, total: viewModel.askedCount,
        onAccept: { onAccept(level) }, onClose: onClose)
    case .unavailable:
      VStack(spacing: 14) {
        Spacer()
        Text("Test şu an hazırlanamadı. Seviyeni listeden seçebilirsin.")
          .font(AppFont.body).foregroundStyle(Palette.muted)
          .multilineTextAlignment(.center)
        Button("Seviye listesine dön", action: onClose).buttonStyle(.chunky)
      }
    }
  }
}

/// Soru, şıklar ve devam butonu.
private struct QuestionPanel: View {
  @ObservedObject var viewModel: LevelTestViewModel
  let question: LevelQuestion

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Soru \(viewModel.askedCount) / \(viewModel.totalQuestions)")
          .font(AppFont.caption).foregroundStyle(Palette.muted)
        Spacer()
        Pill(question.level.rawValue, tone: .accent)
      }
      ProgressBar(value: viewModel.progress, height: 6)
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
          .buttonStyle(.plain)
          .disabled(viewModel.selectedIndex != nil)
        }
      }
      Spacer(minLength: 0)
      if viewModel.selectedIndex != nil {
        Button(viewModel.askedCount >= viewModel.totalQuestions ? "Sonucu gör" : "Devam") {
          viewModel.next()
        }
        .buttonStyle(.chunky)
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .padding(.top, 4)
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

  var body: some View {
    VStack(spacing: 14) {
      Spacer()
      Text(level.rawValue)
        .font(AppFont.rounded(34, weight: .black))
        .foregroundStyle(.white)
        .frame(width: 92, height: 92)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Palette.accent))
      Text("Önerilen seviye: \(level.title)").font(AppFont.title).foregroundStyle(Palette.ink)
        .multilineTextAlignment(.center)
      Text("\(total) sorudan \(correct) doğru · \(level.topics)")
        .font(AppFont.body).foregroundStyle(Palette.muted)
        .multilineTextAlignment(.center)
      Spacer()
      Button("\(level.rawValue) ile devam et", action: onAccept).buttonStyle(.chunky)
      Button("Kendim seçeceğim", action: onClose).buttonStyle(ChunkyButtonStyle(.ghost))
    }
  }
}
