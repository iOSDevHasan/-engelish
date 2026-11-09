import ContentKit
import Foundation
import InjectionKit
import PencilKit
import PuzzleKit
import UserDataKit
import WidgetBridgeKit
import WidgetKit

/// Uygulama verisinden widget anlık görüntüsünü üretip App Group'a yazar.
@MainActor
final class WidgetPublisher {
  @Inject private var userData: any UserDataStoring
  @Inject private var content: any ContentProviding
  /// Anlık görüntü deposu.
  private let store = WidgetSnapshotStore()
  /// Kaç günlük kelime ve bulmaca yazılacağı.
  private let dayCount = 7
  /// Takvim.
  private let calendar = Calendar.current
  /// Izgara çizim geometrisi (bulmaca ekranıyla aynı).
  private let geometry = GridGeometry(cell: 60)

  /// Anlık görüntüyü yeniden üretir; değiştiyse widget'ları yeniler.
  func publish(now: Date = .now) async {
    guard let profile = userData.profile else { return }
    let stats = userData.stats
    let progress = userData.allProgress()
    let today = WidgetDay.string(from: now)
    let solvedToday = progress.values.filter { item in
      item.finishedAt.map { calendar.isDate($0, inSameDayAs: now) } ?? false
    }.count
    var days: [WidgetSnapshot.Day] = []
    for offset in 0..<dayCount {
      guard let date = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
      days.append(await makeDay(date: date, progress: progress))
    }
    let snapshot = WidgetSnapshot(
      generatedAt: now, nickname: profile.displayName, avatar: profile.avatar,
      streak: stats.streak, lastPlayedDay: stats.lastPlayedDay,
      solvedDays: Array(stats.solvedDays.suffix(21)), dailyGoal: profile.dailyGoal,
      solvedToday: .init(day: today, count: solvedToday), days: days)
    if store.save(snapshot) {
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  // MARK: - Private

  /// Bir günün kelimesi ve bulmacası.
  private func makeDay(
    date: Date, progress: [String: PuzzleProgress]
  ) async
    -> WidgetSnapshot.Day
  {
    let key = WidgetDay.string(from: date)
    guard let puzzle = await content.dailyPuzzle(for: date) else {
      return .init(day: key, word: nil, puzzle: nil)
    }
    let words = await content.words(ids: puzzle.wordIds)
    let dayIndex = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
    let word = words.isEmpty ? nil : words[dayIndex % words.count]
    return .init(
      day: key,
      word: word.map { .init(en: $0.en, meaning: $0.meaning, ipa: $0.ipa) },
      puzzle: makePuzzleInfo(puzzle, progress: progress[puzzle.id]))
  }

  /// Bulmacanın küçük ızgarası ve kalemle doldurulmuş kutu oranı.
  private func makePuzzleInfo(
    _ puzzle: Puzzle, progress: PuzzleProgress?
  )
    -> WidgetSnapshot.PuzzleInfo
  {
    let layout = CrosswordLayout(puzzle: puzzle)
    let isFinished = progress?.status == .finished
    let filled = isFinished ? Set(layout.letterCells) : inkedCells(layout, progress: progress)
    let grid = (0..<layout.rows).map { row in
      String(
        (0..<layout.columns).map { col -> Character in
          let point = GridPoint(row: row, col: col)
          switch layout.kind(at: point) {
          case .clue: return "#"
          case .letter: return filled.contains(point) ? "x" : "."
          case .blank: return " "
          }
        })
    }
    let total = max(layout.letterCells.count, 1)
    return .init(
      id: puzzle.id, level: puzzle.level.rawValue, wordCount: puzzle.entries.count,
      minutes: puzzle.estimatedMinutes, progress: Double(filled.count) / Double(total),
      isFinished: isFinished, grid: grid)
  }

  /// Üzerinde mürekkep (ya da açılmış harf) olan harf kutuları.
  private func inkedCells(_ layout: CrosswordLayout, progress: PuzzleProgress?) -> Set<GridPoint> {
    guard let progress else { return [] }
    var cells = Set(progress.revealedCells.compactMap(GridPoint.init(key:)))
    guard let data = progress.drawing, let drawing = try? PKDrawing(data: data) else {
      return cells
    }
    let bounds = drawing.strokes.map(\.renderBounds)
    for point in layout.letterCells where !cells.contains(point) {
      let rect = geometry.rect(for: point).insetBy(dx: 6, dy: 6)
      if bounds.contains(where: { $0.intersects(rect) }) { cells.insert(point) }
    }
    return cells
  }
}
