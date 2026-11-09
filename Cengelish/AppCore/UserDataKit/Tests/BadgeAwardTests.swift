import DesignKit
import Foundation
import Testing

@testable import UserDataKit

@Suite("Rozetler ve unvanlar")
@MainActor
struct BadgeAwardTests {

  /// Takvimi sabit (UTC) tutar; saat koşulları cihazdan bağımsız olur.
  private static var utc: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
  }

  /// Verilen saatte bir tarih üretir.
  private func date(hour: Int, day: Int = 9) -> Date {
    let components = DateComponents(year: 2026, month: 11, day: day, hour: hour)
    return Self.utc.date(from: components) ?? .now
  }

  /// Bir bulmacayı verilen işaretlerle bitirir.
  @discardableResult
  private func finish(
    _ store: UserDataStore, _ id: String, allCorrect: Bool = true, at now: Date
  ) -> FinishResult {
    store.finish(
      puzzleId: id, marks: ["e1": true, "e2": allCorrect],
      wordIdsByEntry: ["e1": "w_a", "e2": "w_b"], isPremium: false, now: now)
  }

  @Test("15 rozet var ve YDS 10 bunlardan biri")
  func catalog() {
    #expect(BadgeKind.allCases.count == 15)
    #expect(BadgeKind.yds10.title == "YDS 10")
    #expect(Set(BadgeKind.allCases.map(\.title)).count == 15)
  }

  @Test("Gece bitirilen ipucusuz, hatasız bulmaca Hatasız ve Gece Kuşu rozetlerini açar")
  func nightAndPerfect() {
    let store = UserDataStore(inMemory: true, calendar: Self.utc)
    let result = finish(store, "a1_01", at: date(hour: 23))
    #expect(result.newBadges.contains(.perfect))
    #expect(result.newBadges.contains(.nightOwl))
    #expect(!result.newBadges.contains(.earlyBird))
    #expect(store.badges[.nightOwl] != nil)
  }

  @Test("Yanlışlı ya da ipuçlu bitiriş Hatasız açmaz; sabah bitiriş Erkenci açar")
  func notPerfectButEarly() {
    let store = UserDataStore(inMemory: true, calendar: Self.utc)
    #expect(
      !finish(store, "a1_01", allCorrect: false, at: date(hour: 7)).newBadges.contains(.perfect))
    store.saveRevealed(puzzleId: "a1_02", cells: ["1,1"], hintsUsed: 1)
    let hinted = finish(store, "a1_02", at: date(hour: 12))
    #expect(!hinted.newBadges.contains(.perfect))
    #expect(store.badges[.earlyBird] != nil)
  }

  @Test("YDS paketinden 10 bulmaca YDS 10 rozetini ve YDS Savaşçısı unvanını açar")
  func yds10() {
    let store = UserDataStore(inMemory: true, calendar: Self.utc)
    for index in 1...9 { finish(store, String(format: "yds_%02d", index), at: date(hour: 12)) }
    finish(store, "b1_01", at: date(hour: 12))
    #expect(store.badges[.yds10] == nil)
    let result = finish(store, "yds_10", at: date(hour: 12))
    #expect(result.newBadges.contains(.yds10))
    #expect(result.newBadges.contains(.puzzles10) == false)
    #expect(store.badges[.puzzles10] != nil)
    let snapshot = AchievementSnapshot(stats: store.stats, ydsSolved: 10)
    #expect(UserTitle.ydsSavascisi.isUnlocked(badges: Set(store.badges.keys), snapshot: snapshot))
  }

  @Test("Günlük bulmacalar ve öğrenilen kelimeler sayaçlı rozetlere sayılır")
  func dailyAndLearned() {
    let store = UserDataStore(inMemory: true, calendar: Self.utc)
    for day in 1...25 {
      store.addToNotebook(wordId: "w_\(day)", source: "manual")
      store.setLearned(wordId: "w_\(day)", learned: true)
    }
    for day in 1...7 {
      finish(store, String(format: "daily_2026-11-%02d", day), at: date(hour: 12, day: day))
    }
    #expect(store.badges[.daily7] != nil)
    #expect(store.badges[.learned25] != nil)
    #expect(store.badges[.streak7] != nil)
  }

  @Test("İlerleme hedefle sınırlanır; anlık rozetlerin ilerlemesi yoktur")
  func progress() {
    var stats = UserStats()
    stats.longestStreak = 13
    let snapshot = AchievementSnapshot(stats: stats, ydsSolved: 14)
    #expect(BadgeKind.streak30.progress(snapshot)?.current == 13)
    #expect(BadgeKind.yds10.progress(snapshot)?.current == 10)
    #expect(BadgeKind.speed.progress(snapshot) == nil)
    #expect(!BadgeKind.speed.isEarned(snapshot, event: nil))
  }

  @Test("Paket kimliği bulmaca kimliğinden çıkarılır")
  func packIds() {
    #expect(AchievementSnapshot.packId(of: "yds_03") == "yds")
    #expect(AchievementSnapshot.packId(of: "daily_2026-11-09") == nil)
    let snapshot = AchievementSnapshot(
      stats: UserStats(), finishedPuzzleIds: ["yds_01", "yds_02", "daily_2026-11-09", "a1_01"],
      learnedWords: 3)
    #expect(snapshot.ydsSolved == 2)
    #expect(snapshot.dailySolved == 1)
  }

  @Test("Eski unvan kimlikleri yenilerine eşlenir")
  func legacyTitles() {
    #expect(UserTitle(storedId: "kalemci") == .yeniKalem)
    #expect(UserTitle(storedId: "avci") == .kelimeAvcisi)
    #expect(UserTitle(storedId: "kurt") == .bulmacaKurdu)
    #expect(UserTitle(storedId: "seri") == .yeniKalem)
    #expect(UserTitle(storedId: "geceKusu") == .geceKusu)
    #expect(UserTitle.kalemci.title == "Yeni Kalem")
  }
}
