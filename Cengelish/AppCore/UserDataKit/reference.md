# UserDataKit

**Layer**: AppCore
**Purpose**: SwiftData ile cihazda profil (fotoğraf dahil), ayarlar, ilerleme (PencilKit çizimi dahil), Kelime Defterim (Leitner), seri, rozetler; isteğe bağlı iCloud (CloudKit) ve tüm verileri silme.

## Public API

```swift
@MainActor protocol UserDataStoring   // profile, settings, progress, finish(...), notebook, review, stats, badges, hints, iCloud, deleteAll
  var changes: AnyPublisher<Void, Never>      // her değişiklikte
  var dataErased: AnyPublisher<Void, Never>   // deleteAll sonrası; aynı silmenin `changes`inden önce
  var profilePhoto: Data?                      // JPEG, en uzun kenar 512 px; yoksa nil
  @discardableResult func setProfilePhoto(_ data: Data?) -> Bool  // nil kaldırır; profil yoksa / okunamazsa false
  func deleteAll()   // profil+fotoğraf, ayarlar, ilerleme (çizim, yazılan harfler), defter, seri, rozet
final class UserDataStore: UserDataStoring  // init(inMemory:)
  // saveTyped(puzzleId:letters:) klavye harflerini kaydeder (PuzzleProgress.typedLetters)
enum ProfilePhoto   // maxPixelSize 512, compressionQuality 0.8
  @concurrent static func normalized(_ data: Data) async -> Data?  // ham görüntü → küçük JPEG (arka planda)
UserProfile, AppSettings, Appearance, SpeechAccent, PuzzleProgress (drawing, revealedCells, typedLetters…), PuzzleStatus, NotebookItem, UserStats, FinishResult, StorageUsage
BadgeKind (15 rozet; progress(_:) / isEarned(_:event:)), AchievementSnapshot, FinishEvent
UserTitle (Yeni Kalem, Kelime Avcısı, Gece Kuşu, Bulmaca Kurdu, YDS Savaşçısı, Kelime Ustası;
  init(storedId:) eski kimlikleri eşler, isUnlocked(badges:snapshot:) rozetle açılır)
StreakRules, LeitnerRules, HintRules, StarRules
enum ReminderScheduler
```

## Structure

Persistence/ (SwiftData kayıtları, ContainerFactory) · Model/ (ProfilePhoto dahil) · Rules/ · Store/

## Persistence notes

`PuzzleProgressRecord.typedData` (JSON `[String: String]`, opsiyonel) klavye harflerini tutar;
eski kayıtlarda nil olduğu için hafif göç yeterlidir.

`ProfileRecord.photoData` (`@Attribute(.externalStorage)`, opsiyonel) profil fotoğrafını tutar;
eski kayıtlarda nil, hafif göç yeterli. `UserProfile`'a eklenmez (her profil okumasında büyük
veri yüklenmesin diye); `profilePhoto` ile ayrıca okunur. `updateProfile` fotoğrafa dokunmaz.
`setProfilePhoto` veri hazır (JPEG, ≤ 512 px) değilse kendisi küçültür.

Dosyaya dışa/içe aktarma kaldırıldı (`exportData`, `importData`, `BackupCoder` yok).
`SettingsRecord.lastBackupAt` yalnızca şema uyumu için durur, kullanılmaz.

`deleteAll()` şemadaki her kaydı tek tek siler (harici depodaki fotoğraf ve çizimler dahil),
kaydeder, önce `dataErased` sonra `changes` yayınlar. iCloud tercihi (UserDefaults) korunur.
Bekleyen bildirimleri silmez; çağıran `ReminderScheduler.apply(_:stats:)` ile temizler.

## Badges

Rozetler `finish(...)` içinde `awardBadges` ile verilir. Sayaçlı rozetler `AchievementSnapshot`
(UserStats + bitirilen bulmaca kimlikleri + defterde öğrenilen kelime) üzerinden; YDS sayacı
`yds_NN` kimlik önekinden, günlük sayaç `daily_` önekinden hesaplanır. Anlık rozetler
(`perfect` = ilk bitirişte hatasız ve ipucusuz, `nightOwl` 22–05, `earlyBird` 05–08, `speed` < 3 dk)
`FinishEvent` ile değerlendirilir.

## Dependencies

- DesignKit
