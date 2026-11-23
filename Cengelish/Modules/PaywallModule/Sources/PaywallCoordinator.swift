import ContentKit
import DesignKit
import InjectionKit
import PaywallModuleInterface
import PurchaseKit
import RouterKitInterface
import SwiftUI

/// Çengelish Plus paywall ekranını kurar.
@MainActor
public final class PaywallCoordinator: PaywallModuleInterface {
  @Inject private var nav: Routing
  @Inject private var entitlements: any EntitlementProviding
  @Inject private var content: any ContentProviding

  /// Koordinatörü oluşturur; bağımlılıklar ilk kullanımda çözülür.
  public init() {}

  /// Paywall'u kurar; sınav paketi verilirse "Sınav paketleri" sekmesinde o paket seçili gelir.
  public func createPaywallView(highlightProductId: String?) -> AnyView {
    let viewModel = PaywallViewModel(
      coordinator: self, entitlements: entitlements,
      selected: highlightProductId ?? ProductID.plusLifetime, content: content)
    return AnyView(PaywallView(viewModel: viewModel).chromeless())
  }

  /// Paywall'u kapatır (tam ekran modal olarak sunulur).
  func close() {
    nav.dismissModal()
  }
}
