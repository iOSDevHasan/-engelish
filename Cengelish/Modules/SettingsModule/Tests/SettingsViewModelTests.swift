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

  @Test("Abonelik satırı planı ve yenilenme tarihini gösterir")
  func subscriptionRow() throws {
    let entitlements = StoreStub()
    let free = makeSUT(entitlements: entitlements)
    #expect(free.subscriptionTitle == "Çengelish+'a geç")
    #expect(free.subscriptionDetail.isEmpty)

    let renewal = try #require(
      Calendar(identifier: .gregorian).date(from: DateComponents(year: 2027, month: 11, day: 8)))
    entitlements.isPremium = true
    entitlements.activeSubscription = ActiveSubscription(
      productId: ProductID.plusYearly, renewalDate: renewal)
    let premium = makeSUT(entitlements: entitlements)
    #expect(premium.subscriptionTitle == "Çengelish+ · Yıllık")
    #expect(premium.subscriptionDetail == "8 Kas 2027")
  }

  @Test("Şimdi yedekle dosyayı yazar ve son yedek zamanını kaydeder")
  func backupNow() throws {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let sut = makeSUT(store: store, backupDirectory: directory)
    #expect(sut.lastBackupText() == nil)

    let now = Date.now
    let url = try #require(sut.backupNow(now: now))
    #expect(FileManager.default.fileExists(atPath: url.path()))
    #expect(store.settings.lastBackupAt == now)
    #expect(sut.lastBackupText(now: now)?.hasPrefix("Bugün ") == true)
    let tomorrow = now.addingTimeInterval(86_400)
    #expect(sut.lastBackupText(now: tomorrow)?.hasPrefix("Dün ") == true)
  }

  @Test("Profili düzenle kanca varsa onu açar, yoksa takma adı kaydeder")
  func editProfile() {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    var opened = false
    let hooked = makeSUT(store: store, onEditProfile: { opened = true })
    hooked.openEditProfile()
    #expect(opened)
    #expect(!hooked.isEditingNickname)

    let sut = makeSUT(store: store)
    #expect(sut.nickname == "Deniz")
    sut.openEditProfile()
    #expect(sut.isEditingNickname)
    #expect(sut.nicknameDraft == "Deniz")
    sut.nicknameDraft = "  Ada  "
    sut.saveNickname()
    #expect(store.profile?.nickname == "Ada")
    #expect(sut.nickname == "Ada")
  }

  private func makeSUT(
    store: UserDataStore = UserDataStore(inMemory: true), entitlements: StoreStub = StoreStub(),
    backupDirectory: URL = .temporaryDirectory,
    onEditProfile: (@MainActor () -> Void)? = nil
  ) -> SettingsViewModel {
    Injector.override(Routing.self, with: NavSpy())
    Injector.override(PaywallModuleInterface.self, with: PaywallStub())
    return SettingsViewModel(
      coordinator: SettingsCoordinator(), userData: store, entitlements: entitlements,
      onEditProfile: onEditProfile, backupDirectory: backupDirectory,
      applyReminder: { _, _ in })
  }
}

@MainActor
private final class StoreStub: EntitlementProviding {
  var changes: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
  var isPremium = false
  var ownedProductIds: Set<String> = []
  var products: [StoreProduct] = []
  var activeSubscription: ActiveSubscription?
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
