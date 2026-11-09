import DesignKit
import InjectionKit
import PaywallModuleInterface
import PurchaseKit
import RouterKitInterface
import SettingsModuleInterface
import SwiftUI
import UserDataKit

/// Ayarlar ekranlarını kurar ve aralarında gezinir.
@MainActor
public final class SettingsCoordinator: SettingsModuleInterface {
  @Inject private var nav: Routing
  @Inject private var userData: any UserDataStoring
  @Inject private var entitlements: any EntitlementProviding
  @Inject private var paywall: PaywallModuleInterface

  public init() {}

  public func createSettingsView() -> AnyView {
    AnyView(SettingsView(viewModel: self.makeViewModel()).chromeless())
  }

  public func createPuzzleThemeView() -> AnyView {
    AnyView(PuzzleThemeView(viewModel: self.makeViewModel()).chromeless())
  }

  /// Uygulama görünümü ekranını açar.
  func showAppearance() {
    nav.push(AppearanceView(viewModel: self.makeViewModel()).chromeless())
  }

  /// Bulmaca teması ekranını açar.
  func showPuzzleTheme() {
    nav.push(createPuzzleThemeView())
  }

  /// Veri ve yedekleme ekranını açar.
  func showData() {
    nav.push(DataView(viewModel: self.makeViewModel()).chromeless())
  }

  /// Paywall'u açar.
  func showPaywall() {
    nav.push(paywall.createPaywallView(highlightProductId: nil))
  }

  /// Geri gider.
  func back() {
    nav.pop()
  }

  private func makeViewModel() -> SettingsViewModel {
    SettingsViewModel(coordinator: self, userData: userData, entitlements: entitlements)
  }
}
