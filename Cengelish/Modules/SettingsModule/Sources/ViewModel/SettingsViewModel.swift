import Combine
import Foundation
import PurchaseKit
import UserDataKit

/// Ayarlar, görünüm, tema ve veri ekranlarının ortak durumu.
@MainActor
final class SettingsViewModel: ObservableObject {

  // MARK: - Properties

  @Published private(set) var settings = AppSettings()
  @Published private(set) var isPremium = false
  @Published private(set) var iCloudOn = false
  @Published private(set) var iCloudAvailable = true
  @Published private(set) var usage = StorageUsage(drawings: 0, progress: 0, profile: 0)
  @Published private(set) var contentBytes = 0
  @Published var notice: String?
  private let coordinator: SettingsCoordinator
  private let userData: any UserDataStoring
  private let entitlements: any EntitlementProviding
  private let applyReminder: (AppSettings) -> Void
  private var cancellables: Set<AnyCancellable> = []

  // MARK: - Init

  init(
    coordinator: SettingsCoordinator, userData: any UserDataStoring,
    entitlements: any EntitlementProviding,
    applyReminder: @escaping (AppSettings) -> Void = ReminderScheduler.apply
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

  func back() { coordinator.back() }
  func openAppearance() { coordinator.showAppearance() }
  func openPuzzleTheme() { coordinator.showPuzzleTheme() }
  func openData() { coordinator.showData() }
  func openPaywall() { coordinator.showPaywall() }

  // MARK: - Settings

  /// Ayarı değiştirir; hatırlatıcı ayarıysa bildirimi de günceller.
  func update(_ change: (inout AppSettings) -> Void) {
    userData.updateSettings(change)
    applyReminder(userData.settings)
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
