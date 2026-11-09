import SwiftUI

/// İlk açılış akışı (karşılama, profil, seviye, amaç, veri tercihi).
@MainActor
public protocol OnboardingModuleInterface: AnyObject {
  /// Onboarding akışını oluşturur; profil kaydedilince `onFinish` çağrılır.
  func createOnboardingView(onFinish: @escaping @MainActor () -> Void) -> AnyView
}
