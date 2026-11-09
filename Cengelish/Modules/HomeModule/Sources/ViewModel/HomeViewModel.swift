import Combine
import ContentKit
import DesignKit
import Foundation
import PurchaseKit
import UserDataKit
import WordKit

/// Haftalık seri göstergesindeki bir gün.
struct WeekDay: Identifiable, Equatable {
  let id: String
  let label: String
  let isSolved: Bool
  let isToday: Bool
}

/// Kaldığın yerden devam kartı.
struct ContinueItem: Equatable {
  let puzzleId: String
  let title: String
  let progress: Double
}

/// Ana Sayfa durumu.
@MainActor
final class HomeViewModel: ObservableObject {

  // MARK: - Properties

  @Published private(set) var name = "Kalemci"
  @Published private(set) var avatar = AvatarConfig()
  @Published private(set) var streak = 0
  @Published private(set) var longestStreak = 0
  @Published private(set) var week: [WeekDay] = []
  @Published private(set) var solvedToday = 0
  @Published private(set) var dailyGoal = 2
  @Published private(set) var daily: Puzzle?
  @Published private(set) var dailyDone = false
  @Published private(set) var continueItem: ContinueItem?
  @Published private(set) var wordOfDay: Word?
  /// Seri kartındaki seri dondurma ipucu (premium ve hak varsa).
  @Published private(set) var freezeHint: String?
  /// Günlük hatırlatıcı açık mı.
  @Published private(set) var reminderOn = false
  /// Hatırlatıcı saati (saat, dakika).
  @Published private(set) var reminderTime = (hour: 20, minute: 0)
  /// Hatırlatıcı paneli açık mı.
  @Published var isReminderSheetOpen = false
  /// Kısa bilgi mesajı.
  @Published var notice: String?
  private let coordinator: HomeCoordinator
  private let content: any ContentProviding
  private let userData: any UserDataStoring
  private let entitlements: any EntitlementProviding
  private let pronouncer: any Pronouncing
  private let reminders: ReminderActions
  private let calendar = Calendar.current
  private let now: () -> Date
  private var cancellables: Set<AnyCancellable> = []

  // MARK: - Init

  init(
    coordinator: HomeCoordinator, content: any ContentProviding, userData: any UserDataStoring,
    entitlements: any EntitlementProviding, pronouncer: any Pronouncing,
    reminders: ReminderActions = .live, now: @escaping () -> Date = { .now }
  ) {
    self.coordinator = coordinator
    self.content = content
    self.userData = userData
    self.entitlements = entitlements
    self.pronouncer = pronouncer
    self.reminders = reminders
    self.now = now
    userData.changes.merge(with: entitlements.changes)
      .sink { [weak self] in Task { await self?.load() } }
      .store(in: &cancellables)
  }

  // MARK: - Intents

  /// Ekran verisini yükler.
  func load() async {
    if let profile = userData.profile {
      name = profile.displayName
      avatar = profile.avatar
      dailyGoal = profile.dailyGoal
    }
    let stats = userData.stats
    let settings = userData.settings
    reminderOn = settings.reminderEnabled
    reminderTime = (settings.reminderHour, settings.reminderMinute)
    loadStreak(stats)
    reminders.refreshStreakWarning(settings, stats)
    longestStreak = stats.longestStreak
    week = makeWeek(solvedDays: Set(stats.solvedDays))
    let progress = userData.allProgress()
    solvedToday =
      progress.values.filter { item in
        item.finishedAt.map { calendar.isDateInToday($0) } ?? false
      }.count
    daily = await content.dailyPuzzle(for: .now)
    dailyDone = daily.map { progress[$0.id]?.status == .finished } ?? false
    await loadContinue(progress)
    if let daily {
      let words = await content.words(ids: daily.wordIds)
      let dayIndex = calendar.ordinality(of: .day, in: .era, for: .now) ?? 0
      wordOfDay = words.isEmpty ? nil : words[dayIndex % words.count]
    }
  }

  /// Günün Bulmacasını açar.
  func openDaily() {
    guard let daily else { return }
    coordinator.showPuzzle(daily.id)
  }

  /// Yarım kalan bulmacayı açar.
  func openContinue() {
    guard let continueItem else { return }
    coordinator.showPuzzle(continueItem.puzzleId)
  }

  /// Günün kelimesini okur.
  func speakWordOfDay() {
    guard let wordOfDay else { return }
    pronouncer.speak(wordOfDay.en, language: userData.settings.accent.languageCode)
  }

  /// Üst başlıktaki selamlama ("Merhaba Deniz!").
  var greeting: String { "Merhaba \(name)!" }

  /// Günlük hedef cümlesi ("Bugün 2 bulmaca hedefin var").
  var goalText: String { "Bugün \(dailyGoal) bulmaca hedefin var" }

  // MARK: - Reminder

  /// Hatırlatıcı panelini açar.
  func openReminders() {
    isReminderSheetOpen = true
  }

  /// Hatırlatıcıyı açar (izin ister) ya da kapatır.
  func setReminder(_ on: Bool) async {
    let granted = on ? await reminders.requestPermission() : false
    updateReminder { $0.reminderEnabled = on && granted }
    if on, !granted { notice = "Bildirim izni kapalı. iOS Ayarlar → Çengelish'ten açabilirsin." }
  }

  /// Hatırlatıcı saatini değiştirir.
  func setReminderTime(hour: Int, minute: Int) {
    updateReminder {
      $0.reminderHour = hour
      $0.reminderMinute = minute
    }
  }

  /// Hatırlatıcı açıklaması ("Her gün 20:00 · Günün bulmacası hazır").
  var reminderDetail: String {
    String(
      format: "Her gün %02d:%02d · Günün bulmacası hazır", reminderTime.hour, reminderTime.minute)
  }

  // MARK: - Private

  /// Görünen seriyi ve seri dondurma ipucunu hesaplar.
  ///
  /// `UserDataStoring.stats` seriyi dün oynanmadıysa 0 olarak verir; Çengelish+ dondurma hakkı
  /// dünkü boşluğu affettiği için bu durumda kullanıcıya serinin korunduğu söylenir.
  private func loadStreak(_ stats: UserStats) {
    streak = StreakRules.visibleStreak(
      stats.streak, lastDay: stats.lastPlayedDay, today: dayKey(offset: 0),
      yesterday: dayKey(offset: -1))
    let canFreeze = entitlements.isPremium && stats.freezesUsed < StreakRules.monthlyFreezes
    if canFreeze, stats.lastPlayedDay == dayKey(offset: -2) {
      freezeHint = "Dün kaçırdın ama seri dondurma serini koruyor · bugün çöz, seri devam etsin"
    } else if canFreeze {
      let left = StreakRules.monthlyFreezes - stats.freezesUsed
      freezeHint = "Seri dondurma hazır (\(left) hak) · bir gün kaçırsan da serin bozulmaz"
    } else {
      freezeHint = nil
    }
  }

  /// Bugünden `offset` gün uzaktaki günün anahtarı.
  private func dayKey(offset: Int) -> String {
    DayKey.string(from: calendar.date(byAdding: .day, value: offset, to: now()) ?? now())
  }

  /// Hatırlatıcı ayarını kaydedip bildirimleri yeniden kurar.
  private func updateReminder(_ change: (inout AppSettings) -> Void) {
    userData.updateSettings(change)
    reminders.apply(userData.settings, userData.stats)
  }

  private func makeWeek(solvedDays: Set<String>) -> [WeekDay] {
    let labels = ["Pt", "Sa", "Ça", "Pe", "Cu", "Ct", "Pz"]
    let weekday = (calendar.component(.weekday, from: .now) + 5) % 7
    return (0..<7).map { index in
      let date = calendar.date(byAdding: .day, value: index - weekday, to: .now) ?? .now
      let key = DayKey.string(from: date)
      return WeekDay(
        id: key, label: labels[index], isSolved: solvedDays.contains(key), isToday: index == weekday
      )
    }
  }

  private func loadContinue(_ progress: [String: PuzzleProgress]) async {
    guard
      let item = progress.values.first(where: {
        $0.status == .inProgress && $0.puzzleId != daily?.id
          && !$0.puzzleId.hasPrefix(ReviewPuzzleBuilder.idPrefix)
      }),
      let puzzle = await content.puzzle(id: item.puzzleId)
    else {
      continueItem = nil
      return
    }
    var title = "Bulmaca"
    if let packId = puzzle.packId, let pack = await content.pack(id: packId) {
      let index = (pack.puzzleIds.firstIndex(of: puzzle.id) ?? 0) + 1
      title = "\(pack.title) · Bulmaca \(index)"
    }
    continueItem = ContinueItem(
      puzzleId: puzzle.id, title: title, progress: min(0.9, Double(item.durationSec) / 300))
  }
}
