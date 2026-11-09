import DesignKit
import Foundation
import SwiftUI

/// Rozet türleri ve açılma koşulları.
public enum BadgeKind: String, CaseIterable, Sendable {
  case firstPuzzle, streak7, words100, perfect, nightOwl, speed, streak30, words500

  /// Rozet adı.
  public var title: String {
    switch self {
    case .firstPuzzle: "İlk Bulmaca"
    case .streak7: "7 Gün Seri"
    case .words100: "100 Kelime"
    case .perfect: "Hatasız"
    case .nightOwl: "Gece Kuşu"
    case .speed: "Hız Ustası"
    case .streak30: "30 Gün Seri"
    case .words500: "500 Kelime"
    }
  }

  /// Nasıl kazanıldığının açıklaması.
  public var detail: String {
    switch self {
    case .firstPuzzle: "İlk bulmacanı bitir"
    case .streak7: "7 gün üst üste çöz"
    case .words100: "100 kelimeyi doğru yaz"
    case .perfect: "Bir bulmacayı hatasız bitir"
    case .nightOwl: "Gece 22.00'den sonra bulmaca bitir"
    case .speed: "Bir bulmacayı 3 dakikadan kısa sürede bitir"
    case .streak30: "30 gün üst üste çöz"
    case .words500: "500 kelimeyi doğru yaz"
    }
  }

  /// SF Symbol.
  public var symbol: String {
    switch self {
    case .firstPuzzle: "square.grid.3x3.fill"
    case .streak7, .streak30: "flame.fill"
    case .words100, .words500: "book.fill"
    case .perfect: "checkmark.seal.fill"
    case .nightOwl: "moon.stars.fill"
    case .speed: "bolt.fill"
    }
  }

  /// Madalya rengi.
  public var color: Color {
    switch self {
    case .firstPuzzle: Color(hex: 0x6C5CE7)
    case .streak7, .streak30: Color(hex: 0xFF8A3D)
    case .words100, .words500: Color(hex: 0x1FB57A)
    case .perfect: Color(hex: 0x3C9BE0)
    case .nightOwl: Color(hex: 0x5B4BC4)
    case .speed: Color(hex: 0xFF5A8A)
    }
  }

  /// Rozetle gelen ödül açıklaması.
  public var reward: String? {
    switch self {
    case .streak7: "Fiyonk aksesuarı"
    case .streak30: "Taç aksesuarı"
    case .words100: "Kulaklık aksesuarı"
    case .words500: "\"Kelime Ustası\" unvanı"
    default: nil
    }
  }

  /// İlerleme (mevcut, hedef); ilerlemesi sayılamayan rozetler için nil.
  public func progress(_ stats: UserStats) -> (current: Int, target: Int)? {
    switch self {
    case .streak7: (min(stats.longestStreak, 7), 7)
    case .streak30: (min(stats.longestStreak, 30), 30)
    case .words100: (min(stats.wordsSeen, 100), 100)
    case .words500: (min(stats.wordsSeen, 500), 500)
    case .firstPuzzle: (min(stats.puzzlesSolved, 1), 1)
    default: nil
    }
  }
}

/// Profil unvanları.
public enum UserTitle: String, CaseIterable, Sendable {
  case kalemci, avci, kurt, seri, usta

  /// Unvan kimliği.
  public var id: String { rawValue }

  /// Ekranda görünen unvan.
  public var title: String {
    switch self {
    case .kalemci: "Kalemci"
    case .avci: "Kelime Avcısı"
    case .kurt: "Bulmaca Kurdu"
    case .seri: "Seri Ustası"
    case .usta: "Kelime Ustası"
    }
  }

  /// Açılma koşulu.
  public var requirement: String {
    switch self {
    case .kalemci: "Herkese açık"
    case .avci: "50 kelime"
    case .kurt: "10 bulmaca"
    case .seri: "7 günlük seri"
    case .usta: "500 kelime"
    }
  }

  /// Unvanın açık olup olmadığı.
  public func isUnlocked(_ stats: UserStats) -> Bool {
    switch self {
    case .kalemci: true
    case .avci: stats.wordsSeen >= 50
    case .kurt: stats.puzzlesSolved >= 10
    case .seri: stats.longestStreak >= 7
    case .usta: stats.wordsSeen >= 500
    }
  }
}

/// Avatar parçalarının kilit kuralları.
public enum UnlockRules {

  /// Aksesuarın açık olup olmadığı.
  public static func isUnlocked(
    _ accessory: AvatarAccessory, stats: UserStats, isPremium: Bool
  ) -> Bool {
    switch accessory {
    case .none, .glasses, .cap: true
    case .headphones: stats.wordsSeen >= 100
    case .bow: stats.longestStreak >= 7
    case .crown: stats.longestStreak >= 30 || isPremium
    }
  }

  /// Kilitli aksesuarın açılma koşulu.
  public static func requirement(_ accessory: AvatarAccessory) -> String? {
    switch accessory {
    case .headphones: "100 kelime"
    case .bow: "7 gün seri"
    case .crown: "30 gün seri ya da Çengelish+"
    default: nil
    }
  }

  /// Arka plan "Gece" ve "Mercan" Çengelish+ ile açılır.
  public static func isUnlocked(_ background: AvatarBackground, isPremium: Bool) -> Bool {
    switch background {
    case .night, .coral: isPremium
    default: true
    }
  }
}
