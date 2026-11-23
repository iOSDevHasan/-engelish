import Combine
import DesignKit
import Foundation
import InjectionKit
import PaywallModuleInterface
import PurchaseKit
import RouterKitInterface
import SwiftUI
import Testing
import UserDataKit
@testable import SettingsModule

@Suite("SettingsViewModel")
@MainActor
struct SettingsViewModelTests {

  @Test("Ücretsiz kullanıcı premium temayı seçemez, ücretsiz temayı seçer")
  func themeSelection() {
    let store = UserDataStore(inMemory: true)
    let nav = NavSpy()
    Injector.override(Routing.self, with: nav)
    Injector.override(PaywallModuleInterface.self, with: PaywallStub())
    let sut = SettingsViewModel(
      coordinator: SettingsCoordinator(), userData: store, entitlements: StoreStub(),
      applyReminder: { _, _ in })
    sut.selectTheme(id: "pastel", isPremiumTheme: true)
    #expect(store.settings.puzzleTheme == "canli")
    #expect(nav.pushCount == 1)
    sut.selectTheme(id: "okyanus", isPremiumTheme: false)
    #expect(store.settings.puzzleTheme == "okyanus")
  }

  @Test("Elle seçilen tema yüksek kontrastı, gerekirse otomatik Gece temasını kapatır")
  func explicitThemeWins() {
    let store = UserDataStore(inMemory: true)
    store.updateSettings {
      $0.autoNightTheme = true
      $0.highContrast = true
    }
    let sut = SettingsViewModel(
      coordinator: SettingsCoordinator(), userData: store, entitlements: StoreStub(),
      applyReminder: { _, _ in })
    sut.selectTheme(id: "neon", isPremiumTheme: false, keepsInDarkMode: true)
    #expect(store.settings.autoNightTheme)
    #expect(!store.settings.highContrast)
    sut.selectTheme(id: "okyanus", isPremiumTheme: false, keepsInDarkMode: false)
    #expect(store.settings.puzzleTheme == "okyanus")
    #expect(!store.settings.autoNightTheme)
  }

  @Test("Plus satırı ömür boyu planı ve satın alma tarihini gösterir")
  func plusRow() throws {
    let entitlements = StoreStub()
    let free = makeSUT(entitlements: entitlements)
    #expect(free.plusTitle == "Çengelish Plus'a geç")
    #expect(free.plusDetail.isEmpty)

    entitlements.isPremium = true
    #expect(makeSUT(entitlements: entitlements).plusDetail == "Aktif")

    entitlements.plusPurchaseDate = try #require(
      Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: 8)))
    let premium = makeSUT(entitlements: entitlements)
    #expect(premium.plusTitle == "Çengelish Plus · Ömür boyu")
    #expect(premium.plusDetail == "8 Kas 2026")
  }

  @Test("Tüm verileri sil: depo boşalır, silme yayınlanır, hatırlatıcılar varsayılana döner")
  func eraseAllData() {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    store.updateSettings { $0.reminderEnabled = true }
    store.saveTyped(puzzleId: "a1_01", letters: ["1,1": "A"])
    store.addToNotebook(wordId: "w_house", source: "manual")
    var applied: [AppSettings] = []
    var erasedCount = 0
    let cancellable = store.dataErased.sink { erasedCount += 1 }
    Injector.override(Routing.self, with: NavSpy())
    Injector.override(PaywallModuleInterface.self, with: PaywallStub())
    let sut = SettingsViewModel(
      coordinator: SettingsCoordinator(), userData: store, entitlements: StoreStub(),
      applyReminder: { settings, _ in applied.append(settings) })

    sut.eraseAllData()

    #expect(erasedCount == 1)
    #expect(store.profile == nil)
    #expect(store.allProgress().isEmpty)
    #expect(store.notebook.isEmpty)
    #expect(applied.last?.reminderEnabled == false)
    #expect(!sut.settings.reminderEnabled)
    cancellable.cancel()
  }

  @Test("Her ayar satırının Türkçe, kısa bir açıklaması var")
  func settingInfoTexts() {
    #expect(SettingInfo.all.count == 13)
    for text in SettingInfo.all {
      #expect(!text.isEmpty)
      #expect(!text.contains("Çengelish+"))
      let sentences = text.split(separator: ".").filter {
        !$0.trimmingCharacters(in: .whitespaces).isEmpty
      }
      #expect((1...2).contains(sentences.count), "\(text)")
    }
    #expect(SettingInfo.puzzleTheme.contains(PlusBrand.name))
  }

  private func makeSUT(
    store: UserDataStore = UserDataStore(inMemory: true), entitlements: StoreStub = StoreStub()
  ) -> SettingsViewModel {
    Injector.override(Routing.self, with: NavSpy())
    Injector.override(PaywallModuleInterface.self, with: PaywallStub())
    return SettingsViewModel(
      coordinator: SettingsCoordinator(), userData: store, entitlements: entitlements,
      applyReminder: { _, _ in })
  }
}

@MainActor
private final class StoreStub: EntitlementProviding {
  var changes: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
  var isPremium = false
  var ownedProductIds: Set<String> = []
  var products: [StoreProduct] = []
  var plusPurchaseDate: Date?
  func loadProducts() async {}
  func purchase(_ productId: String) async -> PurchaseOutcome { .cancelled }
  func restore() async {}
}

@MainActor
private final class PaywallStub: PaywallModuleInterface {
  func createPaywallView(highlightProductId: String?) -> AnyView { AnyView(EmptyView()) }
}

@MainActor
private final class NavSpy: Routing {
  var stackCount = 0
  var flowExitContext: (@MainActor () -> Void)?
  private(set) var pushCount = 0
  func push<V: View>(_ view: V) { pushCount += 1 }
  func pop() {}
  func pop(count: Int) {}
  func popToRoot() {}
  func popToNavigationRoot() {}
  func clearStack() {}
  func setRoot<V: View>(_ view: V) {}
  func registerDeepLink<V: View>(_ path: DeepLinkPath, @ViewBuilder handler: @escaping () -> V) {}
  func registerDeepLink(_ path: DeepLinkPath, urlHandler: @escaping @MainActor (URL) -> Void) {}
  func handleDeepLink(_ url: URL) -> Bool { false }
}
