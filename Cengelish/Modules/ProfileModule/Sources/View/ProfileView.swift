import DesignKit
import SwiftUI
import UserDataKit

/// Profil sekmesi.
struct ProfileView: View {
  @StateObject var viewModel: ProfileViewModel
  @State private var isCoverPickerShown = false
  @State private var shareImage: Image?

  var body: some View {
    ScrollView {
      VStack(spacing: 12) {
        header
        profileCard
        tiles
        showcase
        level
        StreakCalendarCard(viewModel: viewModel)
        dataRow
      }
      .padding(.horizontal, Metrics.gutter)
      .padding(.bottom, 24)
      .frame(maxWidth: 680)
      .frame(maxWidth: .infinity)
    }
    .screenBackground()
    .sheet(isPresented: $isCoverPickerShown) {
      CoverPickerSheet(
        selection: viewModel.profile.avatar.background, isLocked: viewModel.isLocked,
        onSelect: viewModel.setBackground,
        onPremium: {
          isCoverPickerShown = false
          viewModel.openPaywall()
        })
    }
    .task(id: shareKey) { renderShareCard() }
  }

  // MARK: - Header

  private var header: some View {
    HStack {
      Text("Profil").font(AppFont.rounded(28, weight: .black)).foregroundStyle(Palette.ink)
      Spacer()
      Button(action: viewModel.openSettings) { IconCircle("gearshape.fill") }
        .buttonStyle(.plain)
        .accessibilityLabel("Ayarlar")
    }
    .frame(minHeight: 44)
  }

  // MARK: - Profile card

  private var profileCard: some View {
    VStack(spacing: 0) {
      ProfileCover.gradient(viewModel.profile.avatar.background).frame(height: 66)
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .bottom, spacing: 12) {
          avatarButton
          VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.profile.displayName)
              .font(AppFont.rounded(22, weight: .black))
              .foregroundStyle(Palette.ink)
              .lineLimit(1)
            HStack(spacing: 6) {
              Pill(viewModel.title.title, systemImage: "trophy.fill", tone: .accent)
              Pill(viewModel.profile.level)
              if viewModel.isPremium { Pill("Çengelish+", systemImage: "crown.fill", tone: .gold) }
            }
          }
          .padding(.bottom, 4)
          Spacer(minLength: 0)
        }
        Text(viewModel.memberSinceText).font(AppFont.caption).foregroundStyle(Palette.muted)
        HStack(spacing: 8) {
          Button(action: viewModel.edit) {
            Label("Profili düzenle", systemImage: "pencil")
          }
          .buttonStyle(ChunkyButtonStyle(.secondary, compact: true))
          shareButton
        }
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 14)
      .padding(.top, -44)
    }
    .overlay(alignment: .topTrailing) { paletteButton }
    .background(
      RoundedRectangle(cornerRadius: 26, style: .continuous)
        .fill(Palette.surface)
        .shadow(color: Palette.cardShadow, radius: 0, y: 2)
        .shadow(color: Color.black.opacity(0.06), radius: 14, y: 10)
    )
    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
  }

  private var paletteButton: some View {
    Button {
      isCoverPickerShown = true
    } label: {
      Image(systemName: "paintpalette.fill")
        .font(.system(size: 15, weight: .bold))
        .foregroundStyle(Color(hex: 0x24204D))
        .frame(width: 34, height: 34)
        .background(Circle().fill(Color.white.opacity(0.55)))
    }
    .buttonStyle(.plain)
    .padding(10)
    .accessibilityLabel("Kapak rengini değiştir")
  }

  private var avatarButton: some View {
    Button(action: viewModel.edit) {
      AvatarView(viewModel.profile.avatar, size: 88)
        .overlay(Circle().strokeBorder(Palette.surface, lineWidth: 4))
        .overlay(alignment: .bottomTrailing) {
          Image(systemName: "pencil").font(.system(size: 13, weight: .black))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(Circle().fill(Palette.buttonFill))
            .overlay(Circle().strokeBorder(Palette.surface, lineWidth: 3))
            .offset(x: 2, y: 2)
        }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Avatarı düzenle")
  }

  @ViewBuilder
  private var shareButton: some View {
    if let shareImage {
      ShareLink(
        item: shareImage, preview: SharePreview("Çengelish profilim", image: shareImage)
      ) {
        Image(systemName: "square.and.arrow.up")
      }
      .buttonStyle(ChunkyButtonStyle(.secondary, fullWidth: false, compact: true))
      .accessibilityLabel("Profili paylaş")
    }
  }

  // MARK: - Tiles

  private var tiles: some View {
    HStack(spacing: 8) {
      tile("flame.fill", "\(viewModel.stats.streak)", "gün seri", Palette.pastels[0])
      tile(
        "square.grid.3x3.fill", "\(viewModel.stats.puzzlesSolved)", "bulmaca", Palette.pastels[2])
      tile("book.fill", "\(viewModel.stats.wordsSeen)", "kelime", Palette.pastels[3])
      tile("trophy.fill", "\(viewModel.badges.count)", "rozet", Palette.pastels[1])
    }
  }

  private func tile(_ icon: String, _ value: String, _ label: String, _ fill: Color) -> some View {
    VStack(spacing: 2) {
      Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundStyle(
        Palette.accent)
      Text(value).font(AppFont.rounded(19, weight: .black)).foregroundStyle(Palette.ink)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
      Text(label).font(AppFont.rounded(10, weight: .heavy)).foregroundStyle(Palette.muted)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .padding(.horizontal, 4)
    .background(RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous).fill(fill))
    .accessibilityElement(children: .combine)
  }

  // MARK: - Showcase

  private var showcase: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("Rozet vitrini").font(AppFont.bodyBold).foregroundStyle(Palette.ink)
        Spacer()
        Button(action: viewModel.openBadges) {
          Label("Tümü", systemImage: "chevron.right").labelStyle(TrailingIconLabelStyle())
        }
        .font(AppFont.caption)
        .foregroundStyle(Palette.accent)
      }
      if viewModel.showcase.isEmpty {
        Text("İlk bulmacanı bitirince ilk rozetin burada görünür.")
          .font(AppFont.caption).foregroundStyle(Palette.muted)
      } else {
        HStack(spacing: 8) {
          ForEach(viewModel.showcase, id: \.self) { badge in
            VStack(spacing: 6) {
              MedalView(systemImage: badge.symbol, color: badge.color, size: 56)
              Text(badge.title).font(AppFont.rounded(11.5, weight: .black))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
          }
        }
      }
    }
    .padding(.vertical, 14)
    .padding(.horizontal, 16)
    .card(padding: 0)
  }

  // MARK: - Level

  private var level: some View {
    let progress = viewModel.levelProgress
    return VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(progress.headline).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
        Spacer()
        Text(progress.detail).font(AppFont.caption).foregroundStyle(Palette.muted)
      }
      ProgressBar(value: progress.fraction)
    }
    .padding(.vertical, 14)
    .padding(.horizontal, 16)
    .card(padding: 0)
    .accessibilityElement(children: .combine)
  }

  // MARK: - Data row

  private var dataRow: some View {
    HStack(spacing: 10) {
      Image(systemName: viewModel.iCloudOn ? "icloud.fill" : "iphone")
        .foregroundStyle(Palette.good)
      Text(viewModel.dataText).foregroundStyle(Palette.ink)
      Spacer(minLength: 6)
      Text(viewModel.dataTimestamp).foregroundStyle(Palette.muted)
    }
    .font(AppFont.rounded(12.5, weight: .heavy))
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Palette.surface2))
    .accessibilityElement(children: .combine)
  }

  // MARK: - Share

  /// Paylaşım kartını yeniden çizdiren anahtar.
  private var shareKey: String {
    let stats = viewModel.stats
    return [
      viewModel.profile.displayName, viewModel.title.id, viewModel.profile.level,
      "\(viewModel.profile.avatar)", "\(stats.streak)", "\(stats.puzzlesSolved)",
      "\(stats.wordsSeen)", "\(viewModel.badges.count)",
      viewModel.showcase.map(\.rawValue).joined(),
    ].joined(separator: "|")
  }

  /// Profil kartını resme çevirir.
  @MainActor
  private func renderShareCard() {
    let card = ProfileShareCard(
      profile: viewModel.profile, title: viewModel.title.title, stats: viewModel.stats,
      badgeCount: viewModel.badges.count, showcase: viewModel.showcase
    )
    .environment(\.colorScheme, .light)
    let renderer = ImageRenderer(content: card)
    renderer.scale = 3
    if let image = renderer.uiImage {
      shareImage = Image(uiImage: image)
    }
  }
}
