import ContentKit
import ExploreModuleInterface
import HomeModuleInterface
import InjectionKit
import PaywallModuleInterface
import PurchaseKit
import PuzzleModuleInterface
import RouterKitInterface
import SwiftUI
import UserDataKit
import WordKit

/// Ana Sayfa ekranını kurar.
@MainActor
public final class HomeCoordinator: HomeModuleInterface, HomeRouting {
  @Inject private var nav: Routing
  @Inject private var content: any ContentProviding
  @Inject private var userData: any UserDataStoring
  @Inject private var entitlements: any EntitlementProviding
  @Inject private var pronouncer: any Pronouncing
  @Inject private var puzzle: PuzzleModuleInterface
  @Inject private var explore: ExploreModuleInterface
  @Inject private var paywall: PaywallModuleInterface

  public init() {}

  public func createHomeView() -> AnyView {
    let viewModel = HomeViewModel(
      router: self, content: content, userData: userData, entitlements: entitlements,
      pronouncer: pronouncer)
    return AnyView(HomeView(viewModel: viewModel))
  }

  /// Bulmacayı açar.
  func showPuzzle(_ id: String) {
    nav.push(puzzle.createPuzzleView(puzzleId: id))
  }

  /// Çengelish Plus paywall'unu açar.
  func showPaywall() {
    nav.present(paywall.createPaywallView(highlightProductId: nil))
  }

  /// Paketi açar.
  func showPack(_ id: String) {
    nav.push(explore.createPackView(packId: id))
  }
}
