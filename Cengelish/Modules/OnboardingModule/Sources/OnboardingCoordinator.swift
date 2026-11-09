import InjectionKit
import OnboardingModuleInterface
import SwiftUI
import UserDataKit

/// Onboarding ekranlarını kurar.
@MainActor
public final class OnboardingCoordinator: OnboardingModuleInterface {
  @Inject private var userData: any UserDataStoring

  public init() {}

  public func createOnboardingView(onFinish: @escaping @MainActor () -> Void) -> AnyView {
    let viewModel = OnboardingViewModel(userData: userData, onFinish: onFinish)
    return AnyView(OnboardingView(viewModel: viewModel))
  }
}
