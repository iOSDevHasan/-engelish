import DesignKit
import InjectionKit
import PaywallModuleInterface
import PurchaseKit
import RouterKitInterface
import SwiftUI

/// Çengelish+ paywall ekranını kurar.
@MainActor
public final class PaywallCoordinator: PaywallModuleInterface {
  @Inject private var nav: Routing
  @Inject private var entitlements: any EntitlementProviding

  public init() {}

  public func createPaywallView(highlightProductId: String?) -> AnyView {
    let viewModel = PaywallViewModel(
      coordinator: self, entitlements: entitlements,
      selected: highlightProductId ?? ProductID.plusYearly)
    return AnyView(PaywallView(viewModel: viewModel).chromeless())
  }

  /// Paywall'u kapatır.
  func close() {
    nav.pop()
  }
}
