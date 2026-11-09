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
      value: ContentStore(remote: RemoteContentFactory.make()), for: (any ContentProviding).self,
      scope: .singleton())
    Injector.register(
      value: UserDataStore(), for: (any UserDataStoring).self, scope: .singleton(eager: true))
    Injector.register(
      value: EntitlementStore(), for: (any EntitlementProviding).self,
      scope: .singleton(eager: true))
    Injector.register(value: Pronouncer(), for: (any Pronouncing).self, scope: .singleton())
    // jarvis:register-kits
  }

  private static func registerModules() {
    Injector.register(value: HomeCoordinator(), for: HomeModuleInterface.self)
    Injector.register(value: OnboardingCoordinator(), for: OnboardingModuleInterface.self)
    Injector.register(value: ExploreCoordinator(), for: ExploreModuleInterface.self)
    Injector.register(value: PuzzleCoordinator(), for: PuzzleModuleInterface.self)
    Injector.register(value: NotebookCoordinator(), for: NotebookModuleInterface.self)
    Injector.register(value: ProfileCoordinator(), for: ProfileModuleInterface.self)
    Injector.register(value: SettingsCoordinator(), for: SettingsModuleInterface.self)
    Injector.register(value: PaywallCoordinator(), for: PaywallModuleInterface.self)
    // jarvis:register-modules
  }
}
