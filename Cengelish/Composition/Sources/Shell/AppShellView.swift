import Combine
import DesignKit
import ExploreModuleInterface
import HomeModuleInterface
import InjectionKit
import NotebookModuleInterface
import OnboardingModuleInterface
import ProfileModuleInterface
import PurchaseKit
import RouterKitInterface
import SwiftUI
import UIKit
import UserDataKit

/// Uygulamanın kök görünümü: açılışta splash, ardından profil yoksa onboarding, varsa sekmeli
/// ana yapı. Tüm veriler silinince splash yeniden oynar ve onboarding başlar.
public struct AppShellView: View {
  @StateObject private var model = AppShellModel()
  @Environment(\.scenePhase) private var scenePhase

  /// Kök görünümü oluşturur.
  public init() {}

  public var body: some View {
    ZStack {
      switch model.phase {
      case .splash:
        SplashView(start: model.splashStart)
          .transition(.opacity.combined(with: .scale(scale: 1.04)))
          .zIndex(1)
      case .main:
        MainTabView().transition(.opacity)
      case .onboarding:
        model.onboardingView.transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.35), value: model.phase)
    .preferredColorScheme(model.colorScheme)
    .scrollIndicators(.hidden)
    .chromeless()
    .task { await model.start() }
    .onChange(of: scenePhase) { _, phase in
      if phase == .background { model.publishWidgets(forceReload: true) }
    }
  }
}

/// Kök görünümün durumu: hangi aşamada (splash / onboarding / ana yapı), görünüm tercihi ne.
@MainActor
final class AppShellModel: ObservableObject {
  /// Kökte gösterilen aşama.
  enum Phase: Equatable {
    case splash, onboarding, main
  }

  @Published private(set) var phase = Phase.splash
  @Published private(set) var colorScheme: ColorScheme?
  /// Splash animasyonunun başladığı an.
  private(set) var splashStart = Date()
  private var hasProfile = false
  @Inject private var userData: any UserDataStoring
  @Inject private var entitlements: any EntitlementProviding
  @Inject private var onboarding: OnboardingModuleInterface
  @Inject private var router: Routing
  private var cancellables: Set<AnyCancellable> = []
  private var didStart = false
  /// Widget anlık görüntüsünü yazan yardımcı.
  private let widgets = WidgetPublisher()

  /// Onboarding akışı; bitince kök yeniden değerlendirilir.
  var onboardingView: AnyView {
    onboarding.createOnboardingView { [weak self] in self?.reload() }
  }

  /// İlk açılışta veriyi okur ve satın alma ürünlerini yükler.
  func start() async {
    #if DEBUG
    await ScreenshotDemoSeeder().seedIfRequested()
    #endif
    reload()
    guard !didStart else { return }
    didStart = true
    Task { await finishSplash() }
    userData.dataErased
      .sink { [weak self] in self?.handleErase() }
      .store(in: &cancellables)
    userData.changes
      .sink { [weak self] in self?.reload() }
      .store(in: &cancellables)
    userData.changes
      .debounce(for: .seconds(1), scheduler: RunLoop.main)
      .sink { [weak self] in self?.publishWidgets() }
      .store(in: &cancellables)
    publishWidgets()
    await entitlements.loadProducts()
    publishWidgets()
  }

  /// Widget'ların verisini ve seri uyarısı bildirimini günceller.
  ///
  /// `forceReload` widget'ları değişiklik olmasa da yeniler (arka plana geçerken). Yazma bitene
  /// kadar sistemden süre istenir; yoksa uygulama askıya alınıp widget eski kalabilir.
  func publishWidgets(forceReload: Bool = false) {
    ReminderScheduler.refreshStreakWarning(settings: userData.settings, stats: userData.stats)
    let assertion = BackgroundAssertion(name: "WidgetPublish")
    Task {
      await widgets.publish(forceReload: forceReload)
      assertion.end()
    }
  }

  /// Splash animasyonu bitene kadar bekler, sonra profile göre onboarding'e ya da ana yapıya geçer.
  private func finishSplash() async {
    let hold = UIAccessibility.isReduceMotionEnabled ? 0.6 : SplashView.duration + 0.35
    let remaining = hold - Date().timeIntervalSince(splashStart)
    if remaining > 0 { try? await Task.sleep(for: .seconds(remaining)) }
    phase = hasProfile ? .main : .onboarding
  }

  /// Tüm veriler silinince gezinme yığınını boşaltır ve splash'i yeniden oynatır.
  private func handleErase() {
    router.clearStack()
    replaySplash()
  }

  /// Splash'i baştan oynatır, ardından onboarding'i başlatır (tüm veriler silindikten sonra).
  func replaySplash() {
    guard phase != .splash else { return }
    splashStart = Date()
    phase = .splash
    Task { await finishSplash() }
  }

  /// Profil ve görünüm tercihini yeniden okur; profil silindiyse splash'i yeniden oynatır.
  private func reload() {
    let hadProfile = hasProfile
    hasProfile = userData.profile != nil
    switch phase {
    case .splash:
      break
    case .main where hadProfile && !hasProfile:
      replaySplash()
    case .main, .onboarding:
      phase = hasProfile ? .main : .onboarding
    }
    colorScheme =
      switch userData.settings.appearance {
      case .system: nil
      case .light: .light
      case .dark: .dark
      }
  }
}

/// Dört sekmeli ana yapı (iOS 26+ Liquid Glass sekme çubuğu).
struct MainTabView: View {
  @Inject private var home: HomeModuleInterface
  @Inject private var explore: ExploreModuleInterface
  @Inject private var notebook: NotebookModuleInterface
  @Inject private var profile: ProfileModuleInterface
  @State private var selection = TabID.home

  enum TabID: Hashable {
    case home, explore, notebook, profile
  }

  var body: some View {
    TabView(selection: $selection) {
      Tab("Ana Sayfa", systemImage: "house.fill", value: TabID.home) {
        home.createHomeView()
      }
      Tab("Keşfet", systemImage: "safari.fill", value: TabID.explore) {
        explore.createExploreView()
      }
      Tab("Defterim", systemImage: "book.closed.fill", value: TabID.notebook) {
        notebook.createNotebookView()
      }
      Tab("Profil", systemImage: "person.crop.circle.fill", value: TabID.profile) {
        profile.createProfileView()
      }
    }
    .tint(Palette.accent)
  }
}

/// Uygulama arka plana geçerken kısa bir işin bitmesi için sistemden süre ister.
@MainActor
private final class BackgroundAssertion {
  private var identifier = UIBackgroundTaskIdentifier.invalid

  /// Süreyi başlatır; süre dolarsa kendiliğinden biter.
  init(name: String) {
    identifier = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
      MainActor.assumeIsolated { self?.end() }
    }
  }

  /// Süreyi bitirir (birden çok çağrı güvenlidir).
  func end() {
    guard identifier != .invalid else { return }
    UIApplication.shared.endBackgroundTask(identifier)
    identifier = .invalid
  }
}
