import Testing
import UserDataKit
@testable import ProfileModule

struct ProfileViewModelTests {

  @Test("Kilitli aksesuarlar kural tablosuna göre açılır")
  func unlocks() {
    var stats = UserStats()
    #expect(!UnlockRules.isUnlocked(.headphones, stats: stats, isPremium: false))
    stats.wordsSeen = 100
    #expect(UnlockRules.isUnlocked(.headphones, stats: stats, isPremium: false))
    #expect(UnlockRules.isUnlocked(.crown, stats: UserStats(), isPremium: true))
  }
}
