import Combine
import ContentKit
import DesignKit
import Foundation
import PurchaseKit
import Testing
import UserDataKit
import WordKit
@testable import HomeModule

@Suite("HomeViewModel")
@MainActor
struct HomeViewModelTests {

  @Test("Haftalık gün yapısı eşitlik karşılaştırmasını destekler")
  func weekDayEquality() {
    let day = WeekDay(id: "2026-11-09", label: "Pt", isSolved: true, isToday: true)
    #expect(day == WeekDay(id: "2026-11-09", label: "Pt", isSolved: true, isToday: true))
  }

  @Test("Başlık takma adı ve günlük hedefi gösterir")
  func header() async {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig(), dailyGoal: 3))
    let sut = makeSUT(store: store)
    await sut.load()
    #expect(sut.greeting == "Merhaba Deniz!")
    #expect(sut.goalText == "Bugün 3 bulmaca hedefin var")
  }

  @Test("Plus kullanıcı dünü kaçırınca seri dondurmanın seriyi koruduğu söylenir")
  func freezeProtectsStreak() async {
    let store = UserDataStore(inMemory: true)
    _ = store.finish(
      puzzleId: "p1", marks: ["e": true], wordIdsByEntry: [:], isPremium: true,
      now: .now.addingTimeInterval(-2 * 86_400))
    let plus = makeSUT(store: store, plus: true)
    await plus.load()
    #expect(plus.freezeHint?.contains("seri dondurma serini koruyor") == true)
    #expect(!plus.showsFreezeTeaser)

    let free = makeSUT(store: store, plus: false)
    await free.load()
    #expect(free.streak == 0)
    #expect(free.freezeHint == nil)
  }

  @Test("Plus kullanıcıya kalan dondurma hakkı gösterilir")
  func freezeAvailable() async {
    let sut = makeSUT(store: UserDataStore(inMemory: true), plus: true)
    await sut.load()
    #expect(sut.freezeHint?.contains("2 hak") == true)
  }

  @Test("Plus olmayan kullanıcıya Plus kartı ve seri dondurma tanıtımı gösterilir, paywall açılır")
  func plusPromo() async {
    let router = RouterSpy()
    let free = makeSUT(store: UserDataStore(inMemory: true), plus: false, router: router)
    await free.load()
    #expect(!free.isPlus)
    #expect(free.showsPlusPromo)
    #expect(free.showsFreezeTeaser)
    free.openPaywall()
    #expect(router.paywallCount == 1)

    let plus = makeSUT(store: UserDataStore(inMemory: true), plus: true)
    await plus.load()
    #expect(plus.isPlus)
    #expect(!plus.showsPlusPromo)
    #expect(!plus.showsFreezeTeaser)
  }

  @Test("Plus butonu üyede de paywall'u açar (paywall üyelik durumunu gösterir)")
  func plusButtonOpensPaywallForMember() async {
    let router = RouterSpy()
    let member = makeSUT(store: UserDataStore(inMemory: true), plus: true, router: router)
    await member.load()
    #expect(member.isPlus)
    member.openPaywall()
    #expect(router.paywallCount == 1)
  }

  @Test("Hatırlatıcı kısayolu durumu ve saati gösterir, paneli açar")
  func reminderShortcut() async {
    let store = UserDataStore(inMemory: true)
    let actions = ReminderActions(
      requestPermission: { true }, apply: { _, _ in }, refreshStreakWarning: { _, _ in })
    let sut = makeSUT(store: store, reminders: actions)
    await sut.load()
    #expect(sut.reminderShortcut == "Günlük hatırlatıcı kur")
    sut.openReminders()
    #expect(sut.isReminderSheetOpen)
    await sut.setReminder(true)
    sut.setReminderTime(hour: 7, minute: 30)
    await sut.load()
    #expect(sut.reminderShortcut == "Hatırlatıcı her gün 07:30")
  }

  @Test("Bulmaca yokken Günün Bulmacası açılmaz")
  func openDailyWithoutPuzzle() async {
    let router = RouterSpy()
    let sut = makeSUT(store: UserDataStore(inMemory: true), router: router)
    await sut.load()
    sut.openDaily()
    #expect(router.opened.isEmpty)
  }

  @Test("Hatırlatıcı izin verilince açılır, saat değişince bildirim yeniden kurulur")
  func reminder() async {
    let store = UserDataStore(inMemory: true)
    var applied: [AppSettings] = []
    let actions = ReminderActions(
      requestPermission: { true }, apply: { settings, _ in applied.append(settings) },
      refreshStreakWarning: { _, _ in })
    let sut = makeSUT(store: store, reminders: actions)
    await sut.setReminder(true)
    #expect(store.settings.reminderEnabled)
    sut.setReminderTime(hour: 21, minute: 5)
    #expect(store.settings.reminderHour == 21)
    #expect(applied.count == 2)
    await sut.load()
    #expect(sut.reminderDetail == "Her gün 21:05 · Günün bulmacası hazır")
  }

  @Test("İzin verilmezse hatırlatıcı kapalı kalır ve bilgi gösterilir")
  func reminderDenied() async {
    let store = UserDataStore(inMemory: true)
    let actions = ReminderActions(
      requestPermission: { false }, apply: { _, _ in }, refreshStreakWarning: { _, _ in })
    let sut = makeSUT(store: store, reminders: actions)
    await sut.setReminder(true)
    #expect(!store.settings.reminderEnabled)
    #expect(sut.notice != nil)
  }

  private func makeSUT(
    store: UserDataStore, plus: Bool = false, router: RouterSpy = RouterSpy(),
    reminders: ReminderActions = ReminderActions(
      requestPermission: { false }, apply: { _, _ in }, refreshStreakWarning: { _, _ in })
  ) -> HomeViewModel {
    let entitlements = EntitlementStub()
    entitlements.isPremium = plus
    return HomeViewModel(
      router: router, content: EmptyContent(), userData: store,
      entitlements: entitlements, pronouncer: SilentPronouncer(), reminders: reminders)
  }
}

@Suite("ReminderScheduler.streakWarning")
struct StreakWarningTests {
  private let calendar = Calendar(identifier: .gregorian)

  /// 9 Kasım 2026 verilen saatte.
  private func date(day: Int = 9, hour: Int, minute: Int = 0) -> Date {
    calendar.date(
      from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute)) ?? .now
  }

  private func stats(streak: Int, lastDay: String?) -> UserStats {
    var stats = UserStats()
    stats.streak = streak
    stats.lastPlayedDay = lastDay
    return stats
  }

  private func settings(enabled: Bool = true, hour: Int = 20) -> AppSettings {
    var settings = AppSettings()
    settings.reminderEnabled = enabled
    settings.reminderHour = hour
    return settings
  }

  @Test("Bugün oynanmadıysa uyarı bugün 21:30'a kurulur")
  func todayEvening() {
    let warning = ReminderScheduler.streakWarning(
      settings: settings(), stats: stats(streak: 5, lastDay: "2026-11-08"),
      now: date(hour: 12), calendar: calendar)
    #expect(warning?.fireDate == date(hour: 21, minute: 30))
    #expect(warning?.body == "5 günlük serin bozulmak üzere! Bugünün bulmacasını çöz.")
  }

  @Test("Bugün oynandıysa uyarı yarın akşama kayar")
  func playedToday() {
    let warning = ReminderScheduler.streakWarning(
      settings: settings(), stats: stats(streak: 6, lastDay: "2026-11-09"),
      now: date(hour: 22), calendar: calendar)
    #expect(warning?.fireDate == date(day: 10, hour: 21, minute: 30))
    #expect(warning?.streak == 6)
  }

  @Test("Hatırlatıcı kapalıysa, seri yoksa ya da saat geçtiyse uyarı kurulmaz")
  func noWarning() {
    #expect(
      ReminderScheduler.streakWarning(
        settings: settings(enabled: false), stats: stats(streak: 5, lastDay: "2026-11-08"),
        now: date(hour: 12), calendar: calendar) == nil)
    #expect(
      ReminderScheduler.streakWarning(
        settings: settings(), stats: stats(streak: 3, lastDay: "2026-11-01"),
        now: date(hour: 12), calendar: calendar) == nil)
    #expect(
      ReminderScheduler.streakWarning(
        settings: settings(), stats: stats(streak: 5, lastDay: "2026-11-08"),
        now: date(hour: 22), calendar: calendar) == nil)
  }

  @Test("Geç hatırlatıcıda uyarı hatırlatıcıdan bir saat sonraya kurulur")
  func lateReminder() {
    let warning = ReminderScheduler.streakWarning(
      settings: settings(hour: 22), stats: stats(streak: 2, lastDay: "2026-11-08"),
      now: date(hour: 12), calendar: calendar)
    #expect(warning?.fireDate == date(hour: 23))
  }
}

private struct EmptyContent: ContentProviding {
  func packs() async -> [Pack] { [] }
  func pack(id: String) async -> Pack? { nil }
  func puzzle(id: String) async -> Puzzle? { nil }
  func puzzles(inPack packId: String) async -> [Puzzle] { [] }
  func words(ids: [String]) async -> [Word] { [] }
  func dailyPuzzle(for date: Date) async -> Puzzle? { nil }
}

/// Açılan ekranları kaydeder.
@MainActor
private final class RouterSpy: HomeRouting {
  private(set) var opened: [String] = []
  private(set) var paywallCount = 0
  func showPuzzle(_ id: String) { opened.append(id) }
  func showPaywall() { paywallCount += 1 }
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

@MainActor
private final class SilentPronouncer: Pronouncing {
  func speak(_ text: String, language: String) {}
}
