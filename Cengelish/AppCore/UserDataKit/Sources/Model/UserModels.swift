import DesignKit
import Foundation

/// Kullanıcının cihazdaki profili.
public struct UserProfile: Equatable, Sendable {
  /// Takma ad (boşsa "Kalemci").
  public var nickname: String
  /// Avatar seçimi.
  public var avatar: AvatarConfig
  /// Seçili unvan kimliği.
  public var titleId: String
  /// Profilde gösterilen en fazla 3 rozet.
  public var showcaseBadges: [String]
  /// Seviye (A1...C1).
  public var level: String
  /// Seçilen amaçlar (genel, yds, lgs...).
  public var goals: [String]
  /// Günlük bulmaca hedefi.
  public var dailyGoal: Int
  /// Oluşturulma tarihi.
  public var createdAt: Date

  /// Profili tüm alanlarıyla oluşturur.
  public init(
    nickname: String, avatar: AvatarConfig, titleId: String = UserTitle.kalemci.id,
    showcaseBadges: [String] = [], level: String = "A1", goals: [String] = [],
    dailyGoal: Int = 2, createdAt: Date = .now
  ) {
    self.nickname = nickname
    self.avatar = avatar
    self.titleId = titleId
    self.showcaseBadges = showcaseBadges
    self.level = level
    self.goals = goals
    self.dailyGoal = dailyGoal
    self.createdAt = createdAt
  }

  /// Ekranda gösterilecek ad.
  public var displayName: String { nickname.isEmpty ? "Kalemci" : nickname }
}

/// Uygulama görünümü.
public enum Appearance: String, CaseIterable, Sendable {
  case system, light, dark

  /// Ekranda görünen ad.
  public var title: String {
    switch self {
    case .system: "Sistem"
    case .light: "Açık"
    case .dark: "Koyu"
    }
  }
}

/// Telaffuz aksanı.
public enum SpeechAccent: String, CaseIterable, Sendable {
  case us, uk

  /// Ekranda görünen ad.
  public var title: String { self == .us ? "Amerikan" : "İngiliz" }
  /// AVSpeech dil kodu.
  public var languageCode: String { self == .us ? "en-US" : "en-GB" }
}

/// Oyun ve görünüm ayarları.
public struct AppSettings: Equatable, Sendable {
  /// Uygulama görünümü.
  public var appearance: Appearance = .system
  /// Bulmaca teması kimliği.
  public var puzzleTheme: String = "canli"
  /// Kalem rengi (`auto` ya da onaltılık renk).
  public var penColor: String = "auto"
  /// Kalem kalınlığı çarpanı (0.7 / 1 / 1.4).
  public var penWidth: Double = 1
  /// Koyu modda ızgara otomatik Gece temasına geçer.
  public var autoNightTheme: Bool = true
  /// Yüksek kontrast ızgara.
  public var highContrast: Bool = false
  /// Telaffuz aksanı.
  public var accent: SpeechAccent = .us
  /// Sol el düzeni.
  public var leftHanded: Bool = false
  /// Kutu dolunca sonrakine geç.
  public var autoAdvance: Bool = true
  /// Sadece Apple Pencil ile yaz (iPad).
  public var pencilOnly: Bool = false
  /// Günlük hatırlatıcı açık mı.
  public var reminderEnabled: Bool = false
  /// Hatırlatıcı saati.
  public var reminderHour: Int = 20
  /// Hatırlatıcı dakikası.
  public var reminderMinute: Int = 0

  /// Varsayılan ayarları oluşturur.
  public init() {}
}

/// Bulmaca durumu.
public enum PuzzleStatus: String, Sendable {
  case notStarted, inProgress, finished
}

/// Bir bulmacanın ilerlemesi.
public struct PuzzleProgress: Equatable, Sendable {
  /// Bulmaca kimliği.
  public let puzzleId: String
  /// Durum.
  public var status: PuzzleStatus = .notStarted
  /// Geçen süre (saniye).
  public var durationSec: Int = 0
  /// Kullanılan ipucu.
  public var hintsUsed: Int = 0
  /// Kelime bazında kendi kendine işaretleme (entryId → doğru mu).
  public var marks: [String: Bool] = [:]
  /// İpucuyla açılan kutular (`satır,sütun`).
  public var revealedCells: Set<String> = []
  /// Yıldız (0–3).
  public var stars: Int = 0
  /// Bitirildiği zaman.
  public var finishedAt: Date?
  /// PencilKit çizimi.
  public var drawing: Data?

  /// Boş ilerleme oluşturur.
  public init(puzzleId: String) {
    self.puzzleId = puzzleId
  }
}

/// Defterdeki bir kelime.
public struct NotebookItem: Equatable, Identifiable, Sendable {
  /// Kelime kimliği.
  public let wordId: String
  /// Leitner kutusu (1–5).
  public var box: Int
  /// Sonraki tekrar zamanı.
  public var nextReviewAt: Date
  /// Öğrenildi mi.
  public var learned: Bool
  /// Eklendiği tarih.
  public var addedAt: Date

  public var id: String { wordId }

  /// Defter kaydını oluşturur.
  public init(wordId: String, box: Int, nextReviewAt: Date, learned: Bool, addedAt: Date) {
    self.wordId = wordId
    self.box = box
    self.nextReviewAt = nextReviewAt
    self.learned = learned
    self.addedAt = addedAt
  }

  /// Tekrar zamanı gelmiş mi.
  public func isDue(at date: Date = .now) -> Bool { !learned && nextReviewAt <= date }
}

/// Seri ve sayaçlar.
public struct UserStats: Equatable, Sendable {
  /// Güncel seri (gün).
  public var streak: Int = 0
  /// En uzun seri.
  public var longestStreak: Int = 0
  /// Son oynanan gün (`yyyy-MM-dd`).
  public var lastPlayedDay: String?
  /// Çözülen bulmaca sayısı.
  public var puzzlesSolved: Int = 0
  /// Görülen (doğru işaretlenen) kelime sayısı.
  public var wordsSeen: Int = 0
  /// Hatasız bitirilen bulmaca sayısı.
  public var perfectCount: Int = 0
  /// Bugün kullanılan ipucu.
  public var hintsUsedToday: Int = 0
  /// Bulmaca çözülen günler (`yyyy-MM-dd`).
  public var solvedDays: [String] = []

  /// Boş sayaçlar oluşturur.
  public init() {}
}

/// Bitirilen bulmacanın sonucu.
public struct FinishResult: Equatable, Sendable {
  /// Kazanılan yıldız.
  public let stars: Int
  /// Doğru kelime sayısı.
  public let correct: Int
  /// Toplam kelime sayısı.
  public let total: Int
  /// Güncel seri.
  public let streak: Int
  /// Bu bitişle yeni açılan rozetler.
  public let newBadges: [BadgeKind]
  /// Deftere eklenen kelime kimlikleri.
  public let addedToNotebook: [String]
}
