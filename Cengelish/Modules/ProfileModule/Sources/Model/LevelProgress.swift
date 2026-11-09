import ContentKit
import Foundation

/// Profildeki seviye kartı: "B1 · Orta · B2'ye 420 kelime".
///
/// Formül: `çalışılan = görülen (doğru yazılan) kelime + defterde öğrenilen kelime`. Her seviyenin
/// bir sonraki seviyeye geçiş hedefi vardır (`targets`, toplam çalışılan kelime). Kalan kelime
/// `max(0, hedef - çalışılan)`, çubuk `çalışılan / hedef` (0...1) olarak hesaplanır. Seviye
/// kullanıcının kendi seçimidir; hedefe ulaşınca "B2'ye hazırsın" yazılır. C1 en üst seviyedir ve
/// kendi hedefine göre "x/3000 kelime" gösterir.
struct LevelProgress: Equatable {

  // MARK: - Properties

  /// Seviye başına sonraki seviyeye geçiş hedefi (toplam çalışılan kelime).
  static let targets: [CEFRLevel: Int] = [.a1: 300, .a2: 600, .b1: 1_200, .b2: 2_000, .c1: 3_000]

  /// Kullanıcının seviyesi.
  let level: CEFRLevel
  /// Çalışılan toplam kelime.
  let practiced: Int

  // MARK: - Init

  /// Seviye kimliği ("B1"), görülen ve öğrenilen kelime sayısıyla oluşturur.
  init(levelId: String, wordsSeen: Int, learnedWords: Int) {
    self.level = CEFRLevel(rawValue: levelId.uppercased()) ?? .a1
    self.practiced = max(0, wordsSeen) + max(0, learnedWords)
  }

  // MARK: - Derived

  /// Seviyenin hedefi.
  var target: Int { Self.targets[level] ?? 300 }

  /// Bir sonraki seviye (C1 için nil).
  var next: CEFRLevel? {
    let all = CEFRLevel.allCases
    guard let index = all.firstIndex(of: level), index + 1 < all.count else { return nil }
    return all[index + 1]
  }

  /// Hedefe kalan kelime.
  var remaining: Int { max(0, target - practiced) }

  /// Çubuk doluluğu (0...1).
  var fraction: Double { min(1, Double(practiced) / Double(max(target, 1))) }

  /// "B1 · Orta".
  var headline: String { "\(level.rawValue) · \(level.title)" }

  /// "B2'ye 420 kelime", "B2'ye hazırsın" ya da "1200/3000 kelime".
  var detail: String {
    guard let next else { return "\(min(practiced, target))/\(target) kelime" }
    let name = next.rawValue + TurkishSuffix.dative(next.rawValue)
    return remaining > 0 ? "\(name) \(remaining) kelime" : "\(name) hazırsın"
  }
}
