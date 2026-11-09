import Foundation
import SwiftData

// SwiftData + CloudKit kuralları: her alanın varsayılanı var ya da opsiyonel,
// `@Attribute(.unique)` kullanılmaz. Tekillik depoda kodla sağlanır.

/// Cihazdaki profil kaydı.
@Model
final class ProfileRecord {
  var nickname: String = ""
  var avatarData: Data?
  var title: String = "kalemci"
  var showcaseBadges: [String] = []
  var level: String = "A1"
  var goals: [String] = []
  var dailyGoal: Int = 2
  var isPremiumHint: Bool = false
  var createdAt: Date = Date.now

  init() {}
}

/// Oyun ve görünüm ayarları.
@Model
final class SettingsRecord {
  var appearance: String = "system"
  var puzzleTheme: String = "canli"
  var penColor: String = "auto"
  var penWidth: Double = 1
  var autoNightTheme: Bool = true
  var highContrast: Bool = false
  var accent: String = "us"
  var leftHanded: Bool = false
  var autoAdvance: Bool = true
  var pencilOnly: Bool = false
  var reminderEnabled: Bool = false
  var reminderHour: Int = 20
  var reminderMinute: Int = 0
  var lastBackupAt: Date?

  init() {}
}

/// Bir bulmacanın ilerlemesi.
@Model
final class PuzzleProgressRecord {
  var puzzleId: String = ""
  var status: String = "notStarted"
  var startedAt: Date?
  var finishedAt: Date?
  var durationSec: Int = 0
  var hintsUsed: Int = 0
  var marksData: Data?
  var revealedData: Data?
  var stars: Int = 0
  @Attribute(.externalStorage) var drawing: Data?
  var updatedAt: Date = Date.now

  init(puzzleId: String) {
    self.puzzleId = puzzleId
  }
}

/// Kelime Defterim kaydı (Leitner kutusu).
@Model
final class NotebookRecord {
  var wordId: String = ""
  var addedAt: Date = Date.now
  var source: String = "puzzle"
  var box: Int = 1
  var nextReviewAt: Date = Date.now
  var learned: Bool = false

  init(wordId: String) {
    self.wordId = wordId
  }
}

/// Seri ve sayaçlar.
@Model
final class StatsRecord {
  var streak: Int = 0
  var longestStreak: Int = 0
  var lastPlayedDay: String?
  var freezesUsed: Int = 0
  var freezeMonth: String = ""
  var puzzlesSolved: Int = 0
  var wordsSeen: Int = 0
  var perfectCount: Int = 0
  var hintDay: String?
  var hintsUsedToday: Int = 0
  var solvedDays: [String] = []

  init() {}
}

/// Kazanılan rozet.
@Model
final class BadgeRecord {
  var badgeId: String = ""
  var unlockedAt: Date = Date.now

  init(badgeId: String) {
    self.badgeId = badgeId
  }
}

/// Uygulamanın tüm SwiftData şeması.
enum UserSchema {
  /// Şemadaki model tipleri.
  static let models: [any PersistentModel.Type] = [
    ProfileRecord.self, SettingsRecord.self, PuzzleProgressRecord.self, NotebookRecord.self,
    StatsRecord.self, BadgeRecord.self,
  ]
}
