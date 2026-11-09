import Combine
import ContentKit
import DesignKit
import Foundation
import UserDataKit
import WordKit

/// Haftalık seri göstergesindeki bir gün.
struct WeekDay: Identifiable, Equatable {
  let id: String
  let label: String
  let isSolved: Bool
  let isToday: Bool
}

/// Kaldığın yerden devam kartı.
struct ContinueItem: Equatable {
  let puzzleId: String
  let title: String
  let progress: Double
}

/// Ana Sayfa durumu.
@MainActor
final class HomeViewModel: ObservableObject {

  // MARK: - Properties

  @Published private(set) var name = "Kalemci"
  @Published private(set) var avatar = AvatarConfig()
  @Published private(set) var level = "A1"
  @Published private(set) var streak = 0
  @Published private(set) var longestStreak = 0
  @Published private(set) var week: [WeekDay] = []
  @Published private(set) var solvedToday = 0
  @Published private(set) var dailyGoal = 2
  @Published private(set) var daily: Puzzle?
  @Published private(set) var dailyDone = false
  @Published private(set) var continueItem: ContinueItem?
  @Published private(set) var wordOfDay: Word?
  @Published private(set) var dueCount = 0
  private let coordinator: HomeCoordinator
  private let content: any ContentProviding
  private let userData: any UserDataStoring
  private let pronouncer: any Pronouncing
  private let calendar = Calendar.current
  private var cancellables: Set<AnyCancellable> = []

  // MARK: - Init

  init(
    coordinator: HomeCoordinator, content: any ContentProviding, userData: any UserDataStoring,
    pronouncer: any Pronouncing
  ) {
    self.coordinator = coordinator
    self.content = content
    self.userData = userData
    self.pronouncer = pronouncer
    userData.changes
      .sink { [weak self] in Task { await self?.load() } }
      .store(in: &cancellables)
  }

  // MARK: - Intents

  /// Ekran verisini yükler.
  func load() async {
    if let profile = userData.profile {
      name = profile.displayName
      avatar = profile.avatar
      level = profile.level
      dailyGoal = profile.dailyGoal
    }
    let stats = userData.stats
    streak = stats.streak
    longestStreak = stats.longestStreak
    week = makeWeek(solvedDays: Set(stats.solvedDays))
    let progress = userData.allProgress()
    solvedToday =
      progress.values.filter { item in
        item.finishedAt.map { calendar.isDateInToday($0) } ?? false
      }.count
    daily = await content.dailyPuzzle(for: .now)
    dailyDone = daily.map { progress[$0.id]?.status == .finished } ?? false
    dueCount = userData.notebook.filter { $0.isDue() }.count
    await loadContinue(progress)
    if let daily {
      let words = await content.words(ids: daily.wordIds)
      let dayIndex = calendar.ordinality(of: .day, in: .era, for: .now) ?? 0
      wordOfDay = words.isEmpty ? nil : words[dayIndex % words.count]
    }
  }

  /// Günün Bulmacasını açar.
  func openDaily() {
    guard let daily else { return }
    coordinator.showPuzzle(daily.id)
  }

  /// Yarım kalan bulmacayı açar.
  func openContinue() {
    guard let continueItem else { return }
    coordinator.showPuzzle(continueItem.puzzleId)
  }

  /// Günün kelimesini okur.
  func speakWordOfDay() {
    guard let wordOfDay else { return }
    pronouncer.speak(wordOfDay.en, language: userData.settings.accent.languageCode)
  }

  /// Saate göre selamlama.
  var greeting: String {
    switch calendar.component(.hour, from: .now) {
    case 5..<12: "Günaydın"
    case 12..<18: "İyi günler"
    default: "İyi akşamlar"
    }
  }

  // MARK: - Private

  private func makeWeek(solvedDays: Set<String>) -> [WeekDay] {
    let labels = ["Pt", "Sa", "Ça", "Pe", "Cu", "Ct", "Pz"]
    let weekday = (calendar.component(.weekday, from: .now) + 5) % 7
    return (0..<7).map { index in
      let date = calendar.date(byAdding: .day, value: index - weekday, to: .now) ?? .now
      let key = DayKey.string(from: date)
      return WeekDay(
        id: key, label: labels[index], isSolved: solvedDays.contains(key), isToday: index == weekday
      )
    }
  }

  private func loadContinue(_ progress: [String: PuzzleProgress]) async {
    guard
      let item = progress.values.first(where: {
        $0.status == .inProgress && $0.puzzleId != daily?.id
      }),
      let puzzle = await content.puzzle(id: item.puzzleId)
    else {
      continueItem = nil
      return
    }
    var title = "Bulmaca"
    if let packId = puzzle.packId, let pack = await content.pack(id: packId) {
      let index = (pack.puzzleIds.firstIndex(of: puzzle.id) ?? 0) + 1
      title = "\(pack.title) · Bulmaca \(index)"
    }
    continueItem = ContinueItem(
      puzzleId: puzzle.id, title: title, progress: min(0.9, Double(item.durationSec) / 300))
  }
}
