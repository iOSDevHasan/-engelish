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
      VStack(alignment: .leading, spacing: 16) {
        Text("Kelime Defterim").font(AppFont.title).foregroundStyle(Palette.ink).padding(.top, 8)
        boxes
        if viewModel.dueCount > 0 {
          Button("Tekrara başla (\(viewModel.dueCount))", action: viewModel.startReview)
            .buttonStyle(.chunky)
        }
        Picker("Filtre", selection: $viewModel.filter) {
          ForEach(NotebookFilter.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        if viewModel.visibleRows.isEmpty {
          empty
        } else {
          VStack(spacing: 0) {
            ForEach(viewModel.visibleRows) { row in
              Button {
                viewModel.detail = row
              } label: {
                rowView(row)
              }
              .buttonStyle(.plain)
              Divider().overlay(Palette.line)
            }
          }
          .card(padding: 4)
        }
      }
      .padding(.horizontal, Metrics.gutter)
      .padding(.bottom, 24)
      .frame(maxWidth: 680)
      .frame(maxWidth: .infinity)
    }
    .screenBackground()
    .task { await viewModel.load() }
    .sheet(item: $viewModel.detail) { row in
      WordDetailSheet(
        word: row.word, boxLabel: LeitnerRules.label(box: row.item.box, learned: row.item.learned),
        onSpeak: { viewModel.speak(row.word) }, primaryTitle: "Defterden çıkar",
        onPrimary: { viewModel.remove(row) })
    }
    .fullScreenCover(isPresented: $viewModel.isReviewing) {
      ReviewView(viewModel: viewModel)
    }
  }

  private var boxes: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("Aralıklı tekrar").font(AppFont.section).foregroundStyle(Palette.ink)
        Spacer()
        Text("1 · 3 · 7 · 14 · 30 gün").font(AppFont.tiny).foregroundStyle(Palette.muted)
      }
      HStack(spacing: 8) {
        ForEach(0..<5, id: \.self) { index in
          VStack(spacing: 2) {
            Text("\(viewModel.boxCounts[index])").font(AppFont.headline)
            Text("Kutu \(index + 1)").font(AppFont.tiny)
          }
          .foregroundStyle(Palette.ink)
          .frame(maxWidth: .infinity, minHeight: 64)
          .background(RoundedRectangle(cornerRadius: 16).fill(Palette.pastels[index]))
        }
      }
    }
    .card()
  }

  private func rowView(_ row: NotebookRow) -> some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(row.word.en).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
        Text(row.word.meaning).font(AppFont.caption).foregroundStyle(Palette.muted)
      }
      Spacer()
      Pill(
        viewModel.dueLabel(row.item),
        tone: row.item.isDue() ? .bad : row.item.learned ? .good : .neutral)
      Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
        .foregroundStyle(Palette.lineStrong)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 12)
    .contentShape(Rectangle())
  }

  private var empty: some View {
    VStack(spacing: 10) {
      KalemoView(body: .yellow, accessory: .glasses).frame(width: 70, height: 86)
      Text(viewModel.filter == .due ? "Bugün tekrar yok" : "Defterin boş")
        .font(AppFont.headline).foregroundStyle(Palette.ink)
      Text(
        "Cevap anahtarında yanlış işaretlediğin kelimeler buraya gelir. Bitiş ekranından da ekleyebilirsin."
      )
      .font(AppFont.caption).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
    }
    .padding(24)
    .frame(maxWidth: .infinity)
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
            Text(card.word.ipa).font(AppFont.body).foregroundStyle(Palette.muted)
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
