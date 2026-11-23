import DesignKit
import SwiftUI

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
