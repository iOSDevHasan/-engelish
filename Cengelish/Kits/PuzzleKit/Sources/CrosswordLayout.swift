import ContentKit
import Foundation

/// Bir kutunun türü.
public enum CellKind: Equatable, Sendable {
  /// İpucu kutusu ve içindeki kelimeler.
  case clue([PuzzleEntry])
  /// Harf kutusu.
  case letter
  /// Boş (blok) kutu.
  case blank
}

/// Bulmacadan türetilen ızgara düzeni ve gezinme yardımcıları.
public struct CrosswordLayout: Equatable, Sendable {

  // MARK: - Properties

  /// Kaynak bulmaca.
  public let puzzle: Puzzle
  private let kinds: [GridPoint: CellKind]
  private let entriesByCell: [GridPoint: [PuzzleEntry]]

  // MARK: - Init

  /// Bulmacadan düzen oluşturur.
  public init(puzzle: Puzzle) {
    self.puzzle = puzzle
    var kinds: [GridPoint: CellKind] = [:]
    var byCell: [GridPoint: [PuzzleEntry]] = [:]
    var cluesByCell: [GridPoint: [PuzzleEntry]] = [:]
    for entry in puzzle.entries {
      cluesByCell[entry.clueCell, default: []].append(entry)
      for cell in entry.cells {
        kinds[cell] = .letter
        byCell[cell, default: []].append(entry)
      }
    }
    for (point, entries) in cluesByCell {
      kinds[point] = .clue(entries.sorted { $0.dir == .across && $1.dir == .down })
    }
    self.kinds = kinds
    self.entriesByCell = byCell
  }

  // MARK: - Queries

  /// Satır sayısı.
  public var rows: Int { puzzle.height }
  /// Sütun sayısı.
  public var columns: Int { puzzle.width }

  /// Kutunun türü.
  public func kind(at point: GridPoint) -> CellKind {
    kinds[point] ?? .blank
  }

  /// Kutunun geçtiği kelimeler.
  public func entries(at point: GridPoint) -> [PuzzleEntry] {
    entriesByCell[point] ?? []
  }

  /// Kutuya dokununca seçilecek kelime: önce mevcut yön, yoksa ilk kelime.
  public func entry(at point: GridPoint, preferring direction: Direction?) -> PuzzleEntry? {
    let candidates = entries(at: point)
    return candidates.first { $0.dir == direction } ?? candidates.first
  }

  /// Kelime listesinde sonraki (ya da önceki) kelime.
  public func entry(after entry: PuzzleEntry, step: Int) -> PuzzleEntry {
    let list = puzzle.entries
    guard let index = list.firstIndex(of: entry) else { return entry }
    return list[(index + step + list.count) % list.count]
  }

  /// Kutudaki doğru harf.
  public func answer(at point: GridPoint) -> Character? {
    entries(at: point).first?.letter(at: point)
  }

  /// Tüm harf kutuları.
  public var letterCells: [GridPoint] {
    kinds.compactMap { $0.value == .letter ? $0.key : nil }
  }
}

extension GridPoint {
  /// Kalıcı saklama için `satır,sütun` anahtarı.
  public var key: String { "\(row),\(col)" }

  /// `satır,sütun` anahtarından konum üretir.
  public init?(key: String) {
    let parts = key.split(separator: ",").compactMap { Int($0) }
    guard parts.count == 2 else { return nil }
    self.init(row: parts[0], col: parts[1])
  }
}
