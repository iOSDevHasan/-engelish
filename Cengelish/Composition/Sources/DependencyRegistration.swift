import ContentKit
import InjectionKit
import PurchaseKit
import RouterKit
import RouterKitInterface
import HomeModule
import HomeModuleInterface
import OnboardingModule
import OnboardingModuleInterface
import ExploreModule
import ExploreModuleInterface
import PuzzleModule
import PuzzleModuleInterface
import NotebookModule
import NotebookModuleInterface
import ProfileModule
import ProfileModuleInterface
import SettingsModule
import SettingsModuleInterface
import PaywallModule
import PaywallModuleInterface
import UserDataKit
import WordKit
// jarvis:imports

/// Registers every coordinator and service with `Injector`.
@MainActor
public enum DependencyRegistration {

  /// Wires the navigator, then every Kit and Module. Call once from `AppRootView`.
  public static func registerAll(navigator: AppRouter) {
    Injector.register(
      value: navigator,
      for: Routing.self,
      scope: .singleton(eager: true)
    )
    registerKits()
    registerModules()
  }

  private static func registerKits() {
    Injector.register(
      value: ContentStore(), for: (any ContentProviding).self, scope: .singleton())
    Injector.register(
      value: UserDataStore(), for: (any UserDataStoring).self, scope: .singleton(eager: true))
    Injector.register(
      value: EntitlementStore(), for: (any EntitlementProviding).self,
      scope: .singleton(eager: true))
    Injector.register(value: Pronouncer(), for: (any Pronouncing).self, scope: .singleton())
    // jarvis:register-kits
  }

  /// Modül koordinatörleri tekil tutulur: kabuk yeniden çizildiğinde yeni koordinatör kurulmaz,
  /// görünüm modellerinin tuttuğu yönlendiriciler hep aynı nesneye işaret eder.
  private static func registerModules() {
    Injector.register(
      value: HomeCoordinator(), for: HomeModuleInterface.self, scope: .singleton())
    Injector.register(
      value: OnboardingCoordinator(), for: OnboardingModuleInterface.self, scope: .singleton())
    Injector.register(
      value: ExploreCoordinator(), for: ExploreModuleInterface.self, scope: .singleton())
    Injector.register(
      value: PuzzleCoordinator(), for: PuzzleModuleInterface.self, scope: .singleton())
    Injector.register(
      value: NotebookCoordinator(), for: NotebookModuleInterface.self, scope: .singleton())
    Injector.register(
      value: ProfileCoordinator(), for: ProfileModuleInterface.self, scope: .singleton())
    Injector.register(
      value: SettingsCoordinator(), for: SettingsModuleInterface.self, scope: .singleton())
    Injector.register(
      value: PaywallCoordinator(), for: PaywallModuleInterface.self, scope: .singleton())
    // jarvis:register-modules
  }
}
