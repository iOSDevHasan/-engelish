import DesignKit
import InjectionKit
import ProfileModuleInterface
import PurchaseKit
import RouterKitInterface
import SettingsModuleInterface
import SwiftUI
import UserDataKit

/// Profil ekranını (rozetler dahil) kurar.
@MainActor
public final class ProfileCoordinator: ProfileModuleInterface {
  @Inject private var nav: Routing
  @Inject private var userData: any UserDataStoring
  @Inject private var entitlements: any EntitlementProviding
  @Inject private var settings: SettingsModuleInterface

  public init() {}

  public func createProfileView() -> AnyView {
    AnyView(ProfileView(viewModel: self.makeViewModel()))
  }

  /// Ayarları açar.
  func showSettings() {
    nav.push(settings.createSettingsView())
  }

  /// Geri gider.
  func back() {
    nav.pop()
  }

  /// Ortak görünüm modelini kurar.
  private func makeViewModel() -> ProfileViewModel {
    ProfileViewModel(coordinator: self, userData: userData, entitlements: entitlements)
  }
}
