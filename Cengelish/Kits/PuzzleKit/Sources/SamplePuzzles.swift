import ContentKit

/// Önizlemeler için sabit örnek bulmaca (tasarımdaki 6×6 ızgara).
public enum SamplePuzzles {

  /// HOUSE, RACER, NORTH (→) · HERON, ULCER, EARTH (↓).
  public static let demo = Puzzle(
    id: "sample_demo", packId: nil, kind: .daily, level: .a2, width: 6, height: 6,
    entries: [
      entry("w_house", "HOUSE", "Ev", 1, 1, .across, 1, 0),
      entry("w_racer", "RACER", "Yarışçı", 3, 1, .across, 3, 0),
      entry("w_north", "NORTH", "Kuzey", 5, 1, .across, 5, 0),
      entry("w_heron", "HERON", "Balıkçıl (kuş)", 1, 1, .down, 0, 1),
      entry("w_ulcer", "ULCER", "Mide yarası", 1, 3, .down, 0, 3),
      entry("w_earth", "EARTH", "Dünya gezegeni", 1, 5, .down, 0, 5),
    ])

  private static func entry(
    _ id: String, _ answer: String, _ clue: String, _ row: Int, _ col: Int, _ dir: Direction,
    _ clueRow: Int, _ clueCol: Int
  ) -> PuzzleEntry {
    PuzzleEntry(
      wordId: id, answer: answer, clue: clue, row: row, col: col, dir: dir, clueRow: clueRow,
      clueCol: clueCol)
  }
}
