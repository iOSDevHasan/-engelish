import Foundation

/// Paket türü.
public enum PackKind: String, Codable, Sendable {
  case level
  case exam
  case theme
}

/// Bir bulmaca paketi (seviye, sınav ya da tema).
public struct Pack: Codable, Hashable, Identifiable, Sendable {
  /// Paket kimliği (`a1`, `yds`).
  public let id: String
  /// Başlık.
  public let title: String
  /// Kısa açıklama.
  public let subtitle: String
  /// Tür.
  public let kind: PackKind
  /// Ana seviye.
  public let level: CEFRLevel
  /// Sıralama.
  public let order: Int
  /// Ücretsiz oynanabilen ilk bulmaca sayısı.
  public let freeCount: Int
  /// Tek seferlik satın alma ürün kimliği (sınav paketleri).
  public let productId: String?
  /// Paketteki bulmacalar.
  public let puzzleIds: [String]
  /// Paketteki kelime sayısı.
  public let wordCount: Int
  /// Firebase Storage'daki içerik dosyası.
  public let contentPath: String?
  /// İçerik sürümü; değişince paket yeniden indirilir.
  public let contentVersion: Int?

  /// Paketi tüm alanlarıyla oluşturur.
  public init(
    id: String, title: String, subtitle: String, kind: PackKind, level: CEFRLevel, order: Int,
    freeCount: Int, productId: String?, puzzleIds: [String], wordCount: Int,
    contentPath: String? = nil, contentVersion: Int? = nil
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.kind = kind
    self.level = level
    self.order = order
    self.freeCount = freeCount
    self.productId = productId
    self.puzzleIds = puzzleIds
    self.wordCount = wordCount
    self.contentPath = contentPath
    self.contentVersion = contentVersion
  }

  /// Paketin tamamen ücretsiz olup olmadığı.
  public var isFullyFree: Bool { freeCount >= puzzleIds.count }

  /// Verilen sıradaki bulmacanın ücretsiz olup olmadığı.
  public func isFree(index: Int) -> Bool { index < freeCount }
}

/// Günün bulmacası takvim kaydı.
public struct DailyEntry: Codable, Hashable, Sendable {
  /// `yyyy-MM-dd` biçiminde tarih.
  public let date: String
  /// Bulmaca kimliği.
  public let puzzleId: String
}

/// Uygulamaya gömülü başlangıç içeriği ve önbellek dosyası biçimi.
public struct ContentBundle: Codable, Sendable {
  /// İçerik sürümü.
  public let version: Int
  /// Kelimeler.
  public let words: [Word]
  /// Paketler.
  public let packs: [Pack]
  /// Bulmacalar.
  public let puzzles: [Puzzle]
  /// Günlük bulmaca takvimi.
  public let dailies: [DailyEntry]
}

/// Firebase Storage'dan inen tek paket dosyası.
public struct PackPayload: Codable, Sendable {
  /// Paket bilgisi.
  public let pack: Pack
  /// Paketin bulmacaları.
  public let puzzles: [Puzzle]
  /// Bulmacalardaki kelimeler.
  public let words: [Word]

  /// Paket dosyasını oluşturur.
  public init(pack: Pack, puzzles: [Puzzle], words: [Word]) {
    self.pack = pack
    self.puzzles = puzzles
    self.words = words
  }
}

/// Firestore'dan gelen günlük bulmaca belgesi.
public struct DailyPayload: Codable, Sendable {
  /// `yyyy-MM-dd` tarih.
  public let date: String
  /// Bulmaca.
  public let puzzle: Puzzle
  /// Bulmacadaki kelimeler.
  public let words: [Word]

  /// Günlük bulmaca belgesini oluşturur.
  public init(date: String, puzzle: Puzzle, words: [Word]) {
    self.date = date
    self.puzzle = puzzle
    self.words = words
  }
}
