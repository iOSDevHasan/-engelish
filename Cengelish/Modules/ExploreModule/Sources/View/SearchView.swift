import ContentKit
import DesignKit
import SwiftUI
import WordKit

/// Keşfet araması: paketler ve kelimeler.
struct SearchView: View {
  @StateObject var viewModel: SearchViewModel
  @FocusState private var isFieldFocused: Bool

  var body: some View {
    VStack(spacing: 0) {
      searchBar
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          if viewModel.isQueryEmpty {
            hint(
              "Paket ya da kelime ara", detail: "İngilizce kelime ya da Türkçe anlam yazabilirsin.")
          } else if viewModel.hasNoResults {
            if viewModel.isLoading {
              ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
            } else {
              hint("Sonuç bulunamadı", detail: "Başka bir kelime ya da paket adı dene.")
            }
          } else {
            packSection
            wordSection
          }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .frame(maxWidth: 680)
        .frame(maxWidth: .infinity)
      }
      .scrollDismissesKeyboard(.interactively)
    }
    .screenBackground()
    .task { await viewModel.load() }
    .onAppear { isFieldFocused = true }
    .sheet(item: $viewModel.selectedWord) { word in
      let inNotebook = viewModel.isInNotebook(word)
      WordDetailSheet(
        word: word, boxLabel: inNotebook ? "Defterde" : nil, onSpeak: { viewModel.speak(word) },
        primaryTitle: inNotebook ? nil : "Deftere ekle",
        onPrimary: inNotebook ? nil : { viewModel.addToNotebook(word) })
    }
  }

  // MARK: - Search bar

  /// Geri butonu ve arama alanı.
  private var searchBar: some View {
    HStack(spacing: 10) {
      Button(action: viewModel.back) { IconCircle("chevron.left") }
        .buttonStyle(.plain)
        .accessibilityLabel("Geri")
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass").font(.system(size: 15, weight: .bold))
          .foregroundStyle(Palette.muted)
        TextField("Paket ya da kelime ara", text: $viewModel.query)
          .font(AppFont.body)
          .foregroundStyle(Palette.ink)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .submitLabel(.search)
          .focused($isFieldFocused)
        if !viewModel.query.isEmpty {
          Button {
            viewModel.query = ""
          } label: {
            Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.muted)
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Temizle")
        }
      }
      .padding(.horizontal, 14)
      .frame(height: 40)
      .background(Capsule().fill(Palette.surface2))
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.top, 4)
    .padding(.bottom, 6)
  }

  // MARK: - Results

  /// Eşleşen paketler.
  @ViewBuilder private var packSection: some View {
    let packs = viewModel.packResults
    if !packs.isEmpty {
      VStack(alignment: .leading, spacing: 8) {
        SectionHeader("Paketler") { EmptyView() }
        VStack(spacing: 0) {
          ForEach(packs) { card in
            Button {
              viewModel.open(card)
            } label: {
              PackResultRow(card: card)
            }
            .buttonStyle(.plain)
            if card.id != packs.last?.id { Divider().overlay(Palette.line) }
          }
        }
        .card(padding: 4)
      }
    }
  }

  /// Eşleşen kelimeler.
  @ViewBuilder private var wordSection: some View {
    let words = viewModel.wordResults
    if !words.isEmpty {
      VStack(alignment: .leading, spacing: 8) {
        SectionHeader("Kelimeler") {
          Text("\(words.count)").font(AppFont.caption).foregroundStyle(Palette.muted)
        }
        VStack(spacing: 0) {
          ForEach(words) { word in
            WordRow(word: word, onSpeak: { viewModel.speak(word) }) {
              Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                .foregroundStyle(Palette.lineStrong)
                .padding(.top, 10)
            }
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .onTapGesture { viewModel.select(word) }
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Detayı aç") { viewModel.select(word) }
            if word.id != words.last?.id { Divider().overlay(Palette.line) }
          }
        }
        .card(padding: 4)
      }
    }
  }

  /// Boş durum metni.
  private func hint(_ title: String, detail: String) -> some View {
    VStack(spacing: 6) {
      Image(systemName: "magnifyingglass").font(.system(size: 28, weight: .bold))
        .foregroundStyle(Palette.lineStrong)
      Text(title).font(AppFont.headline).foregroundStyle(Palette.ink)
      Text(detail).font(AppFont.caption).foregroundStyle(Palette.muted)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 48)
  }
}

/// Arama sonucundaki paket satırı.
private struct PackResultRow: View {
  let card: PackCard

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 3) {
        Eyebrow(PackRules.eyebrow(for: card.pack.kind))
        Text(card.pack.title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
        Text("\(card.puzzleCount) bulmaca · \(card.pack.subtitle)")
          .font(AppFont.caption).foregroundStyle(Palette.muted).lineLimit(2)
      }
      Spacer()
      if card.isLocked {
        Image(systemName: "lock.fill").font(.system(size: 13, weight: .bold))
          .foregroundStyle(Palette.muted)
      }
      Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
        .foregroundStyle(Palette.lineStrong)
    }
    .padding(12)
    .contentShape(Rectangle())
  }
}
