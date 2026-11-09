import ContentKit
import InjectionKit
import OnboardingModuleInterface
import PaywallModuleInterface
import PurchaseKit
import RouterKitInterface
import SwiftUI
import UserDataKit

/// Onboarding ekranlarını kurar; bitişte Çengelish+ paywall'unu bir kez açar.
@MainActor
public final class OnboardingCoordinator: OnboardingModuleInterface {
  @Inject private var nav: Routing
  @Inject private var userData: any UserDataStoring
  @Inject private var content: any ContentProviding
  @Inject private var entitlements: any EntitlementProviding
  @Inject private var paywall: PaywallModuleInterface

  public init() {}

  public func createOnboardingView(onFinish: @escaping @MainActor () -> Void) -> AnyView {
    let viewModel = OnboardingViewModel(
      userData: userData, content: content,
      isPremium: { [weak self] in self?.entitlements.isPremium ?? false },
      onFinish: onFinish,
      showPaywall: { [weak self] in self?.showPaywall() })
    return AnyView(OnboardingView(viewModel: viewModel))
  }

  /// Paywall'u (kapatılabilir) açar.
  func showPaywall() {
    nav.push(paywall.createPaywallView(highlightProductId: nil))
  }
}
