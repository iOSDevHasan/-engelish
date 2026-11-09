import SwiftUI

/// Kalemo'nun gövde rengi.
public enum AvatarBody: String, CaseIterable, Codable, Sendable {
  case yellow, mint, sky, pink, purple, orange

  /// Ekranda görünen ad.
  public var title: String {
    switch self {
    case .yellow: "Sarı"
    case .mint: "Nane"
    case .sky: "Gökyüzü"
    case .pink: "Pembe"
    case .purple: "Mor"
    case .orange: "Turuncu"
    }
  }

  /// Gövdenin ana rengi.
  public var color: Color { Color(hex: hexes.0) }
  /// Gövdenin gölge rengi.
  public var shade: Color { Color(hex: hexes.1) }

  private var hexes: (UInt32, UInt32) {
    switch self {
    case .yellow: (0xFFC93C, 0xE6A800)
    case .mint: (0x5ED6A5, 0x2FB582)
    case .sky: (0x6EC1FF, 0x3C9BE0)
    case .pink: (0xFF9CC2, 0xE66E9C)
    case .purple: (0xA78BFA, 0x7C5CE0)
    case .orange: (0xFF9E5E, 0xE07A35)
    }
  }
}

/// Kalemo'nun aksesuarı.
public enum AvatarAccessory: String, CaseIterable, Codable, Sendable {
  case none, glasses, cap, headphones, bow, crown

  /// Ekranda görünen ad.
  public var title: String {
    switch self {
    case .none: "Yok"
    case .glasses: "Gözlük"
    case .cap: "Kep"
    case .headphones: "Kulaklık"
    case .bow: "Fiyonk"
    case .crown: "Taç"
    }
  }
}

/// Avatarın arka plan rengi.
public enum AvatarBackground: String, CaseIterable, Codable, Sendable {
  case lilac, mint, sky, peach, pink, lemon, night, coral

  /// Arka plan rengi (mod değiştirmez; avatar her yerde aynı görünür).
  public var color: Color {
    switch self {
    case .lilac: Color(hex: 0xE9E4FF)
    case .mint: Color(hex: 0xD6F5E6)
    case .sky: Color(hex: 0xD9F0FF)
    case .peach: Color(hex: 0xFFE3D3)
    case .pink: Color(hex: 0xFFE0EC)
    case .lemon: Color(hex: 0xFFF4C2)
    case .night: Color(hex: 0x2B2563)
    case .coral: Color(hex: 0xFF8A80)
    }
  }
}

/// Bir kullanıcının avatar seçimi.
public struct AvatarConfig: Codable, Equatable, Sendable {
  /// Gövde rengi.
  public var body: AvatarBody
  /// Aksesuar.
  public var accessory: AvatarAccessory
  /// Arka plan.
  public var background: AvatarBackground

  /// Avatarı parçalarıyla oluşturur.
  public init(
    body: AvatarBody = .mint, accessory: AvatarAccessory = .none,
    background: AvatarBackground = .lilac
  ) {
    self.body = body
    self.accessory = accessory
    self.background = background
  }

  /// Uygulamanın maskotu: sarı, aksesuarsız Kalemo.
  public static let mascot = AvatarConfig(body: .yellow, accessory: .none, background: .lemon)
}
