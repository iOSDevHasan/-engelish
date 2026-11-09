import DesignKit
import Foundation

/// Uygulamanın widget'lar için yazdığı anlık görüntü. Widget eklentisi sadece bunu okur.
public struct WidgetSnapshot: Codable, Equatable, Sendable {
  /// Görüntünün yazıldığı an.
  public var generatedAt: Date
  /// Takma ad.
  public var nickname: String
  /// Avatar.
  public var avatar: AvatarConfig
  /// Yazıldığı andaki seri.
  public var streak: Int
  /// Son oynanan gün (`yyyy-MM-dd`).
  public var lastPlayedDay: String?
  /// Bulmaca çözülen günler (`yyyy-MM-dd`), son 14 gün yeterli.
  public var solvedDays: [String]
  /// Günlük bulmaca hedefi.
  public var dailyGoal: Int
  /// Bugün bitirilen bulmaca sayısı ve günü.
  public var solvedToday: DayCount
  /// Bugünden başlayarak birkaç günün kelimesi ve bulmacası.
  public var days: [Day]

  /// Anlık görüntüyü tüm alanlarıyla oluşturur.
  public init(
    generatedAt: Date, nickname: String, avatar: AvatarConfig, streak: Int,
    lastPlayedDay: String?, solvedDays: [String], dailyGoal: Int, solvedToday: DayCount,
    days: [Day]
  ) {
    self.generatedAt = generatedAt
    self.nickname = nickname
    self.avatar = avatar
    self.streak = streak
    self.lastPlayedDay = lastPlayedDay
    self.solvedDays = solvedDays
    self.dailyGoal = dailyGoal
    self.solvedToday = solvedToday
    self.days = days
  }

  /// Bir günün sayacı.
  public struct DayCount: Codable, Equatable, Sendable {
    /// Gün (`yyyy-MM-dd`).
    public var day: String
    /// Sayı.
    public var count: Int

    /// Sayacı oluşturur.
    public init(day: String, count: Int) {
      self.day = day
      self.count = count
    }
  }

  /// Bir günün widget içeriği.
  public struct Day: Codable, Equatable, Sendable {
    /// Gün (`yyyy-MM-dd`).
    public var day: String
    /// Günün kelimesi.
    public var word: WordInfo?
    /// Günün bulmacası.
    public var puzzle: PuzzleInfo?

    /// Gün içeriğini oluşturur.
    public init(day: String, word: WordInfo?, puzzle: PuzzleInfo?) {
      self.day = day
      self.word = word
      self.puzzle = puzzle
    }
  }

  /// Günün kelimesi.
  public struct WordInfo: Codable, Equatable, Sendable {
    /// İngilizce kelime.
    public var en: String
    /// Türkçe anlam.
    public var meaning: String
    /// Telaffuz (IPA).
    public var ipa: String

    /// Kelime bilgisini oluşturur.
    public init(en: String, meaning: String, ipa: String) {
      self.en = en
      self.meaning = meaning
      self.ipa = ipa
    }
  }

  /// Günün bulmacası.
  public struct PuzzleInfo: Codable, Equatable, Sendable {
    /// Bulmaca kimliği.
    public var id: String
    /// Seviye (`B1`).
    public var level: String
    /// Kelime sayısı.
    public var wordCount: Int
    /// Tahmini süre (dakika).
    public var minutes: Int
    /// Tamamlanma oranı (0...1).
    public var progress: Double
    /// Bitti mi.
    public var isFinished: Bool
    /// Izgara satırları: `#` ipucu kutusu, `.` boş harf kutusu, `x` dolu harf kutusu, ` ` boşluk.
    public var grid: [String]

    /// Bulmaca bilgisini oluşturur.
    public init(
      id: String, level: String, wordCount: Int, minutes: Int, progress: Double,
      isFinished: Bool, grid: [String]
    ) {
      self.id = id
      self.level = level
      self.wordCount = wordCount
      self.minutes = minutes
      self.progress = progress
      self.isFinished = isFinished
      self.grid = grid
    }
  }
}

// MARK: - Derived values

extension WidgetSnapshot {

  /// Verilen günün içeriği; yoksa en yakın önceki gün.
  public func content(for day: String) -> Day? {
    days.last { $0.day <= day } ?? days.first
  }

  /// Verilen gün için gösterilecek seri: dün ya da bugün oynandıysa seri sürer, yoksa 0.
  public func streak(on day: String, calendar: Calendar = .current) -> Int {
    guard let lastPlayedDay else { return 0 }
    if lastPlayedDay == day { return streak }
    guard
      let date = WidgetDay.date(from: day),
      let yesterday = calendar.date(byAdding: .day, value: -1, to: date)
    else { return 0 }
    return WidgetDay.string(from: yesterday) == lastPlayedDay ? streak : 0
  }

  /// Verilen günde bitirilen bulmaca sayısı.
  public func solvedCount(on day: String) -> Int {
    solvedToday.day == day ? solvedToday.count : 0
  }

  /// Verilen günün haftası (Pazartesi–Pazar) için çözülen günler.
  public func week(containing day: String, calendar: Calendar = .current) -> [WeekSlot] {
    guard let date = WidgetDay.date(from: day) else { return [] }
    let solved = Set(solvedDays)
    let weekday = (calendar.component(.weekday, from: date) + 5) % 7
    return (0..<7).map { index in
      let slotDate = calendar.date(byAdding: .day, value: index - weekday, to: date) ?? date
      let key = WidgetDay.string(from: slotDate)
      return WeekSlot(day: key, isSolved: solved.contains(key), isToday: index == weekday)
    }
  }

  /// Haftanın bir günü.
  public struct WeekSlot: Equatable, Sendable {
    /// Gün (`yyyy-MM-dd`).
    public let day: String
    /// O gün bulmaca çözüldü mü.
    public let isSolved: Bool
    /// Gösterilen gün mü.
    public let isToday: Bool
  }
}

// MARK: - Sample

extension WidgetSnapshot {

  /// Galeri ve önizleme için örnek veri.
  public static func sample(now: Date = .now) -> WidgetSnapshot {
    let today = WidgetDay.string(from: now)
    let calendar = Calendar.current
    let solved = (1...5).compactMap { offset in
      calendar.date(byAdding: .day, value: -offset, to: now).map { WidgetDay.string(from: $0) }
    }
    return WidgetSnapshot(
      generatedAt: now, nickname: "Deniz", avatar: .mascot, streak: 12,
      lastPlayedDay: solved.first, solvedDays: solved, dailyGoal: 2,
      solvedToday: DayCount(day: today, count: 0),
      days: [
        Day(
          day: today,
          word: WordInfo(en: "thorough", meaning: "titiz, eksiksiz", ipa: "/ˈθɝː.oʊ/"),
          puzzle: PuzzleInfo(
            id: "daily_sample", level: "B1", wordCount: 6, minutes: 5, progress: 0.4,
            isFinished: false,
            grid: ["#.#.#.#", "#xxxx..", "#.#.#x#", "#..xx..", "#x#.#.#", "#......", "#.#.#.#"]))
      ])
  }
}
