import Combine
import DesignKit
import Foundation
import OSLog
import SwiftData

/// SwiftData tabanlı kullanıcı verisi deposu.
@MainActor
public final class UserDataStore: ObservableObject, UserDataStoring {

  // MARK: - Properties

  @Published private var revision = 0
  private let container: ModelContainer
  private let calendar: Calendar
  private let logger = Logger(subsystem: "com.hasangurbuz.cengelish", category: "data")
  private var context: ModelContext { container.mainContext }

  public var changes: AnyPublisher<Void, Never> {
    $revision.dropFirst().map { _ in () }.eraseToAnyPublisher()
  }

  // MARK: - Init

  /// Depoyu oluşturur. Testlerde `inMemory: true` kullanılır.
  public init(inMemory: Bool = false, calendar: Calendar = .current) {
    self.container = ContainerFactory.make(inMemory: inMemory)
    self.calendar = calendar
  }

  // MARK: - Profile

  public var profile: UserProfile? {
    guard let record = fetchFirst(ProfileRecord.self) else { return nil }
    return UserProfile(
      nickname: record.nickname,
      avatar: record.avatarData.flatMap { try? JSONDecoder().decode(AvatarConfig.self, from: $0) }
        ?? AvatarConfig(),
      titleId: record.title,
      showcaseBadges: record.showcaseBadges,
      level: record.level,
      goals: record.goals,
      dailyGoal: record.dailyGoal,
      createdAt: record.createdAt
    )
  }

  public func createProfile(_ profile: UserProfile) {
    let record = fetchFirst(ProfileRecord.self) ?? insert(ProfileRecord())
    apply(profile, to: record)
    record.createdAt = profile.createdAt
    commit()
  }

  public func updateProfile(_ profile: UserProfile) {
    guard let record = fetchFirst(ProfileRecord.self) else { return createProfile(profile) }
    apply(profile, to: record)
    commit()
  }

  // MARK: - Settings

  public var settings: AppSettings {
    guard let r = fetchFirst(SettingsRecord.self) else { return AppSettings() }
    var s = AppSettings()
    s.appearance = Appearance(rawValue: r.appearance) ?? .system
    s.puzzleTheme = r.puzzleTheme
    s.penColor = r.penColor
    s.penWidth = r.penWidth
    s.autoNightTheme = r.autoNightTheme
    s.highContrast = r.highContrast
    s.accent = SpeechAccent(rawValue: r.accent) ?? .us
    s.leftHanded = r.leftHanded
    s.autoAdvance = r.autoAdvance
    s.pencilOnly = r.pencilOnly
    s.reminderEnabled = r.reminderEnabled
    s.reminderHour = r.reminderHour
    s.reminderMinute = r.reminderMinute
    return s
  }

  public func updateSettings(_ change: (inout AppSettings) -> Void) {
    var s = settings
    change(&s)
    let r = fetchFirst(SettingsRecord.self) ?? insert(SettingsRecord())
    r.appearance = s.appearance.rawValue
    r.puzzleTheme = s.puzzleTheme
    r.penColor = s.penColor
    r.penWidth = s.penWidth
    r.autoNightTheme = s.autoNightTheme
    r.highContrast = s.highContrast
    r.accent = s.accent.rawValue
    r.leftHanded = s.leftHanded
    r.autoAdvance = s.autoAdvance
    r.pencilOnly = s.pencilOnly
    r.reminderEnabled = s.reminderEnabled
    r.reminderHour = s.reminderHour
    r.reminderMinute = s.reminderMinute
    commit()
  }

  // MARK: - Progress

  public func progress(for puzzleId: String) -> PuzzleProgress {
    guard let record = progressRecord(puzzleId) else { return PuzzleProgress(puzzleId: puzzleId) }
    return Self.snapshot(record)
  }

  public func allProgress() -> [String: PuzzleProgress] {
    let records = (try? context.fetch(FetchDescriptor<PuzzleProgressRecord>())) ?? []
    var result: [String: PuzzleProgress] = [:]
    for record in records {
      var snapshot = Self.snapshot(record)
      snapshot.drawing = nil
      result[record.puzzleId] = snapshot
    }
    return result
  }

  public func saveDraft(puzzleId: String, drawing: Data?, durationSec: Int) {
    let record = progressRecord(puzzleId) ?? insert(PuzzleProgressRecord(puzzleId: puzzleId))
    record.drawing = drawing
    record.durationSec = max(record.durationSec, durationSec)
    if record.status == PuzzleStatus.notStarted.rawValue {
      record.status = PuzzleStatus.inProgress.rawValue
      record.startedAt = .now
    }
    record.updatedAt = .now
    commit()
  }

  public func saveRevealed(puzzleId: String, cells: Set<String>, hintsUsed: Int) {
    let record = progressRecord(puzzleId) ?? insert(PuzzleProgressRecord(puzzleId: puzzleId))
    record.revealedData = try? JSONEncoder().encode(cells.sorted())
    record.hintsUsed = hintsUsed
    record.updatedAt = .now
    commit()
  }

  public func finish(
    puzzleId: String, marks: [String: Bool], wordIdsByEntry: [String: String],
    isPremium: Bool, now: Date
  ) -> FinishResult {
    let record = progressRecord(puzzleId) ?? insert(PuzzleProgressRecord(puzzleId: puzzleId))
    let wasFinished = record.status == PuzzleStatus.finished.rawValue
    let correct = marks.values.filter { $0 }.count
    let stars = StarRules.stars(correct: correct, total: marks.count, hints: record.hintsUsed)
    record.marksData = try? JSONEncoder().encode(marks)
    record.status = PuzzleStatus.finished.rawValue
    record.finishedAt = now
    record.stars = max(record.stars, stars)

    let stats = statsRecord()
    let before = snapshot(stats)
    let today = DayMath.key(now, calendar)
    if !wasFinished {
      stats.puzzlesSolved += 1
      stats.wordsSeen += correct
      if correct == marks.count, !marks.isEmpty { stats.perfectCount += 1 }
    }
    stats.streak = StreakRules.next(
      current: stats.streak, lastDay: stats.lastPlayedDay, today: today,
      yesterday: DayMath.key(now, calendar, offset: -1),
      dayBefore: DayMath.key(now, calendar, offset: -2), canFreeze: isPremium)
    stats.longestStreak = max(stats.longestStreak, stats.streak)
    stats.lastPlayedDay = today
    if !stats.solvedDays.contains(today) { stats.solvedDays.append(today) }

    var added: [String] = []
    for (entryId, isCorrect) in marks where !isCorrect {
      guard let wordId = wordIdsByEntry[entryId] else { continue }
      if insertNotebook(wordId: wordId) { added.append(wordId) }
    }
    let newBadges = awardBadges(
      before: before, after: snapshot(stats), durationSec: record.durationSec, now: now)
    commit()
    return FinishResult(
      stars: stars, correct: correct, total: marks.count, streak: stats.streak,
      newBadges: newBadges, addedToNotebook: added)
  }

  public func resetProgress(puzzleId: String) {
    guard let record = progressRecord(puzzleId) else { return }
    context.delete(record)
    commit()
  }

  // MARK: - Notebook

  public var notebook: [NotebookItem] {
    let descriptor = FetchDescriptor<NotebookRecord>(sortBy: [SortDescriptor(\.nextReviewAt)])
    return ((try? context.fetch(descriptor)) ?? []).map {
      NotebookItem(
        wordId: $0.wordId, box: $0.box, nextReviewAt: $0.nextReviewAt, learned: $0.learned,
        addedAt: $0.addedAt)
    }
  }

  public func addToNotebook(wordId: String) {
    if insertNotebook(wordId: wordId) { commit() }
  }

  public func removeFromNotebook(wordId: String) {
    notebookRecords(wordId).forEach(context.delete)
    commit()
  }

  public func review(wordId: String, knew: Bool) {
    guard let record = notebookRecords(wordId).first else { return }
    let result = LeitnerRules.review(box: record.box, knew: knew, now: .now)
    record.box = result.box
    record.nextReviewAt = result.next
    record.learned = result.learned
    commit()
  }

  // MARK: - Stats & badges

  public var stats: UserStats {
    var s = snapshot(statsRecord(createIfNeeded: false))
    s.streak = StreakRules.visibleStreak(
      s.streak, lastDay: s.lastPlayedDay, today: DayMath.key(.now, calendar),
      yesterday: DayMath.key(.now, calendar, offset: -1))
    return s
  }

  public var badges: [BadgeKind: Date] {
    let records = (try? context.fetch(FetchDescriptor<BadgeRecord>())) ?? []
    var result: [BadgeKind: Date] = [:]
    for record in records {
      guard let kind = BadgeKind(rawValue: record.badgeId) else { continue }
      result[kind] = min(result[kind] ?? record.unlockedAt, record.unlockedAt)
    }
    return result
  }

  public func hintsLeft(isPremium: Bool) -> Int? {
    guard !isPremium else { return nil }
    let stats = statsRecord(createIfNeeded: false)
    let used = stats?.hintDay == DayMath.key(.now, calendar) ? stats?.hintsUsedToday ?? 0 : 0
    return max(0, HintRules.freeDailyHints - used)
  }

  public func consumeHints(_ count: Int, isPremium: Bool) -> Bool {
    if let left = hintsLeft(isPremium: isPremium), left < count { return false }
    let stats = statsRecord()
    let today = DayMath.key(.now, calendar)
    if stats.hintDay != today {
      stats.hintDay = today
      stats.hintsUsedToday = 0
    }
    stats.hintsUsedToday += count
    commit()
    return true
  }

  // MARK: - Data

  public var isICloudBackupEnabled: Bool {
    UserDefaults.standard.bool(forKey: ContainerFactory.iCloudKey)
  }

  public var isICloudAvailable: Bool { ContainerFactory.isCloudAvailable }

  public func setICloudBackup(_ enabled: Bool) {
    UserDefaults.standard.set(enabled, forKey: ContainerFactory.iCloudKey)
    revision += 1
  }

  public func storageUsage() -> StorageUsage {
    let records = (try? context.fetch(FetchDescriptor<PuzzleProgressRecord>())) ?? []
    let drawings = records.reduce(0) { $0 + ($1.drawing?.count ?? 0) }
    let progress = records.count * 400 + notebook.count * 120
    return StorageUsage(drawings: drawings, progress: progress, profile: 2_048)
  }

  public func exportData() throws -> Data {
    try BackupCoder.encode(from: context)
  }

  public func importData(_ data: Data) throws {
    try BackupCoder.restore(data, into: context)
    commit()
  }

  public func clearOldDrawings(keep: Int) -> Int {
    var descriptor = FetchDescriptor<PuzzleProgressRecord>(
      predicate: #Predicate { $0.status == "finished" },
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
    descriptor.includePendingChanges = true
    let finished = (try? context.fetch(descriptor)) ?? []
    var cleared = 0
    for record in finished.dropFirst(keep) where record.drawing != nil {
      record.drawing = nil
      cleared += 1
    }
    commit()
    return cleared
  }

  public func deleteAll() {
    for model in UserSchema.models {
      try? context.delete(model: model)
    }
    commit()
  }

  // MARK: - Private helpers

  /// Değişiklikleri kaydeder ve dinleyicilere haber verir.
  private func commit() {
    do {
      try context.save()
    } catch {
      logger.error("Kayıt başarısız: \(error.localizedDescription)")
    }
    revision += 1
  }

  private func fetchFirst<T: PersistentModel>(_ type: T.Type) -> T? {
    var descriptor = FetchDescriptor<T>()
    descriptor.fetchLimit = 1
    return try? context.fetch(descriptor).first
  }

  @discardableResult
  private func insert<T: PersistentModel>(_ model: T) -> T {
    context.insert(model)
    return model
  }

  private func apply(_ profile: UserProfile, to record: ProfileRecord) {
    record.nickname = profile.nickname
    record.avatarData = try? JSONEncoder().encode(profile.avatar)
    record.title = profile.titleId
    record.showcaseBadges = Array(profile.showcaseBadges.prefix(3))
    record.level = profile.level
    record.goals = profile.goals
    record.dailyGoal = profile.dailyGoal
  }

  private func progressRecord(_ puzzleId: String) -> PuzzleProgressRecord? {
    var descriptor = FetchDescriptor<PuzzleProgressRecord>(
      predicate: #Predicate { $0.puzzleId == puzzleId })
    descriptor.fetchLimit = 1
    return try? context.fetch(descriptor).first
  }

  private func notebookRecords(_ wordId: String) -> [NotebookRecord] {
    let descriptor = FetchDescriptor<NotebookRecord>(predicate: #Predicate { $0.wordId == wordId })
    return (try? context.fetch(descriptor)) ?? []
  }

  /// Kelimeyi deftere ekler; eklendiyse true döner.
  private func insertNotebook(wordId: String) -> Bool {
    if let existing = notebookRecords(wordId).first {
      existing.box = 1
      existing.learned = false
      existing.nextReviewAt = .now
      return false
    }
    insert(NotebookRecord(wordId: wordId))
    return true
  }

  private func statsRecord() -> StatsRecord {
    statsRecord(createIfNeeded: true) ?? insert(StatsRecord())
  }

  private func statsRecord(createIfNeeded: Bool) -> StatsRecord? {
    if let existing = fetchFirst(StatsRecord.self) { return existing }
    return createIfNeeded ? insert(StatsRecord()) : nil
  }

  private func snapshot(_ record: StatsRecord?) -> UserStats {
    var s = UserStats()
    guard let record else { return s }
    s.streak = record.streak
    s.longestStreak = record.longestStreak
    s.lastPlayedDay = record.lastPlayedDay
    s.puzzlesSolved = record.puzzlesSolved
    s.wordsSeen = record.wordsSeen
    s.perfectCount = record.perfectCount
    s.hintsUsedToday =
      record.hintDay == DayMath.key(.now, calendar) ? record.hintsUsedToday : 0
    s.solvedDays = record.solvedDays
    return s
  }

  private static func snapshot(_ record: PuzzleProgressRecord) -> PuzzleProgress {
    var p = PuzzleProgress(puzzleId: record.puzzleId)
    p.status = PuzzleStatus(rawValue: record.status) ?? .notStarted
    p.durationSec = record.durationSec
    p.hintsUsed = record.hintsUsed
    p.marks =
      record.marksData.flatMap { try? JSONDecoder().decode([String: Bool].self, from: $0) } ?? [:]
    p.revealedCells = Set(
      record.revealedData.flatMap { try? JSONDecoder().decode([String].self, from: $0) } ?? [])
    p.stars = record.stars
    p.finishedAt = record.finishedAt
    p.drawing = record.drawing
    return p
  }

  /// Koşulu yeni sağlanan rozetleri ekler ve döner.
  private func awardBadges(
    before: UserStats, after: UserStats, durationSec: Int, now: Date
  )
    -> [BadgeKind]
  {
    let owned = Set(badges.keys)
    let hour = calendar.component(.hour, from: now)
    var earned: [BadgeKind] = []
    for kind in BadgeKind.allCases where !owned.contains(kind) {
      let unlocked: Bool =
        switch kind {
        case .firstPuzzle: after.puzzlesSolved >= 1
        case .streak7: after.longestStreak >= 7
        case .streak30: after.longestStreak >= 30
        case .words100: after.wordsSeen >= 100
        case .words500: after.wordsSeen >= 500
        case .perfect: after.perfectCount > before.perfectCount
        case .nightOwl: hour >= 22 || hour < 5
        case .speed: durationSec > 0 && durationSec < 180
        }
      if unlocked {
        insert(BadgeRecord(badgeId: kind.rawValue))
        earned.append(kind)
      }
    }
    return earned
  }
}

/// Gün anahtarı hesapları.
enum DayMath {
  /// Tarihi (isteğe bağlı gün kaydırmasıyla) `yyyy-MM-dd` metnine çevirir.
  static func key(_ date: Date, _ calendar: Calendar, offset: Int = 0) -> String {
    let shifted = calendar.date(byAdding: .day, value: offset, to: date) ?? date
    let p = calendar.dateComponents([.year, .month, .day], from: shifted)
    return String(format: "%04d-%02d-%02d", p.year ?? 0, p.month ?? 0, p.day ?? 0)
  }
}
