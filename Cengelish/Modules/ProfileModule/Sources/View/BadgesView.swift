import DesignKit
import SwiftUI
import UserDataKit

/// Rozet koleksiyonu, vitrin seçimi ve sıradaki ödüller.
struct BadgesView: View {
  @StateObject var viewModel: ProfileViewModel

  var body: some View {
    VStack(spacing: 0) {
      NavHeader("Rozetler", onLeading: viewModel.back) {
        Pill("\(viewModel.earned.count) / \(BadgeKind.allCases.count)", tone: .accent)
      }
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          if !viewModel.earned.isEmpty {
            HStack {
              Text("Kazanılanlar").font(AppFont.section).foregroundStyle(Palette.ink)
              Spacer()
              Text("Vitrine eklemek için dokun").font(AppFont.caption).foregroundStyle(
                Palette.muted)
            }
            LazyVGrid(
              columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10
            ) {
              ForEach(viewModel.earned, id: \.self) { badge in
                Button {
                  viewModel.toggleShowcase(badge)
                } label: {
                  earnedTile(badge)
                }
                .buttonStyle(.plain)
              }
            }
          }
          Text("Sıradakiler").font(AppFont.section).foregroundStyle(Palette.ink)
          ForEach(viewModel.upcoming, id: \.self) { badge in
            HStack(spacing: 12) {
              MedalView(systemImage: badge.symbol, color: badge.color, size: 48, isLocked: true)
              VStack(alignment: .leading, spacing: 4) {
                HStack {
                  Text(badge.title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
                  Spacer()
                  if let progress = badge.progress(viewModel.stats) {
                    Text("\(progress.current)/\(progress.target)").font(AppFont.caption)
                      .foregroundStyle(Palette.muted)
                  }
                }
                if let progress = badge.progress(viewModel.stats) {
                  ProgressBar(
                    value: Double(progress.current) / Double(progress.target), tint: Palette.streak,
                    height: 6)
                } else {
                  Text(badge.detail).font(AppFont.caption).foregroundStyle(Palette.muted)
                }
                if let reward = badge.reward {
                  Text("Ödül: \(reward)").font(AppFont.tiny).foregroundStyle(Palette.muted)
                }
              }
            }
            .card(padding: 12)
          }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 30)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
      }
    }
    .screenBackground()
  }

  private func earnedTile(_ badge: BadgeKind) -> some View {
    let pinned = viewModel.showcase.contains(badge)
    return VStack(spacing: 6) {
      MedalView(systemImage: badge.symbol, color: badge.color, size: 54)
        .overlay(alignment: .topTrailing) {
          if pinned {
            Image(systemName: "pin.fill").font(.system(size: 10, weight: .bold))
              .foregroundStyle(.white)
              .frame(width: 22, height: 22)
              .background(Circle().fill(Palette.accent))
              .offset(x: 6, y: -4)
          }
        }
      Text(badge.title).font(AppFont.tiny).foregroundStyle(Palette.ink)
      Text(viewModel.dateText(badge)).font(.system(size: 9, weight: .bold, design: .rounded))
        .foregroundStyle(Palette.muted)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .background(RoundedRectangle(cornerRadius: 18).fill(Palette.surface))
    .accessibilityLabel("\(badge.title)\(pinned ? ", vitrinde" : "")")
  }
}
