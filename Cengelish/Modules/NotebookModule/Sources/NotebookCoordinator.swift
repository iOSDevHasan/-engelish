import ContentKit
import InjectionKit
import NotebookModuleInterface
import PaywallModuleInterface
import PurchaseKit
import PuzzleModuleInterface
import RouterKitInterface
import SwiftUI
import UserDataKit
import WordKit

/// Kelime Defterim ekranını kurar; tekrar bulmacasını ve paywall'u açar.
@MainActor
public final class NotebookCoordinator: NotebookModuleInterface, NotebookRouting {

  // MARK: - Properties

  @Inject private var nav: Routing
  @Inject private var content: any ContentProviding
  @Inject private var userData: any UserDataStoring
  @Inject private var pronouncer: any Pronouncing
  @Inject private var entitlements: any EntitlementProviding
  @Inject private var puzzle: PuzzleModuleInterface
  @Inject private var paywall: PaywallModuleInterface

  // MARK: - Init

  public init() {}

  // MARK: - NotebookModuleInterface

  public func createNotebookView() -> AnyView {
    let viewModel = NotebookViewModel(
      router: self, content: content, userData: userData, pronouncer: pronouncer,
      entitlements: entitlements)
    return AnyView(NotebookView(viewModel: viewModel))
  }

  // MARK: - NotebookRouting

  /// Bulmacayı açar.
  func showPuzzle(_ puzzleId: String) {
    nav.push(puzzle.createPuzzleView(puzzleId: puzzleId))
  }

  /// Paywall'u açar.
  func showPaywall() {
    nav.push(paywall.createPaywallView(highlightProductId: nil))
  }
}
