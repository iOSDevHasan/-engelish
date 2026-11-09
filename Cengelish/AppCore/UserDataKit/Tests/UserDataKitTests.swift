import DesignKit
import Foundation
import Testing
@testable import UserDataKit

@Suite("UserDataKit")
@MainActor
struct UserDataKitTests {

  @Test("Seri: dün oynandıysa artar, boşluk varsa 1'e döner, dondurma bir günü affeder")
  func streakRules() {
    let next = { (last: String?, freeze: Bool) in
      StreakRules.next(
        current: 4, lastDay: last, today: "2026-11-09", yesterday: "2026-11-08",
        dayBefore: "2026-11-07", canFreeze: freeze)
    }
    #expect(next("2026-11-09", false) == 4)
    #expect(next("2026-11-08", false) == 5)
    #expect(next("2026-11-07", false) == 1)
    #expect(next("2026-11-07", true) == 5)
    #expect(next(nil, false) == 1)
  }

  @Test(
    "Leitner: bilinen kelime kutu atlar, bilinmeyen 1. kutuya döner, 5. kutudan sonra öğrenilir")
  func leitner() {
    let now = Date(timeIntervalSince1970: 0)
    #expect(LeitnerRules.review(box: 1, knew: true, now: now).box == 2)
    #expect(LeitnerRules.review(box: 4, knew: false, now: now).box == 1)
    #expect(LeitnerRules.review(box: 5, knew: true, now: now).learned)
  }

  @Test("Bitiş: yanlış kelimeler deftere eklenir, ilk bulmaca rozeti açılır, seri başlar")
  func finishFlow() {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    let result = store.finish(
      puzzleId: "a1_01", marks: ["e1": true, "e2": false],
      wordIdsByEntry: ["e1": "w_house", "e2": "w_racer"], isPremium: false, now: .now)
    #expect(result.correct == 1)
    #expect(result.addedToNotebook == ["w_racer"])
    #expect(result.newBadges.contains(.firstPuzzle))
    #expect(store.stats.streak == 1)
    #expect(store.notebook.map(\.wordId) == ["w_racer"])
    #expect(store.progress(for: "a1_01").status == .finished)
  }

  @Test("Tekrar bulmacası: doğru kelime kutu atlar, yanlış kelime 1. kutuya döner")
  func reviewPuzzleMovesBoxes() {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    store.addToNotebook(wordId: "w_house", source: "manual")
    store.addToNotebook(wordId: "w_racer", source: "manual")
    let result = store.finish(
      puzzleId: "review_1", marks: ["e1": true, "e2": false],
      wordIdsByEntry: ["e1": "w_house", "e2": "w_racer"], isPremium: true, now: .now)
    let boxes = Dictionary(uniqueKeysWithValues: store.notebook.map { ($0.wordId, $0.box) })
    #expect(boxes["w_house"] == 2)
    #expect(boxes["w_racer"] == 1)
    #expect(result.addedToNotebook.isEmpty)
  }

  @Test("Seri dondurma: Çengelish+ ile bir günlük boşluk ayda iki kez affedilir")
  func streakFreezeLimit() {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    let calendar = Calendar.current
    let start = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 12))!
    let day = { (offset: Int) in calendar.date(byAdding: .day, value: offset, to: start)! }
    let play = { (offset: Int) in
      store.finish(
        puzzleId: "p\(offset)", marks: ["e": true], wordIdsByEntry: ["e": "w_house"],
        isPremium: true, now: day(offset)
      ).streak
    }
    #expect(play(0) == 1)
    #expect(play(2) == 2)  // 1. dondurma
    #expect(play(4) == 3)  // 2. dondurma
    #expect(play(6) == 1)  // bu ay hak kalmadı
  }

  @Test("İpucu: ücretsiz kullanıcının günde 3 hakkı var")
  func hintQuota() {
    let store = UserDataStore(inMemory: true)
    #expect(store.hintsLeft(isPremium: false) == 3)
    #expect(store.consumeHints(3, isPremium: false))
    #expect(!store.consumeHints(1, isPremium: false))
    #expect(store.hintsLeft(isPremium: true) == nil)
  }

  @Test("Dışa aktarılan veri geri yüklenince profil ve defter aynı kalır")
  func backupRoundTrip() throws {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Ece", avatar: AvatarConfig(body: .pink)))
    store.addToNotebook(wordId: "w_heron", source: "manual")
    let data = try store.exportData()
    store.deleteAll()
    #expect(store.profile == nil)
    try store.importData(data)
    #expect(store.profile?.nickname == "Ece")
    #expect(store.profile?.avatar.body == .pink)
    #expect(store.notebook.map(\.wordId) == ["w_heron"])
  }
}
