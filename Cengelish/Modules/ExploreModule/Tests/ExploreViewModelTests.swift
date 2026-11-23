import ContentKit
import DesignKit
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
    #expect(card.progressText == "3/12")
  }

  @Test(
    "Seviyeler Tümü'de yatay şeritte, kendi bölümünde ızgarada; şerit kullanıcının seviyesine kayar"
  )
  func levelLayoutAndCurrentLevel() async {
    let sut = makeExplore()
    await sut.load()
    #expect(sut.showsLevelCarousel)
    #expect(sut.currentLevelId == nil)
    sut.segment = .levels
    #expect(!sut.showsLevelCarousel)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig(), level: "B1"))
    await sut.load()
    #expect(sut.currentLevelId == "b1")
    #expect(sut.levels.filter(sut.isCurrentLevel).map(\.id) == ["b1"])
  }

  @Test("Seviye kartı rengi seviyeye göre farklıdır; paket rengi türüne göre seçilir")
  func levelColorIdentity() {
    let tints = CEFRLevel.allCases.map { PackStyle.tint(for: $0) }
    #expect(Set(tints.map(\.description)).count == CEFRLevel.allCases.count)
    #expect(
      PackStyle.puzzleCount(PackCard(pack: ContentFixture.pack, solved: 0, isLocked: false))
        == "12 bulmaca")
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

  @Test("Sınav kartı satın alınmadıkça kilitli; Plus hepsini açar")
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

  @Test("Ücretsiz tema açık, Plus'lı tema ve ücretsizi olmayan seviye kilitli")
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
    #expect(tech == "3 bulmaca · Plus")
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
    #expect(PackRules.themeSymbol(for: "bilim") == "atom")
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

  @Test("Aramada seçilen kelimenin paneli açılır")
  func searchSelectsWord() async {
    let sut = makeSearch()
    await sut.load()
    let word = ContentFixture.words[0]
    sut.select(word)
    #expect(sut.selectedWord == word)
    #expect(!sut.isInNotebook(word))
  }

  @Test("Plus yoksa Keşfet'te tanıtım gösterilir ve paywall ürünsüz açılır")
  func explorePlusPromo() async {
    let sut = makeExplore()
    await sut.load()
    #expect(sut.showsPlusPromo)
    sut.openPaywall()
    #expect(paywall.highlights == [nil])
    entitlements.isPremium = true
    await sut.load()
    #expect(!sut.showsPlusPromo)
  }

  // MARK: - Sequential play rule

  @Test("Sıralı oynama: ilk bitmemiş sıradaki, sonrakiler öncekini bekler")
  func sequenceBasic() {
    let access = PackRules.access(
      stars: [3, 2, nil, nil, nil], plusLocked: [false, false, false, false, false])
    #expect(
      access == [
        .finished(stars: 3), .finished(stars: 2), .next,
        .needsPrevious(blocker: 3, needsPlus: false),
        .needsPrevious(blocker: 3, needsPlus: false),
      ])
    #expect(PackRules.sequenceMessage(blocker: 3) == "Önce 3. bulmacayı bitir")
  }

  @Test("Sıralı oynama: hiç bitmemişse ilk bulmaca sıradaki, hepsi bittiyse sıradaki yok")
  func sequenceEdges() {
    #expect(
      PackRules.access(stars: [nil, nil], plusLocked: [false, false])
        == [.next, .needsPrevious(blocker: 1, needsPlus: false)])
    #expect(
      PackRules.access(stars: [1, 0], plusLocked: [true, true])
        == [.finished(stars: 1), .finished(stars: 0)])
    #expect(PackRules.access(stars: [], plusLocked: []).isEmpty)
  }

  @Test("Sıralı oynama: arada bitmiş bulmaca tekrar oynanır, sıra ilk boşluktan devam eder")
  func sequenceGap() {
    let access = PackRules.access(
      stars: [3, nil, 2, nil], plusLocked: [false, false, false, false])
    #expect(
      access == [
        .finished(stars: 3), .next, .finished(stars: 2),
        .needsPrevious(blocker: 2, needsPlus: false),
      ])
  }

  @Test("Sıralı oynama: Plus kilidi üstüne eklenir; sıradaki Plus isterse paywall açılır")
  func sequenceWithPlus() {
    let partly = PackRules.access(stars: [nil, nil, nil], plusLocked: [false, true, true])
    #expect(
      partly == [
        .next, .needsPrevious(blocker: 1, needsPlus: true),
        .needsPrevious(blocker: 1, needsPlus: true),
      ])
    #expect(partly.map(\.showsPlusBadge) == [false, true, true])
    let blocked = PackRules.access(stars: [2, nil, nil], plusLocked: [false, true, true])
    #expect(blocked == [.finished(stars: 2), .needsPlus, .needsPlus])
    #expect(blocked.map(\.isPlayable) == [true, false, false])
  }

  // MARK: - Pack detail

  @Test("Plus'lı tema paketinde sıradaki Plus ister; paywall ürün seçmeden açılır")
  func themePackLock() async {
    let sut = makePack("teknoloji")
    await sut.load()
    #expect(sut.tiles.allSatisfy { $0.access == .needsPlus })
    #expect(sut.primaryTitle == "Kilidi aç")
    #expect(sut.primaryNeedsPlus)
    #expect(sut.hasPlusLockedTiles && sut.plusLockedCount == 3)
    sut.openNext()
    #expect(paywall.highlights == [nil])
    entitlements.isPremium = true
    await sut.load()
    #expect(sut.tiles.first?.access == .next)
    #expect(sut.tiles.dropFirst().allSatisfy { !$0.access.isPlayable })
    #expect(!sut.hasPlusLockedTiles)
  }

  @Test("Sınav paketinde kilitli bulmaca paywall'u paketin ürünüyle açar; satın alınca sırayla")
  func examPackLock() async {
    let sut = makePack("yds")
    await sut.load()
    #expect(sut.summary == "4 bulmaca · 40 kelime · B2–C1 · YDS'de sık çıkan akademik kelimeler")
    #expect(sut.promoTitle == "Paketin kilidini aç")
    if let tile = sut.tiles.first { sut.open(tile) }
    #expect(paywall.highlights == [ProductID.packYDS])
    entitlements.ownedProductIds = [ProductID.packYDS]
    await sut.load()
    #expect(sut.tiles.first?.access == .next)
    #expect(!sut.hasPlusLockedTiles)
    if let tile = sut.tiles.first { sut.open(tile) }
    #expect(puzzle.opened == ["yds_1"])
  }

  @Test("Sıra kilitli bulmacaya dokununca bulmaca açılmaz; kare sallanır ve uyarı çıkar")
  func sequenceNudge() async {
    let sut = makePack("a1")
    await sut.load()
    let locked = sut.tiles[2]
    sut.open(locked)
    #expect(puzzle.opened.isEmpty)
    #expect(sut.nudge?.message == "Önce 1. bulmacayı bitir")
    #expect(sut.nudge?.tileId == locked.id)
    #expect(sut.shakes[locked.id] == 1)
    let serial = sut.nudge?.serial ?? 0
    sut.open(locked)
    #expect(sut.shakes[locked.id] == 2)
    sut.dismissNudge(serial: serial)
    #expect(sut.nudge != nil)
    sut.dismissNudge(serial: serial + 1)
    #expect(sut.nudge == nil)
  }

  @Test("Bitirilen bulmaca bir sonrakinin kilidini açar")
  func finishingUnlocksNext() async {
    let sut = makePack("a1")
    _ = store.finish(
      puzzleId: "a1_1", marks: ["e1": true], wordIdsByEntry: [:], isPremium: false, now: .now)
    await sut.load()
    #expect(sut.tiles[0].access.isFinished)
    #expect(sut.tiles[1].access == .next)
    #expect(sut.tiles[2].access == .needsPrevious(blocker: 2, needsPlus: false))
    #expect(sut.primaryTitle == "Bulmaca 2'yi çöz")
    #expect(sut.solved == 1)
    sut.openNext()
    #expect(puzzle.opened == ["a1_2"])
  }

  @Test("Seviye paketinde ücretsiz bulmacalar sırayla, kalanı ayrıca Plus ister")
  func levelPackLock() async {
    let sut = makePack("a1")
    await sut.load()
    #expect(sut.tiles.first?.access == .next)
    #expect(sut.tiles.prefix(4).allSatisfy { !$0.access.showsPlusBadge })
    #expect(sut.tiles.dropFirst(4).allSatisfy { $0.access.showsPlusBadge })
    #expect(sut.primaryTitle == "Bulmaca 1'i çöz")
    #expect(!sut.primaryNeedsPlus)
    #expect(sut.promoSubtitle == "8 bulmaca daha Çengelish Plus ile açılır.")
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
