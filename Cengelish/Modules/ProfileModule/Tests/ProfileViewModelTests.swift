import Combine
import DesignKit
import Foundation
import PurchaseKit
import Testing
import UserDataKit

@testable import ProfileModule

@MainActor
struct ProfileViewModelTests {

  /// Sabit (UTC) takvim.
  private static var utc: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
  }

  /// 2026 içinde verilen günün öğlesi.
  private static func date(month: Int = 11, day: Int, hour: Int = 12) -> Date {
    utc.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour)) ?? .now
  }

  private func makeViewModel(
    store: UserDataStore, premium: Bool = false, now: Date = ProfileViewModelTests.date(day: 9)
  ) -> ProfileViewModel {
    let entitlements = EntitlementStub()
    entitlements.isPremium = premium
    return ProfileViewModel(
      coordinator: ProfileCoordinator(), userData: store, entitlements: entitlements,
      calendar: Self.utc, now: { now })
  }

  // MARK: - Unlocks

  @Test("Kilitli aksesuarlar kural tablosuna göre açılır")
  func unlocks() {
    var stats = UserStats()
    #expect(!UnlockRules.isUnlocked(.headphones, stats: stats, isPremium: false))
    stats.wordsSeen = 100
    #expect(UnlockRules.isUnlocked(.headphones, stats: stats, isPremium: false))
    #expect(UnlockRules.isUnlocked(.crown, stats: UserStats(), isPremium: true))
  }

  // MARK: - Level progress

  @Test("Seviye: kalan = hedef - (görülen + öğrenilen), çubuk = çalışılan / hedef")
  func levelProgress() {
    let b1 = LevelProgress(levelId: "B1", wordsSeen: 800, learnedWords: 64)
    #expect(b1.practiced == 864)
    #expect(b1.target == 1_200)
    #expect(b1.remaining == 336)
    #expect(abs(b1.fraction - 0.72) < 0.0001)
    #expect(b1.headline == "B1 · Orta")
    #expect(b1.detail == "B2'ye 336 kelime")
  }

  @Test("Seviye: hedefe ulaşınca hazırsın, C1 en üst, bilinmeyen seviye A1 sayılır")
  func levelEdges() {
    #expect(LevelProgress(levelId: "A2", wordsSeen: 700, learnedWords: 0).detail == "B1'e hazırsın")
    #expect(LevelProgress(levelId: "A2", wordsSeen: 700, learnedWords: 0).fraction == 1)
    #expect(
      LevelProgress(levelId: "C1", wordsSeen: 120, learnedWords: 0).detail == "120/3000 kelime")
    #expect(LevelProgress(levelId: "x", wordsSeen: 0, learnedWords: 0).detail == "A2'ye 300 kelime")
  }

  // MARK: - Turkish text

  @Test("Yıl ekleri okunuşa göre seçilir")
  func ablative() {
    #expect(TurkishSuffix.ablative(2026) == "'dan")
    #expect(TurkishSuffix.ablative(2025) == "'ten")
    #expect(TurkishSuffix.ablative(2027) == "'den")
    #expect(TurkishSuffix.ablative(2030) == "'dan")
    #expect(TurkishSuffix.ablative(2040) == "'tan")
    #expect(
      ProfileDateText.since(Self.date(month: 10, day: 3), calendar: Self.utc)
        == "Ekim 2026'dan beri")
  }

  @Test("Göreli zaman: dk / sa / gün")
  func relative() {
    let now = Self.date(day: 9)
    #expect(ProfileDateText.relative(now.addingTimeInterval(-20), now: now) == "az önce")
    #expect(ProfileDateText.relative(now.addingTimeInterval(-120), now: now) == "2 dk önce")
    #expect(ProfileDateText.relative(now.addingTimeInterval(-7_200), now: now) == "2 sa önce")
    #expect(ProfileDateText.relative(now.addingTimeInterval(-86_400 * 3), now: now) == "3 gün önce")
  }

  // MARK: - Calendar

  @Test("Takvim: pazartesi başlar, çözülen, bugün ve dondurulan günler işaretlenir")
  func streakMonth() {
    let solved: Set = ["2026-11-02", "2026-11-04", "2026-11-09"]
    let month = StreakMonth.make(
      containing: Self.date(day: 15), solvedDays: solved, today: Self.date(day: 9),
      canFreeze: true, calendar: Self.utc)
    #expect(month.title == "Kasım 2026")
    #expect(month.leadingBlanks == 6)  // 1 Kasım 2026 pazar.
    #expect(month.days.count == 30)
    #expect(month.solvedCount == 3)
    #expect(month.days[2].state == .frozen)
    #expect(month.days[8].isToday)
    #expect(month.days[9].state == .future)
    let free = StreakMonth.make(
      containing: Self.date(day: 15), solvedDays: solved, today: Self.date(day: 9),
      canFreeze: false, calendar: Self.utc)
    #expect(free.frozenCount == 0)
  }

  @Test("Takvim gezinmesi gelecek aya ve profil öncesine gitmez")
  func monthNavigation() {
    let store = UserDataStore(inMemory: true, calendar: Self.utc)
    store.createProfile(
      UserProfile(
        nickname: "Deniz", avatar: AvatarConfig(), createdAt: Self.date(month: 10, day: 5)))
    let viewModel = makeViewModel(store: store)
    #expect(!viewModel.canShowNextMonth)
    viewModel.shiftMonth(by: 1)
    #expect(viewModel.month.title == "Kasım 2026")
    viewModel.shiftMonth(by: -1)
    #expect(viewModel.month.title == "Ekim 2026")
    #expect(!viewModel.canShowPreviousMonth)
    #expect(viewModel.canShowNextMonth)
  }

  // MARK: - Profile

  @Test("Profil satırı: Türkçe ay, rozet sayısı, eski unvan eşlemesi")
  func profileTexts() {
    let store = UserDataStore(inMemory: true, calendar: Self.utc)
    store.createProfile(
      UserProfile(
        nickname: "Deniz", avatar: AvatarConfig(), titleId: "kurt",
        createdAt: Self.date(month: 10, day: 5)))
    _ = store.finish(
      puzzleId: "a1_01", marks: ["e1": true], wordIdsByEntry: ["e1": "w_a"], isPremium: false,
      now: Self.date(day: 9))
    let viewModel = makeViewModel(store: store)
    #expect(viewModel.title == .bulmacaKurdu)
    #expect(viewModel.draftTitle == .bulmacaKurdu)
    let count = store.badges.count
    #expect(viewModel.memberSinceText == "Ekim 2026'dan beri · \(count) rozet")
    #expect(viewModel.dataTimestamp == "Yedek yok")
  }

  @Test("Takma ad 16 karakterle sınırlanır ve sayaç gösterilir")
  func nicknameLimit() {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    let viewModel = makeViewModel(store: store)
    #expect(viewModel.nicknameCounter == "5/16")
    viewModel.draft.nickname = String(repeating: "a", count: 20)
    viewModel.limitNickname()
    #expect(viewModel.nicknameCounter == "16/16")
  }

  @Test("Vitrin en fazla 3 rozet tutar ve dokununca açılıp kapanır")
  func showcaseToggle() {
    let store = UserDataStore(inMemory: true, calendar: Self.utc)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    // Gece, hızlı ve hatasız bitiriş: İlk Bulmaca, Hatasız, Gece Kuşu, Hız Ustası.
    store.saveDraft(puzzleId: "a1_01", drawing: nil, durationSec: 60)
    _ = store.finish(
      puzzleId: "a1_01", marks: ["e1": true], wordIdsByEntry: ["e1": "w_a"], isPremium: false,
      now: Self.date(day: 9, hour: 23))
    let viewModel = makeViewModel(store: store)
    #expect(viewModel.earned.count >= 4)
    let first = viewModel.showcase[0]
    viewModel.toggleShowcase(first)
    #expect(!viewModel.showcase.contains(first))
    #expect(viewModel.showcase.count == 2)
    viewModel.toggleShowcase(first)
    #expect(viewModel.showcase.count == 3)
    #expect(viewModel.showcase.contains(first))
  }

  @Test("Çengelish+ kullanıcısı için bu ayki dondurmalar sayılır")
  func freezes() {
    let store = UserDataStore(inMemory: true, calendar: Self.utc)
    for day in [6, 8] {
      _ = store.finish(
        puzzleId: "a1_0\(day)", marks: ["e1": true], wordIdsByEntry: [:], isPremium: true,
        now: Self.date(day: day))
    }
    let viewModel = makeViewModel(store: store, premium: true)
    #expect(viewModel.freezesUsedThisMonth == 1)
    #expect(viewModel.freezeText == "Seri dondurma · bu ay 1/2 kullanıldı")
  }
}

@MainActor
private final class EntitlementStub: EntitlementProviding {
  var changes: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
  var isPremium = false
  var ownedProductIds: Set<String> = []
  var products: [StoreProduct] = []
  func loadProducts() async {}
  func purchase(_ productId: String) async -> PurchaseOutcome { .cancelled }
  func restore() async {}
}
