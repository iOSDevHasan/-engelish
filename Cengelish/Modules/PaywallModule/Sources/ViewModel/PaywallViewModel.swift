import Combine
import ContentKit
import Foundation
import PurchaseKit

/// Paywall durumu: sekmeler, planlar, seçime göre değişen avantajlar, satın alma ve Plus
/// üyeleri için açılmış (üyelik) durum.
@MainActor
final class PaywallViewModel: ObservableObject {

  // MARK: - Properties

  /// Gösterilen aşama: planlar ya da üyelik / satın alma sonrası açılmış durum.
  @Published private(set) var stage: PaywallStage
  /// Çengelish Plus'ın satın alındığı tarih; bilinmiyorsa nil.
  @Published private(set) var plusPurchaseDate: Date?
  /// Uzun Plus avantaj listesinin tamamı açık mı.
  @Published private(set) var isBenefitsExpanded = false
  /// Açık sekme.
  @Published private(set) var tab: PaywallTab
  /// Seçili ürün kimliği.
  @Published private(set) var selected: String
  /// Çengelish Plus satırı (ömür boyu, tek seferlik).
  @Published private(set) var plusPlans: [PlanOption] = []
  /// Tek seferlik sınav paketi satırları (YDS, YÖKDİL, LGS, IELTS, TOEFL).
  @Published private(set) var packPlans: [PlanOption] = []
  /// Paket sayıları (içerik okununca güncellenir).
  @Published private(set) var facts = ContentFacts.fallback
  /// Satın alma ya da geri yükleme sürüyor mu.
  @Published private(set) var isWorking = false
  /// Uyarıda gösterilecek mesaj.
  @Published var message: String?

  /// Sekme değişince geri dönülecek son paket seçimi.
  private var lastPackId = ProductID.packYDS
  private let coordinator: PaywallCoordinator
  private let entitlements: any EntitlementProviding
  private let content: (any ContentProviding)?
  private var cancellables: Set<AnyCancellable> = []

  /// Plus listesi kısaltıldığında görünen avantaj sayısı.
  static let collapsedBenefitCount = 6

  // MARK: - Init

  /// Seçili ürünle kurar; sınav paketiyse "Sınav paketleri" sekmesi açılır.
  init(
    coordinator: PaywallCoordinator, entitlements: any EntitlementProviding, selected: String,
    content: (any ContentProviding)? = nil
  ) {
    self.coordinator = coordinator
    self.entitlements = entitlements
    self.content = content
    stage = entitlements.isPremium ? .member : .plans
    plusPurchaseDate = entitlements.plusPurchaseDate
    if ProductID.examPacks.contains(selected) {
      tab = .packs
      lastPackId = selected
      self.selected = selected
    } else {
      tab = .plus
      self.selected = ProductID.plusLifetime
    }
    rebuildPlans()
    entitlements.changes
      .sink { [weak self] in Task { @MainActor in self?.entitlementsChanged() } }
      .store(in: &cancellables)
  }

  // MARK: - Derived

  /// Seçili sekmenin satırları.
  var visiblePlans: [PlanOption] { tab == .plus ? plusPlans : packPlans }

  /// Tüm satırlar (önce Plus, sonra sınav paketleri).
  var plans: [PlanOption] { plusPlans + packPlans }

  /// Seçili satır.
  var selectedPlan: PlanOption? { plans.first { $0.id == selected } }

  /// Seçim bir sınav paketi mi.
  var isPackSelected: Bool { ProductID.examPacks.contains(selected) }

  /// Seçime göre avantaj listesi.
  var benefits: [Benefit] {
    isPackSelected
      ? PaywallCatalog.packBenefits(for: selected, facts: facts)
      : PaywallCatalog.plusBenefits(facts: facts)
  }

  /// Avantaj kartında görünen satırlar; uzun Plus listesi açılana kadar kısaltılır.
  var visibleBenefits: [Benefit] {
    let all = benefits
    guard canToggleBenefits, !isBenefitsExpanded else { return all }
    return Array(all.prefix(Self.collapsedBenefitCount))
  }

  /// Kısaltılmış listede gizli kalan avantaj sayısı.
  var hiddenBenefitCount: Int { benefits.count - visibleBenefits.count }

  /// Avantaj listesi açılıp kapanabilir mi (yalnızca uzun Plus listesi).
  var canToggleBenefits: Bool {
    !isPackSelected && benefits.count > Self.collapsedBenefitCount + 1
  }

  /// Avantaj kartının başlığı.
  var benefitsTitle: String {
    guard let exam = ProductID.examTitle(for: selected) else { return "Plus ile neler açılır?" }
    return "\(exam) Paketinde neler var?"
  }

  /// Satın alma butonundaki metin.
  var ctaTitle: String {
    if selectedPlan?.isOwned == true {
      return isPackSelected ? "Bu paket sende var" : "Plus zaten aktif"
    }
    guard isPackSelected else { return "Plus'ı ömür boyu al" }
    return "\(ProductID.examTitle(for: selected) ?? "Sınav") Paketini al"
  }

  /// Satın alma butonu kullanılabilir mi.
  var canPurchase: Bool { !isWorking && selectedPlan?.isOwned != true }

  /// Butonun altındaki yasal açıklama (tüm ürünler tek seferlik; abonelik yok).
  var disclosure: String {
    "Tek seferlik \(fullPrice(for: selected)) ödeme; abonelik değildir, yenilenmez. Satın alma "
      + "Apple Kimliğine bağlıdır ve diğer cihazlarına geri yüklenebilir."
  }

  // MARK: - Unlocked

  /// Planlar yerine açılmış (üyelik ya da yeni satın alma) durum mu gösteriliyor.
  var isUnlocked: Bool { stage != .plans }

  /// Az önce satın alma ya da geri yükleme yapıldı mı (kutlama animasyonu).
  var isCelebrating: Bool { stage.isCelebration }

  /// Kahraman alanının başlığı.
  var heroTitle: String {
    switch stage {
    case .plans: ProductID.plusName
    case .member, .welcome: "\(ProductID.plusName)'sın!"
    case .packUnlocked(let productId):
      "\(ProductID.examTitle(for: productId) ?? "Sınav") Paketi senin!"
    }
  }

  /// Kahraman alanının tek satırlık alt metni.
  var heroSubtitle: String {
    switch stage {
    case .plans:
      return "\(ProductID.examPacks.count) sınav paketi, tema paketleri ve sınırsız ipucu."
    case .member:
      return "Tüm Plus ayrıcalıkların açık. İyi bulmacalar!"
    case .welcome:
      return "Hoş geldin! Sınav ve tema paketleri, sınırsız ipucu artık senin."
    case .packUnlocked(let productId):
      let info = facts.exam(productId)
      return "\(info.puzzleCount) bulmaca ve \(info.wordCount) kelime ömür boyu kilitsiz."
    }
  }

  /// Üyelik kartındaki plan, satın alma tarihi ve durum bilgisi.
  var membershipFacts: [MembershipFact] {
    guard stage == .member || stage == .welcome else { return [] }
    var facts = [
      MembershipFact(
        id: "plan", systemImage: "crown.fill", label: "Plan",
        value: ProductID.displayTitle(for: ProductID.plusLifetime) ?? ProductID.plusName)
    ]
    if let plusPurchaseDate {
      facts.append(
        MembershipFact(
          id: "purchase", systemImage: "calendar", label: "Satın alma",
          value: Self.longDate(plusPurchaseDate)))
    }
    facts.append(
      MembershipFact(
        id: "status", systemImage: "checkmark.seal.fill", label: "Durum",
        value: "Aktif · süresiz"))
    return facts
  }

  /// Açılmış durumda listelenen kazanımların başlığı.
  var unlockedBenefitsTitle: String {
    if case .packUnlocked = stage { return "Pakette açılanlar" }
    return "Plus ile açık olanlar"
  }

  /// Açılmış durumda listelenen kazanımlar (yalnızca dahil olanlar).
  var unlockedBenefits: [Benefit] {
    switch stage {
    case .packUnlocked(let productId):
      PaywallCatalog.packBenefits(for: productId, facts: facts).filter(\.isIncluded)
    case .plans, .member, .welcome:
      PaywallCatalog.plusBenefits(facts: facts)
    }
  }

  /// Açılmış durumdaki ana butonun metni.
  var continueTitle: String {
    switch stage {
    case .welcome: "Hadi başlayalım"
    case .plans, .member, .packUnlocked: "Devam et"
    }
  }

  // MARK: - Intents

  /// Ürünleri, Plus bilgisini ve paket sayılarını yükler.
  func load() async {
    if stage == .plans { await entitlements.loadProducts() }
    if let packs = await content?.packs(), let loaded = ContentFacts(packs: packs) {
      facts = loaded
    }
    plusPurchaseDate = entitlements.plusPurchaseDate
    rebuildPlans()
  }

  /// Uzun Plus avantaj listesini açar ya da kısaltır.
  func toggleBenefits() {
    guard canToggleBenefits else { return }
    isBenefitsExpanded.toggle()
  }

  /// Yetkiler değişince (başka cihazdan alım, onaylanan bekleyen alım) durumu yeniler; satın
  /// alma sürerken sonucu `purchase()` belirler.
  func entitlementsChanged() {
    plusPurchaseDate = entitlements.plusPurchaseDate
    guard !isWorking else { return }
    if stage == .plans, entitlements.isPremium {
      stage = .member
    }
    rebuildPlans()
  }

  /// Sekmeyi değiştirir; o sekmedeki son seçim geri gelir.
  func selectTab(_ newTab: PaywallTab) {
    guard newTab != tab else { return }
    tab = newTab
    selected = newTab == .plus ? ProductID.plusLifetime : lastPackId
  }

  /// Ürünü seçer ve gerekirse sekmesini açar.
  func select(_ productId: String) {
    guard ProductID.all.contains(productId) else { return }
    if ProductID.examPacks.contains(productId) {
      lastPackId = productId
      tab = .packs
    } else {
      tab = .plus
    }
    selected = productId
  }

  /// Seçili ürünü satın alır.
  func purchase() async {
    guard canPurchase else { return }
    isWorking = true
    defer { isWorking = false }
    switch await entitlements.purchase(selected) {
    case .purchased:
      plusPurchaseDate = entitlements.plusPurchaseDate
      rebuildPlans()
      stage = isPackSelected ? .packUnlocked(selected) : .welcome
    case .pending:
      let item = isPackSelected ? "paket" : ProductID.plusName
      message = "Satın alma onay bekliyor. Onaylanınca \(item) açılacak."
    case .cancelled:
      break
    case .failed(let reason):
      message = reason
    }
  }

  /// Satın alımları geri yükler.
  func restore() async {
    isWorking = true
    defer { isWorking = false }
    await entitlements.restore()
    plusPurchaseDate = entitlements.plusPurchaseDate
    rebuildPlans()
    if entitlements.isPremium {
      stage = .welcome
    } else if !entitlements.ownedProductIds.isEmpty {
      message = "Sınav paketlerin geri yüklendi."
    } else {
      message = "Bu Apple Kimliğinde geri yüklenecek satın alma bulunamadı."
    }
  }

  /// Ekranı kapatır.
  func close() {
    coordinator.close()
  }

  /// Uzun Türkçe tarih ("9 Kasım 2027").
  static func longDate(_ date: Date) -> String {
    date.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "tr_TR")))
  }

  // MARK: - Fallback prices

  /// StoreKit ürünleri yüklenemediğinde gösterilen örnek fiyatlar.
  static func fallbackPrice(for productId: String) -> String {
    productId == ProductID.plusLifetime ? "999,99 ₺" : "199,99 ₺"
  }

  /// Lansman bitince ömür boyu Plus'ın Türkiye fiyatı (App Store Connect'te zamanlanan artış).
  static let regularLifetimePrice: Decimal = 1_499.99
  /// Lansman sonrası fiyatın ekrandaki hali.
  static let regularLifetimePriceText = "1.499,99 ₺"

  /// Ömür boyu Plus lansman fiyatında mı: mağaza fiyatı Türk lirası ve normal fiyatın altında.
  /// Mağaza fiyatı yüklenmediyse örnek fiyat (999,99 ₺) lansman fiyatı sayılır; başka para
  /// biriminde lansman metni gösterilmez.
  static func isLaunchPrice(_ product: StoreProduct?) -> Bool {
    guard let product else { return true }
    guard product.currencyCode == "TRY", let price = product.price else { return false }
    return price < regularLifetimePrice
  }

  // MARK: - Private

  /// Mağaza ürünleri; yüklenmediyse boş.
  private var storeProducts: [String: StoreProduct] {
    Dictionary(entitlements.products.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
  }

  /// Ürünün tam fiyatı (mağazadan, yoksa örnek).
  private func fullPrice(for productId: String) -> String {
    storeProducts[productId]?.displayPrice ?? Self.fallbackPrice(for: productId)
  }

  /// Mağaza ürünlerinden plan satırlarını üretir; yüklenmediyse örnek fiyatları gösterir.
  private func rebuildPlans() {
    let products = storeProducts
    let isLaunch = Self.isLaunchPrice(products[ProductID.plusLifetime])
    let scope = "Tüm bulmacalar ve \(ProductID.examPacks.count) sınav paketi"
    plusPlans = [
      PlanOption(
        id: ProductID.plusLifetime, title: "Ömür boyu",
        detail: isLaunch
          ? "Lansmana özel · sonra \(Self.regularLifetimePriceText)" : "Tek ödeme · \(scope)",
        price: fullPrice(for: ProductID.plusLifetime), unit: "tek sefer",
        badge: isLaunch ? "Lansmana özel" : nil, isRecommended: true,
        isOwned: entitlements.isPremium)
    ]
    packPlans = ProductID.examPacks.map { productId in
      let info = facts.exam(productId)
      let exam = ProductID.examTitle(for: productId) ?? ""
      return PlanOption(
        id: productId, title: exam,
        detail:
          "\(info.puzzleCount) bulmaca · \(info.wordCount) kelime · "
          + PaywallCatalog.levelRange(for: productId),
        price: fullPrice(for: productId), unit: "tek sefer", badge: nil, isRecommended: false,
        isOwned: entitlements.canAccess(productId: productId))
    }
  }
}
