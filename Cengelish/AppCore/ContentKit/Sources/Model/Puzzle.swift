import Foundation

/// Izgaradaki bir hücrenin konumu.
public struct GridPoint: Hashable, Codable, Sendable {
  /// Satır (0'dan başlar).
  public let row: Int
  /// Sütun (0'dan başlar).
  public let col: Int

  /// Satır ve sütunla konum oluşturur.
  public init(row: Int, col: Int) {
    self.row = row
    self.col = col
  }
}

/// Kelimenin yazılış yönü.
public enum Direction: String, Codable, Sendable {
  case across
  case down

  /// Ekrandaki ok ve açıklama.
  public var title: String { self == .across ? "Soldan sağa" : "Yukarıdan aşağı" }
}

/// Bulmacadaki tek bir kelime (ipucu kutusu + harf kutuları).
public struct PuzzleEntry: Codable, Hashable, Identifiable, Sendable {
  /// Kelime kimliği.
  public let wordId: String
  /// Büyük harfli cevap.
  public let answer: String
  /// İpucu kutusundaki Türkçe ipucu.
  public let clue: String
  /// İlk harfin satırı.
  public let row: Int
  /// İlk harfin sütunu.
  public let col: Int
  /// Yön.
  public let dir: Direction
  /// İpucu kutusunun satırı.
  public let clueRow: Int
  /// İpucu kutusunun sütunu.
  public let clueCol: Int

  /// Kelimeyi tüm alanlarıyla oluşturur.
  public init(
    wordId: String, answer: String, clue: String, row: Int, col: Int, dir: Direction,
    clueRow: Int, clueCol: Int
  ) {
    self.wordId = wordId
    self.answer = answer
    self.clue = clue
    self.row = row
    self.col = col
    self.dir = dir
    self.clueRow = clueRow
    self.clueCol = clueCol
  }

  /// Bulmaca içinde benzersiz kimlik.
  public var id: String { "\(dir.rawValue)-\(clueRow)-\(clueCol)" }

  /// İpucu kutusunun konumu.
  public var clueCell: GridPoint { GridPoint(row: clueRow, col: clueCol) }

  /// Kelimenin harf kutuları, sırasıyla.
  public var cells: [GridPoint] {
    (0..<answer.count).map { offset in
      dir == .across
        ? GridPoint(row: row, col: col + offset) : GridPoint(row: row + offset, col: col)
    }
  }

  /// Verilen kutudaki doğru harf.
  public func letter(at point: GridPoint) -> Character? {
    guard let index = cells.firstIndex(of: point) else { return nil }
    return Array(answer)[index]
  }
}

/// Bulmacanın türü.
public enum PuzzleKind: String, Codable, Sendable {
  case pack
  case daily
}

/// Bir çengel bulmaca.
public struct Puzzle: Codable, Hashable, Identifiable, Sendable {
  /// Bulmaca kimliği.
  public let id: String
  /// Ait olduğu paket (günlük bulmacalarda yok).
  public let packId: String?
  /// Tür.
  public let kind: PuzzleKind
  /// Seviye.
  public let level: CEFRLevel
  /// Sütun sayısı.
  public let width: Int
  /// Satır sayısı.
  public let height: Int
  /// Kelimeler.
  public let entries: [PuzzleEntry]
  /// İçerik sürümü.
  public let version: Int

  /// Bulmacayı tüm alanlarıyla oluşturur.
  public init(
    id: String, packId: String?, kind: PuzzleKind, level: CEFRLevel, width: Int, height: Int,
    entries: [PuzzleEntry], version: Int = 1
  ) {
    self.id = id
    self.packId = packId
    self.kind = kind
    self.level = level
    self.width = width
    self.height = height
    self.entries = entries
    self.version = version
  }

  /// Bulmacadaki benzersiz kelime kimlikleri.
  public var wordIds: [String] { entries.map(\.wordId) }

  /// Bulmacadaki harf kutusu sayısı.
  public var letterCount: Int { Set(entries.flatMap(\.cells)).count }

  /// Tahmini çözüm süresi (dakika).
  public var estimatedMinutes: Int { max(3, letterCount / 6) }
}
