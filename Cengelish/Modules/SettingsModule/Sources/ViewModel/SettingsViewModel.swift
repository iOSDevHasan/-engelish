import Combine
import DesignKit
import Foundation
import PurchaseKit
import UserDataKit

/// Ayarlar, görünüm, tema ve veri ekranlarının ortak durumu.
@MainActor
final class SettingsViewModel: ObservableObject {

  // MARK: - Properties

  @Published private(set) var settings = AppSettings()
  @Published private(set) var isPremium = false
  @Published private(set) var subscription: ActiveSubscription?
  @Published private(set) var nickname = "Kalemci"
  @Published private(set) var iCloudOn = false
  @Published private(set) var iCloudAvailable = true
  @Published private(set) var usage = StorageUsage(drawings: 0, progress: 0, profile: 0)
  @Published private(set) var contentBytes = 0
  @Published var notice: String?
  /// Takma ad düzenleme penceresi açık mı (profil düzenleme kancası yoksa).
  @Published var isEditingNickname = false
  /// Takma ad penceresindeki taslak.
  @Published var nicknameDraft = ""
  /// Takma ad için en fazla karakter.
  let nicknameLimit = 16
  private let coordinator: SettingsCoordinator
  private let userData: any UserDataStoring
  private let entitlements: any EntitlementProviding
  private let applyReminder: (AppSettings, UserStats) -> Void
  private let onEditProfile: (@MainActor () -> Void)?
  private let backupDirectory: URL
  private var cancellables: Set<AnyCancellable> = []

  // MARK: - Init

  init(
    coordinator: SettingsCoordinator, userData: any UserDataStoring,
    entitlements: any EntitlementProviding,
    onEditProfile: (@MainActor () -> Void)? = nil,
    backupDirectory: URL = .documentsDirectory,
    applyReminder: @escaping (AppSettings, UserStats) -> Void = {
      ReminderScheduler.apply($0, stats: $1)
    }
  ) {
    self.coordinator = coordinator
    self.userData = userData
    self.entitlements = entitlements
    self.onEditProfile = onEditProfile
    self.backupDirectory = backupDirectory
    self.applyReminder = applyReminder
    reload()
    userData.changes.merge(with: entitlements.changes)
      .sink { [weak self] in self?.reload() }
      .store(in: &cancellables)
  }

  // MARK: - Navigation

  func back() { coordinator.back() }
  func openAppearance() { coordinator.showAppearance() }
  func openPuzzleTheme() { coordinator.showPuzzleTheme() }
  func openData() { coordinator.showData() }
  func openPaywall() { coordinator.showPaywall() }

  /// Profil düzenleme ekranını açar; kanca yoksa takma ad penceresini açar.
  func openEditProfile() {
    if let onEditProfile { return onEditProfile() }
    nicknameDraft = userData.profile?.nickname ?? ""
    isEditingNickname = true
  }

  /// Taslak takma adı profile kaydeder.
  func saveNickname() {
    guard var profile = userData.profile else { return }
    profile.nickname = String(
      nicknameDraft.trimmingCharacters(in: .whitespacesAndNewlines).prefix(nicknameLimit))
    userData.updateProfile(profile)
  }

  // MARK: - Subscription

  /// Abonelik satırının başlığı ("Çengelish+ · Yıllık").
  var subscriptionTitle: String {
    guard isPremium else { return "Çengelish+'a geç" }
    return subscription.map { "Çengelish+ · \($0.planTitle)" } ?? "Çengelish+ aktif"
  }

  /// Abonelik satırının değeri: yenilenme tarihi ("8 Kas 2027").
  var subscriptionDetail: String {
    guard isPremium else { return "" }
    guard let date = subscription?.renewalDate else { return "Yönet" }
    return Self.renewalText(date)
  }

  /// "8 Kas 2027" biçiminde Türkçe tarih.
  static func renewalText(_ date: Date) -> String {
    date.formatted(.dateTime.day().month(.abbreviated).year().locale(DateText.locale))
  }
  // MARK: - Settings

  /// Ayarı değiştirir; hatırlatıcı ayarıysa bildirimi de günceller.
  func update(_ change: (inout AppSettings) -> Void) {
    userData.updateSettings(change)
    applyReminder(userData.settings, userData.stats)
  }

  /// Hatırlatıcı saatinin "20:00" biçimi.
  var reminderTimeText: String {
    String(format: "%02d:%02d", settings.reminderHour, settings.reminderMinute)
  }

  /// Hatırlatıcıyı açarken izin ister.
  func setReminder(_ on: Bool) async {
    let granted = on ? await ReminderScheduler.requestPermission() : false
    update { $0.reminderEnabled = on && granted }
    if on, !granted { notice = "Bildirim izni kapalı. iOS Ayarlar → Çengelish'ten açabilirsin." }
  }

  /// Bulmaca temasını seçer; premium tema kilitliyse paywall açar.
  func selectTheme(id: String, isPremiumTheme: Bool) {
    guard !isPremiumTheme || isPremium else { return openPaywall() }
    update { $0.puzzleTheme = id }
  }

  // MARK: - Data

  /// iCloud yedeklemeyi açar/kapatır.
  func setICloud(_ on: Bool) {
    userData.setICloudBackup(on)
    notice = "Değişiklik uygulamayı kapatıp açınca geçerli olur."
  }

  /// Verileri dışa aktarılacak bir dosyaya yazar ve URL'ini döner.
  func makeExportFile() -> URL? {
    do {
      let data = try userData.exportData()
      let url = URL.temporaryDirectory.appending(path: "Cengelish-yedek.cengelish")
      try data.write(to: url, options: .atomic)
      return url
    } catch {
      notice = "Dışa aktarma başarısız: \(error.localizedDescription)"
      return nil
    }
  }

  /// Verileri Belgeler klasörüne yedekler ve son yedek zamanını kaydeder.
  @discardableResult
  func backupNow(now: Date = .now) -> URL? {
    do {
      let data = try userData.exportData()
      let url = backupDirectory.appending(path: "Cengelish-yedek.cengelish")
      try data.write(to: url, options: .atomic)
      userData.updateSettings { $0.lastBackupAt = now }
      notice =
        "Yedek alındı. \"Verilerimi dışa aktar\" ile dosyayı başka bir yere de kaydedebilirsin."
      return url
    } catch {
      notice = "Yedekleme başarısız: \(error.localizedDescription)"
      return nil
    }
  }

  /// Son yedeğin metni ("Bugün 21:04", "Dün 09:12", "8 Kas 21:04"); yoksa nil.
  func lastBackupText(now: Date = .now, calendar: Calendar = .current) -> String? {
    guard let date = settings.lastBackupAt else { return nil }
    let parts = calendar.dateComponents([.hour, .minute], from: date)
    let time = String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    if calendar.isDate(date, inSameDayAs: now) { return "Bugün \(time)" }
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
      calendar.isDate(date, inSameDayAs: yesterday)
    {
      return "Dün \(time)"
    }
    return "\(DateText.dayMonthShort(date)) \(time)"
  }

  /// Seçilen dosyadan verileri geri yükler.
  func importFile(_ url: URL) {
    let scoped = url.startAccessingSecurityScopedResource()
    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
    do {
      try userData.importData(Data(contentsOf: url))
      notice = "Verilerin geri yüklendi."
    } catch {
      notice = "Bu dosya okunamadı. Çengelish'ten dışa aktarılmış bir .cengelish dosyası seç."
    }
  }

  /// Eski çizimleri temizler.
  func clearDrawings() {
    let count = userData.clearOldDrawings(keep: 50)
    notice = count == 0 ? "Temizlenecek eski çizim yok." : "\(count) bulmacanın çizimi silindi."
  }

  /// Tüm veriyi siler (onboarding'e döner).
  func deleteAll() {
    userData.deleteAll()
  }

  /// Bayt değerini okunur metne çevirir.
  func format(bytes: Int) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
  }

  // MARK: - Private

  private func reload() {
    settings = userData.settings
    isPremium = entitlements.isPremium
    subscription = entitlements.activeSubscription
    nickname = userData.profile?.displayName ?? "Kalemci"
    iCloudOn = userData.isICloudBackupEnabled
    iCloudAvailable = userData.isICloudAvailable
    usage = userData.storageUsage()
    contentBytes =
      Self.directorySize(URL.applicationSupportDirectory.appending(path: "Content"))
      + 130_000
  }

  /// Klasördeki dosyaların toplam boyutu.
  private static func directorySize(_ url: URL) -> Int {
    let files =
      (try? FileManager.default.contentsOfDirectory(
        at: url, includingPropertiesForKeys: [.fileSizeKey])) ?? []
    return files.reduce(0) {
      $0 + ((try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
    }
  }
}
