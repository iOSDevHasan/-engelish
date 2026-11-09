import Combine
import InjectionKit
import PurchaseKit
import RouterKitInterface
import SwiftUI
import Testing
@testable import PaywallModule

@Suite("PaywallViewModel")
@MainActor
struct PaywallViewModelTests {

  @Test("Ürünler yüklenmese de üç plan örnek fiyatlarla görünür")
  func fallbackPlans() {
    let sut = makeSUT(store: StoreSpy())
    #expect(
      sut.plans.map(\.id) == [ProductID.plusYearly, ProductID.plusMonthly, ProductID.packYDS])
    #expect(sut.ctaTitle == "7 gün ücretsiz dene")
    #expect(sut.plans.last?.title == "Sadece YDS Paketi")
    #expect(sut.plans.map(\.price) == ["37,50 ₺", "74,99 ₺", "199,99 ₺"])
  }

  @Test(
    "Sınav paketiyle açılınca o paketin tek seferlik seçeneği gösterilir",
    arguments: [
      (ProductID.packYOKDIL, "Sadece YÖKDİL Paketi", "199,99 ₺"),
      (ProductID.packLGS, "Sadece LGS Paketi", "129,99 ₺"),
      (ProductID.packIELTS, "Sadece IELTS Paketi", "199,99 ₺"),
      (ProductID.packTOEFL, "Sadece TOEFL Paketi", "199,99 ₺"),
    ])
  func examPackOption(productId: String, title: String, price: String) {
    let sut = makeSUT(store: StoreSpy(), selected: productId)
    #expect(sut.plans.map(\.id) == [ProductID.plusYearly, ProductID.plusMonthly, productId])
    #expect(sut.plans.last?.title == title)
    #expect(sut.plans.last?.price == price)
    #expect(sut.selected == productId)
    #expect(sut.ctaTitle == "Devam et")
  }

  @Test("Mağaza fiyatı varsa örnek fiyatın yerine geçer")
  func storePrice() {
    let store = StoreSpy()
    store.products = [
      StoreProduct(
        id: ProductID.packLGS, title: "LGS Paketi", displayPrice: "99,99 ₺",
        monthlyEquivalent: nil, trialText: nil, isSubscription: false)
    ]
    let sut = makeSUT(store: store, selected: ProductID.packLGS)
    #expect(sut.plans.last?.price == "99,99 ₺")
  }

  @Test("Satın alma başarılı olunca ekran kapanır")
  func purchaseCloses() async {
    let nav = NavSpy()
    let sut = makeSUT(store: StoreSpy(), nav: nav)
    await sut.purchase()
    #expect(nav.popCount == 1)
  }

  private func makeSUT(
    store: StoreSpy, nav: NavSpy = NavSpy(), selected: String = ProductID.plusYearly
  ) -> PaywallViewModel {
    Injector.override(Routing.self, with: nav)
    return PaywallViewModel(
      coordinator: PaywallCoordinator(), entitlements: store, selected: selected)
  }
}

@MainActor
private final class StoreSpy: EntitlementProviding {
  var changes: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
  var isPremium = false
  var ownedProductIds: Set<String> = []
  var products: [StoreProduct] = []
  func loadProducts() async {}
  func purchase(_ productId: String) async -> PurchaseOutcome { .purchased }
  func restore() async {}
}

@MainActor
private final class NavSpy: Routing {
  var stackCount = 0
  var flowExitContext: (@MainActor () -> Void)?
  private(set) var popCount = 0
  func push<V: View>(_ view: V) {}
  func pop() { popCount += 1 }
  func pop(count: Int) {}
  func popToRoot() {}
  func popToNavigationRoot() {}
  func clearStack() {}
  func setRoot<V: View>(_ view: V) {}
  func registerDeepLink<V: View>(_ path: DeepLinkPath, @ViewBuilder handler: @escaping () -> V) {}
  func registerDeepLink(_ path: DeepLinkPath, urlHandler: @escaping @MainActor (URL) -> Void) {}
  func handleDeepLink(_ url: URL) -> Bool { false }
}
