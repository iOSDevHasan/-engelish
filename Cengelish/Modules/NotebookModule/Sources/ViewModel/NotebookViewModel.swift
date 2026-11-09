import Combine
import ContentKit
import DesignKit
import Foundation
import PurchaseKit
import UserDataKit
import WordKit

/// Defter listesindeki satır.
struct NotebookRow: Identifiable, Equatable {
  let word: Word
  let item: NotebookItem

  var id: String { word.id }
}

/// Defter filtresi (Tümü / Tekrar / Öğrendim).
enum NotebookFilter: String, CaseIterable, Identifiable {
  case all
  case due
  case learned

  var id: String { rawValue }
}

/// Defter ekranının açtığı diğer ekranlar.
@MainActor
protocol NotebookRouting: AnyObject {
  /// Bulmacayı açar.
  func showPuzzle(_ puzzleId: String)
  /// Çengelish+ paywall'unu açar.
  func showPaywall()
}

/// Kelime Defterim durumu, elle kelime ekleme, kart ve bulmaca tekrarı.
@MainActor
final class NotebookViewModel: ObservableObject {

  // MARK: - Properties

  @Published var filter: NotebookFilter = .due
  @Published private(set) var rows: [NotebookRow] = []
  @Published var detail: NotebookRow?
  @Published var isReviewing = false
  @Published private(set) var reviewQueue: [NotebookRow] = []
  @Published var isRevealed = false
  @Published var isAddingWord = false
  @Published var query = ""
  @Published private(set) var pool: [Word] = []
  @Published private(set) var isBuildingPuzzle = false
  @Published var notice: String?
  @Published private(set) var sourceTitles: [String: String] = [:]
  private weak var router: NotebookRouting?
  private let content: any ContentProviding
  private let userData: any UserDataStoring
  private let pronouncer: any Pronouncing
  private let entitlements: any EntitlementProviding
  private let puzzleSeed: UInt64?
  private var didChooseInitialFilter = false
  private var cancellables: Set<AnyCancellable> = []

  // MARK: - Init

  /// Görünüm modelini servislerle oluşturur; `puzzleSeed` testlerde bulmacayı sabitler.
  init(
    router: NotebookRouting?, content: any ContentProviding, userData: any UserDataStoring,
    pronouncer: any Pronouncing, entitlements: any EntitlementProviding,
    puzzleSeed: UInt64? = nil
  ) {
    self.router = router
    self.content = content
    self.userData = userData
    self.pronouncer = pronouncer
    self.entitlements = entitlements
    self.puzzleSeed = puzzleSeed
    userData.changes
      .sink { [weak self] in Task { await self?.load() } }
      .store(in: &cancellables)
  }

  // MARK: - Derived

  /// Seçili bölmedeki satırlar.
  var visibleRows: [NotebookRow] { rows(for: filter) }

  /// Defterdeki toplam kelime.
  var totalCount: Int { rows.count }

  /// Bugün tekrar edilecek kelime sayısı.
  var dueCount: Int { rows(for: .due).count }

  /// Öğrenilen kelime sayısı.
  var learnedCount: Int { rows(for: .learned).count }

  /// Tekrar kartındaki kelime.
  var currentCard: NotebookRow? { reviewQueue.first }

  /// Kullanıcının seçtiği telaffuz aksanı.
  var accent: WordAccent { WordAccent(languageCode: userData.settings.accent.languageCode) }

  /// Bölme başlığı.
  func title(for filter: NotebookFilter) -> String {
    switch filter {
    case .all: "Tümü"
    case .due: "Tekrar (\(dueCount))"
    case .learned: "Öğrendim"
    }
  }

  /// Bölmedeki satırlar.
  func rows(for filter: NotebookFilter, now: Date = .now) -> [NotebookRow] {
    switch filter {
    case .all: rows
    case .due: rows.filter { $0.item.isDue(at: now) }
    case .learned: rows.filter(\.item.learned)
    }
  }

  /// Satırın tekrar etiketi ("Bugün", "Yarın", "3 gün sonra", "1 hafta sonra").
  func dueLabel(_ item: NotebookItem, now: Date = .now) -> String {
    if item.learned { return "Öğrenildi" }
    if item.isDue(at: now) { return "Bugün" }
    let calendar = Calendar.current
    let days =
      calendar.dateComponents(
        [.day], from: calendar.startOfDay(for: now),
        to: calendar.startOfDay(for: item.nextReviewAt)
      ).day ?? 0
    switch days {
    case ...0: return "Bugün"
    case 1: return "Yarın"
    case 2..<7: return "\(days) gün sonra"
    case 7..<30: return "\(max(1, Int((Double(days) / 7).rounded()))) hafta sonra"
    default: return "\(max(1, days / 30)) ay sonra"
    }
  }

  /// Kelimenin ilk görüldüğü yer ve tarih ("Günün Bulmacası · 8 Kasım").
  func firstSeen(_ item: NotebookItem) -> String {
    let title = item.source == "manual" ? "Elle eklendi" : sourceTitles[item.source] ?? item.source
    return "\(title) · \(DateText.dayMonth(item.addedAt))"
  }

  /// Elle ekleme aramasının sonuçları; önce baştan eşleşenler.
  var searchResults: [Word] {
    let text = query.trimmingCharacters(in: .whitespaces)
    guard !text.isEmpty else { return Array(pool.prefix(Self.searchLimit)) }
    let matches = pool.filter {
      $0.en.localizedStandardContains(text) || $0.meaning.localizedStandardContains(text)
    }
    let lower = text.lowercased()
    let prefix = matches.filter { $0.en.lowercased().hasPrefix(lower) }
    let rest = matches.filter { !$0.en.lowercased().hasPrefix(lower) }
    return Array((prefix + rest).prefix(Self.searchLimit))
  }

  /// Kelime defterde mi.
  func isInNotebook(_ word: Word) -> Bool {
    rows.contains { $0.word.id == word.id }
  }

  // MARK: - Loading

  /// Defteri ve kaynak bulmaca adlarını yükler.
  func load() async {
    let items = userData.notebook
    let words = await content.words(ids: items.map(\.wordId))
    let byId = Dictionary(words.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    rows = items.compactMap { item in byId[item.wordId].map { NotebookRow(word: $0, item: item) } }
      .sorted(by: Self.order)
    await resolveSources(Set(items.map(\.source)))
    if !didChooseInitialFilter, !rows.isEmpty {
      didChooseInitialFilter = true
      filter = dueCount > 0 ? .due : .all
    }
    if let detail {
      self.detail = rows.first { $0.id == detail.id }
    }
  }

  /// Bulmaca kimliklerini ekranda görünen adlara çevirir.
  private func resolveSources(_ sources: Set<String>) async {
    var titles = sourceTitles
    for source in sources where source != "manual" && titles[source] == nil {
      titles[source] = await sourceTitle(source)
    }
    sourceTitles = titles
  }

  /// Tek bir kaynak kimliğinin adı.
  private func sourceTitle(_ source: String) async -> String {
    if source.hasPrefix(ReviewPuzzleBuilder.idPrefix) { return "Tekrar bulmacası" }
    guard let puzzle = await content.puzzle(id: source) else { return source }
    if puzzle.isReview { return "Tekrar bulmacası" }
    if puzzle.kind == .daily { return "Günün Bulmacası" }
    if let packId = puzzle.packId, let pack = await content.pack(id: packId) {
      let index = (pack.puzzleIds.firstIndex(of: puzzle.id) ?? 0) + 1
      return "\(pack.title) · Bulmaca \(index)"
    }
    return source
  }

  // MARK: - Adding

  /// Elle ekleme panelini açar ve kelime havuzunu yükler.
  func startAdding() async {
    query = ""
    isAddingWord = true
    if pool.isEmpty {
      pool = await content.wordPool().sorted {
        $0.en.localizedCaseInsensitiveCompare($1.en) == .orderedAscending
      }
    }
  }

  /// Kelimeyi elle deftere ekler.
  func add(_ word: Word) {
    guard !isInNotebook(word) else { return }
    userData.addToNotebook(wordId: word.id, source: "manual")
  }

  // MARK: - Card review

  /// Bugünün tekrarlarını kartlarla başlatır.
  func startReview() {
    reviewQueue = rows(for: .due).shuffled()
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

  // MARK: - Puzzle review

  /// Bugünün kelimelerinden tekrar bulmacası kurup açar (Çengelish+); değilse paywall açılır.
  func startPuzzleReview() async {
    guard entitlements.isPremium else {
      router?.showPaywall()
      return
    }
    let due = rows(for: .due).map(\.word)
    guard !due.isEmpty, !isBuildingPuzzle else { return }
    isBuildingPuzzle = true
    defer { isBuildingPuzzle = false }
    let pool = await content.wordPool()
    let builder = puzzleSeed.map(ReviewPuzzleBuilder.init(seed:)) ?? ReviewPuzzleBuilder()
    let puzzle = await Task.detached(priority: .userInitiated) {
      builder.build(dueWords: due, pool: pool)
    }.value
    guard let puzzle else {
      notice = "Bu kelimelerle bulmaca kurulamadı. Kartla tekrar edebilirsin."
      return
    }
    await content.registerTransient(puzzle)
    router?.showPuzzle(puzzle.id)
  }

  // MARK: - Word actions

  /// Kelimeyi kullanıcının aksanıyla okur.
  func speak(_ word: Word) {
    speak(word, accent: accent)
  }

  /// Kelimeyi verilen aksanla okur.
  func speak(_ word: Word, accent: WordAccent) {
    pronouncer.speak(word.en, language: accent.languageCode)
  }

  /// Kelimeyi öğrenildi olarak işaretler ya da tekrara geri alır ve paneli kapatır.
  func setLearned(_ row: NotebookRow, learned: Bool) {
    userData.setLearned(wordId: row.word.id, learned: learned)
    detail = nil
  }

  /// Kelimeyi defterden çıkarır.
  func remove(_ row: NotebookRow) {
    userData.removeFromNotebook(wordId: row.word.id)
    detail = nil
  }

  // MARK: - Helpers

  /// Arama sonucu sınırı.
  private static let searchLimit = 80

  /// Satır sırası: tekrarı yakın olanlar önce, öğrenilenler en sonda.
  private static func order(_ lhs: NotebookRow, _ rhs: NotebookRow) -> Bool {
    if lhs.item.learned != rhs.item.learned { return !lhs.item.learned }
    if lhs.item.nextReviewAt != rhs.item.nextReviewAt {
      return lhs.item.nextReviewAt < rhs.item.nextReviewAt
    }
    return lhs.word.en < rhs.word.en
  }
}
