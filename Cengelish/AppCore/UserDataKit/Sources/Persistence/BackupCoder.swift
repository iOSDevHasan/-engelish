import Foundation
import SwiftData

/// Dışa aktarma dosyasının (`.cengelish`) biçimi.
struct BackupFile: Codable {
  struct Profile: Codable {
    var nickname: String
    var avatarData: Data?
    var title: String
    var showcaseBadges: [String]
    var level: String
    var goals: [String]
    var dailyGoal: Int
    var createdAt: Date
  }

  struct Progress: Codable {
    var puzzleId: String
    var status: String
    var startedAt: Date?
    var finishedAt: Date?
    var durationSec: Int
    var hintsUsed: Int
    var marksData: Data?
    var revealedData: Data?
    var stars: Int
    var drawing: Data?
  }

  struct Note: Codable {
    var wordId: String
    var addedAt: Date
    var box: Int
    var nextReviewAt: Date
    var learned: Bool
  }

  struct Stats: Codable {
    var streak: Int
    var longestStreak: Int
    var lastPlayedDay: String?
    var puzzlesSolved: Int
    var wordsSeen: Int
    var perfectCount: Int
    var solvedDays: [String]
  }

  var format = 1
  var exportedAt = Date.now
  var profile: Profile?
  var progress: [Progress]
  var notebook: [Note]
  var stats: Stats?
  var badges: [String: Date]
}

/// Kullanıcı verisini dosyaya yazar ve dosyadan geri yükler.
enum BackupCoder {

  /// Tüm kayıtları JSON dosyasına çevirir.
  static func encode(from context: ModelContext) throws -> Data {
    let profile = try context.fetch(FetchDescriptor<ProfileRecord>()).first.map {
      BackupFile.Profile(
        nickname: $0.nickname, avatarData: $0.avatarData, title: $0.title,
        showcaseBadges: $0.showcaseBadges, level: $0.level, goals: $0.goals,
        dailyGoal: $0.dailyGoal, createdAt: $0.createdAt)
    }
    let progress = try context.fetch(FetchDescriptor<PuzzleProgressRecord>()).map {
      BackupFile.Progress(
        puzzleId: $0.puzzleId, status: $0.status, startedAt: $0.startedAt,
        finishedAt: $0.finishedAt, durationSec: $0.durationSec, hintsUsed: $0.hintsUsed,
        marksData: $0.marksData, revealedData: $0.revealedData, stars: $0.stars,
        drawing: $0.drawing)
    }
    let notes = try context.fetch(FetchDescriptor<NotebookRecord>()).map {
      BackupFile.Note(
        wordId: $0.wordId, addedAt: $0.addedAt, box: $0.box, nextReviewAt: $0.nextReviewAt,
        learned: $0.learned)
    }
    let stats = try context.fetch(FetchDescriptor<StatsRecord>()).first.map {
      BackupFile.Stats(
        streak: $0.streak, longestStreak: $0.longestStreak, lastPlayedDay: $0.lastPlayedDay,
        puzzlesSolved: $0.puzzlesSolved, wordsSeen: $0.wordsSeen, perfectCount: $0.perfectCount,
        solvedDays: $0.solvedDays)
    }
    var badges: [String: Date] = [:]
    for record in try context.fetch(FetchDescriptor<BadgeRecord>()) {
      badges[record.badgeId] = record.unlockedAt
    }
    let file = BackupFile(
      profile: profile, progress: progress, notebook: notes, stats: stats, badges: badges)
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return try encoder.encode(file)
  }

  /// Mevcut veriyi silip dosyadaki veriyi yükler (ayarlar korunur).
  static func restore(_ data: Data, into context: ModelContext) throws {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let file = try decoder.decode(BackupFile.self, from: data)
    try context.delete(model: ProfileRecord.self)
    try context.delete(model: PuzzleProgressRecord.self)
    try context.delete(model: NotebookRecord.self)
    try context.delete(model: StatsRecord.self)
    try context.delete(model: BadgeRecord.self)
    if let p = file.profile {
      let record = ProfileRecord()
      record.nickname = p.nickname
      record.avatarData = p.avatarData
      record.title = p.title
      record.showcaseBadges = p.showcaseBadges
      record.level = p.level
      record.goals = p.goals
      record.dailyGoal = p.dailyGoal
      record.createdAt = p.createdAt
      context.insert(record)
    }
    for p in file.progress {
      let record = PuzzleProgressRecord(puzzleId: p.puzzleId)
      record.status = p.status
      record.startedAt = p.startedAt
      record.finishedAt = p.finishedAt
      record.durationSec = p.durationSec
      record.hintsUsed = p.hintsUsed
      record.marksData = p.marksData
      record.revealedData = p.revealedData
      record.stars = p.stars
      record.drawing = p.drawing
      context.insert(record)
    }
    for n in file.notebook {
      let record = NotebookRecord(wordId: n.wordId)
      record.addedAt = n.addedAt
      record.box = n.box
      record.nextReviewAt = n.nextReviewAt
      record.learned = n.learned
      context.insert(record)
    }
    if let s = file.stats {
      let record = StatsRecord()
      record.streak = s.streak
      record.longestStreak = s.longestStreak
      record.lastPlayedDay = s.lastPlayedDay
      record.puzzlesSolved = s.puzzlesSolved
      record.wordsSeen = s.wordsSeen
      record.perfectCount = s.perfectCount
      record.solvedDays = s.solvedDays
      context.insert(record)
    }
    for (id, date) in file.badges {
      let record = BadgeRecord(badgeId: id)
      record.unlockedAt = date
      context.insert(record)
    }
  }
}
