import Combine
import ContentKit
import Foundation
import PurchaseKit
import Testing
import UserDataKit
import WordKit
@testable import NotebookModule

@Suite("NotebookViewModel")
@MainActor
struct NotebookViewModelTests {

  /// Test için görünüm modeli ve bağımlılıkları.
  ///
  /// Yönlendirici gerçek uygulamadaki gibi yalnızca görünüm modeline verilir (koordinatör DI'da
  /// `factory`; başka kimse tutmaz). Testler açılan ekranları `RouteLog` üzerinden okur.
  private func makeSUT(
    plus: Bool = false, pool: [Word] = poolWords
  ) -> (NotebookViewModel, UserDataStore, ContentStub, RouteLog) {
    let store = UserDataStore(inMemory: true)
    let content = ContentStub(pool: pool)
    let log = RouteLog()
    let entitlements = EntitlementStub()
    entitlements.isPremium = plus
    let sut = NotebookViewModel(
      router: RouterSpy(log: log), content: content, userData: store,
      pronouncer: SilentPronouncer(), entitlements: entitlements, puzzleSeed: 11)
    return (sut, store, content, log)
  }

  @Test("Özet sayıları ve bölmeler doğru hesaplanır")
  func countsAndSegments() async {
    let (sut, store, _, _) = makeSUT()
    store.addToNotebook(wordId: "w_house", source: "manual")
    store.addToNotebook(wordId: "w_cat", source: "a1_01")
    store.addToNotebook(wordId: "w_dog", source: "manual")
    store.setLearned(wordId: "w_dog", learned: true)
    store.addToNotebook(wordId: "w_sun", source: "manual")
    store.review(wordId: "w_sun", knew: true)
    await sut.load()
    #expect(sut.totalCount == 4)
    #expect(sut.dueCount == 2)
    #expect(sut.learnedCount == 1)
    #expect(sut.filter == .due)
    #expect(Set(sut.visibleRows.map(\.word.id)) == ["w_house", "w_cat"])
    #expect(sut.title(for: .due) == "Tekrar (2)")
    #expect(sut.title(for: .all) == "Tümü")
    #expect(sut.title(for: .learned) == "Öğrendim")
    sut.filter = .learned
    #expect(sut.visibleRows.map(\.word.id) == ["w_dog"])
    sut.filter = .all
    #expect(sut.visibleRows.count == 4)
    #expect(sut.visibleRows.last?.word.id == "w_dog")
    let sun = sut.rows.first { $0.word.id == "w_sun" }
    #expect(sun.map { sut.dueLabel($0.item) } == "3 gün sonra")
  }

  @Test("Tekrar yoksa ilk açılışta Tümü bölmesi seçilir")
  func initialFilterWithoutDue() async {
    let (sut, store, _, _) = makeSUT()
    store.addToNotebook(wordId: "w_dog", source: "manual")
    store.setLearned(wordId: "w_dog", learned: true)
    await sut.load()
    #expect(sut.filter == .all)
  }

  @Test("İlk görüldüğü yer bulmaca adına çevrilir")
  func firstSeen() async throws {
    let (sut, store, _, _) = makeSUT()
    store.addToNotebook(wordId: "w_cat", source: "a1_01")
    store.addToNotebook(wordId: "w_sun", source: "daily_1")
    store.addToNotebook(wordId: "w_house", source: "manual")
    await sut.load()
    let rows = Dictionary(uniqueKeysWithValues: sut.rows.map { ($0.word.id, $0.item) })
    #expect(try sut.firstSeen(#require(rows["w_cat"])).hasPrefix("A1 · Başlangıç · Bulmaca 1 · "))
    #expect(try sut.firstSeen(#require(rows["w_sun"])).hasPrefix("Günün Bulmacası · "))
    #expect(try sut.firstSeen(#require(rows["w_house"])).hasPrefix("Elle eklendi · "))
  }

  @Test("Öğrendim ve Tekrarda kalsın defteri günceller")
  func learnedToggle() async throws {
    let (sut, store, _, _) = makeSUT()
    store.addToNotebook(wordId: "w_cat", source: "manual")
    await sut.load()
    let row = try #require(sut.rows.first)
    sut.detail = row
    sut.setLearned(row, learned: true)
    #expect(sut.detail == nil)
    #expect(store.notebook.first?.learned == true)
    sut.setLearned(row, learned: false)
    #expect(store.notebook.first?.learned == false)
  }

  @Test("Bulmacadan gelen ve eski elle eklenmiş kelimeler birlikte listelenir")
  func puzzleAndLegacyManualWords() async {
    let (sut, store, _, _) = makeSUT()
    store.addToNotebook(wordId: "w_cat", source: "a1_01")
    store.addToNotebook(wordId: "w_house", source: "manual")
    await sut.load()
    sut.filter = .all
    #expect(Set(sut.visibleRows.map(\.word.id)) == ["w_cat", "w_house"])
  }

  @Test("Plus durumu yüklemede yetkiden okunur")
  func plusState() async {
    let (free, _, _, _) = makeSUT(plus: false)
    await free.load()
    #expect(!free.isPlus)
    let (plus, _, _, _) = makeSUT(plus: true)
    await plus.load()
    #expect(plus.isPlus)
  }

  @Test("Ücretsiz kullanıcı bulmaca tekrarında paywall görür")
  func puzzleReviewNeedsPlus() async {
    let (sut, store, content, log) = makeSUT(plus: false)
    store.addToNotebook(wordId: "w_cat", source: "manual")
    await sut.load()
    await sut.startPuzzleReview()
    #expect(log.paywallCount == 1)
    #expect(log.opened.isEmpty)
    #expect(await content.transient.isEmpty)
  }

  @Test("Çengelish Plus kullanıcısı için tekrar bulmacası kurulur, kaydedilir ve açılır")
  func puzzleReviewOpensPuzzle() async throws {
    let (sut, store, content, log) = makeSUT(plus: true)
    ["w_cat", "w_house", "w_sun"].forEach { store.addToNotebook(wordId: $0, source: "manual") }
    await sut.load()
    await sut.startPuzzleReview()
    let id = try #require(log.opened.first)
    #expect(id.hasPrefix(ReviewPuzzleBuilder.idPrefix))
    let puzzle = try #require(await content.puzzle(id: id))
    #expect(puzzle.isReview)
    #expect(!Set(puzzle.wordIds).isDisjoint(with: ["w_cat", "w_house", "w_sun"]))
    #expect(!sut.isBuildingPuzzle)
    #expect(sut.notice == nil)
  }

  @Test("Görünüm modeli yönlendiriciyi canlı tutar (tekrar bulmacası düğmesi boşa düşmez)")
  func keepsRouterAlive() async {
    weak var weakRouter: RouterSpy?
    let sut: NotebookViewModel
    do {
      let router = RouterSpy(log: RouteLog())
      weakRouter = router
      sut = NotebookViewModel(
        router: router, content: ContentStub(), userData: UserDataStore(inMemory: true),
        pronouncer: SilentPronouncer(), entitlements: EntitlementStub())
    }
    #expect(weakRouter != nil)
    withExtendedLifetime(sut) {}
  }

  @Test("Tek bir tekrar kelimesi havuzla doldurularak bulmacaya girer")
  func singleDueWordFillsFromPool() async throws {
    let (sut, store, content, log) = makeSUT(plus: true)
    store.addToNotebook(wordId: "w_house", source: "a1_01")
    await sut.load()
    await sut.startPuzzleReview()
    let id = try #require(log.opened.first)
    let puzzle = try #require(await content.puzzle(id: id))
    #expect(puzzle.wordIds.contains("w_house"))
    #expect(puzzle.entries.count >= 5)
  }

  @Test("Bulmaca kurulamazsa açık bir Türkçe açıklama gösterilir, ekran açılmaz")
  func puzzleReviewNotBuilt() async {
    let (sut, store, content, log) = makeSUT(plus: true, pool: [])
    ["w_cat", "w_house"].forEach { store.addToNotebook(wordId: $0, source: "manual") }
    await sut.load()
    await sut.startPuzzleReview()
    #expect(sut.notice == NotebookViewModel.Notice.notBuilt)
    #expect(log.opened.isEmpty)
    #expect(await content.transient.isEmpty)
    #expect(!sut.isBuildingPuzzle)
  }

  @Test("Tekrar kelimelerinin hiçbiri sığmazsa ilgisiz bulmaca açılmaz")
  func puzzleReviewNoFittingWord() async {
    let (sut, store, content, log) = makeSUT(plus: true)
    store.addToNotebook(wordId: "w_blackboard", source: "manual")
    await sut.load()
    await sut.startPuzzleReview()
    #expect(sut.notice == NotebookViewModel.Notice.noFit)
    #expect(log.opened.isEmpty)
    #expect(await content.transient.isEmpty)
  }
}

// MARK: - Fakes

/// Küçük ama bulmaca kurmaya yeten kelime havuzu.
private let poolWords: [Word] = {
  let entries: [(String, String)] = [
    ("house", "ev"), ("cat", "kedi"), ("dog", "köpek"), ("sun", "güneş"), ("tea", "çay"),
    ("ant", "karınca"), ("art", "sanat"), ("arm", "kol"), ("ear", "kulak"), ("eye", "göz"),
    ("egg", "yumurta"), ("ice", "buz"), ("ink", "mürekkep"), ("oil", "yağ"), ("one", "bir"),
    ("ten", "on"), ("toe", "ayak parmağı"), ("top", "tepe"), ("tree", "ağaç"), ("road", "yol"),
    ("rain", "yağmur"), ("rice", "pirinç"), ("ring", "yüzük"), ("rose", "gül"), ("salt", "tuz"),
    ("seat", "koltuk"), ("star", "yıldız"), ("tear", "gözyaşı"), ("time", "zaman"),
    ("note", "not"), ("nose", "burun"), ("name", "ad"), ("near", "yakın"), ("east", "doğu"),
    ("area", "alan"), ("idea", "fikir"), ("iron", "demir"), ("lion", "aslan"), ("line", "çizgi"),
    ("late", "geç"), ("lake", "göl"), ("meat", "et"), ("milk", "süt"), ("moon", "ay"),
    ("door", "kapı"), ("desk", "sıra"), ("cake", "kek"), ("care", "özen"), ("coat", "palto"),
    ("cold", "soğuk"), ("table", "masa"), ("chair", "sandalye"), ("water", "su"),
    ("apple", "elma"), ("bread", "ekmek"), ("green", "yeşil"), ("horse", "at"),
    ("lemon", "limon"), ("money", "para"), ("night", "gece"), ("ocean", "okyanus"),
    ("paper", "kâğıt"), ("river", "nehir"), ("sheep", "koyun"), ("stone", "taş"),
    ("tiger", "kaplan"), ("train", "tren"), ("onion", "soğan"), ("earth", "dünya"),
    ("heart", "kalp"), ("start", "başla"), ("smile", "gülümse"), ("store", "mağaza"),
    ("teeth", "dişler"), ("sister", "kız kardeş"), ("tomato", "domates"), ("orange", "portakal"),
    ("garden", "bahçe"), ("winter", "kış"), ("summer", "yaz"), ("silver", "gümüş"),
    ("letter", "mektup"), ("street", "sokak"), ("dinner", "akşam yemeği"), ("listen", "dinle"),
    ("animal", "hayvan"), ("island", "ada"), ("rabbit", "tavşan"), ("carrot", "havuç"),
    ("teacher", "öğretmen"), ("morning", "sabah"), ("kitchen", "mutfak"),
    ("brother", "erkek kardeş"), ("blackboard", "kara tahta"),
    ("chicken", "tavuk"), ("station", "istasyon"), ("rainbow", "gökkuşağı"), ("student", "öğrenci"),
  ]
  return entries.map { en, tr in
    Word(
      id: "w_\(en)", en: en, level: .a1, pos: "noun", clue: tr.capitalized, meaning: tr,
      ipa: "/\(en)/", example: "This is a \(en).")
  }
}()

/// Bellekte içerik; geçici bulmacaları kaydeder.
private actor ContentStub: ContentProviding {
  private(set) var transient: [String: Puzzle] = [:]
  private let pool: [Word]
  private let pack = Pack(
    id: "a1", title: "A1 · Başlangıç", subtitle: "", kind: .level, level: .a1, order: 0,
    freeCount: 1, productId: nil, puzzleIds: ["a1_01"], wordCount: 0)

  init(pool: [Word] = poolWords) {
    self.pool = pool
  }

  func packs() async -> [Pack] { [pack] }
  func pack(id: String) async -> Pack? { id == pack.id ? pack : nil }
  func puzzle(id: String) async -> Puzzle? {
    if let puzzle = transient[id] { return puzzle }
    switch id {
    case "a1_01":
      return Puzzle(
        id: id, packId: "a1", kind: .pack, level: .a1, width: 7, height: 7, entries: [])
    case "daily_1":
      return Puzzle(
        id: id, packId: nil, kind: .daily, level: .a1, width: 7, height: 7, entries: [])
    default:
      return nil
    }
  }
  func puzzles(inPack packId: String) async -> [Puzzle] { [] }
  func words(ids: [String]) async -> [Word] {
    ids.compactMap { id in poolWords.first { $0.id == id } }
  }
  func dailyPuzzle(for date: Date) async -> Puzzle? { nil }
  func wordPool() async -> [Word] { pool }
  func registerTransient(_ puzzle: Puzzle, words: [Word]) async { transient[puzzle.id] = puzzle }
}

/// Açılan ekranların kaydı (yönlendiriciden ayrı; yönlendiriciyi test tutmaz).
@MainActor
private final class RouteLog {
  var opened: [String] = []
  var paywallCount = 0
}

/// Açılan ekranları `RouteLog`'a yazar.
@MainActor
private final class RouterSpy: NotebookRouting {
  private let log: RouteLog
  init(log: RouteLog) { self.log = log }
  func showPuzzle(_ puzzleId: String) { log.opened.append(puzzleId) }
  func showPaywall() { log.paywallCount += 1 }
}

/// Ayarlanabilir yetki servisi.
@MainActor
private final class EntitlementStub: EntitlementProviding {
  var changes: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
  var isPremium = false
  var ownedProductIds: Set<String> = []
  var products: [StoreProduct] = []
  func loadProducts() async {}
  func purchase(_ productId: String) async -> PurchaseOutcome { .cancelled }
  func restore() async {}
}

@MainActor
private final class SilentPronouncer: Pronouncing {
  func speak(_ text: String, language: String) {}
}
