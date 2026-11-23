import Foundation
import Testing

@testable import ContentKit

/// Gömülü içeriğin tamamını "çözer": her bulmacanın ızgarası cevaplarla doldurulur, her kelime
/// ızgaradan geri okunur ve paket / takvim bağlantıları denetlenir.
@Suite("Gömülü içerik bütünlüğü")
struct ContentIntegrityTests {

  private static let bundle = try? ContentStore.loadStarterBundle()

  /// Gömülü içerik.
  private func content() throws -> ContentBundle {
    try #require(Self.bundle)
  }

  @Test("Her bulmaca cevaplarla eksiksiz çözülür; ızgaradan okunan kelime cevaba eşittir")
  func everyPuzzleSolves() throws {
    let bundle = try content()
    for puzzle in bundle.puzzles {
      let grid = try solvedGrid(puzzle)
      for entry in puzzle.entries {
        let read = String(entry.cells.compactMap { grid[$0] })
        #expect(read == entry.answer, "\(puzzle.id) \(entry.id): \(read) ≠ \(entry.answer)")
      }
    }
  }

  @Test("İpucu kutusu kelimenin hemen önündedir; kutular ızgaranın içindedir")
  func cluesSitBeforeAnswers() throws {
    for puzzle in try content().puzzles {
      for entry in puzzle.entries {
        let start = try #require(entry.cells.first)
        let expected =
          entry.dir == .across
          ? GridPoint(row: start.row, col: start.col - 1)
          : GridPoint(row: start.row - 1, col: start.col)
        #expect(entry.clueCell == expected, "\(puzzle.id) \(entry.id)")
        for cell in entry.cells + [entry.clueCell] {
          #expect((0..<puzzle.height).contains(cell.row), "\(puzzle.id) \(entry.id)")
          #expect((0..<puzzle.width).contains(cell.col), "\(puzzle.id) \(entry.id)")
        }
      }
    }
  }

  @Test("Bir bulmacada aynı kelime ya da aynı ipucu iki kez yoktur")
  func noRepeatedWordsInPuzzle() throws {
    for puzzle in try content().puzzles {
      let words = puzzle.entries.map(\.wordId)
      #expect(Set(words).count == words.count, "\(puzzle.id)")
      let clues = puzzle.entries.map { $0.clue.lowercased() }
      #expect(Set(clues).count == clues.count, "\(puzzle.id): aynı ipucu iki kez")
      let answers = puzzle.entries.map(\.answer)
      for (index, answer) in answers.enumerated() {
        for other in answers[(index + 1)...] {
          #expect(
            !answer.contains(other) && !other.contains(answer),
            "\(puzzle.id): \(answer) / \(other) birbirini içeriyor")
        }
      }
      let ids = puzzle.entries.map(\.id)
      #expect(Set(ids).count == ids.count, "\(puzzle.id)")
      #expect(puzzle.entries.count >= 4, "\(puzzle.id)")
    }
  }

  @Test("Cevap, ipucu ve kelime havuzu birbirini tutar; ipucu cevabı ele vermez")
  func entriesMatchWords() throws {
    let bundle = try content()
    let words = Dictionary(uniqueKeysWithValues: bundle.words.map { ($0.id, $0) })
    for puzzle in bundle.puzzles {
      for entry in puzzle.entries {
        let word = try #require(words[entry.wordId], "\(puzzle.id) \(entry.wordId)")
        #expect(entry.answer == word.en.uppercased(), "\(puzzle.id) \(entry.wordId)")
        #expect(entry.answer.count >= 3, "\(puzzle.id) \(entry.wordId)")
        #expect(entry.answer.allSatisfy { $0.isASCII && $0.isUppercase }, "\(entry.answer)")
        #expect(!entry.clue.isEmpty, "\(puzzle.id) \(entry.wordId)")
        #expect(
          !entry.clue.lowercased().contains(word.en.lowercased()),
          "\(puzzle.id): ipucu cevabı içeriyor (\(entry.clue))")
      }
    }
    for word in bundle.words {
      #expect(!word.meaning.isEmpty, "\(word.id)")
      #expect(!word.example.isEmpty, "\(word.id)")
      #expect(word.ipa.hasPrefix("/") && word.ipa.hasSuffix("/"), "\(word.id)")
    }
  }

  @Test("Paketlerin bulmacaları var, tek pakete aittir ve aynı bulmaca iki kez yoktur")
  func packsReferenceTheirPuzzles() throws {
    let bundle = try content()
    let puzzles = Dictionary(uniqueKeysWithValues: bundle.puzzles.map { ($0.id, $0) })
    var seen = Set<String>()
    for pack in bundle.packs {
      #expect(!pack.puzzleIds.isEmpty, "\(pack.id)")
      #expect(pack.freeCount <= pack.puzzleIds.count, "\(pack.id)")
      var answerSets = Set<[String]>()
      for id in pack.puzzleIds {
        #expect(seen.insert(id).inserted, "\(id) iki pakette")
        let puzzle = try #require(puzzles[id], "\(pack.id): \(id) yok")
        #expect(puzzle.packId == pack.id, "\(id)")
        #expect(puzzle.kind == .pack, "\(id)")
        let answers = puzzle.entries.map(\.answer).sorted()
        #expect(answerSets.insert(answers).inserted, "\(id) paketteki başka bulmacanın aynısı")
      }
    }
  }

  @Test("Günlük takvim ardışık günlerdir ve her gün günlük bir bulmacaya bağlanır")
  func dailyCalendarIsContinuous() throws {
    let bundle = try content()
    let puzzles = Dictionary(uniqueKeysWithValues: bundle.puzzles.map { ($0.id, $0) })
    let days = bundle.dailies.compactMap { DailyPuzzleBuilder.dayNumber(from: $0.date) }
    #expect(days.count == bundle.dailies.count)
    #expect(days == days.sorted())
    for (previous, next) in zip(days, days.dropFirst()) {
      #expect(next == previous + 1)
    }
    for daily in bundle.dailies {
      let puzzle = try #require(puzzles[daily.puzzleId], "\(daily.date)")
      #expect(puzzle.kind == .daily, "\(daily.date)")
    }
  }

  // MARK: - Helpers

  /// Izgarayı cevaplarla doldurur; kesişen kutuda farklı harf ya da ipucu kutusuna harf düşerse
  /// test başarısız olur.
  private func solvedGrid(_ puzzle: Puzzle) throws -> [GridPoint: Character] {
    var grid: [GridPoint: Character] = [:]
    let clues = Set(puzzle.entries.map(\.clueCell))
    for entry in puzzle.entries {
      #expect(entry.cells.count == entry.answer.count, "\(puzzle.id) \(entry.id)")
      for (cell, letter) in zip(entry.cells, entry.answer) {
        #expect(!clues.contains(cell), "\(puzzle.id): ipucu kutusunda harf")
        if let existing = grid[cell] {
          #expect(existing == letter, "\(puzzle.id): \(cell) çakışıyor")
        }
        grid[cell] = letter
      }
    }
    return grid
  }
}
