import ContentKit
import Testing
@testable import PuzzleKit

struct PuzzleKitTests {

  private let puzzle = Puzzle(
    id: "t", packId: nil, kind: .daily, level: .a1, width: 6, height: 6,
    entries: [
      PuzzleEntry(
        wordId: "w_house", answer: "HOUSE", clue: "Ev", row: 1, col: 1, dir: .across,
        clueRow: 1, clueCol: 0),
      PuzzleEntry(
        wordId: "w_heron", answer: "HERON", clue: "Balıkçıl", row: 1, col: 1, dir: .down,
        clueRow: 0, clueCol: 1),
    ])

  @Test("Kesişim kutusu iki kelimeye de aittir ve doğru harfi verir")
  func intersection() {
    let layout = CrosswordLayout(puzzle: puzzle)
    let point = GridPoint(row: 1, col: 1)
    #expect(layout.entries(at: point).count == 2)
    #expect(layout.answer(at: point) == "H")
    #expect(layout.entry(at: point, preferring: .down)?.wordId == "w_heron")
  }

  @Test("İpucu kutuları ve bloklar doğru sınıflanır")
  func kinds() {
    let layout = CrosswordLayout(puzzle: puzzle)
    if case .clue = layout.kind(at: GridPoint(row: 1, col: 0)) {
    } else {
      Issue.record("ipucu değil")
    }
    #expect(layout.kind(at: GridPoint(row: 3, col: 3)) == .blank)
  }

  @Test("Tema kimliği bilinmiyorsa Canlı döner; koyu modda Gece'ye geçer")
  func themes() {
    #expect(PuzzleTheme.theme(id: "yok").id == "canli")
    #expect(
      PuzzleTheme.resolve(id: "okyanus", isDark: true, autoNight: true, highContrast: false).id
        == "gece")
  }
}
