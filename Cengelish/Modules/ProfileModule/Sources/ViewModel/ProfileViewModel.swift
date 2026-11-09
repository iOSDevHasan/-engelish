import Combine
import DesignKit
import Foundation
import PurchaseKit
import UserDataKit

/// Profil ekranlarının ortak durumu.
@MainActor
final class ProfileViewModel: ObservableObject {

  // MARK: - Properties

  @Published private(set) var profile = UserProfile(nickname: "", avatar: AvatarConfig())
  @Published private(set) var stats = UserStats()
  @Published private(set) var badges: [BadgeKind: Date] = [:]
  @Published private(set) var isPremium = false
  @Published private(set) var iCloudOn = false
  @Published private(set) var iCloudAvailable = false
  @Published var draft = UserProfile(nickname: "", avatar: AvatarConfig())
  private let coordinator: ProfileCoordinator
  private let userData: any UserDataStoring
  private let entitlements: any EntitlementProviding
  private var cancellables: Set<AnyCancellable> = []

  // MARK: - Init

  init(
    coordinator: ProfileCoordinator, userData: any UserDataStoring,
    entitlements: any EntitlementProviding
  ) {
    self.coordinator = coordinator
    self.userData = userData
    self.entitlements = entitlements
    reload()
    draft = profile
    userData.changes.merge(with: entitlements.changes)
      .sink { [weak self] in self?.reload() }
      .store(in: &cancellables)
  }

  // MARK: - Navigation

  func edit() { coordinator.showEdit() }
  func openBadges() { coordinator.showBadges() }
  func openSettings() { coordinator.showSettings() }
  func openPaywall() { coordinator.showPaywall() }
  func back() { coordinator.back() }

  // MARK: - Derived

  /// Seçili unvan.
  var title: UserTitle { UserTitle(rawValue: profile.titleId) ?? .kalemci }

  /// Vitrindeki rozetler (seçilmediyse kazanılan ilk üç).
  var showcase: [BadgeKind] {
    let chosen = profile.showcaseBadges.compactMap(BadgeKind.init(rawValue:)).filter {
      badges[$0] != nil
    }
    if !chosen.isEmpty { return chosen }
    return Array(BadgeKind.allCases.filter { badges[$0] != nil }.prefix(3))
  }

  /// Kazanılan rozetler, kazanılma sırasıyla.
  var earned: [BadgeKind] {
    BadgeKind.allCases.filter { badges[$0] != nil }
      .sorted { (badges[$0] ?? .now) < (badges[$1] ?? .now) }
  }

  /// Henüz kazanılmamış rozetler.
  var upcoming: [BadgeKind] { BadgeKind.allCases.filter { badges[$0] == nil } }

  /// Aksesuarın kilit nedeni (açıksa nil).
  func lockReason(_ accessory: AvatarAccessory) -> String? {
    UnlockRules.isUnlocked(accessory, stats: stats, isPremium: isPremium)
      ? nil : UnlockRules.requirement(accessory)
  }

  /// Arka planın kilitli olup olmadığı.
  func isLocked(_ background: AvatarBackground) -> Bool {
    !UnlockRules.isUnlocked(background, isPremium: isPremium)
  }

  /// Rozetin tarih metni.
  func dateText(_ badge: BadgeKind) -> String {
    badges[badge].map(DateText.dayMonthShort) ?? ""
  }

  // MARK: - Editing

  /// Düzenlemeyi kaydeder ve geri döner.
  func saveDraft() {
    var updated = draft
    updated.nickname = String(updated.nickname.prefix(16)).trimmingCharacters(in: .whitespaces)
    userData.updateProfile(updated)
    coordinator.back()
  }

  /// Düzenlemeden vazgeçer.
  func cancelDraft() {
    draft = profile
    coordinator.back()
  }

  /// Rozeti vitrine ekler ya da çıkarır (en fazla 3).
  func toggleShowcase(_ badge: BadgeKind) {
    var current = showcase.map(\.rawValue)
    if let index = current.firstIndex(of: badge.rawValue) {
      current.remove(at: index)
    } else if current.count < 3 {
      current.append(badge.rawValue)
    } else {
      current = Array(current.dropFirst()) + [badge.rawValue]
    }
    var updated = profile
    updated.showcaseBadges = current
    userData.updateProfile(updated)
  }

  private func reload() {
    profile = userData.profile ?? profile
    stats = userData.stats
    badges = userData.badges
    isPremium = entitlements.isPremium
    iCloudOn = userData.isICloudBackupEnabled
    iCloudAvailable = userData.isICloudAvailable
  }
}
