import Combine
import ContentKit
import DesignKit
import ExploreModuleInterface
import HomeModuleInterface
import InjectionKit
import NotebookModuleInterface
import OnboardingModuleInterface
import ProfileModuleInterface
import PurchaseKit
import SwiftUI
import UserDataKit

/// Uygulamanın kök görünümü: profil yoksa onboarding, varsa sekmeli ana yapı.
public struct AppShellView: View {
  @StateObject private var model = AppShellModel()
  @Environment(\.scenePhase) private var scenePhase

  /// Kök görünümü oluşturur.
  public init() {}

  public var body: some View {
    Group {
      if model.hasProfile {
        MainTabView()
      } else {
        model.onboardingView
      }
    }
    .preferredColorScheme(model.colorScheme)
    .chromeless()
    .task { await model.start() }
    .onChange(of: scenePhase) { _, phase in
      if phase == .background { model.publishWidgets() }
    }
  }
}

/// Kök görünümün durumu: profil var mı, görünüm tercihi ne.
@MainActor
final class AppShellModel: ObservableObject {
  @Published private(set) var hasProfile = false
  @Published private(set) var colorScheme: ColorScheme?
  @Inject private var userData: any UserDataStoring
  @Inject private var entitlements: any EntitlementProviding
  @Inject private var content: any ContentProviding
  @Inject private var onboarding: OnboardingModuleInterface
  private var cancellables: Set<AnyCancellable> = []
  private var didStart = false
  /// Widget anlık görüntüsünü yazan yardımcı.
  private let widgets = WidgetPublisher()

  /// Onboarding akışı; bitince kök yeniden değerlendirilir.
  var onboardingView: AnyView {
    onboarding.createOnboardingView { [weak self] in self?.reload() }
  }

  /// İlk açılışta veriyi okur, ürünleri ve uzak içeriği yükler.
  func start() async {
    reload()
    guard !didStart else { return }
    didStart = true
    userData.changes
      .sink { [weak self] in self?.reload() }
      .store(in: &cancellables)
    userData.changes
      .debounce(for: .seconds(1), scheduler: RunLoop.main)
      .sink { [weak self] in self?.publishWidgets() }
      .store(in: &cancellables)
    publishWidgets()
    await entitlements.loadProducts()
    let owned = entitlements.ownedProductIds
    let packs = await content.packs()
    let entitled = Set(
      packs.filter { entitlements.isPremium || owned.contains($0.productId ?? "-") }.map(\.id))
    await content.refreshFromRemote(entitledPackIds: entitled)
    publishWidgets()
  }

  /// Widget'ların verisini ve seri uyarısı bildirimini günceller.
  func publishWidgets() {
    ReminderScheduler.refreshStreakWarning(settings: userData.settings, stats: userData.stats)
    Task { await widgets.publish() }
  }

  /// Profil ve görünüm tercihini yeniden okur.
  private func reload() {
    hasProfile = userData.profile != nil
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
