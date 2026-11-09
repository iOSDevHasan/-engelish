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

  @Test("Premium kullanıcı dünü kaçırınca seri dondurmanın seriyi koruduğu söylenir")
  func freezeProtectsStreak() async {
    let store = UserDataStore(inMemory: true)
    _ = store.finish(
      puzzleId: "p1", marks: ["e": true], wordIdsByEntry: [:], isPremium: true,
      now: .now.addingTimeInterval(-2 * 86_400))
    let premium = makeSUT(store: store, premium: true)
    await premium.load()
    #expect(premium.freezeHint?.contains("seri dondurma serini koruyor") == true)

    let free = makeSUT(store: store, premium: false)
    await free.load()
    #expect(free.streak == 0)
    #expect(free.freezeHint == nil)
  }

  @Test("Premium kullanıcıya kalan dondurma hakkı gösterilir")
  func freezeAvailable() async {
    let sut = makeSUT(store: UserDataStore(inMemory: true), premium: true)
    await sut.load()
    #expect(sut.freezeHint?.contains("2 hak") == true)
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
    store: UserDataStore, premium: Bool = false,
    reminders: ReminderActions = ReminderActions(
      requestPermission: { false }, apply: { _, _ in }, refreshStreakWarning: { _, _ in })
  ) -> HomeViewModel {
    let entitlements = EntitlementStub()
    entitlements.isPremium = premium
    return HomeViewModel(
      coordinator: HomeCoordinator(), content: EmptyContent(), userData: store,
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
  func refreshFromRemote(entitledPackIds: Set<String>) async {}
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
