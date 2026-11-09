import Combine
import Foundation

/// Modüllerin kullanıcı verisine eriştiği arayüz. Tüm veri cihazda tutulur.
@MainActor
public protocol UserDataStoring: AnyObject {
  /// Veri her değiştiğinde yayın yapar.
  var changes: AnyPublisher<Void, Never> { get }

  // MARK: Profile

  /// Mevcut profil; onboarding bitmediyse nil.
  var profile: UserProfile? { get }
  /// Onboarding sonunda profili oluşturur.
  func createProfile(_ profile: UserProfile)
  /// Profili günceller.
  func updateProfile(_ profile: UserProfile)

  // MARK: Settings

  /// Ayarlar.
  var settings: AppSettings { get }
  /// Ayarları günceller.
  func updateSettings(_ change: (inout AppSettings) -> Void)

  // MARK: Progress

  /// Bulmacanın ilerlemesi.
  func progress(for puzzleId: String) -> PuzzleProgress
  /// Tüm bulmaca ilerlemeleri (puzzleId → durum ve yıldız).
  func allProgress() -> [String: PuzzleProgress]
  /// Çizimi ve geçen süreyi kaydeder.
  func saveDraft(puzzleId: String, drawing: Data?, durationSec: Int)
  /// İpucuyla açılan kutuları kaydeder.
  func saveRevealed(puzzleId: String, cells: Set<String>, hintsUsed: Int)
  /// Bulmacayı kendi kendine işaretlemeyle bitirir; seri, rozet ve defteri günceller.
  func finish(
    puzzleId: String, marks: [String: Bool], wordIdsByEntry: [String: String],
    isPremium: Bool, now: Date
  ) -> FinishResult
  /// Bulmacayı sıfırlar.
  func resetProgress(puzzleId: String)

  // MARK: Notebook

  /// Defterdeki kelimeler.
  var notebook: [NotebookItem] { get }
  /// Kelimeyi deftere ekler (zaten varsa tekrara alır). `source`: bulmaca kimliği ya da `manual`.
  func addToNotebook(wordId: String, source: String)
  /// Kelimeyi öğrenildi olarak işaretler ya da tekrara geri alır.
  func setLearned(wordId: String, learned: Bool)
  /// Kelimeyi defterden çıkarır.
  func removeFromNotebook(wordId: String)
  /// Tekrar sonucunu işler.
  func review(wordId: String, knew: Bool)

  // MARK: Stats & badges

  /// Sayaçlar.
  var stats: UserStats { get }
  /// Kazanılan rozetler (kimlik → tarih).
  var badges: [BadgeKind: Date] { get }
  /// Bugün kalan ipucu hakkı (premium için nil = sınırsız).
  func hintsLeft(isPremium: Bool) -> Int?
  /// İpucu hakkı harcar; yetmezse false döner.
  func consumeHints(_ count: Int, isPremium: Bool) -> Bool

  // MARK: Data

  /// iCloud yedekleme açık mı (değişiklik uygulama yeniden açılınca geçerli olur).
  var isICloudBackupEnabled: Bool { get }
  /// Bu cihazda iCloud kullanılabilir mi (iCloud'a giriş yapılmış ve yetki var).
  var isICloudAvailable: Bool { get }
  /// iCloud yedeklemeyi açar/kapatır.
  func setICloudBackup(_ enabled: Bool)
  /// Verilerin cihazda kapladığı tahmini alan.
  func storageUsage() -> StorageUsage
  /// Tüm veriyi dosyaya aktarılabilir JSON olarak döner.
  func exportData() throws -> Data
  /// Dışa aktarılmış dosyadan verileri geri yükler.
  func importData(_ data: Data) throws
  /// Biten bulmacaların çizimlerini siler (son `keep` tanesi hariç).
  func clearOldDrawings(keep: Int) -> Int
  /// Tüm kullanıcı verisini siler.
  func deleteAll()
}

/// Cihazdaki veri boyutları (bayt).
public struct StorageUsage: Equatable, Sendable {
  /// El yazısı çizimleri.
  public let drawings: Int
  /// İlerleme ve defter kayıtları.
  public let progress: Int
  /// Profil ve ayarlar.
  public let profile: Int

  /// Toplam.
  public var total: Int { drawings + progress + profile }

  /// Boyutlarla oluşturur.
  public init(drawings: Int, progress: Int, profile: Int) {
    self.drawings = drawings
    self.progress = progress
    self.profile = profile
  }
}
