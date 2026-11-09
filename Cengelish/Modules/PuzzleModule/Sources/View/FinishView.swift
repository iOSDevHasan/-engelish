import ContentKit
import DesignKit
import PuzzleKit
import SwiftUI
import UserDataKit
import WordKit

/// Bitiş ekranı.
struct FinishView: View {
  @StateObject var viewModel: FinishViewModel
  let theme: (ColorScheme) -> PuzzleTheme
  @Environment(\.colorScheme) private var scheme
  @State private var shareImage: Image?

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        hero
        stats
        if !viewModel.result.newBadges.isEmpty { badges }
        VStack(alignment: .leading, spacing: 0) {
          HStack {
            Text("Bu bulmacanın kelimeleri").font(AppFont.section).foregroundStyle(Palette.ink)
            Spacer()
            Text("\(viewModel.words.count) kelime").font(AppFont.caption).foregroundStyle(
              Palette.muted)
          }
          .padding(.bottom, 4)
          ForEach(viewModel.words) { word in
            WordRow(word: word, onSpeak: { viewModel.speak(word) }) {
              Button {
                viewModel.toggleNotebook(word)
              } label: {
                Pill(
                  viewModel.notebookIds.contains(word.id) ? "Defterde" : "Deftere ekle",
                  systemImage: viewModel.notebookIds.contains(word.id) ? "bookmark.fill" : "plus",
                  tone: viewModel.notebookIds.contains(word.id) ? .bad : .neutral)
              }
              .buttonStyle(.plain)
            }
            Divider().overlay(Palette.line)
          }
        }
        .card()
      }
      .padding(.horizontal, Metrics.gutter)
      .padding(.vertical, 12)
      .frame(maxWidth: 640)
      .frame(maxWidth: .infinity)
    }
    .safeAreaInset(edge: .bottom) {
      HStack(spacing: 10) {
        if let shareImage {
          ShareLink(
            item: shareImage,
            preview: SharePreview("Çengelish sonucum", image: shareImage)
          ) {
            Label("Paylaş", systemImage: "square.and.arrow.up")
          }
          .buttonStyle(.chunkySecondary)
        }
        Button(viewModel.hasNext ? "Sonraki bulmaca" : "Ana sayfaya dön", action: viewModel.next)
          .buttonStyle(.chunky)
      }
      .padding(.horizontal, Metrics.gutter)
      .padding(.vertical, 8)
      .frame(maxWidth: 640)
      .background(Palette.background)
    }
    .screenBackground()
    .task { renderShareCard() }
  }

  private var hero: some View {
    VStack(spacing: 8) {
      AvatarView(viewModel.avatar, size: 96)
      Text(viewModel.headline).font(AppFont.title).foregroundStyle(Palette.ink)
      HStack(spacing: 4) {
        ForEach(0..<3, id: \.self) { index in
          Image(systemName: index < viewModel.result.stars ? "star.fill" : "star")
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(index < viewModel.result.stars ? Palette.gold : Palette.lineStrong)
        }
      }
      .accessibilityLabel("\(viewModel.result.stars) yıldız")
    }
    .padding(.top, 12)
  }

  private var stats: some View {
    HStack(spacing: 10) {
      tile("\(viewModel.result.correct)/\(viewModel.result.total)", "doğru", Palette.good)
      tile(viewModel.durationText, "süre", Palette.accent)
      tile("\(viewModel.result.streak)", "gün seri", Palette.streak)
    }
  }

  private func tile(_ value: String, _ label: String, _ color: Color) -> some View {
    VStack(spacing: 2) {
      Text(value).font(AppFont.headline).foregroundStyle(color)
      Text(label).font(AppFont.tiny).foregroundStyle(Palette.muted)
    }
    .frame(maxWidth: .infinity)
    .card(padding: 12)
  }

  private var badges: some View {
    VStack(alignment: .leading, spacing: 10) {
      Eyebrow("Yeni rozet")
      ForEach(viewModel.result.newBadges, id: \.self) { badge in
        HStack(spacing: 12) {
          MedalView(systemImage: badge.symbol, color: badge.color, size: 48)
          VStack(alignment: .leading, spacing: 2) {
            Text(badge.title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
            Text(badge.reward.map { "Ödül: \($0)" } ?? badge.detail).font(AppFont.caption)
              .foregroundStyle(Palette.muted)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .card()
  }

  /// Paylaşım kartını resme çevirir (cevaplar görünmez).
  @MainActor
  private func renderShareCard() {
    let card = ShareCardView(
      layout: viewModel.session.layout, title: viewModel.session.title, avatar: viewModel.avatar,
      name: viewModel.name, result: viewModel.result, duration: viewModel.durationText)
    let renderer = ImageRenderer(content: card)
    renderer.scale = 3
    if let image = renderer.uiImage {
      shareImage = Image(uiImage: image)
    }
  }
}

/// Paylaşım kartı: dolu kutular, avatar ve sonuç; cevaplar gösterilmez.
struct ShareCardView: View {
  let layout: CrosswordLayout
  let title: String
  let avatar: AvatarConfig
  let name: String
  let result: FinishResult
  let duration: String

  var body: some View {
    VStack(spacing: 14) {
      HStack(spacing: 10) {
        AvatarView(avatar, size: 48)
        VStack(alignment: .leading, spacing: 2) {
          Text(name).font(AppFont.bodyBold)
          Text(title).font(AppFont.caption).opacity(0.85)
        }
        Spacer()
        Text(String(repeating: "★", count: result.stars)).font(AppFont.headline)
          .foregroundStyle(Color(hex: 0xFFC93C))
      }
      PuzzleGridView(
        layout: layout, theme: shareTheme, cellSize: 22,
        letters: Dictionary(uniqueKeysWithValues: layout.letterCells.map { ($0, ("·", .filled)) }),
        showsClueText: false)
      HStack {
        Text("\(result.correct)/\(result.total) doğru · \(duration) · \(result.streak) gün seri")
          .font(AppFont.caption)
        Spacer()
      }
      Text("Sen de çöz → Çengelish").font(AppFont.bodyBold)
    }
    .foregroundStyle(.white)
    .padding(22)
    .frame(width: 340)
    .background(
      LinearGradient(
        colors: [Color(hex: 0x6C5CE7), Color(hex: 0x8E7BFF)], startPoint: .topLeading,
        endPoint: .bottomTrailing)
    )
    .environment(\.colorScheme, .light)
  }

  private var shareTheme: PuzzleTheme {
    PuzzleTheme(
      id: "share", name: "", detail: "", isPremium: false, cell: .white.opacity(0.25),
      clue: .white.opacity(0.15), clueInk: .white, line: .clear, pen: Color(hex: 0xFFC93C),
      pencil: .white, blank: .clear, stripedBlanks: false, highlight: .white.opacity(0.25),
      active: .white, activeRing: nil, arrow: .white, gap: 3, border: 0, cornerRatio: 0.2,
      keyInk: .white)
  }
}
