import Combine
import ContentKit
import InjectionKit
import PurchaseKit
import PuzzleKit
import RouterKitInterface
import SwiftUI
import Testing
@testable import PaywallModule

@Suite("PaywallViewModel")
@MainActor
struct PaywallViewModelTests {

  @Test("Ürünler yüklenmese de tüm planlar örnek fiyatlarla görünür")
  func fallbackPlans() {
    let sut = makeSUT(store: StoreSpy())
    #expect(sut.plans.map(\.id) == ProductID.all)
    #expect(sut.tab == .plus)
    #expect(sut.visiblePlans.map(\.id) == [ProductID.plusLifetime])
    #expect(sut.ctaTitle == "Plus'ı ömür boyu al")
    #expect(sut.plusPlans.map(\.price) == ["999,99 ₺"])
    #expect(sut.plusPlans.first?.unit == "tek sefer")
    #expect(sut.plusPlans.first?.detail == "Lansmana özel · sonra 1.499,99 ₺")
    #expect(sut.plusPlans.first?.isRecommended == true)
    #expect(sut.plusPlans.first?.badge == "Lansmana özel")
    #expect(sut.packPlans.map(\.title) == ["YDS", "YÖKDİL", "LGS", "IELTS", "TOEFL"])
    #expect(
      sut.packPlans.map(\.price) == Array(repeating: "199,99 ₺", count: 5))
  }

  @Test(
    "Sınav paketiyle açılınca paket sekmesi ve o paket seçili gelir",
    arguments: [
      (ProductID.packYOKDIL, "YÖKDİL Paketini al"),
      (ProductID.packLGS, "LGS Paketini al"),
      (ProductID.packIELTS, "IELTS Paketini al"),
      (ProductID.packTOEFL, "TOEFL Paketini al"),
    ])
  func examPackSelection(productId: String, cta: String) {
    let sut = makeSUT(store: StoreSpy(), selected: productId)
    #expect(sut.tab == .packs)
    #expect(sut.selected == productId)
    #expect(sut.visiblePlans.map(\.id) == ProductID.examPacks)
    #expect(sut.ctaTitle == cta)
    #expect(sut.isPackSelected)
  }

  @Test("Bilinmeyen ürünle açılınca ömür boyu Plus seçilir")
  func unknownProduct() {
    let sut = makeSUT(store: StoreSpy(), selected: "bilinmeyen")
    #expect(sut.tab == .plus)
    #expect(sut.selected == ProductID.plusLifetime)
  }

  @Test("Sekme değişince o sekmedeki son seçim geri gelir")
  func tabSwitchRemembersSelection() {
    let sut = makeSUT(store: StoreSpy())
    sut.selectTab(.packs)
    #expect(sut.selected == ProductID.packYDS)
    sut.select(ProductID.packLGS)
    sut.selectTab(.plus)
    #expect(sut.selected == ProductID.plusLifetime)
    sut.selectTab(.packs)
    #expect(sut.selected == ProductID.packLGS)
    sut.select(ProductID.plusLifetime)
    #expect(sut.tab == .plus)
  }

  @Test("Avantaj listesi seçime göre değişir")
  func benefitsFollowSelection() {
    let sut = makeSUT(store: StoreSpy())
    #expect(sut.benefitsTitle == "Plus ile neler açılır?")
    #expect(sut.benefits.allSatisfy { $0.isIncluded })
    #expect(sut.benefits.map(\.id).prefix(3) == ["plus.exams", "plus.themes", "plus.hints"])
    // Herkese açık olanlar (seviyeler, çevrimdışı) ve uygulamada olmayan avantajlar listelenmez.
    #expect(!sut.benefits.contains { ["plus.all", "plus.offline", "plus.avatar"].contains($0.id) })
    sut.select(ProductID.packTOEFL)
    #expect(sut.benefitsTitle == "TOEFL Paketinde neler var?")
    #expect(sut.benefits.first?.title == "60 TOEFL bulmacası")
    #expect(sut.benefits.contains { $0.title == "259 kelime" })
    #expect(sut.benefits.contains { $0.title == "Tek seferlik, ömür boyu" })
    #expect(sut.benefits.contains { !$0.isIncluded })
    #expect(sut.disclosure.contains("abonelik değildir"))
  }

  @Test("Ömür boyu Plus tek seferlik ödeme olarak açıklanır, otomatik yenileme yazmaz")
  func lifetimeDisclosure() {
    let sut = makeSUT(store: StoreSpy())
    #expect(sut.disclosure.contains("Tek seferlik 999,99 ₺"))
    #expect(sut.disclosure.contains("abonelik değildir"))
    #expect(!sut.disclosure.contains("otomatik yenilenir"))
  }

  @Test("Mağaza fiyatı varsa örnek fiyatın yerine geçer")
  func storePrice() async {
    let store = StoreSpy()
    store.products = [
      StoreProduct(
        id: ProductID.plusLifetime, title: "", displayPrice: "999,99 ₺", price: 999.99,
        currencyCode: "TRY"),
      StoreProduct(id: ProductID.packLGS, title: "", displayPrice: "149,99 ₺"),
    ]
    let sut = makeSUT(store: store)
    await sut.load()
    #expect(sut.plusPlans.first?.price == "999,99 ₺")
    #expect(sut.plusPlans.first?.badge == "Lansmana özel")
    #expect(sut.packPlans.first { $0.id == ProductID.packLGS }?.price == "149,99 ₺")
  }

  @Test("Lansman metni yalnızca Türk lirasında ve normal fiyatın altındayken görünür")
  func launchPrice() {
    func product(_ price: Decimal?, _ currency: String?) -> StoreProduct {
      StoreProduct(
        id: ProductID.plusLifetime, title: "", displayPrice: "", price: price,
        currencyCode: currency)
    }
    #expect(PaywallViewModel.isLaunchPrice(nil))
    #expect(PaywallViewModel.isLaunchPrice(product(999.99, "TRY")))
    #expect(!PaywallViewModel.isLaunchPrice(product(1_499.99, "TRY")))
    #expect(!PaywallViewModel.isLaunchPrice(product(29.99, "USD")))
    #expect(!PaywallViewModel.isLaunchPrice(product(nil, "TRY")))
  }

  @Test("Lansman bitince ömür boyu satırında lansman rozeti olmaz")
  func regularPrice() async {
    let store = StoreSpy()
    store.products = [
      StoreProduct(
        id: ProductID.plusLifetime, title: "", displayPrice: "1.499,99 ₺", price: 1_499.99,
        currencyCode: "TRY")
    ]
    let sut = makeSUT(store: store)
    await sut.load()
    #expect(sut.plusPlans.first?.badge == nil)
    #expect(sut.plusPlans.first?.detail == "Tek ödeme · Tüm bulmacalar ve 5 sınav paketi")
  }

  @Test("Sahip olunan paket işaretlenir ve satın alınamaz")
  func ownedPack() async {
    let store = StoreSpy()
    store.ownedProductIds = [ProductID.packYDS]
    let sut = makeSUT(store: store, selected: ProductID.packYDS)
    #expect(sut.selectedPlan?.isOwned == true)
    #expect(!sut.canPurchase)
    #expect(sut.ctaTitle == "Bu paket sende var")
    await sut.purchase()
    #expect(store.purchased.isEmpty)
  }

  @Test("Paket sayıları içerikten okunur")
  func contentFacts() async {
    let sut = makeSUT(store: StoreSpy(), selected: ProductID.packIELTS, content: ContentStub())
    await sut.load()
    #expect(sut.facts.totalPuzzles == 7)
    #expect(sut.facts.levelSpan == "A1–B2")
    #expect(sut.facts.plusThemeTitles == ["Futbol"])
    #expect(sut.facts.themePuzzles == 1)
    #expect(
      PaywallCatalog.plusBenefits(facts: sut.facts).first { $0.id == "plus.themes" }?.title
        == "1 tema paketi · 1 bulmaca")
    #expect(sut.benefits.first?.title == "3 IELTS bulmacası")
    #expect(
      sut.packPlans.first { $0.id == ProductID.packIELTS }?.detail.hasPrefix("3 bulmaca · 42")
        == true)
  }

  @Test("Bulmaca teması avantajı sayıyla yazılır ve en fazla üç örnek verir")
  func themeBenefit() throws {
    let premium = PuzzleTheme.all.filter(\.isPremium).map(\.name)
    let benefit = try #require(
      PaywallCatalog.plusBenefits(facts: .fallback).first { $0.id == "plus.puzzleThemes" })
    #expect(benefit.title == "\(premium.count) özel bulmaca teması")
    #expect(PaywallCatalog.themeExamples(["A", "B", "C", "D"]) == "A, B, C ve daha fazlası")
    #expect(PaywallCatalog.themeExamples(["A", "B"]) == "A ve B temaları dahil")
  }

  @Test("Çok tema paketi varsa alt satır ilk dördü ve kalan sayısını yazar")
  func themeDetailShortens() {
    #expect(PaywallCatalog.themeDetail(["İş", "Futbol"]) == "İş ve Futbol konularında kelimeler")
    let many = ["İş", "Futbol", "Doğa", "Teknoloji", "Okul", "Spor"]
    #expect(PaywallCatalog.themeDetail(many) == "İş, Futbol, Doğa, Teknoloji ve 2 konu daha")
  }

  @Test("Türkçe liste 've' ile birleşir")
  func turkishList() {
    #expect(PaywallCatalog.list(["A", "B", "C"]) == "A, B ve C")
    #expect(PaywallCatalog.list(["A"]) == "A")
    #expect(PaywallCatalog.list([]).isEmpty)
  }

  @Test("Plus satın alınınca kutlamalı hoş geldin durumu gösterilir, devam edince kapanır")
  func purchaseShowsWelcome() async {
    let nav = NavSpy()
    let store = StoreSpy()
    let sut = makeSUT(store: store, nav: nav)
    #expect(sut.stage == .plans)
    store.premiumAfterPurchase = true
    await sut.purchase()
    #expect(store.purchased == [ProductID.plusLifetime])
    #expect(sut.stage == .welcome)
    #expect(sut.isUnlocked)
    #expect(sut.isCelebrating)
    #expect(sut.heroTitle == "Çengelish Plus'sın!")
    #expect(sut.continueTitle == "Hadi başlayalım")
    #expect(sut.membershipFacts.first?.value == "Çengelish Plus Ömür Boyu")
    #expect(nav.dismissCount == 0)
    sut.close()
    #expect(nav.dismissCount == 1)
  }

  @Test("Sınav paketi satın alınınca paket açıldı durumu gösterilir")
  func purchasePackShowsUnlocked() async {
    let store = StoreSpy()
    let sut = makeSUT(store: store, selected: ProductID.packLGS)
    await sut.purchase()
    #expect(sut.stage == .packUnlocked(ProductID.packLGS))
    #expect(sut.isCelebrating)
    #expect(sut.heroTitle == "LGS Paketi senin!")
    #expect(sut.heroSubtitle.hasPrefix("60 bulmaca ve 291 kelime"))
    #expect(sut.unlockedBenefitsTitle == "Pakette açılanlar")
    #expect(sut.unlockedBenefits.allSatisfy { $0.isIncluded })
    #expect(sut.unlockedBenefits.count == 4)
    #expect(sut.membershipFacts.isEmpty)
  }

  @Test("Plus üyesi paywall'u açınca planlar yerine üyelik durumu görünür")
  func memberSeesUnlockedState() async throws {
    let store = StoreSpy()
    store.isPremium = true
    store.plusPurchaseDate = try #require(
      Calendar(identifier: .gregorian).date(
        from: DateComponents(year: 2026, month: 11, day: 9, hour: 12)))
    let sut = makeSUT(store: store, selected: ProductID.packYDS)
    await sut.load()
    #expect(sut.stage == .member)
    #expect(sut.isUnlocked)
    #expect(!sut.isCelebrating)
    #expect(store.loadCount == 0)
    #expect(sut.heroTitle == "Çengelish Plus'sın!")
    #expect(sut.continueTitle == "Devam et")
    #expect(sut.unlockedBenefitsTitle == "Plus ile açık olanlar")
    #expect(sut.unlockedBenefits == PaywallCatalog.plusBenefits(facts: sut.facts))
    #expect(sut.membershipFacts.map(\.label) == ["Plan", "Satın alma", "Durum"])
    #expect(
      sut.membershipFacts.map(\.value)
        == ["Çengelish Plus Ömür Boyu", "9 Kasım 2026", "Aktif · süresiz"])
  }

  @Test("Satın alma tarihi bilinmiyorsa kartta yalnızca plan ve durum yazar; üye değilse boştur")
  func membershipWithoutDate() {
    let store = StoreSpy()
    store.isPremium = true
    #expect(makeSUT(store: store).membershipFacts.map(\.label) == ["Plan", "Durum"])
    #expect(makeSUT(store: StoreSpy()).membershipFacts.isEmpty)
  }

  @Test("Plus olmayan kullanıcı planları görür; sınav paketleri satın alınabilir")
  func nonMemberCanBuyPacks() {
    let sut = makeSUT(store: StoreSpy(), selected: ProductID.packTOEFL)
    #expect(sut.stage == .plans)
    #expect(!sut.isUnlocked)
    #expect(sut.heroTitle == "Çengelish Plus")
    #expect(sut.canPurchase)
  }

  @Test("Geri yükleme Plus'ı açarsa hoş geldin, yalnızca paket açarsa mesaj gösterilir")
  func restoreOutcomes() async {
    let plusStore = StoreSpy()
    plusStore.premiumAfterRestore = true
    let plus = makeSUT(store: plusStore)
    await plus.restore()
    #expect(plus.stage == .welcome)

    let packStore = StoreSpy()
    packStore.ownedAfterRestore = [ProductID.packYDS]
    let pack = makeSUT(store: packStore)
    await pack.restore()
    #expect(pack.stage == .plans)
    #expect(pack.message == "Sınav paketlerin geri yüklendi.")
    #expect(pack.packPlans.first { $0.id == ProductID.packYDS }?.isOwned == true)

    let empty = makeSUT(store: StoreSpy())
    await empty.restore()
    #expect(empty.stage == .plans)
    #expect(empty.message?.contains("bulunamadı") == true)
  }

  @Test("Plans açıkken Plus başka yoldan gelirse üyelik durumuna geçilir")
  func entitlementChangeShowsMember() {
    let store = StoreSpy()
    let sut = makeSUT(store: store)
    sut.entitlementsChanged()
    #expect(sut.stage == .plans)
    store.isPremium = true
    sut.entitlementsChanged()
    #expect(sut.stage == .member)
  }

  @Test("Uzun Plus listesi kısaltılır, açılır; paket listesi hep tamdır")
  func benefitsCollapse() {
    let sut = makeSUT(store: StoreSpy())
    #expect(sut.canToggleBenefits)
    #expect(sut.visibleBenefits.count == PaywallViewModel.collapsedBenefitCount)
    #expect(sut.hiddenBenefitCount == sut.benefits.count - PaywallViewModel.collapsedBenefitCount)
    sut.toggleBenefits()
    #expect(sut.isBenefitsExpanded)
    #expect(sut.visibleBenefits == sut.benefits)
    #expect(sut.hiddenBenefitCount == 0)
    sut.select(ProductID.packYDS)
    #expect(!sut.canToggleBenefits)
    #expect(sut.visibleBenefits == sut.benefits)
  }

  @Test("Bekleyen satın almada mesaj Çengelish Plus adını kullanır")
  func pendingMessage() async {
    let store = StoreSpy()
    store.outcome = .pending
    let sut = makeSUT(store: store)
    await sut.purchase()
    #expect(sut.message?.contains("Çengelish Plus") == true)
  }

  private func makeSUT(
    store: StoreSpy, nav: NavSpy = NavSpy(), selected: String = ProductID.plusLifetime,
    content: (any ContentProviding)? = nil
  ) -> PaywallViewModel {
    Injector.override(Routing.self, with: nav)
    return PaywallViewModel(
      coordinator: PaywallCoordinator(), entitlements: store, selected: selected, content: content)
  }
}

@MainActor
private final class StoreSpy: EntitlementProviding {
  var changes: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
  var isPremium = false
  var ownedProductIds: Set<String> = []
  var products: [StoreProduct] = []
  var plusPurchaseDate: Date?
  var outcome = PurchaseOutcome.purchased
  var premiumAfterPurchase = false
  var premiumAfterRestore = false
  var ownedAfterRestore: Set<String> = []
  private(set) var purchased: [String] = []
  private(set) var loadCount = 0
  func loadProducts() async { loadCount += 1 }
  func purchase(_ productId: String) async -> PurchaseOutcome {
    purchased.append(productId)
    if outcome == .purchased, premiumAfterPurchase {
      plusPurchaseDate = .now
      isPremium = true
    }
    return outcome
  }
  func restore() async {
    isPremium = isPremium || premiumAfterRestore
    ownedProductIds.formUnion(ownedAfterRestore)
  }
}

@MainActor
private final class NavSpy: Routing {
  var stackCount = 0
  var flowExitContext: (@MainActor () -> Void)?
  private(set) var dismissCount = 0
  func push<V: View>(_ view: V) {}
  func pop() {}
  func pop(count: Int) {}
  func popToRoot() {}
  func popToNavigationRoot() {}
  func clearStack() {}
  func setRoot<V: View>(_ view: V) {}
  func registerDeepLink<V: View>(_ path: DeepLinkPath, @ViewBuilder handler: @escaping () -> V) {}
  func registerDeepLink(_ path: DeepLinkPath, urlHandler: @escaping @MainActor (URL) -> Void) {}
  func handleDeepLink(_ url: URL) -> Bool { false }
  func dismissModal() { dismissCount += 1 }
}

private struct ContentStub: ContentProviding {
  func packs() async -> [Pack] {
    [
      pack("a1", kind: .level, level: .a1, puzzles: 2, words: 10, free: 2),
      pack("b2", kind: .level, level: .b2, puzzles: 1, words: 10, free: 0),
      pack(
        "ielts", kind: .exam, level: .b2, puzzles: 3, words: 42, free: 0,
        productId: ProductID.packIELTS),
      pack("futbol", kind: .theme, level: .a2, puzzles: 1, words: 10, free: 0),
    ]
  }
  func pack(id: String) async -> Pack? { nil }
  func puzzle(id: String) async -> Puzzle? { nil }
  func puzzles(inPack packId: String) async -> [Puzzle] { [] }
  func words(ids: [String]) async -> [Word] { [] }
  func dailyPuzzle(for date: Date) async -> Puzzle? { nil }

  private func pack(
    _ id: String, kind: PackKind, level: CEFRLevel, puzzles: Int, words: Int, free: Int,
    productId: String? = nil
  ) -> Pack {
    Pack(
      id: id, title: id.capitalized, subtitle: "", kind: kind, level: level, order: 0,
      freeCount: free, productId: productId,
      puzzleIds: (0..<puzzles).map { "\(id)_\($0)" }, wordCount: words)
  }
}
