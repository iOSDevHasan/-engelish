import DesignKit
import SwiftUI
import UserDataKit

// MARK: - Cover

/// Profil kapağının degradesi: avatarın arka plan rengiyle uyumlu (açık ve koyu mod).
enum ProfileCover {

  /// Arka plana göre kapak degradesi.
  static func gradient(_ background: AvatarBackground) -> LinearGradient {
    LinearGradient(
      stops: [
        .init(color: colors(background).0, location: 0),
        .init(color: colors(background).1, location: 0.6),
        .init(color: colors(background).2, location: 1),
      ], startPoint: .leading, endPoint: .trailing)
  }

  /// Üç degrade durağı.
  private static func colors(_ background: AvatarBackground) -> (Color, Color, Color) {
    let d = Palette.dynamic
    return switch background {
    case .lilac: (d(0xC9BDFF, 0x4B3FA8), d(0xE9E4FF, 0x2A2558), d(0xFFE3D3, 0x3D2335))
    case .mint: (d(0x9FE6C6, 0x1F6B50), d(0xD6F5E6, 0x1C3B30), d(0xD9F0FF, 0x1F3346))
    case .sky: (d(0xA9D9FF, 0x24567F), d(0xD9F0FF, 0x1F3346), d(0xE8E3FF, 0x2C2858))
    case .peach: (d(0xFFC2A1, 0x7A3F2A), d(0xFFE3D3, 0x3A2A2A), d(0xFFE0EC, 0x3D2335))
    case .pink: (d(0xFFB3CF, 0x7A2E50), d(0xFFE0EC, 0x3D2335), d(0xE8E3FF, 0x2C2858))
    case .lemon: (d(0xFFE07A, 0x6B5A1C), d(0xFFF4C2, 0x3B3217), d(0xFFE3D3, 0x3A2A2A))
    case .night: (d(0x2B2563, 0x2B2563), d(0x4B3FA8, 0x3A3175), d(0x8E80FF, 0x5B4BC4))
    case .coral: (d(0xFF8A80, 0x8A3A35), d(0xFFC2BC, 0x4A2A2E), d(0xFFE3D3, 0x3A2A2A))
    }
  }
}

// MARK: - Share card

/// Paylaşılan profil kartı: avatar, ad, unvan, seviye ve sayaçlar.
struct ProfileShareCard: View {
  let profile: UserProfile
  let title: String
  let stats: UserStats
  let badgeCount: Int
  let showcase: [BadgeKind]

  var body: some View {
    VStack(spacing: 0) {
      ProfileCover.gradient(profile.avatar.background).frame(height: 70)
      VStack(spacing: 10) {
        AvatarView(profile.avatar, size: 96)
          .overlay(Circle().strokeBorder(Palette.surface, lineWidth: 4))
          .padding(.top, -48)
        Text(profile.displayName).font(AppFont.title).foregroundStyle(Palette.ink)
        HStack(spacing: 6) {
          Pill(title, systemImage: "trophy.fill", tone: .accent)
          Pill(profile.level)
        }
        HStack(spacing: 8) {
          stat("\(stats.streak)", "gün seri")
          stat("\(stats.puzzlesSolved)", "bulmaca")
          stat("\(stats.wordsSeen)", "kelime")
          stat("\(badgeCount)", "rozet")
        }
        .padding(.top, 4)
        if !showcase.isEmpty {
          HStack(spacing: 14) {
            ForEach(showcase, id: \.self) { badge in
              MedalView(systemImage: badge.symbol, color: badge.color, size: 44)
            }
          }
        }
        Text("Çengelish · Sen de çöz").font(AppFont.caption).foregroundStyle(Palette.accent)
          .padding(.top, 2)
      }
      .padding(.horizontal, 18)
      .padding(.bottom, 18)
    }
    .frame(width: 340)
    .background(Palette.surface)
    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
  }

  private func stat(_ value: String, _ label: String) -> some View {
    VStack(spacing: 2) {
      Text(value).font(AppFont.headline).foregroundStyle(Palette.ink)
      Text(label).font(AppFont.tiny).foregroundStyle(Palette.muted)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 8)
    .background(RoundedRectangle(cornerRadius: 14).fill(Palette.surface2))
  }
}

// MARK: - Cover picker

/// Kapağın palet butonuyla açılan arka plan seçici.
struct CoverPickerSheet: View {
  let selection: AvatarBackground
  let isLocked: (AvatarBackground) -> Bool
  let onSelect: (AvatarBackground) -> Void
  let onPremium: () -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text("Kapak ve arka plan").font(AppFont.section).foregroundStyle(Palette.ink)
        Spacer()
        Button("Bitti") { dismiss() }.font(AppFont.bodyBold).foregroundStyle(Palette.accent)
      }
      ProfileCover.gradient(selection)
        .frame(height: 66)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      BackgroundPicker(
        selection: Binding(get: { selection }, set: onSelect), isLocked: isLocked)
      if AvatarBackground.allCases.contains(where: isLocked) {
        Button(action: onPremium) {
          Label("Gece ve Mercan Çengelish+ ile açılır", systemImage: "lock.fill")
            .font(AppFont.caption)
            .foregroundStyle(Palette.muted)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(Metrics.gutter)
    .presentationDetents([.height(250)])
    .presentationDragIndicator(.visible)
    .background(Palette.background.ignoresSafeArea())
  }
}
