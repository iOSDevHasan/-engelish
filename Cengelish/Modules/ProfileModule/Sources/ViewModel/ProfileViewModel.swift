import Combine
import DesignKit
import Foundation
import PurchaseKit
import UserDataKit

/// Profil ekranlarının ortak durumu.
@MainActor
final class ProfileViewModel: ObservableObject {

  // MARK: - Properties

  /// Takma ad karakter sınırı.
  static let nicknameLimit = 16
  /// Vitrindeki en fazla rozet.
  static let showcaseLimit = 3
  /// Çengelish+ ile ayda kullanılabilen seri dondurma hakkı.
  static let monthlyFreezeAllowance = StreakRules.monthlyFreezes

  @Published private(set) var profile = UserProfile(nickname: "", avatar: AvatarConfig())
  @Published private(set) var stats = UserStats()
  @Published private(set) var badges: [BadgeKind: Date] = [:]
  @Published private(set) var snapshot = AchievementSnapshot(stats: UserStats())
  @Published private(set) var isPremium = false
  @Published private(set) var iCloudOn = false
  @Published private(set) var iCloudAvailable = false
  @Published private(set) var lastBackupAt: Date?
  /// Takvimde gösterilen ay (ayın herhangi bir günü).
  @Published private(set) var displayedMonth: Date
  @Published var draft = UserProfile(nickname: "", avatar: AvatarConfig())
  private let coordinator: ProfileCoordinator
  private let userData: any UserDataStoring
  private let entitlements: any EntitlementProviding
  private let calendar: Calendar
  private let now: () -> Date
  private var cancellables: Set<AnyCancellable> = []

  // MARK: - Init

  init(
    coordinator: ProfileCoordinator, userData: any UserDataStoring,
    entitlements: any EntitlementProviding, calendar: Calendar = .current,
    now: @escaping () -> Date = { .now }
  ) {
    self.coordinator = coordinator
    self.userData = userData
    self.entitlements = entitlements
    self.calendar = calendar
    self.now = now
    self.displayedMonth = now()
    reload()
    draft = profile
    draft.titleId = title.id
    userData.changes.merge(with: entitlements.changes)
      .sink { [weak self] in self?.reload() }
      .store(in: &cancellables)
  }

  // MARK: - Navigation

  func edit() { coordinator.showEdit() }
  func openBadges() { coordinator.showBadges() }
  func openSettings() { coordinator.showSettings() }
  func openPaywall() { coordinator.showPaywall() }
  func back() { coordinator.back() }

  // MARK: - Profile

  /// Seçili unvan (eski kimlikler yenilerine eşlenir).
  var title: UserTitle { UserTitle(storedId: profile.titleId) }

  /// Taslaktaki unvan.
  var draftTitle: UserTitle { UserTitle(storedId: draft.titleId) }

  /// "Ekim 2026'dan beri · 7 rozet".
  var memberSinceText: String {
    "\(ProfileDateText.since(profile.createdAt, calendar: calendar)) · \(badges.count) rozet"
  }

  /// Seviye kartı.
  var levelProgress: LevelProgress {
    LevelProgress(
      levelId: profile.level, wordsSeen: stats.wordsSeen, learnedWords: snapshot.learnedWords)
  }

  /// Veri satırı metni.
  var dataText: String {
    switch (iCloudOn, iCloudAvailable) {
    case (true, true): "Veriler bu cihazda · iCloud yedek açık"
    case (true, false): "Veriler bu cihazda · iCloud'a giriş bekleniyor"
    default: "Veriler sadece bu cihazda"
    }
  }

  /// Veri satırının sağındaki zaman ("2 dk önce") ya da yedek durumu.
  var dataTimestamp: String {
    if let lastBackupAt { return ProfileDateText.relative(lastBackupAt, now: now()) }
    return iCloudOn && iCloudAvailable ? "Otomatik" : "Yedek yok"
  }

  /// Takma adı sınıra göre kırpar.
  func limitNickname() {
    if draft.nickname.count > Self.nicknameLimit {
      draft.nickname = String(draft.nickname.prefix(Self.nicknameLimit))
    }
  }

  /// "5/16".
  var nicknameCounter: String { "\(draft.nickname.count)/\(Self.nicknameLimit)" }

  // MARK: - Streak calendar

  /// Takvimdeki ay.
  var month: StreakMonth {
    StreakMonth.make(
      containing: displayedMonth, solvedDays: Set(stats.solvedDays), today: now(),
      canFreeze: isPremium, calendar: calendar)
  }

  /// Sonraki aya geçilebilir mi (gelecek aylar gösterilmez).
  var canShowNextMonth: Bool { monthStart(displayedMonth) < monthStart(now()) }

  /// Önceki aya geçilebilir mi (profil oluşturulmadan ya da ilk çözümden öncesi gösterilmez).
  var canShowPreviousMonth: Bool { monthStart(displayedMonth) > monthStart(earliestDay) }

  /// Takvimi bir ay kaydırır.
  func shiftMonth(by value: Int) {
    guard value > 0 ? canShowNextMonth : canShowPreviousMonth,
      let date = calendar.date(byAdding: .month, value: value, to: displayedMonth)
    else { return }
    displayedMonth = date
  }

  /// Bu ay kullanılan seri dondurma (Çengelish+).
  var freezesUsedThisMonth: Int {
    StreakMonth.make(
      containing: now(), solvedDays: Set(stats.solvedDays), today: now(), canFreeze: true,
      calendar: calendar
    ).frozenCount
  }

  /// "Seri dondurma · bu ay 1/2 kullanıldı".
  var freezeText: String {
    let used = min(freezesUsedThisMonth, Self.monthlyFreezeAllowance)
    return "Seri dondurma · bu ay \(used)/\(Self.monthlyFreezeAllowance) kullanıldı"
  }

  // MARK: - Badges

  /// Vitrindeki rozetler (seçilmediyse kazanılan ilk üç).
  var showcase: [BadgeKind] {
    let chosen = profile.showcaseBadges.compactMap(BadgeKind.init(rawValue:)).filter {
      badges[$0] != nil
    }
    if !chosen.isEmpty { return Array(chosen.prefix(Self.showcaseLimit)) }
    return Array(earned.prefix(Self.showcaseLimit))
  }

  /// Kazanılan rozetler, kazanılma sırasıyla.
  var earned: [BadgeKind] {
    BadgeKind.allCases.filter { badges[$0] != nil }
      .sorted { (badges[$0] ?? .now) < (badges[$1] ?? .now) }
  }

  /// Henüz kazanılmamış rozetler; hedefe en yakın olanlar önce.
  var upcoming: [BadgeKind] {
    let locked = BadgeKind.allCases.filter { badges[$0] == nil }
    return locked.sorted { completion($0) > completion($1) }
  }

  /// Rozetin ilerlemesi.
  func progress(_ badge: BadgeKind) -> (current: Int, target: Int)? {
    badge.progress(snapshot)
  }

  /// Unvanın açık olup olmadığı.
  func isUnlocked(_ title: UserTitle) -> Bool {
    title.isUnlocked(badges: Set(badges.keys), snapshot: snapshot)
  }

  /// Aksesuarın kilit nedeni (açıksa nil).
  func lockReason(_ accessory: AvatarAccessory) -> String? {
    UnlockRules.isUnlocked(accessory, stats: stats, isPremium: isPremium)
      ? nil : UnlockRules.requirement(accessory)
  }

  /// Arka planın kilitli olup olmadığı.
  func isLocked(_ background: AvatarBackground) -> Bool {
    !UnlockRules.isUnlocked(background, isPremium: isPremium)
  }

  /// Rozetin tarih metni.
  func dateText(_ badge: BadgeKind) -> String {
    badges[badge].map(DateText.dayMonthShort) ?? ""
  }

  // MARK: - Editing

  /// Düzenlemeyi kaydeder ve geri döner.
  func saveDraft() {
    var updated = draft
    updated.nickname = String(updated.nickname.prefix(Self.nicknameLimit))
      .trimmingCharacters(in: .whitespaces)
    if !isUnlocked(draftTitle) { updated.titleId = title.id }
    userData.updateProfile(updated)
    coordinator.back()
  }

  /// Düzenlemeden vazgeçer.
  func cancelDraft() {
    draft = profile
    coordinator.back()
  }

  /// Kapak / avatar arka planını hemen kaydeder.
  func setBackground(_ background: AvatarBackground) {
    guard !isLocked(background) else { return }
    var updated = profile
    updated.avatar.background = background
    userData.updateProfile(updated)
    draft.avatar.background = background
  }

  /// Rozeti vitrine ekler ya da çıkarır (en fazla 3; doluysa en eskisi çıkar).
  func toggleShowcase(_ badge: BadgeKind) {
    guard badges[badge] != nil else { return }
    var current = showcase.map(\.rawValue)
    if let index = current.firstIndex(of: badge.rawValue) {
      current.remove(at: index)
    } else if current.count < Self.showcaseLimit {
      current.append(badge.rawValue)
    } else {
      current = Array(current.dropFirst()) + [badge.rawValue]
    }
    var updated = profile
    updated.showcaseBadges = current
    userData.updateProfile(updated)
  }

  // MARK: - Private helpers

  private func reload() {
    profile = userData.profile ?? profile
    stats = userData.stats
    badges = userData.badges
    let finished = userData.allProgress().values.filter { $0.status == .finished }.map(\.puzzleId)
    snapshot = AchievementSnapshot(
      stats: stats, finishedPuzzleIds: finished,
      learnedWords: userData.notebook.filter(\.learned).count)
    isPremium = entitlements.isPremium
    iCloudOn = userData.isICloudBackupEnabled
    iCloudAvailable = userData.isICloudAvailable
    lastBackupAt = userData.settings.lastBackupAt
  }

  /// Rozetin tamamlanma oranı (sayaçsızlar en sona).
  private func completion(_ badge: BadgeKind) -> Double {
    guard let progress = badge.progress(snapshot) else { return -1 }
    return Double(progress.current) / Double(max(progress.target, 1))
  }

  /// Takvimin gidebileceği en eski gün.
  private var earliestDay: Date {
    let first = stats.solvedDays.min().flatMap(date(fromKey:))
    return min(profile.createdAt, first ?? profile.createdAt)
  }

  private func monthStart(_ date: Date) -> Date {
    calendar.dateInterval(of: .month, for: date)?.start ?? date
  }

  /// `yyyy-MM-dd` anahtarını tarihe çevirir.
  private func date(fromKey key: String) -> Date? {
    let parts = key.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
  }
}
