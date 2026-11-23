import ContentKit
import DesignKit
import SwiftUI
import UserDataKit
import WordKit

/// Kelime Defterim sekmesi.
///
/// Defter yalnızca bulmacalarda yanlış yapılan ya da bilinmeyen kelimelerle dolar; elle ekleme
/// yoktur.
struct NotebookView: View {
  @StateObject var viewModel: NotebookViewModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        header.appearAnimation(index: 0)
        summary.appearAnimation(index: 1)
        SegmentBar(
          NotebookFilter.allCases.map { ($0, viewModel.title(for: $0)) },
          selection: $viewModel.filter
        )
        .appearAnimation(index: 2)
        content.appearAnimation(index: 3)
      }
      .animation(Motion.gentle, value: viewModel.visibleRows.map(\.id))
      .animation(Motion.snappy, value: viewModel.filter)
      .padding(.horizontal, Metrics.gutter)
      .padding(.bottom, 24)
      .frame(maxWidth: 680)
      .frame(maxWidth: .infinity)
    }
    .scrollIndicators(.hidden)
    .statusBarScrim()
    .screenBackground()
    .safeAreaInset(edge: .bottom) { reviewActions }
    .animation(Motion.gentle, value: viewModel.dueCount > 0)
    .task { await viewModel.load() }
    .appBottomSheet(item: $viewModel.detail) { row in detailSheet(row) }
    .alert(
      "Bulmaca hazırlanamadı",
      isPresented: Binding(
        get: { viewModel.notice != nil }, set: { if !$0 { viewModel.notice = nil } })
    ) {
      Button("Tamam", role: .cancel) {}
    } message: {
      Text(viewModel.notice ?? "")
    }
  }

  // MARK: - Sections

  /// Başlık ve defterin nasıl dolduğunu anlatan alt satır.
  private var header: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Kelime Defterim").font(AppFont.title).foregroundStyle(Palette.ink)
      Text("Bulmacalarda yanlış yaptığın ya da bilemediğin kelimeler")
        .font(AppFont.caption).foregroundStyle(Palette.muted)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.top, 8)
  }

  /// Kelime / bugün tekrar / öğrenildi sayıları.
  private var summary: some View {
    HStack(spacing: 0) {
      summaryItem(viewModel.totalCount, "kelime", tint: Palette.ink)
      Rectangle().fill(Palette.line).frame(width: 1, height: 36)
      summaryItem(viewModel.dueCount, "bugün tekrar", tint: Palette.accent)
      Rectangle().fill(Palette.line).frame(width: 1, height: 36)
      summaryItem(viewModel.learnedCount, "öğrenildi", tint: Palette.good)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 6)
    .card(padding: 0)
  }

  /// Özet kartındaki tek sayı.
  private func summaryItem(_ value: Int, _ title: String, tint: Color) -> some View {
    VStack(spacing: 2) {
      Text("\(value)").font(AppFont.rounded(24, weight: .black)).foregroundStyle(tint)
        .contentTransition(.numericText(value: Double(value)))
      Text(title).font(AppFont.tiny.weight(.heavy)).foregroundStyle(Palette.muted)
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .combine)
  }

  /// Seçili bölmenin içeriği: liste ya da boş durum.
  @ViewBuilder
  private var content: some View {
    if viewModel.visibleRows.isEmpty {
      empty
        .id(viewModel.filter)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    } else {
      list.transition(.opacity)
    }
  }

  /// Seçili bölmedeki kelimeler; eklenen / çıkan satırlar kayarak girer, sönerek çıkar.
  private var list: some View {
    VStack(spacing: 0) {
      ForEach(viewModel.visibleRows) { row in
        NotebookRowView(
          row: row, dueLabel: viewModel.dueLabel(row.item),
          onSpeak: { viewModel.speak(row.word) }, onOpen: { viewModel.detail = row }
        )
        .overlay(alignment: .bottom) {
          if row.id != viewModel.visibleRows.last?.id {
            Rectangle().fill(Palette.line).frame(height: 1)
          }
        }
        .transition(
          .asymmetric(
            insertion: .offset(y: -10).combined(with: .opacity),
            removal: .scale(scale: 0.9, anchor: .leading).combined(with: .opacity)))
      }
    }
    .padding(.horizontal, 14)
    .card(padding: 0)
  }

  /// Bulmacayla tekrar eylemi (Çengelish Plus).
  @ViewBuilder
  private var reviewActions: some View {
    if viewModel.dueCount > 0 {
      puzzleReviewButton
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .frame(maxWidth: 680)
        .frame(maxWidth: .infinity)
        .background(Palette.background.opacity(0.94))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
  }

  /// Bulmacayla tekrar butonu: Plus'ta mor, değilse paywall'u açan altın Plus butonu; köşesinde
  /// Plus rozeti.
  @ViewBuilder
  private var puzzleReviewButton: some View {
    let button = Button {
      Task { await viewModel.startPuzzleReview() }
    } label: {
      HStack(spacing: 8) {
        if viewModel.isBuildingPuzzle {
          ProgressView().tint(viewModel.isPlus ? .white : Palette.goldInk)
        } else {
          Image(systemName: "square.grid.3x3.fill")
        }
        Text("\(viewModel.dueCount) kelimeyi bulmacayla tekrar et")
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .contentTransition(.numericText(value: Double(viewModel.dueCount)))
      }
    }
    .disabled(viewModel.isBuildingPuzzle)
    .accessibilityHint(viewModel.isPlus ? "" : "\(PlusBrand.name) gerekir")
    if viewModel.isPlus {
      button.buttonStyle(.chunky).plusCorner(true, inset: -6)
    } else {
      button.buttonStyle(.plus).plusCorner(true, inset: -6)
    }
  }

  /// Bölme boşken gösterilen durum.
  private var empty: some View {
    VStack(spacing: 10) {
      KalemoView(body: .yellow, accessory: .glasses).frame(width: 70, height: 86)
      Text(emptyTitle).font(AppFont.headline).foregroundStyle(Palette.ink)
        .multilineTextAlignment(.center)
      Text(emptyMessage)
        .font(AppFont.caption).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      if viewModel.filter == .all {
        howItWorks.padding(.top, 8)
      }
    }
    .padding(.vertical, 24)
    .padding(.horizontal, 8)
    .frame(maxWidth: .infinity)
  }

  /// Defterin nasıl dolduğunu anlatan üç adım.
  private var howItWorks: some View {
    VStack(alignment: .leading, spacing: 12) {
      step("xmark.circle.fill", tint: Palette.bad, "Cevap anahtarında ✗ çıkan kelimeler eklenir")
      step(
        "questionmark.circle.fill", tint: Palette.streak, "Bilemediğin kelimeler de buraya gelir")
      step(
        "arrow.triangle.2.circlepath.circle.fill", tint: Palette.accent,
        "Zamanı gelince bulmacayla tekrar edersin")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .card(padding: 14)
  }

  /// "Nasıl dolar" kartındaki tek adım.
  private func step(_ icon: String, tint: Color, _ text: String) -> some View {
    HStack(spacing: 10) {
      Image(systemName: icon).font(.system(size: 20, weight: .bold)).foregroundStyle(tint)
        .frame(width: 26)
      Text(text).font(AppFont.caption).foregroundStyle(Palette.ink)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var emptyTitle: String {
    switch viewModel.filter {
    case .all: "Defterin henüz boş"
    case .due: "Bugün tekrar yok"
    case .learned: "Henüz öğrenilen yok"
    }
  }

  private var emptyMessage: String {
    switch viewModel.filter {
    case .all:
      "Bulmacalarda yanlış yaptığın ya da bilemediğin kelimeler buraya kendiliğinden gelir."
    case .due: "Tekrar zamanı gelen kelimeler burada görünür."
    case .learned: "Kutu 5'i geçen ya da Öğrendim dediğin kelimeler burada toplanır."
    }
  }

  /// Kelime detay paneli; `appBottomSheet` içinde düz içerik olarak gösterilir.
  private func detailSheet(_ row: NotebookRow) -> some View {
    WordDetailSheet(
      word: row.word, onSpeak: { viewModel.speak(row.word) }, accent: viewModel.accent,
      onSpeakAccent: { viewModel.speak(row.word, accent: $0) },
      notebook: WordNotebookStatus(
        firstSeen: viewModel.firstSeen(row.item), box: row.item.box,
        maxBox: LeitnerRules.maxBox, learned: row.item.learned,
        onKeepReviewing: { viewModel.setLearned(row, learned: false) },
        onLearned: { viewModel.setLearned(row, learned: true) },
        onRemove: { viewModel.remove(row) }))
  }
}

/// Defter satırı: telaffuz, kelime ve anlam, tekrar zamanı ve kutu ilerlemesi.
private struct NotebookRowView: View {
  let row: NotebookRow
  let dueLabel: String
  let onSpeak: () -> Void
  let onOpen: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      SpeakerButton(word: row.word.en, action: onSpeak)
      Button(action: onOpen) {
        HStack(spacing: 8) {
          VStack(alignment: .leading, spacing: 2) {
            Text(row.word.en).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
            Text(row.word.meaning).font(AppFont.caption).foregroundStyle(Palette.muted)
              .lineLimit(1)
          }
          Spacer(minLength: 4)
          VStack(alignment: .trailing, spacing: 5) {
            Text(dueLabel).font(AppFont.caption)
              .foregroundStyle(row.item.isDue() ? Palette.accent : Palette.muted)
            BoxDots(
              box: row.item.learned ? LeitnerRules.maxBox : row.item.box,
              maxBox: LeitnerRules.maxBox)
          }
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(PressScaleButtonStyle())
      .accessibilityHint("Kelime detayını açar")
    }
    .padding(.vertical, 11)
  }
}
