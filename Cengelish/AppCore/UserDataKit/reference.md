# UserDataKit

**Layer**: AppCore
**Purpose**: SwiftData ile cihazda profil, ayarlar, ilerleme (PencilKit çizimi dahil), Kelime Defterim (Leitner), seri, rozetler; isteğe bağlı iCloud (CloudKit) ve dosyaya yedek.

## Public API

```swift
@MainActor protocol UserDataStoring   // profile, settings, progress, finish(...), notebook, review, stats, badges, hints, iCloud, export/import, deleteAll
final class UserDataStore: UserDataStoring  // init(inMemory:)
UserProfile, AppSettings, Appearance, SpeechAccent, PuzzleProgress, PuzzleStatus, NotebookItem, UserStats, FinishResult, StorageUsage
BadgeKind, UserTitle, UnlockRules, StreakRules, LeitnerRules, HintRules, StarRules
enum ReminderScheduler
```

## Structure

Persistence/ (SwiftData kayıtları, ContainerFactory, BackupCoder) · Model/ · Rules/ · Store/

## Dependencies

- DesignKit
