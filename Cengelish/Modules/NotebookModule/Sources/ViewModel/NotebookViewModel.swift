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
  /// Çengelish Plus paywall'unu açar.
  func showPaywall()
}

/// Kelime Defterim durumu ve bulmacayla tekrar.
///
/// Defter yalnızca bulmacalarda yanlış yapılan ya da bilinmeyen kelimelerle dolar
/// (`UserDataStoring.finish`); elle ekleme yoktur. Eski `manual` kayıtlar görünmeye devam eder.
///
/// Yönlendiriciyi (koordinatör) güçlü tutar: koordinatör DI'da `factory` olarak kaydedildiği ve
/// sekme görünümü yeniden kurulunca yenisi çözüldüğü için başka kimse onu canlı tutmaz.
@MainActor
final class NotebookViewModel: ObservableObject {

  // MARK: - Properties

  @Published var filter: NotebookFilter = .due
  @Published private(set) var rows: [NotebookRow] = []
  @Published var detail: NotebookRow?
  /// Kullanıcının Çengelish Plus'ı var mı (bulmacayla tekrar kilidi).
  @Published private(set) var isPlus = false
  @Published private(set) var isBuildingPuzzle = false
  /// Tekrar bulmacası kurulamayınca gösterilen açıklama.
  @Published var notice: String?
  @Published private(set) var sourceTitles: [String: String] = [:]
  private let router: any NotebookRouting
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
    router: any NotebookRouting, content: any ContentProviding, userData: any UserDataStoring,
    pronouncer: any Pronouncing, entitlements: any EntitlementProviding,
    puzzleSeed: UInt64? = nil
  ) {
    self.router = router
    self.content = content
    self.userData = userData
    self.pronouncer = pronouncer
    self.entitlements = entitlements
    self.puzzleSeed = puzzleSeed
    self.isPlus = entitlements.isPremium
    userData.changes.merge(with: entitlements.changes)
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

  // MARK: - Loading

  /// Defteri ve kaynak bulmaca adlarını yükler.
  func load() async {
    isPlus = entitlements.isPremium
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

  // MARK: - Puzzle review

  /// Bugünün kelimelerinden tekrar bulmacası kurup açar (Çengelish Plus); değilse paywall açılır.
  ///
  /// Kalan kutular cihazdaki kelime havuzuyla doldurulur. Bulmaca kurulamazsa ya da tekrar
  /// kelimelerinin hiçbiri ızgaraya sığmazsa `notice` ile nedeni gösterilir.
  func startPuzzleReview() async {
    guard entitlements.isPremium else {
      router.showPaywall()
      return
    }
    guard !isBuildingPuzzle else { return }
    let due = rows(for: .due).map(\.word)
    guard !due.isEmpty else {
      notice = Notice.nothingDue
      return
    }
    isBuildingPuzzle = true
    defer { isBuildingPuzzle = false }
    let pool = await content.wordPool()
    let builder = puzzleSeed.map(ReviewPuzzleBuilder.init(seed:)) ?? ReviewPuzzleBuilder()
    let puzzle = await Task.detached(priority: .userInitiated) {
      builder.build(dueWords: due, pool: pool)
    }.value
    guard let puzzle else {
      notice = Notice.notBuilt
      return
    }
    // Tekrar kelimelerinin hiçbiri sığmadıysa (ör. hepsi 3–7 harf dışında) bulmaca açılmaz.
    guard !Set(puzzle.wordIds).isDisjoint(with: due.map(\.id)) else {
      notice = Notice.noFit
      return
    }
    await content.registerTransient(puzzle)
    router.showPuzzle(puzzle.id)
  }

  /// Tekrar bulmacası açıklamaları.
  enum Notice {
    /// Bugün tekrar edilecek kelime yok.
    static let nothingDue = "Bugün tekrar edilecek kelimen yok. Yarın yeniden bak."
    /// Üretici bulmaca kuramadı.
    static let notBuilt = "Bu kelimelerle bulmaca kurulamadı. Biraz sonra yeniden dene."
    /// Tekrar kelimelerinin hiçbiri ızgaraya sığmadı.
    static let noFit =
      "Tekrar kelimelerin bulmacaya sığmadı. Bulmacada 3–7 harfli, tek sözcüklük kelimeler "
      + "kullanılabiliyor."
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

  /// Satır sırası: tekrarı yakın olanlar önce, öğrenilenler en sonda.
  private static func order(_ lhs: NotebookRow, _ rhs: NotebookRow) -> Bool {
    if lhs.item.learned != rhs.item.learned { return !lhs.item.learned }
    if lhs.item.nextReviewAt != rhs.item.nextReviewAt {
      return lhs.item.nextReviewAt < rhs.item.nextReviewAt
    }
    return lhs.word.en < rhs.word.en
  }
}
