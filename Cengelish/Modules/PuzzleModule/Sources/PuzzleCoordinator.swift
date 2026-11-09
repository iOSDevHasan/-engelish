import ContentKit
import DesignKit
import InjectionKit
import PaywallModuleInterface
import PencilKit
import PurchaseKit
import PuzzleKit
import PuzzleModuleInterface
import RouterKitInterface
import SettingsModuleInterface
import SwiftUI
import UserDataKit
import WordKit

/// Bulmaca akışının ekranlarını kurar: bulmaca → cevap anahtarı → bitiş.
@MainActor
public final class PuzzleCoordinator: PuzzleModuleInterface {
  @Inject private var nav: Routing
  @Inject private var content: any ContentProviding
  @Inject private var userData: any UserDataStoring
  @Inject private var entitlements: any EntitlementProviding
  @Inject private var pronouncer: any Pronouncing
  @Inject private var paywall: PaywallModuleInterface
  @Inject private var settings: SettingsModuleInterface

  public init() {}

  public func createPuzzleView(puzzleId: String) -> AnyView {
    let viewModel = PuzzleViewModel(
      puzzleId: puzzleId, coordinator: self, content: content, userData: userData,
      entitlements: entitlements)
    return AnyView(PuzzleView(viewModel: viewModel).chromeless())
  }

  /// Cevap anahtarını açar.
  func showAnswerKey(_ session: PuzzleSession) {
    let viewModel = AnswerKeyViewModel(
      session: session, coordinator: self, userData: userData, entitlements: entitlements)
    nav.push(AnswerKeyView(viewModel: viewModel, theme: theme(for:)).chromeless())
  }

  /// Bitiş ekranını açar.
  func showFinish(session: PuzzleSession, result: FinishResult, drawing: PKDrawing) {
    let viewModel = FinishViewModel(
      session: session, result: result, coordinator: self, userData: userData,
      pronouncer: pronouncer)
    nav.push(FinishView(viewModel: viewModel, theme: theme(for:)).chromeless())
  }

  /// Paketteki sonraki bulmacayı açar.
  func openNext(puzzleId: String) {
    nav.popToRoot()
    nav.push(createPuzzleView(puzzleId: puzzleId))
  }

  /// Ana sayfaya döner.
  func home() {
    nav.popToRoot()
  }

  /// Paywall'u açar.
  func showPaywall() {
    nav.push(paywall.createPaywallView(highlightProductId: nil))
  }

  /// Tüm temalar ekranını açar.
  func showThemes() {
    nav.push(settings.createPuzzleThemeView())
  }

  /// Geri gider.
  func back() {
    nav.pop()
  }

  /// Ayarlara göre gösterilecek bulmaca teması.
  private func theme(for scheme: ColorScheme) -> PuzzleTheme {
    let settings = userData.settings
    return PuzzleTheme.resolve(
      id: settings.puzzleTheme, isDark: scheme == .dark, autoNight: settings.autoNightTheme,
      highContrast: settings.highContrast)
  }
}
