import Foundation
import PurchaseKit

/// Paywall'daki bir plan satırı.
struct PlanOption: Identifiable, Equatable {
  let id: String
  let title: String
  let detail: String
  let price: String
  let unit: String?
  let badge: String?
}

/// Paywall durumu: planlar, seçim ve satın alma.
@MainActor
final class PaywallViewModel: ObservableObject {

  // MARK: - Properties

  @Published var selected: String
  @Published private(set) var plans: [PlanOption] = []
  @Published private(set) var isWorking = false
  @Published var message: String?

  /// Çengelish+ avantajları.
  let benefits = [
    "Tüm seviyeler ve 500+ bulmaca",
    "YDS, YÖKDİL, LGS, IELTS ve TOEFL paketleri",
    "Sınırsız ipucu ve seri dondurma",
    "Tüm bulmaca temaları ve özel avatar parçaları",
    "Tekrar bulmacası, çevrimdışı oyun",
  ]
  /// Tek seferlik seçenekte gösterilen sınav paketi (açılışta seçili paket, yoksa YDS).
  let packProductId: String
  private let coordinator: PaywallCoordinator
  private let entitlements: any EntitlementProviding

  // MARK: - Init

  init(coordinator: PaywallCoordinator, entitlements: any EntitlementProviding, selected: String) {
    self.coordinator = coordinator
    self.entitlements = entitlements
    self.selected = selected
    packProductId = ProductID.examPacks.contains(selected) ? selected : ProductID.packYDS
    rebuildPlans()
  }

  // MARK: - Intents

  /// Ürünleri yükler.
  func load() async {
    await entitlements.loadProducts()
    rebuildPlans()
  }

  /// Seçili ürünü satın alır.
  func purchase() async {
    isWorking = true
    defer { isWorking = false }
    switch await entitlements.purchase(selected) {
    case .purchased:
      coordinator.close()
    case .pending:
      message = "Satın alma onay bekliyor. Onaylanınca Çengelish+ açılacak."
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
    if entitlements.isPremium || !entitlements.ownedProductIds.isEmpty {
      coordinator.close()
    } else {
      message = "Bu Apple Kimliğinde geri yüklenecek satın alma bulunamadı."
    }
  }

  /// Ekranı kapatır.
  func close() {
    coordinator.close()
  }

  /// Seçili planın butonundaki metin.
  var ctaTitle: String {
    selected == ProductID.plusYearly ? "7 gün ücretsiz dene" : "Devam et"
  }

  // MARK: - Fallback prices

  /// StoreKit ürünleri yüklenemediğinde gösterilen örnek fiyatlar.
  static func fallbackPrice(for productId: String) -> String {
    switch productId {
    case ProductID.plusMonthly: "74,99 ₺"
    case ProductID.plusYearly: "449,99 ₺"
    case ProductID.packLGS: "129,99 ₺"
    default: "199,99 ₺"
    }
  }

  // MARK: - Private

  /// Mağaza ürünlerinden plan satırlarını üretir; yüklenmediyse örnek fiyatları gösterir.
  private func rebuildPlans() {
    let products = Dictionary(uniqueKeysWithValues: entitlements.products.map { ($0.id, $0) })
    let yearly = products[ProductID.plusYearly]
    let monthly = products[ProductID.plusMonthly]
    let pack = products[packProductId]
    let examTitle = ProductID.examTitle(for: packProductId) ?? "YDS"
    let yearlyPrice = yearly?.displayPrice ?? Self.fallbackPrice(for: ProductID.plusYearly)
    plans = [
      PlanOption(
        id: ProductID.plusYearly, title: "Yıllık",
        detail:
          "\(yearly?.trialText ?? "7 gün ücretsiz"), sonra \(yearlyPrice)/yıl",
        price: yearly?.monthlyEquivalent ?? "37,50 ₺", unit: "/ay", badge: "%50 tasarruf"),
      PlanOption(
        id: ProductID.plusMonthly, title: "Aylık", detail: "İstediğin zaman iptal et",
        price: monthly?.displayPrice ?? Self.fallbackPrice(for: ProductID.plusMonthly), unit: "/ay",
        badge: nil),
      PlanOption(
        id: packProductId, title: "Sadece \(examTitle) Paketi", detail: "Tek seferlik · ömür boyu",
        price: pack?.displayPrice ?? Self.fallbackPrice(for: packProductId), unit: nil, badge: nil),
    ]
  }
}
