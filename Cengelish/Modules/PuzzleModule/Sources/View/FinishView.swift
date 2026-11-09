import ContentKit
import DesignKit
import SwiftUI
import UserDataKit
import WordKit

/// Bitiş ekranı.
struct FinishView: View {
  @StateObject var viewModel: FinishViewModel

  var body: some View {
    VStack(spacing: 0) {
      NavHeader("", leadingSymbol: "xmark", onLeading: viewModel.home) {
        Button(action: viewModel.share) { IconCircle("square.and.arrow.up") }
          .buttonStyle(.plain)
          .accessibilityLabel("Paylaş")
      }
      scroll
    }
    .safeAreaInset(edge: .bottom) { bottomBar }
    .screenBackground()
  }

  private var scroll: some View {
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
      .padding(.bottom, 12)
      .frame(maxWidth: 640)
      .frame(maxWidth: .infinity)
    }
  }

  private var bottomBar: some View {
    HStack(spacing: 10) {
      Button(action: viewModel.share) {
        Label("Paylaş", systemImage: "square.and.arrow.up")
      }
      .buttonStyle(.chunkySecondary)
      Button(viewModel.hasNext ? "Sonraki bulmaca" : "Ana sayfaya dön", action: viewModel.next)
        .buttonStyle(.chunky)
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.vertical, 8)
    .frame(maxWidth: 640)
    .frame(maxWidth: .infinity)
    .background(Palette.background)
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
}
