import DesignKit
import InjectionKit
import PaywallModuleInterface
import ProfileModuleInterface
import PurchaseKit
import RouterKitInterface
import SettingsModuleInterface
import SwiftUI
import UserDataKit

/// Profil, profil düzenleme ve rozet ekranlarını kurar.
@MainActor
public final class ProfileCoordinator: ProfileModuleInterface {
  @Inject private var nav: Routing
  @Inject private var userData: any UserDataStoring
  @Inject private var entitlements: any EntitlementProviding
  @Inject private var settings: SettingsModuleInterface
  @Inject private var paywall: PaywallModuleInterface

  public init() {}

  public func createProfileView() -> AnyView {
    AnyView(ProfileView(viewModel: self.makeViewModel()))
  }

  /// Profili düzenle ekranını açar.
  func showEdit() {
    nav.push(EditProfileView(viewModel: self.makeViewModel()).chromeless())
  }

  /// Rozetler ekranını açar.
  func showBadges() {
    nav.push(BadgesView(viewModel: self.makeViewModel()).chromeless())
  }

  /// Ayarları açar.
  func showSettings() {
    nav.push(settings.createSettingsView())
  }

  /// Paywall'u açar.
  func showPaywall() {
    nav.push(paywall.createPaywallView(highlightProductId: nil))
  }

  /// Geri gider.
  func back() {
    nav.pop()
  }

  private func makeViewModel() -> ProfileViewModel {
    ProfileViewModel(coordinator: self, userData: userData, entitlements: entitlements)
  }
}
