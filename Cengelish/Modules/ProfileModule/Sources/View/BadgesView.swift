import DesignKit
import SwiftUI
import UserDataKit

/// Rozet koleksiyonu, vitrin seçimi ve sıradaki ödüller.
struct BadgesView: View {
  @StateObject var viewModel: ProfileViewModel

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

  var body: some View {
    VStack(spacing: 0) {
      NavHeader("Rozetler", onLeading: viewModel.back) {
        Pill("\(viewModel.earned.count) / \(BadgeKind.allCases.count)", tone: .accent)
      }
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          showcaseCard
          if !viewModel.earned.isEmpty { earnedSection }
          if !viewModel.upcoming.isEmpty {
            Text("Sıradakiler").font(AppFont.section).foregroundStyle(Palette.ink)
            ForEach(viewModel.upcoming, id: \.self) { badge in upcomingRow(badge) }
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

  // MARK: - Showcase

  private var showcaseCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("Profil vitrini").font(AppFont.bodyBold).foregroundStyle(Palette.ink)
        Spacer()
        Text("\(ProfileViewModel.showcaseLimit) rozet seç").font(AppFont.caption)
          .foregroundStyle(Palette.muted)
      }
      HStack(spacing: 8) {
        ForEach(0..<ProfileViewModel.showcaseLimit, id: \.self) { index in
          let showcase = viewModel.showcase
          if index < showcase.count {
            Button {
              viewModel.toggleShowcase(showcase[index])
            } label: {
              VStack(spacing: 6) {
                medal(showcase[index], size: 56, pinned: true)
                Text(showcase[index].title).font(AppFont.rounded(11.5, weight: .black))
                  .foregroundStyle(Palette.ink)
                  .multilineTextAlignment(.center)
              }
              .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(showcase[index].title), vitrinden çıkar")
          } else {
            emptySlot
          }
        }
      }
    }
    .card()
  }

  private var emptySlot: some View {
    VStack(spacing: 6) {
      Circle()
        .strokeBorder(Palette.lineStrong, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
        .frame(width: 56, height: 56)
        .overlay(Image(systemName: "plus").font(.system(size: 16, weight: .bold)))
        .foregroundStyle(Palette.muted)
      Text("Boş").font(AppFont.rounded(11.5, weight: .black)).foregroundStyle(Palette.muted)
    }
    .frame(maxWidth: .infinity)
    .accessibilityLabel("Boş vitrin yeri")
  }

  // MARK: - Earned

  private var earnedSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("Kazanılanlar").font(AppFont.section).foregroundStyle(Palette.ink)
        Spacer()
        Text("Vitrine eklemek için dokun").font(AppFont.caption).foregroundStyle(Palette.muted)
      }
      LazyVGrid(columns: columns, spacing: 10) {
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
  }

  private func earnedTile(_ badge: BadgeKind) -> some View {
    let pinned = viewModel.showcase.contains(badge)
    return VStack(spacing: 6) {
      medal(badge, size: 44, pinned: pinned)
      Text(badge.title).font(AppFont.rounded(11.5, weight: .black)).foregroundStyle(Palette.ink)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
      Text(viewModel.dateText(badge)).font(AppFont.rounded(9.5, weight: .bold))
        .foregroundStyle(Palette.muted)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 12)
    .padding(.bottom, 10)
    .padding(.horizontal, 6)
    .card(padding: 0)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(badge.title)\(pinned ? ", vitrinde" : "")")
    .accessibilityAddTraits(pinned ? .isSelected : [])
  }

  // MARK: - Upcoming

  private func upcomingRow(_ badge: BadgeKind) -> some View {
    HStack(spacing: 10) {
      MedalView(systemImage: badge.symbol, color: badge.color, size: 44, isLocked: true)
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(badge.title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
          Spacer()
          if let progress = viewModel.progress(badge) {
            Text("\(progress.current)/\(progress.target)").font(AppFont.caption)
              .foregroundStyle(Palette.muted)
          }
        }
        if let progress = viewModel.progress(badge) {
          ProgressBar(
            value: Double(progress.current) / Double(max(progress.target, 1)),
            tint: Palette.streak, height: 6
          )
          .padding(.top, 2)
        } else {
          Text(badge.detail).font(AppFont.caption).foregroundStyle(Palette.muted)
        }
        if let reward = badge.reward {
          Text("Ödül: \(reward)").font(AppFont.tiny).foregroundStyle(Palette.muted)
        }
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 14)
    .card(padding: 0)
    .accessibilityElement(children: .combine)
  }

  // MARK: - Helpers

  private func medal(_ badge: BadgeKind, size: CGFloat, pinned: Bool) -> some View {
    MedalView(systemImage: badge.symbol, color: badge.color, size: size)
      .overlay(alignment: .topTrailing) {
        if pinned {
          Image(systemName: "pin.fill").font(.system(size: 10, weight: .bold))
            .foregroundStyle(Palette.accent)
            .frame(width: 22, height: 22)
            .background(Circle().fill(Palette.surface))
            .shadow(color: .black.opacity(0.2), radius: 1.5, y: 1)
            .offset(x: 6, y: -6)
        }
      }
  }
}
