import Combine
import InjectionKit
import PaywallModuleInterface
import PurchaseKit
import RouterKitInterface
import SwiftUI
import Testing
import UserDataKit
@testable import SettingsModule

@Suite("SettingsViewModel")
@MainActor
struct SettingsViewModelTests {

  @Test("Ücretsiz kullanıcı premium temayı seçemez, ücretsiz temayı seçer")
  func themeSelection() {
    let store = UserDataStore(inMemory: true)
    let nav = NavSpy()
    Injector.override(Routing.self, with: nav)
    Injector.override(PaywallModuleInterface.self, with: PaywallStub())
    let sut = SettingsViewModel(
      coordinator: SettingsCoordinator(), userData: store, entitlements: StoreStub(),
      applyReminder: { _ in })
    sut.selectTheme(id: "pastel", isPremiumTheme: true)
    #expect(store.settings.puzzleTheme == "canli")
    #expect(nav.pushCount == 1)
    sut.selectTheme(id: "okyanus", isPremiumTheme: false)
    #expect(store.settings.puzzleTheme == "okyanus")
  }
}

@MainActor
private final class StoreStub: EntitlementProviding {
  var changes: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
  var isPremium = false
  var ownedProductIds: Set<String> = []
  var products: [StoreProduct] = []
  func loadProducts() async {}
  func purchase(_ productId: String) async -> PurchaseOutcome { .cancelled }
  func restore() async {}
}

@MainActor
private final class PaywallStub: PaywallModuleInterface {
  func createPaywallView(highlightProductId: String?) -> AnyView { AnyView(EmptyView()) }
}

@MainActor
private final class NavSpy: Routing {
  var stackCount = 0
  var flowExitContext: (@MainActor () -> Void)?
  private(set) var pushCount = 0
  func push<V: View>(_ view: V) { pushCount += 1 }
  func pop() {}
  func pop(count: Int) {}
  func popToRoot() {}
  func popToNavigationRoot() {}
  func clearStack() {}
  func setRoot<V: View>(_ view: V) {}
  func registerDeepLink<V: View>(_ path: DeepLinkPath, @ViewBuilder handler: @escaping () -> V) {}
  func registerDeepLink(_ path: DeepLinkPath, urlHandler: @escaping @MainActor (URL) -> Void) {}
  func handleDeepLink(_ url: URL) -> Bool { false }
}
