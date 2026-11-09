import DesignKit
import Foundation
import SwiftUI

// MARK: - Achievement snapshot

/// Rozet koşullarını değerlendirmek için gereken sayaçlar.
///
/// Bulmaca kimlikleri `<paketId>_<sıra>` (`yds_03`) ya da `daily_<gün>` biçimindedir; sınav ve
/// günlük sayaçları bu öneklerden hesaplanır.
public struct AchievementSnapshot: Equatable, Sendable {
  /// Seri ve genel sayaçlar.
  public var stats: UserStats
  /// Bitirilen YDS paketi bulmacası sayısı.
  public var ydsSolved: Int
  /// Bitirilen Günün Bulmacası sayısı.
  public var dailySolved: Int
  /// Defterde "Öğrenildi" olan kelime sayısı.
  public var learnedWords: Int

  /// YDS paketinin kimliği.
  public static let ydsPackId = "yds"
  /// Günün Bulmacası kimlik öneki.
  public static let dailyPrefix = "daily_"

  /// Sayaçlarla oluşturur.
  public init(stats: UserStats, ydsSolved: Int = 0, dailySolved: Int = 0, learnedWords: Int = 0) {
    self.stats = stats
    self.ydsSolved = ydsSolved
    self.dailySolved = dailySolved
    self.learnedWords = learnedWords
  }

  /// Bitirilen bulmaca kimliklerinden sınav ve günlük sayaçlarını çıkararak oluşturur.
  public init(stats: UserStats, finishedPuzzleIds: [String], learnedWords: Int) {
    self.init(
      stats: stats,
      ydsSolved: finishedPuzzleIds.filter { Self.packId(of: $0) == Self.ydsPackId }.count,
      dailySolved: finishedPuzzleIds.filter { $0.hasPrefix(Self.dailyPrefix) }.count,
      learnedWords: learnedWords)
  }

  /// Bulmaca kimliğindeki paket kimliği (`yds_03` → `yds`); günlük bulmacalar için nil.
  public static func packId(of puzzleId: String) -> String? {
    guard !puzzleId.hasPrefix(dailyPrefix), let index = puzzleId.lastIndex(of: "_") else {
      return nil
    }
    return String(puzzleId[..<index])
  }
}

/// Bitirilen bulmacanın anlık koşulları (saat, süre, hatasızlık).
public struct FinishEvent: Equatable, Sendable {
  /// Bitirme saati (0–23).
  public let hour: Int
  /// Çözüm süresi (saniye).
  public let durationSec: Int
  /// İlk bitirişte tüm kelimeler doğru ve hiç ipucu yok.
  public let isFlawless: Bool

  /// Koşullarla oluşturur.
  public init(hour: Int, durationSec: Int, isFlawless: Bool) {
    self.hour = hour
    self.durationSec = durationSec
    self.isFlawless = isFlawless
  }
}

// MARK: - Badges

/// Rozet türleri ve açılma koşulları (15 rozet).
public enum BadgeKind: String, CaseIterable, Sendable {
  case firstPuzzle, puzzles10, puzzles50
  case streak7, streak30
  case words100, words500
  case perfect, perfect10
  case nightOwl, earlyBird, speed
  case yds10, daily7, learned25

  /// Rozet adı.
  public var title: String {
    switch self {
    case .firstPuzzle: "İlk Bulmaca"
    case .puzzles10: "10 Bulmaca"
    case .puzzles50: "50 Bulmaca"
    case .streak7: "7 Gün Seri"
    case .streak30: "30 Gün Seri"
    case .words100: "100 Kelime"
    case .words500: "500 Kelime"
    case .perfect: "Hatasız"
    case .perfect10: "Kusursuz 10"
    case .nightOwl: "Gece Kuşu"
    case .earlyBird: "Erkenci"
    case .speed: "Hız Ustası"
    case .yds10: "YDS 10"
    case .daily7: "Günün Kurdu"
    case .learned25: "Defter Ustası"
    }
  }

  /// Nasıl kazanıldığının açıklaması.
  public var detail: String {
    switch self {
    case .firstPuzzle: "İlk bulmacanı bitir"
    case .puzzles10: "10 bulmaca bitir"
    case .puzzles50: "50 bulmaca bitir"
    case .streak7: "7 gün üst üste çöz"
    case .streak30: "30 gün üst üste çöz"
    case .words100: "100 kelimeyi doğru yaz"
    case .words500: "500 kelimeyi doğru yaz"
    case .perfect: "Bir bulmacayı ipucusuz ve hatasız bitir"
    case .perfect10: "10 bulmacada tüm kelimeleri doğru yaz"
    case .nightOwl: "Gece 22.00'den sonra bulmaca bitir"
    case .earlyBird: "Sabah 08.00'den önce bulmaca bitir"
    case .speed: "Bir bulmacayı 3 dakikadan kısa sürede bitir"
    case .yds10: "YDS paketinden 10 bulmaca bitir"
    case .daily7: "7 Günün Bulmacası çöz"
    case .learned25: "Defterinden 25 kelime öğren"
    }
  }

  /// SF Symbol.
  public var symbol: String {
    switch self {
    case .firstPuzzle, .puzzles10, .puzzles50: "square.grid.3x3.fill"
    case .streak7, .streak30: "flame.fill"
    case .words100, .words500: "book.fill"
    case .perfect, .perfect10: "checkmark.seal.fill"
    case .nightOwl: "moon.stars.fill"
    case .earlyBird: "sunrise.fill"
    case .speed: "bolt.fill"
    case .yds10: "graduationcap.fill"
    case .daily7: "calendar"
    case .learned25: "brain.head.profile"
    }
  }

  /// Madalya rengi.
  public var color: Color {
    switch self {
    case .firstPuzzle, .puzzles10, .puzzles50: Color(hex: 0x6C5CE7)
    case .streak7, .streak30: Color(hex: 0xFF8A3D)
    case .words100, .words500, .learned25: Color(hex: 0x1FB57A)
    case .perfect, .perfect10, .daily7: Color(hex: 0x3C9BE0)
    case .nightOwl, .yds10: Color(hex: 0x5B4BC4)
    case .earlyBird: Color(hex: 0xFFB020)
    case .speed: Color(hex: 0xFF5A8A)
    }
  }

  /// Rozetle gelen ödül açıklaması.
  public var reward: String? {
    switch self {
    case .streak7: "Fiyonk aksesuarı"
    case .streak30: "Taç aksesuarı"
    case .words100: "Kulaklık aksesuarı ve \"Kelime Avcısı\" unvanı"
    case .words500: "\"Kelime Ustası\" unvanı"
    case .puzzles10: "\"Bulmaca Kurdu\" unvanı"
    case .nightOwl: "\"Gece Kuşu\" unvanı"
    case .yds10: "\"YDS Savaşçısı\" unvanı"
    default: nil
    }
  }

  /// İlerleme (mevcut, hedef); ilerlemesi sayılamayan rozetler için nil.
  public func progress(_ snapshot: AchievementSnapshot) -> (current: Int, target: Int)? {
    guard let target, let value = value(snapshot) else { return nil }
    return (min(value, target), target)
  }

  /// Rozetin koşulunun sağlanıp sağlanmadığı. Anlık rozetler `event` olmadan açılmaz.
  public func isEarned(_ snapshot: AchievementSnapshot, event: FinishEvent?) -> Bool {
    if let target, let value = value(snapshot) { return value >= target }
    guard let event else { return false }
    switch self {
    case .perfect: return event.isFlawless
    case .nightOwl: return event.hour >= 22 || event.hour < 5
    case .earlyBird: return event.hour >= 5 && event.hour < 8
    case .speed: return event.durationSec > 0 && event.durationSec < 180
    default: return false
    }
  }

  /// Sayaçlı rozetin hedefi.
  private var target: Int? {
    switch self {
    case .firstPuzzle: 1
    case .puzzles10, .perfect10, .yds10: 10
    case .puzzles50: 50
    case .streak7, .daily7: 7
    case .streak30: 30
    case .words100: 100
    case .words500: 500
    case .learned25: 25
    case .perfect, .nightOwl, .earlyBird, .speed: nil
    }
  }

  /// Sayaçlı rozetin güncel değeri.
  private func value(_ snapshot: AchievementSnapshot) -> Int? {
    let stats = snapshot.stats
    return switch self {
    case .firstPuzzle, .puzzles10, .puzzles50: stats.puzzlesSolved
    case .streak7, .streak30: stats.longestStreak
    case .words100, .words500: stats.wordsSeen
    case .perfect10: stats.perfectCount
    case .yds10: snapshot.ydsSolved
    case .daily7: snapshot.dailySolved
    case .learned25: snapshot.learnedWords
    case .perfect, .nightOwl, .earlyBird, .speed: nil
    }
  }
}

// MARK: - Titles

/// Profil unvanları; rozetlerle açılır.
public enum UserTitle: String, CaseIterable, Sendable {
  case yeniKalem, kelimeAvcisi, geceKusu, bulmacaKurdu, ydsSavascisi, kelimeUstasi

  /// Varsayılan unvan (eski adıyla).
  public static var kalemci: UserTitle { .yeniKalem }

  /// Kayıtlı kimlikten unvanı çözer; eski sürümlerin kimliklerini yenilerine eşler.
  public init(storedId: String) {
    if let title = UserTitle(rawValue: storedId) {
      self = title
      return
    }
    switch storedId {
    case "avci": self = .kelimeAvcisi
    case "kurt": self = .bulmacaKurdu
    case "usta": self = .kelimeUstasi
    default: self = .yeniKalem
    }
  }

  /// Unvan kimliği.
  public var id: String { rawValue }

  /// Ekranda görünen unvan.
  public var title: String {
    switch self {
    case .yeniKalem: "Yeni Kalem"
    case .kelimeAvcisi: "Kelime Avcısı"
    case .geceKusu: "Gece Kuşu"
    case .bulmacaKurdu: "Bulmaca Kurdu"
    case .ydsSavascisi: "YDS Savaşçısı"
    case .kelimeUstasi: "Kelime Ustası"
    }
  }

  /// Unvanı açan rozet (herkese açık unvan için nil).
  public var badge: BadgeKind? {
    switch self {
    case .yeniKalem: nil
    case .kelimeAvcisi: .words100
    case .geceKusu: .nightOwl
    case .bulmacaKurdu: .puzzles10
    case .ydsSavascisi: .yds10
    case .kelimeUstasi: .words500
    }
  }

  /// Açılma koşulu.
  public var requirement: String {
    badge.map { "\($0.title) rozeti" } ?? "Herkese açık"
  }

  /// Unvanın açık olup olmadığı: rozeti kazanıldıysa (ya da sayacı yeterliyse) açılır.
  public func isUnlocked(badges: Set<BadgeKind>, snapshot: AchievementSnapshot) -> Bool {
    guard let badge else { return true }
    return badges.contains(badge) || badge.isEarned(snapshot, event: nil)
  }
}

// MARK: - Avatar unlocks

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
