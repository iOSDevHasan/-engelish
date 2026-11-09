import DesignKit
import SwiftUI
import UserDataKit

/// Profil sekmesi.
struct ProfileView: View {
  @StateObject var viewModel: ProfileViewModel

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        cover
        identity
        tiles
        showcase
        if !viewModel.isPremium { premium }
        dataRow
      }
      .padding(.horizontal, Metrics.gutter)
      .padding(.bottom, 24)
      .frame(maxWidth: 680)
      .frame(maxWidth: .infinity)
    }
    .screenBackground()
  }

  private var cover: some View {
    ZStack(alignment: .bottom) {
      RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
        .fill(
          LinearGradient(
            colors: [Palette.accent.opacity(0.55), Palette.pastels[2], Palette.pastels[0]],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .frame(height: 120)
        .overlay(alignment: .topTrailing) {
          Button(action: viewModel.openSettings) { IconCircle("gearshape.fill") }
            .buttonStyle(.plain)
            .padding(10)
            .accessibilityLabel("Ayarlar")
        }
      Button(action: viewModel.edit) {
        AvatarView(viewModel.profile.avatar, size: 104)
          .overlay(Circle().strokeBorder(Palette.background, lineWidth: 5))
          .overlay(alignment: .bottomTrailing) {
            Image(systemName: "pencil").font(.system(size: 13, weight: .black))
              .foregroundStyle(.white)
              .frame(width: 30, height: 30)
              .background(Circle().fill(Palette.buttonFill))
              .overlay(Circle().strokeBorder(Palette.background, lineWidth: 3))
          }
      }
      .buttonStyle(.plain)
      .offset(y: 52)
      .accessibilityLabel("Avatarı düzenle")
    }
    .padding(.top, 8)
    .padding(.bottom, 52)
  }

  private var identity: some View {
    VStack(spacing: 8) {
      Text(viewModel.profile.displayName).font(AppFont.title).foregroundStyle(Palette.ink)
      HStack(spacing: 6) {
        Pill(viewModel.title.title, systemImage: "rosette", tone: .gold)
        Pill(viewModel.profile.level, tone: .accent)
        if viewModel.isPremium { Pill("Çengelish+", systemImage: "crown.fill", tone: .gold) }
      }
      Button("Profili düzenle", action: viewModel.edit)
        .buttonStyle(ChunkyButtonStyle(.secondary, fullWidth: false, compact: true))
        .padding(.top, 4)
    }
  }

  private var tiles: some View {
    HStack(spacing: 10) {
      tile("flame.fill", "\(viewModel.stats.streak)", "gün seri", Palette.streak)
      tile("square.grid.3x3.fill", "\(viewModel.stats.puzzlesSolved)", "bulmaca", Palette.accent)
      tile("book.fill", "\(viewModel.stats.wordsSeen)", "kelime", Palette.good)
    }
  }

  private func tile(_ icon: String, _ value: String, _ label: String, _ color: Color) -> some View {
    VStack(spacing: 4) {
      Image(systemName: icon).foregroundStyle(color)
      Text(value).font(AppFont.headline).foregroundStyle(Palette.ink)
      Text(label).font(AppFont.tiny).foregroundStyle(Palette.muted)
    }
    .frame(maxWidth: .infinity)
    .card(padding: 12)
  }

  private var showcase: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Rozet vitrini").font(AppFont.section).foregroundStyle(Palette.ink)
        Spacer()
        Button(action: viewModel.openBadges) {
          Label(
            "Tümü \(viewModel.earned.count)/\(BadgeKind.allCases.count)",
            systemImage: "chevron.right"
          )
          .labelStyle(TrailingIconLabelStyle())
        }
        .font(AppFont.caption)
        .foregroundStyle(Palette.accent)
      }
      if viewModel.showcase.isEmpty {
        Text("İlk bulmacanı bitirince ilk rozetin burada görünür.")
          .font(AppFont.caption).foregroundStyle(Palette.muted)
      } else {
        HStack(spacing: 10) {
          ForEach(viewModel.showcase, id: \.self) { badge in
            VStack(spacing: 6) {
              MedalView(systemImage: badge.symbol, color: badge.color, size: 58)
              Text(badge.title).font(AppFont.tiny).foregroundStyle(Palette.ink)
            }
            .frame(maxWidth: .infinity)
          }
        }
      }
    }
    .card()
  }

  private var premium: some View {
    Button(action: viewModel.openPaywall) {
      OptionRow(isSelected: true) {
        Image(systemName: "crown.fill").foregroundStyle(Palette.accent)
        VStack(alignment: .leading, spacing: 2) {
          Text("Çengelish+'a geç").font(AppFont.bodyBold).foregroundStyle(Palette.ink)
          Text("Taç, Gece arka planı ve tüm paketler").font(AppFont.caption)
            .foregroundStyle(Palette.muted)
        }
        Spacer()
        Image(systemName: "chevron.right").foregroundStyle(Palette.muted)
      }
    }
    .buttonStyle(.plain)
  }

  private var dataText: String {
    switch (viewModel.iCloudOn, viewModel.iCloudAvailable) {
    case (true, true): "Veriler bu cihazda · iCloud yedek açık"
    case (true, false): "Veriler bu cihazda · iCloud'a giriş bekleniyor"
    default: "Veriler sadece bu cihazda"
    }
  }

  private var dataRow: some View {
    HStack(spacing: 8) {
      Image(systemName: viewModel.iCloudOn ? "icloud.fill" : "iphone")
      Text(dataText)
      Spacer()
    }
    .font(AppFont.caption)
    .foregroundStyle(Palette.muted)
    .padding(.horizontal, 6)
  }
}
