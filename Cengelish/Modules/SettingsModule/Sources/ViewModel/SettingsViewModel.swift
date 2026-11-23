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
  @Published private(set) var plusPurchaseDate: Date?
  @Published private(set) var iCloudOn = false
  @Published private(set) var iCloudAvailable = true
  @Published private(set) var usage = StorageUsage(drawings: 0, progress: 0, profile: 0)
  @Published private(set) var contentBytes = 0
  @Published var notice: String?
  private let coordinator: SettingsCoordinator
  private let userData: any UserDataStoring
  private let entitlements: any EntitlementProviding
  private let applyReminder: (AppSettings, UserStats) -> Void
  private var cancellables: Set<AnyCancellable> = []

  // MARK: - Init

  init(
    coordinator: SettingsCoordinator, userData: any UserDataStoring,
    entitlements: any EntitlementProviding,
    applyReminder: @escaping (AppSettings, UserStats) -> Void = {
      ReminderScheduler.apply($0, stats: $1)
    }
  ) {
    self.coordinator = coordinator
    self.userData = userData
    self.entitlements = entitlements
    self.applyReminder = applyReminder
    reload()
    userData.changes.merge(with: entitlements.changes)
      .sink { [weak self] in self?.reload() }
      .store(in: &cancellables)
  }

  // MARK: - Navigation

  /// Geri gider.
  func back() { coordinator.back() }
  /// Uygulama görünümü ekranını açar.
  func openAppearance() { coordinator.showAppearance() }
  /// Bulmaca teması ekranını açar.
  func openPuzzleTheme() { coordinator.showPuzzleTheme() }
  /// Veri ve yedekleme ekranını açar.
  func openData() { coordinator.showData() }
  /// Paywall'u açar.
  func openPaywall() { coordinator.showPaywall() }

  // MARK: - Plus

  /// Plus satırının başlığı ("Çengelish Plus · Ömür boyu").
  var plusTitle: String {
    isPremium ? "\(PlusBrand.name) · Ömür boyu" : "\(PlusBrand.name)'a geç"
  }

  /// Plus satırının değeri: satın alma tarihi ("8 Kas 2026"); bilinmiyorsa "Aktif".
  var plusDetail: String {
    guard isPremium else { return "" }
    return plusPurchaseDate.map(Self.dateText) ?? "Aktif"
  }

  /// Plus'a geçiş kartının alt metni.
  static let plusPitch = "Tüm bulmaca temaları, sınav paketleri ve seri dondurma"

  /// "8 Kas 2026" biçiminde Türkçe tarih.
  static func dateText(_ date: Date) -> String {
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
  ///
  /// Elle seçilen tema her zaman uygulanır: yüksek kontrast (tüm temaları siyah-beyaz yapar)
  /// kapanır; kendi koyu görünümü olmayan bir tema seçilince "Koyu modda Gece teması" da kapanır.
  func selectTheme(id: String, isPremiumTheme: Bool, keepsInDarkMode: Bool = true) {
    guard !isPremiumTheme || isPremium else { return openPaywall() }
    update {
      $0.puzzleTheme = id
      $0.highContrast = false
      if !keepsInDarkMode { $0.autoNightTheme = false }
    }
  }

  // MARK: - Data

  /// iCloud yedeklemeyi açar/kapatır.
  func setICloud(_ on: Bool) {
    userData.setICloudBackup(on)
    notice = "Değişiklik uygulamayı kapatıp açınca geçerli olur."
  }

  /// Tüm veriyi siler ve bekleyen bildirimleri kaldırır.
  ///
  /// Depo `dataErased` yayınlar; uygulama kabuğu açılış ekranını ve ardından onboarding'i
  /// gösterir.
  func eraseAllData() {
    userData.deleteAll()
    applyReminder(userData.settings, userData.stats)
  }

  /// Bayt değerini okunur metne çevirir.
  func format(bytes: Int) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
  }

  // MARK: - Private

  private func reload() {
    settings = userData.settings
    isPremium = entitlements.isPremium
    plusPurchaseDate = entitlements.plusPurchaseDate
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
