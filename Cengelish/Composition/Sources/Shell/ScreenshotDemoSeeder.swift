#if DEBUG
import ContentKit
import DesignKit
import Foundation
import InjectionKit
import PuzzleKit
import UserDataKit

/// Mağaza ekran görüntüleri için örnek veri yükler (yalnızca Debug).
///
/// `-screenshotDemo` başlatma argümanıyla ve henüz profil yokken çalışır: iki haftalık seri,
/// biten bulmacalar, defter kelimeleri ve bugünün bulmacasında açılmış harfler üretir.
@MainActor
struct ScreenshotDemoSeeder {
  @Inject private var userData: any UserDataStoring
  @Inject private var content: any ContentProviding
  /// Örnek veriyi açan başlatma argümanı.
  static let argument = "-screenshotDemo"
  /// Takvim.
  private let calendar = Calendar.current

  /// Argüman verildiyse ve profil yoksa örnek veriyi yazar.
  func seedIfRequested(now: Date = .now) async {
    guard ProcessInfo.processInfo.arguments.contains(Self.argument), userData.profile == nil
    else { return }
    let start = calendar.date(byAdding: .day, value: -15, to: now) ?? now
    userData.createProfile(
      UserProfile(
        nickname: "Deniz",
        avatar: AvatarConfig(body: .sky, accessory: .headphones, background: .lilac),
        level: "B1", goals: ["genel", "yds"], dailyGoal: 2, createdAt: start))
    await finishPastDays(now: now)
    learnSomeWords()
    await revealToday(now: now)
    var profile = userData.profile
    profile?.showcaseBadges = userData.badges.keys.map(\.rawValue).sorted().prefix(3).map { $0 }
    if let profile { userData.updateProfile(profile) }
  }

  // MARK: - Private

  /// Son 14 günün her birinde iki bulmaca bitirir.
  private func finishPastDays(now: Date) async {
    var puzzles: [Puzzle] = []
    for packId in ["a1", "a2", "b1"] {
      puzzles += await content.puzzles(inPack: packId)
    }
    var index = 0
    for offset in stride(from: 14, through: 1, by: -1) {
      guard let day = calendar.date(byAdding: .day, value: -offset, to: now),
        let evening = calendar.date(bySettingHour: 20, minute: 15, second: 0, of: day)
      else { continue }
      for _ in 0..<2 where index < puzzles.count {
        finish(puzzles[index], missEvery: index % 3 == 0 ? 3 : 0, at: evening)
        index += 1
      }
    }
  }

  /// Bulmacayı bitirir; `missEvery` > 0 ise o aralıkla kelimeleri yanlış işaretler.
  private func finish(_ puzzle: Puzzle, missEvery: Int, at date: Date) {
    var marks: [String: Bool] = [:]
    for (offset, entry) in puzzle.entries.enumerated() {
      marks[entry.id] = missEvery == 0 || offset % missEvery != 1
    }
    let wordIds = Dictionary(uniqueKeysWithValues: puzzle.entries.map { ($0.id, $0.wordId) })
    userData.saveDraft(
      puzzleId: puzzle.id, drawing: nil, durationSec: 240 + puzzle.entries.count * 20)
    _ = userData.finish(
      puzzleId: puzzle.id, marks: marks, wordIdsByEntry: wordIds, isPremium: false, now: date)
  }

  /// Defterdeki kelimelerin bir kısmını öğrenildi yapar.
  private func learnSomeWords() {
    for (offset, item) in userData.notebook.enumerated() where offset % 3 == 0 {
      userData.setLearned(wordId: item.wordId, learned: true)
    }
  }

  /// Bugünün bulmacasında kelimelerin yarısını açar.
  private func revealToday(now: Date) async {
    guard let puzzle = await content.dailyPuzzle(for: now) else { return }
    let cells = puzzle.entries.enumerated()
      .filter { $0.offset % 2 == 0 }
      .flatMap { $0.element.cells }
    userData.saveRevealed(puzzleId: puzzle.id, cells: Set(cells.map(\.key)), hintsUsed: 0)
    userData.saveDraft(puzzleId: puzzle.id, drawing: nil, durationSec: 150)
  }
}
#endif
