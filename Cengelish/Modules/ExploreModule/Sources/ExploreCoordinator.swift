import ContentKit
import DesignKit
import ExploreModuleInterface
import InjectionKit
import PaywallModuleInterface
import PurchaseKit
import PuzzleModuleInterface
import RouterKitInterface
import SwiftUI
import UserDataKit
import WordKit

/// Keşfet ve paket ekranlarını kurar.
@MainActor
public final class ExploreCoordinator: ExploreModuleInterface {
  @Inject private var nav: Routing
  @Inject private var content: any ContentProviding
  @Inject private var userData: any UserDataStoring
  @Inject private var entitlements: any EntitlementProviding
  @Inject private var puzzle: PuzzleModuleInterface
  @Inject private var paywall: PaywallModuleInterface
  @Inject private var pronouncer: any Pronouncing

  /// Koordinatörü oluşturur; bağımlılıklar `Injector` ile çözülür.
  public init() {}

  // MARK: - ExploreModuleInterface

  public func createExploreView() -> AnyView {
    let viewModel = ExploreViewModel(
      coordinator: self, content: content, userData: userData, entitlements: entitlements)
    return AnyView(ExploreView(viewModel: viewModel))
  }

  public func createPackView(packId: String) -> AnyView {
    let viewModel = PackViewModel(
      packId: packId, coordinator: self, content: content, userData: userData,
      entitlements: entitlements)
    return AnyView(PackView(viewModel: viewModel).chromeless())
  }

  // MARK: - Navigation

  /// Arama ekranını açar.
  func showSearch() {
    let viewModel = SearchViewModel(
      coordinator: self, content: content, userData: userData, entitlements: entitlements,
      pronouncer: pronouncer)
    nav.push(SearchView(viewModel: viewModel).chromeless())
  }

  /// Tüm tema paketleri listesini açar (Keşfet ekranının durumunu paylaşır).
  func showThemes(viewModel: ExploreViewModel) {
    nav.push(ThemeListView(viewModel: viewModel).chromeless())
  }

  /// Paket detayını açar.
  func showPack(_ packId: String) {
    nav.push(createPackView(packId: packId))
  }

  /// Bulmacayı açar.
  func showPuzzle(_ puzzleId: String) {
    nav.push(puzzle.createPuzzleView(puzzleId: puzzleId))
  }

  /// Paywall'u (isteğe bağlı ürün seçili) açar.
  func showPaywall(productId: String?) {
    nav.push(paywall.createPaywallView(highlightProductId: productId))
  }

  /// Geri gider.
  func back() {
    nav.pop()
  }
}
