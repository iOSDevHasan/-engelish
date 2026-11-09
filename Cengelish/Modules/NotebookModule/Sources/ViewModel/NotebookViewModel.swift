import Combine
import ContentKit
import Foundation
import UserDataKit
import WordKit

/// Defter listesindeki satır.
struct NotebookRow: Identifiable, Equatable {
  let word: Word
  let item: NotebookItem

  var id: String { word.id }
}

/// Defter filtresi.
enum NotebookFilter: String, CaseIterable, Identifiable {
  case due = "Bugün"
  case all = "Tümü"
  case learned = "Öğrenilenler"

  var id: String { rawValue }
}

/// Kelime Defterim durumu ve tekrar oturumu.
@MainActor
final class NotebookViewModel: ObservableObject {

  // MARK: - Properties

  @Published var filter: NotebookFilter = .due
  @Published private(set) var rows: [NotebookRow] = []
  @Published private(set) var boxCounts: [Int] = Array(repeating: 0, count: 5)
  @Published var detail: NotebookRow?
  @Published var isReviewing = false
  @Published private(set) var reviewQueue: [NotebookRow] = []
  @Published var isRevealed = false
  private let content: any ContentProviding
  private let userData: any UserDataStoring
  private let pronouncer: any Pronouncing
  private var cancellables: Set<AnyCancellable> = []

  // MARK: - Init

  init(content: any ContentProviding, userData: any UserDataStoring, pronouncer: any Pronouncing) {
    self.content = content
    self.userData = userData
    self.pronouncer = pronouncer
    userData.changes
      .sink { [weak self] in Task { await self?.load() } }
      .store(in: &cancellables)
  }

  // MARK: - Derived

  /// Filtrelenmiş satırlar.
  var visibleRows: [NotebookRow] {
    switch filter {
    case .due: rows.filter { $0.item.isDue() }
    case .all: rows.filter { !$0.item.learned }
    case .learned: rows.filter(\.item.learned)
    }
  }

  /// Bugün tekrar edilecek kelime sayısı.
  var dueCount: Int { rows.filter { $0.item.isDue() }.count }

  /// Tekrar kartındaki kelime.
  var currentCard: NotebookRow? { reviewQueue.first }

  /// Satırın tekrar etiketi.
  func dueLabel(_ item: NotebookItem) -> String {
    if item.learned { return "Öğrenildi" }
    if item.isDue() { return "Bugün" }
    let days = Calendar.current.dateComponents([.day], from: .now, to: item.nextReviewAt).day ?? 0
    return days <= 1 ? "Yarın" : "\(days) gün sonra"
  }

  // MARK: - Intents

  /// Defteri yükler.
  func load() async {
    let items = userData.notebook
    let words = await content.words(ids: items.map(\.wordId))
    let byId = Dictionary(uniqueKeysWithValues: words.map { ($0.id, $0) })
    rows = items.compactMap { item in byId[item.wordId].map { NotebookRow(word: $0, item: item) } }
    boxCounts = (1...5).map { box in items.filter { !$0.learned && $0.box == box }.count }
    if filter == .due && dueCount == 0 && !rows.isEmpty { filter = .all }
  }

  /// Bugünün tekrarlarını başlatır.
  func startReview() {
    reviewQueue = rows.filter { $0.item.isDue() }.shuffled()
    isRevealed = false
    isReviewing = !reviewQueue.isEmpty
  }

  /// Kartın cevabını gösterir.
  func reveal() {
    isRevealed = true
    if let word = currentCard?.word { speak(word) }
  }

  /// Kartı bildi/bilmedi olarak işaretler ve sonrakine geçer.
  func answer(knew: Bool) {
    guard let card = reviewQueue.first else { return }
    userData.review(wordId: card.word.id, knew: knew)
    reviewQueue.removeFirst()
    isRevealed = false
    if reviewQueue.isEmpty { isReviewing = false }
  }

  /// Kelimeyi okur.
  func speak(_ word: Word) {
    pronouncer.speak(word.en, language: userData.settings.accent.languageCode)
  }

  /// Kelimeyi defterden çıkarır.
  func remove(_ row: NotebookRow) {
    userData.removeFromNotebook(wordId: row.word.id)
    detail = nil
  }
}
