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
    store.addToNotebook(wordId: "w_heron")
    let data = try store.exportData()
    store.deleteAll()
    #expect(store.profile == nil)
    try store.importData(data)
    #expect(store.profile?.nickname == "Ece")
    #expect(store.profile?.avatar.body == .pink)
    #expect(store.notebook.map(\.wordId) == ["w_heron"])
  }
}
