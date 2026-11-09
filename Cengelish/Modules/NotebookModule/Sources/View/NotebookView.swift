import ContentKit
import DesignKit
import SwiftUI
import UserDataKit
import WordKit

/// Kelime Defterim sekmesi.
struct NotebookView: View {
  @StateObject var viewModel: NotebookViewModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        header
        summary
        SegmentBar(
          NotebookFilter.allCases.map { ($0, viewModel.title(for: $0)) },
          selection: $viewModel.filter)
        if viewModel.visibleRows.isEmpty {
          empty
        } else {
          list
        }
      }
      .padding(.horizontal, Metrics.gutter)
      .padding(.bottom, 24)
      .frame(maxWidth: 680)
      .frame(maxWidth: .infinity)
    }
    .screenBackground()
    .safeAreaInset(edge: .bottom) { reviewActions }
    .task { await viewModel.load() }
    .sheet(item: $viewModel.detail) { row in detailSheet(row) }
    .sheet(isPresented: $viewModel.isAddingWord) { AddWordSheet(viewModel: viewModel) }
    .fullScreenCover(isPresented: $viewModel.isReviewing) {
      ReviewView(viewModel: viewModel)
    }
    .alert(
      "Bulmaca hazırlanamadı",
      isPresented: Binding(
        get: { viewModel.notice != nil }, set: { if !$0 { viewModel.notice = nil } })
    ) {
      Button("Kartla tekrar et") { viewModel.startReview() }
      Button("Tamam", role: .cancel) {}
    } message: {
      Text(viewModel.notice ?? "")
    }
  }

  // MARK: - Sections

  /// Başlık ve kelime ekleme butonu.
  private var header: some View {
    HStack {
      Text("Kelime Defterim").font(AppFont.title).foregroundStyle(Palette.ink)
      Spacer()
      Button {
        Task { await viewModel.startAdding() }
      } label: {
        Image(systemName: "plus")
          .font(.system(size: 17, weight: .bold))
          .foregroundStyle(Palette.ink)
          .frame(width: 40, height: 40)
          .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.surface2))
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Kelime ekle")
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
      summaryItem(viewModel.learnedCount, "öğrenildi", tint: Palette.ink)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 6)
    .card(padding: 0)
  }

  /// Özet kartındaki tek sayı.
  private func summaryItem(_ value: Int, _ title: String, tint: Color) -> some View {
    VStack(spacing: 2) {
      Text("\(value)").font(AppFont.rounded(24, weight: .black)).foregroundStyle(tint)
        .contentTransition(.numericText())
      Text(title).font(AppFont.tiny.weight(.heavy)).foregroundStyle(Palette.muted)
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .combine)
  }

  /// Seçili bölmedeki kelimeler.
  private var list: some View {
    VStack(spacing: 0) {
      ForEach(viewModel.visibleRows) { row in
        NotebookRowView(
          row: row, dueLabel: viewModel.dueLabel(row.item),
          onSpeak: { viewModel.speak(row.word) }, onOpen: { viewModel.detail = row })
        if row.id != viewModel.visibleRows.last?.id {
          Rectangle().fill(Palette.line).frame(height: 1)
        }
      }
    }
    .padding(.horizontal, 14)
    .card(padding: 0)
  }

  /// Bulmacayla tekrar (Çengelish+) ve kartla tekrar eylemleri.
  @ViewBuilder
  private var reviewActions: some View {
    if viewModel.dueCount > 0 {
      VStack(spacing: 4) {
        Button {
          Task { await viewModel.startPuzzleReview() }
        } label: {
          HStack(spacing: 8) {
            if viewModel.isBuildingPuzzle {
              ProgressView().tint(.white)
            } else {
              Image(systemName: "square.grid.3x3.fill")
            }
            Text("\(viewModel.dueCount) kelimeyi bulmacayla tekrar et").lineLimit(1)
          }
        }
        .buttonStyle(.chunky)
        .disabled(viewModel.isBuildingPuzzle)
        Button("Kartla tekrar", action: viewModel.startReview)
          .buttonStyle(ChunkyButtonStyle(.ghost, compact: true))
      }
      .padding(.horizontal, Metrics.gutter)
      .padding(.top, 8)
      .frame(maxWidth: 680)
      .frame(maxWidth: .infinity)
      .background(Palette.background.opacity(0.92))
    }
  }

  /// Bölme boşken gösterilen durum.
  private var empty: some View {
    VStack(spacing: 10) {
      KalemoView(body: .yellow, accessory: .glasses).frame(width: 70, height: 86)
      Text(emptyTitle).font(AppFont.headline).foregroundStyle(Palette.ink)
      Text(emptyMessage)
        .font(AppFont.caption).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
      if viewModel.filter == .all {
        Button("Kelime ekle") { Task { await viewModel.startAdding() } }
          .buttonStyle(ChunkyButtonStyle(.secondary, fullWidth: false, compact: true))
          .padding(.top, 4)
      }
    }
    .padding(24)
    .frame(maxWidth: .infinity)
  }

  private var emptyTitle: String {
    switch viewModel.filter {
    case .all: "Defterin boş"
    case .due: "Bugün tekrar yok"
    case .learned: "Henüz öğrenilen yok"
    }
  }

  private var emptyMessage: String {
    switch viewModel.filter {
    case .all:
      "Cevap anahtarında yanlış işaretlediğin kelimeler buraya gelir. "
        + "Bitiş ekranından ya da + ile de ekleyebilirsin."
    case .due: "Tekrar zamanı gelen kelimeler burada görünür."
    case .learned: "Kutu 5'i geçen ya da Öğrendim dediğin kelimeler burada toplanır."
    }
  }

  /// Kelime detay paneli.
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
      .buttonStyle(.plain)
      .accessibilityHint("Kelime detayını açar")
    }
    .padding(.vertical, 11)
  }
}

/// Havuzdan kelime arayıp elle deftere ekleme paneli.
private struct AddWordSheet: View {
  @ObservedObject var viewModel: NotebookViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      List(viewModel.searchResults) { word in
        let added = viewModel.isInNotebook(word)
        Button {
          viewModel.add(word)
        } label: {
          HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
              Text(word.en).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
              Text(word.meaning).font(AppFont.caption).foregroundStyle(Palette.muted)
                .lineLimit(1)
            }
            Spacer()
            Pill(word.level.rawValue)
            Image(systemName: added ? "checkmark.circle.fill" : "plus.circle.fill")
              .font(.system(size: 22, weight: .bold))
              .foregroundStyle(added ? Palette.good : Palette.accent)
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(added)
        .accessibilityLabel(added ? "\(word.en), defterde" : "\(word.en) ekle")
        .listRowBackground(Palette.surface)
      }
      .scrollContentBackground(.hidden)
      .background(Palette.background)
      .overlay {
        if viewModel.searchResults.isEmpty {
          ContentUnavailableView.search(text: viewModel.query)
        }
      }
      .searchable(
        text: $viewModel.query, placement: .navigationBarDrawer(displayMode: .always),
        prompt: "İngilizce ya da Türkçe ara"
      )
      .navigationTitle("Kelime ekle")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Bitti") { dismiss() }
        }
      }
    }
    .sensoryFeedback(.success, trigger: viewModel.totalCount)
    .presentationDragIndicator(.visible)
  }
}

/// Tekrar kartları: Türkçe anlam → İngilizce kelime.
private struct ReviewView: View {
  @ObservedObject var viewModel: NotebookViewModel

  var body: some View {
    VStack(spacing: 20) {
      HStack {
        Button {
          viewModel.isReviewing = false
        } label: {
          IconCircle("xmark")
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tekrarı bitir")
        Spacer()
        Text("\(viewModel.reviewQueue.count) kart kaldı").font(AppFont.caption)
          .foregroundStyle(Palette.muted)
      }
      Spacer()
      if let card = viewModel.currentCard {
        VStack(spacing: 14) {
          Eyebrow("Türkçesi")
          Text(card.word.meaning).font(AppFont.title).foregroundStyle(Palette.ink)
            .multilineTextAlignment(.center)
          Text("\(card.word.en.count) harf").font(AppFont.caption).foregroundStyle(Palette.muted)
          if viewModel.isRevealed {
            Divider().overlay(Palette.line)
            Text(card.word.en).font(AppFont.display).foregroundStyle(Palette.accent)
            Text(card.word.ipa(british: viewModel.accent.isBritish)).font(AppFont.body)
              .foregroundStyle(Palette.muted)
            Text(card.word.example).font(AppFont.body.italic()).foregroundStyle(Palette.ink)
              .multilineTextAlignment(.center)
          }
        }
        .frame(maxWidth: .infinity)
        .card(padding: 24)
        .onTapGesture(perform: viewModel.reveal)
      }
      Spacer()
      if viewModel.isRevealed {
        HStack(spacing: 10) {
          Button("Bilmiyorum") { viewModel.answer(knew: false) }.buttonStyle(.chunkySecondary)
          Button("Biliyorum") { viewModel.answer(knew: true) }.buttonStyle(.chunky)
        }
      } else {
        Button("Cevabı göster", action: viewModel.reveal).buttonStyle(.chunky)
      }
    }
    .padding(Metrics.gutter)
    .frame(maxWidth: 560)
    .frame(maxWidth: .infinity)
    .screenBackground()
  }
}
