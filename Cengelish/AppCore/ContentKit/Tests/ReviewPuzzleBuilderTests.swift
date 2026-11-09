import Foundation
import Testing
@testable import ContentKit

@Suite("ReviewPuzzleBuilder")
struct ReviewPuzzleBuilderTests {

  /// Bulmacanın kesişimleri tutarlı, ipucu kutuları harf kutusu değil ve her şey ızgarada mı.
  private func expectValid(_ puzzle: Puzzle) {
    var letters: [GridPoint: Character] = [:]
    let clues = puzzle.entries.map(\.clueCell)
    #expect(Set(clues).count == clues.count)
    for entry in puzzle.entries {
      #expect(ReviewPuzzleBuilder.lengthRange.contains(entry.answer.count))
      for (point, char) in zip(entry.cells, entry.answer) {
        if let existing = letters[point] { #expect(existing == char) }
        letters[point] = char
        #expect(point.row < puzzle.height && point.col < puzzle.width)
      }
    }
    #expect(Set(clues).isDisjoint(with: letters.keys))
    #expect(Set(puzzle.entries.map(\.answer)).count == puzzle.entries.count)
  }

  /// Gömülü içerikteki uzunluğu uygun kelimeler.
  private func pool() throws -> [Word] {
    try ContentStore.loadStarterBundle().words.filter {
      ReviewPuzzleBuilder.lengthRange.contains($0.en.count)
    }
  }

  @Test("Tekrar kelimeleri yerleşir ve ızgara geçerlidir")
  func placesDueWords() throws {
    let words = try pool()
    let a1 = words.filter { $0.level == .a1 }
    let due = [3, 4, 5].compactMap { length in a1.first { $0.en.count == length } }
    #expect(due.count == 3)
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let puzzle = try #require(
      ReviewPuzzleBuilder(seed: 42).build(dueWords: due, pool: words, now: now))
    expectValid(puzzle)
    #expect(Set(due.map(\.id)).isSubset(of: Set(puzzle.wordIds)))
    #expect(puzzle.id == "review_1800000000000")
    #expect(puzzle.packId == ReviewPuzzleBuilder.packId)
    #expect(puzzle.kind == .pack)
    #expect(puzzle.isReview)
    #expect(puzzle.level == .a1)
    #expect(puzzle.width == 7 && [7, 9].contains(puzzle.height))
  }

  @Test("Aynı tohum aynı bulmacayı üretir")
  func deterministic() throws {
    let words = try pool()
    let due = Array(words.filter { $0.level == .b1 }.prefix(4))
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let first = ReviewPuzzleBuilder(seed: 7).build(dueWords: due, pool: words, now: now)
    let second = ReviewPuzzleBuilder(seed: 7).build(dueWords: due, pool: words, now: now)
    #expect(first != nil)
    #expect(first == second)
  }

  @Test("Birçok tohumda geçerli ve hızlı üretilir")
  func manySeeds() throws {
    let words = try pool()
    let clock = ContinuousClock()
    var worst: Duration = .zero
    var shuffler = SeededGenerator(seed: 2026)
    for seed in UInt64(1)...12 {
      let level = CEFRLevel.allCases[Int(seed) % 5]
      let due = Array(
        words.filter { $0.level == level }.shuffled(using: &shuffler).prefix(Int(seed % 6) + 1))
      var puzzle: Puzzle?
      let elapsed = clock.measure {
        puzzle = ReviewPuzzleBuilder(seed: seed).build(dueWords: due, pool: words)
      }
      worst = max(worst, elapsed)
      let built = try #require(puzzle)
      expectValid(built)
      #expect(!Set(due.map(\.id)).isDisjoint(with: Set(built.wordIds)))
    }
    // Hata ayıklama derlemesinde de makul kalmalı.
    #expect(worst < .seconds(2))
  }

  @Test("Kelime havuzu yetersizse nil döner")
  func returnsNilWithoutPool() {
    let word = Word(
      id: "w_cat", en: "cat", level: .a1, pos: "noun", clue: "Kedi", meaning: "kedi",
      ipa: "/kæt/", example: "A cat.")
    #expect(ReviewPuzzleBuilder(seed: 1).build(dueWords: [word], pool: [word]) == nil)
  }

  @Test("Geçici bulmaca depoda bulunur")
  func transientRegistration() async throws {
    let store = ContentStore(
      cacheDirectory: URL.temporaryDirectory.appending(path: UUID().uuidString))
    let words = await store.wordPool()
    #expect(!words.isEmpty)
    let due = Array(words.filter { $0.level == .a1 && $0.en.count <= 5 }.prefix(2))
    let puzzle = try #require(ReviewPuzzleBuilder(seed: 3).build(dueWords: due, pool: words))
    #expect(await store.puzzle(id: puzzle.id) == nil)
    await store.registerTransient(puzzle)
    #expect(await store.puzzle(id: puzzle.id) == puzzle)
    #expect(await store.words(ids: puzzle.wordIds).count == Set(puzzle.wordIds).count)
  }
}
