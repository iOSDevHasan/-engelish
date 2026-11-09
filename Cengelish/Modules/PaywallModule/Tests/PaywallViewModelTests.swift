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
  }

  @Test("Satın alma başarılı olunca ekran kapanır")
  func purchaseCloses() async {
    let nav = NavSpy()
    let sut = makeSUT(store: StoreSpy(), nav: nav)
    await sut.purchase()
    #expect(nav.popCount == 1)
  }

  private func makeSUT(store: StoreSpy, nav: NavSpy = NavSpy()) -> PaywallViewModel {
    Injector.override(Routing.self, with: nav)
    return PaywallViewModel(
      coordinator: PaywallCoordinator(), entitlements: store, selected: ProductID.plusYearly)
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
