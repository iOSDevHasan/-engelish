import ContentKit
import InjectionKit
import PaywallModuleInterface
import PurchaseKit
import PuzzleModuleInterface
import RouterKitInterface
import Testing
import UserDataKit

@testable import ExploreModule

@Suite("ExploreModule", .serialized)
@MainActor
struct ExploreViewModelTests {
  private let paywall = PaywallSpy()
  private let puzzle = PuzzleSpy()
  private let nav = NavSpy()
  private let entitlements = EntitlementStub()
  private let store = UserDataStore(inMemory: true)

  init() {
    Injector.override(Routing.self, with: nav)
    Injector.override(PaywallModuleInterface.self, with: paywall)
    Injector.override(PuzzleModuleInterface.self, with: puzzle)
  }

  private func makeExplore() -> ExploreViewModel {
    ExploreViewModel(
      coordinator: ExploreCoordinator(), content: ContentStub(), userData: store,
      entitlements: entitlements)
  }

  private func makeSearch() -> SearchViewModel {
    SearchViewModel(
      coordinator: ExploreCoordinator(), content: ContentStub(), userData: store,
      entitlements: entitlements, pronouncer: SilentPronouncer())
  }

  private func makePack(_ id: String) -> PackViewModel {
    PackViewModel(
      packId: id, coordinator: ExploreCoordinator(), content: ContentStub(), userData: store,
      entitlements: entitlements)
  }

  // MARK: - Explore

  @Test("Paket kartının ilerleme oranı çözülen / toplam bulmacadır")
  func progressRatio() {
    let card = PackCard(pack: ContentFixture.pack, solved: 3, isLocked: false)
    #expect(card.progress == 0.25)
    #expect(card.percent == 25)
  }

  @Test("Paketler türlerine ayrılır, bulmacası olmayan paket gizlenir")
  func groupsAndHidesEmpty() async {
    let sut = makeExplore()
    await sut.load()
    #expect(sut.levels.map(\.id) == ["a1", "b1"])
    #expect(sut.exams.map(\.id) == ["yds", "lgs"])
    #expect(sut.themes.count == 7)
  }

  @Test("Bölüm seçimi gösterilen bölümleri süzer")
  func segmentFiltering() async {
    let sut = makeExplore()
    await sut.load()
    #expect(sut.showsLevels && sut.showsExams && sut.showsThemes)
    #expect(sut.visibleThemes.count == ExploreViewModel.themePreviewCount)
    sut.segment = .levels
    #expect(sut.showsLevels && !sut.showsExams && !sut.showsThemes)
    sut.segment = .exams
    #expect(!sut.showsLevels && sut.showsExams && !sut.showsThemes)
    sut.segment = .themes
    #expect(!sut.showsLevels && !sut.showsExams && sut.showsThemes)
    #expect(sut.visibleThemes.count == 7)
  }

  @Test("Sınav kartı satın alınmadıkça kilitli; premium hepsini açar")
  func examLocks() async {
    let sut = makeExplore()
    await sut.load()
    #expect(sut.exams.allSatisfy { $0.isLocked })
    entitlements.ownedProductIds = [ProductID.packYDS]
    await sut.load()
    #expect(sut.exams.first { $0.id == "yds" }?.isLocked == false)
    #expect(sut.exams.first { $0.id == "lgs" }?.isLocked == true)
    entitlements.isPremium = true
    await sut.load()
    #expect(sut.exams.allSatisfy { !$0.isLocked })
  }

  @Test("Ücretsiz tema açık, premium tema ve ücretsizi olmayan seviye kilitli")
  func themeAndLevelLocks() async {
    let sut = makeExplore()
    await sut.load()
    #expect(sut.themes.first { $0.id == "mutfak" }?.isLocked == false)
    #expect(sut.themes.first { $0.id == "teknoloji" }?.isLocked == true)
    #expect(sut.levels.first { $0.id == "a1" }?.isLocked == false)
    #expect(sut.levels.first { $0.id == "b1" }?.isLocked == true)
    let mutfak = sut.themes.first { $0.id == "mutfak" }.map { ThemeText.detail($0) }
    #expect(mutfak == "3 bulmaca · Ücretsiz")
    let tech = sut.themes.first { $0.id == "teknoloji" }.map { ThemeText.spokenDetail($0) }
    #expect(tech == "3 bulmaca · Premium")
  }

  @Test("Seviye aralığı bulmacalardan türetilir, gerekirse bilinen aralığa düşer")
  func levelRanges() async {
    let sut = makeExplore()
    await sut.load()
    #expect(sut.exams.first { $0.id == "yds" }?.levelRange == "B2–C1")
    #expect(sut.exams.first { $0.id == "lgs" }?.levelRange == "A2–B1")
    #expect(sut.levels.first { $0.id == "a1" }?.levelRange == "A1")
  }

  @Test("Tema simgesi kimliğe göre seçilir, bilinmeyen temada genel simge")
  func themeSymbols() {
    #expect(PackRules.themeSymbol(for: "mutfak") == "fork.knife")
    #expect(PackRules.themeSymbol(for: "uzay") == "square.grid.2x2.fill")
  }

  // MARK: - Search

  @Test("Arama paket başlığı/açıklaması ve kelimenin İngilizcesi/anlamıyla eşleşir")
  func search() async {
    let sut = makeSearch()
    await sut.load()
    #expect(sut.isQueryEmpty && sut.packResults.isEmpty && sut.wordResults.isEmpty)

    sut.query = "is"
    #expect(sut.packResults.map(\.id).contains("is"))
    #expect(sut.wordResults.map(\.id).contains("w_job"))

    sut.query = "house"
    #expect(sut.wordResults.map(\.id) == ["w_house", "w_whouse"])

    sut.query = "COCUK"
    #expect(sut.wordResults.map(\.id) == ["w_child"])

    sut.query = "tarif"
    #expect(sut.packResults.map(\.id) == ["mutfak"])

    sut.query = "zzz"
    #expect(sut.hasNoResults)
  }

  @Test("Aramadan kelime deftere eklenir")
  func searchAddsToNotebook() async {
    let sut = makeSearch()
    await sut.load()
    let word = ContentFixture.words[0]
    sut.select(word)
    #expect(sut.selectedWord == word)
    sut.addToNotebook(word)
    #expect(sut.isInNotebook(word))
    #expect(sut.selectedWord == nil)
  }

  // MARK: - Pack detail

  @Test("Premium tema paketinde bulmacalar kilitli; paywall ürün seçmeden açılır")
  func themePackLock() async {
    let sut = makePack("teknoloji")
    await sut.load()
    #expect(sut.tiles.allSatisfy { $0.state == .locked })
    #expect(sut.primaryTitle == "Kilidi aç")
    if let tile = sut.tiles.first { sut.open(tile) }
    #expect(paywall.highlights == [nil])
    entitlements.isPremium = true
    await sut.load()
    #expect(sut.tiles.first?.state == .current)
  }

  @Test("Sınav paketinde kilitli bulmaca paywall'u paketin ürünüyle açar")
  func examPackLock() async {
    let sut = makePack("yds")
    await sut.load()
    #expect(sut.summary == "4 bulmaca · 40 kelime · B2–C1 · YDS'de sık çıkan akademik kelimeler")
    if let tile = sut.tiles.first { sut.open(tile) }
    #expect(paywall.highlights == [ProductID.packYDS])
    entitlements.ownedProductIds = [ProductID.packYDS]
    await sut.load()
    #expect(sut.tiles.allSatisfy { $0.state != .locked })
    if let tile = sut.tiles.first { sut.open(tile) }
    #expect(puzzle.opened == ["yds_1"])
  }

  @Test("Seviye paketinde ücretsiz bulmacalar açık, kalanı premium ister")
  func levelPackLock() async {
    let sut = makePack("a1")
    await sut.load()
    #expect(sut.tiles.prefix(4).allSatisfy { $0.state != .locked })
    #expect(sut.tiles.dropFirst(4).allSatisfy { $0.state == .locked })
    #expect(sut.primaryTitle == "Bulmaca 1'i çöz")
  }

  // MARK: - Text

  @Test("Türkçe belirtme hâli eki sayının okunuşuna uyar")
  func accusative() {
    #expect(TurkishText.accusative(15) == "15'i")
    #expect(TurkishText.accusative(2) == "2'yi")
    #expect(TurkishText.accusative(3) == "3'ü")
    #expect(TurkishText.accusative(6) == "6'yı")
    #expect(TurkishText.accusative(9) == "9'u")
    #expect(TurkishText.accusative(10) == "10'u")
    #expect(TurkishText.accusative(40) == "40'ı")
    #expect(TurkishText.accusative(100) == "100'ü")
    #expect(TurkishText.number(1200) == "1.200")
  }
}
