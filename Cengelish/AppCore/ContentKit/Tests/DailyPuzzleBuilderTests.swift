import Foundation
import Testing

@testable import ContentKit

@Suite("DailyPuzzleBuilder")
struct DailyPuzzleBuilderTests {

  /// Gömülü kelimelerle kurulan üretici.
  private func builder() throws -> DailyPuzzleBuilder {
    DailyPuzzleBuilder(words: try ContentStore.loadStarterBundle().words)
  }

  /// Kesişimler tutarlı, ipucu kutuları harf kutusu değil, her şey ızgarada ve kelimeler tekil mi.
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
    #expect(puzzle.entries.count >= 5)
  }

  @Test("Aynı gün her seferinde aynı bulmacayı verir")
  func sameDateSamePuzzle() throws {
    let first = try #require(try builder().build(dayKey: "2028-03-14"))
    let second = try #require(try builder().build(dayKey: "2028-03-14"))
    #expect(first == second)
    #expect(first.id == "daily_2028-03-14")
    #expect(first.kind == .daily)
    #expect(first.packId == nil)
  }

  @Test("Farklı günler farklı bulmaca verir")
  func differentDatesDiffer() throws {
    let builder = try builder()
    let first = try #require(builder.build(dayKey: "2028-03-14"))
    let second = try #require(builder.build(dayKey: "2028-03-15"))
    #expect(first.entries != second.entries)
  }

  @Test("On gün boyunca geçerli, hızlı ve uygun seviyeden üretilir")
  func tenDaysOfDailies() throws {
    let builder = try builder()
    let words = Dictionary(
      uniqueKeysWithValues: try ContentStore.loadStarterBundle().words.map { ($0.id, $0) })
    let clock = ContinuousClock()
    var total: Duration = .zero
    for day in 1...10 {
      let key = String(format: "2029-01-%02d", day)
      var puzzle: Puzzle?
      let elapsed = clock.measure { puzzle = builder.build(dayKey: key) }
      total += elapsed
      let built = try #require(puzzle)
      expectValid(built)
      #expect(DailyPuzzleBuilder.dayLevels.contains(built.level))
      for id in built.wordIds {
        let word = try #require(words[id])
        #expect(DailyPuzzleBuilder.isEligible(word))
      }
    }
    // Widget 7 günü birden ister; hata ayıklama derlemesinde de makul kalmalı. Ortalama
    // ölçülür: paralel çalışan testler tek bir günü yavaşlatsa da sonuç kararlı kalır.
    #expect(total / 10 < .milliseconds(1_500))
  }

  @Test("Ardışık aynı seviyeli günlerin öne çıkan kelimeleri çakışmaz")
  func featuredWordsRotate() throws {
    let builder = try builder()
    let day = try #require(DailyPuzzleBuilder.dayNumber(from: "2028-03-14"))
    let today = Set(builder.featuredWords(level: .a2, day: day).map(\.id))
    let next = Set(builder.featuredWords(level: .a2, day: day + 2).map(\.id))
    #expect(today.count == DailyPuzzleBuilder.featuredCount)
    #expect(today.isDisjoint(with: next))
  }

  @Test("Gün anahtarı saat diliminden bağımsız gün sayısına çevrilir")
  func dayNumbers() {
    #expect(DailyPuzzleBuilder.dayNumber(from: "1970-01-01") == 0)
    #expect(DailyPuzzleBuilder.dayNumber(from: "2000-03-01") == 11_017)
    #expect(DailyPuzzleBuilder.dayNumber(from: "2026-11-09") == 20_766)
    #expect(DailyPuzzleBuilder.dayNumber(from: "bozuk") == nil)
    #expect(
      DailyPuzzleBuilder.seed(for: "2026-11-09") == DailyPuzzleBuilder.seed(for: "2026-11-09"))
  }

  @Test("Takvimde olmayan gün cihazda üretilir, kimliğiyle bulunur ve önbellekte kalıcıdır")
  func storeGeneratesAndPersists() async throws {
    let folder = URL.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    // Gömülü takvimden sonraki, bugünden önceki bir gün: üretilip önbelleğe yazılır.
    let past = try #require(
      Calendar(identifier: .gregorian).date(from: DateComponents(year: 2025, month: 6, day: 1)))
    let key = DayKey.string(from: past)
    let store = ContentStore(cacheDirectory: folder)
    let puzzle = try #require(await store.dailyPuzzle(for: past))
    #expect(puzzle.id == DailyPuzzleBuilder.idPrefix + key)
    #expect(puzzle.kind == .daily)
    #expect(await store.puzzle(id: puzzle.id) == puzzle)
    #expect(await store.dailyPuzzle(for: past) == puzzle)
    #expect(await store.words(ids: puzzle.wordIds).count == Set(puzzle.wordIds).count)
    let file = folder.appending(path: "\(ContentStore.generatedDailyPrefix)\(key).json")
    #expect(FileManager.default.fileExists(atPath: file.path()))
    // Yeni açılışta önbellekten aynı bulmaca okunur.
    let reopened = ContentStore(cacheDirectory: folder)
    #expect(await reopened.puzzle(id: puzzle.id) == puzzle)
    #expect(await reopened.dailyPuzzle(for: past) == puzzle)
  }

  @Test("Gömülü takvimdeki gün üretilmez")
  func bundledDayIsUsed() async throws {
    let bundle = try ContentStore.loadStarterBundle()
    let entry = try #require(bundle.dailies.first)
    let parts = entry.date.split(separator: "-").compactMap { Int($0) }
    let date = try #require(
      Calendar.current.date(
        from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12)))
    let store = ContentStore(
      cacheDirectory: URL.temporaryDirectory.appending(path: UUID().uuidString))
    let puzzle = try #require(await store.dailyPuzzle(for: date))
    #expect(puzzle == bundle.puzzles.first { $0.id == entry.puzzleId })
  }
}
