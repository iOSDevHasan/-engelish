import Combine
import DesignKit
import Foundation
import PurchaseKit
import UIKit
import UserDataKit

/// Profil ve rozet ekranlarının ortak durumu.
@MainActor
final class ProfileViewModel: ObservableObject {

  // MARK: - Properties

  /// Takma ad karakter sınırı.
  static let nicknameLimit = 16

  @Published private(set) var profile = UserProfile(nickname: "", avatar: AvatarConfig())
  @Published private(set) var stats = UserStats()
  @Published private(set) var badges: [BadgeKind: Date] = [:]
  @Published private(set) var snapshot = AchievementSnapshot(stats: UserStats())
  @Published private(set) var isPremium = false
  /// Kayıtlı profil fotoğrafı; yoksa avatar maskottur.
  @Published private(set) var photo: UIImage?
  /// Düzenleme panelindeki takma ad taslağı.
  @Published var draftNickname = ""
  /// Düzenleme panelindeki fotoğraf taslağı (saklanmaya hazır JPEG).
  @Published private(set) var draftPhotoData: Data?
  /// Düzenleme panelindeki fotoğraf önizlemesi.
  @Published private(set) var draftPhoto: UIImage?
  /// Seçilen fotoğraf hazırlanıyor.
  @Published private(set) var isPreparingPhoto = false
  /// Panelde gösterilen kısa hata.
  @Published var photoError: String?
  /// Taslaktaki fotoğraf kayıtlı olandan farklı mı.
  private var isPhotoChanged = false
  /// `photo`'nun çözüldüğü veri (değişmediyse yeniden çözülmez).
  private var photoData: Data?
  private let coordinator: ProfileCoordinator
  private let userData: any UserDataStoring
  private let entitlements: any EntitlementProviding
  private let calendar: Calendar
  private var cancellables: Set<AnyCancellable> = []

  // MARK: - Init

  init(
    coordinator: ProfileCoordinator, userData: any UserDataStoring,
    entitlements: any EntitlementProviding, calendar: Calendar = .current
  ) {
    self.coordinator = coordinator
    self.userData = userData
    self.entitlements = entitlements
    self.calendar = calendar
    reload()
    beginEditing()
    userData.changes.merge(with: entitlements.changes)
      .sink { [weak self] in self?.reload() }
      .store(in: &cancellables)
  }

  // MARK: - Navigation

  /// Ayarları açar.
  func openSettings() { coordinator.showSettings() }
  /// Geri gider.
  func back() { coordinator.back() }

  // MARK: - Profile

  /// Gösterilen unvan: açılmış unvanların en yükseği (unvan seçimi yok).
  var title: UserTitle {
    UserTitle.allCases.last(where: isUnlocked) ?? .kalemci
  }

  /// Panelde önizlenen ad: taslak boşsa kayıtlı ad.
  var draftDisplayName: String {
    let trimmed = draftNickname.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? profile.displayName : trimmed
  }

  /// "Ekim 2026'dan beri".
  var memberSinceText: String {
    ProfileDateText.since(profile.createdAt, calendar: calendar)
  }

  /// Seviye kartı.
  var levelProgress: LevelProgress {
    LevelProgress(
      levelId: profile.level, wordsSeen: stats.wordsSeen, learnedWords: snapshot.learnedWords)
  }

  /// "5/16".
  var nicknameCounter: String { "\(draftNickname.count)/\(Self.nicknameLimit)" }

  /// Takma adı sınıra göre kırpar.
  func limitNickname() {
    guard draftNickname.count > Self.nicknameLimit else { return }
    draftNickname = String(draftNickname.prefix(Self.nicknameLimit))
  }

  /// Unvanın açık olup olmadığı.
  func isUnlocked(_ title: UserTitle) -> Bool {
    title.isUnlocked(badges: Set(badges.keys), snapshot: snapshot)
  }

  // MARK: - Editing

  /// Taslağı kayıtlı profille başlatır (düzenleme paneli açılırken).
  func beginEditing() {
    draftNickname = profile.nickname
    draftPhotoData = photoData
    draftPhoto = photo
    isPhotoChanged = false
    isPreparingPhoto = false
    photoError = nil
  }

  /// Seçilen ham fotoğrafı arka planda küçültüp taslağa koyar.
  func pickPhoto(_ data: Data) async {
    isPreparingPhoto = true
    defer { isPreparingPhoto = false }
    guard let prepared = await ProfilePhoto.normalized(data),
      let image = UIImage(data: prepared)
    else {
      photoError = "Bu fotoğraf açılamadı. Başka bir fotoğraf seç."
      return
    }
    draftPhotoData = prepared
    draftPhoto = image
    isPhotoChanged = true
    photoError = nil
  }

  /// Fotoğraf seçici veriyi okuyamadığında hatayı gösterir.
  func photoLoadFailed() {
    photoError = "Bu fotoğraf açılamadı. Başka bir fotoğraf seç."
  }

  /// Taslaktaki fotoğrafı kaldırır (avatar maskota döner).
  func removeDraftPhoto() {
    draftPhotoData = nil
    draftPhoto = nil
    isPhotoChanged = true
  }

  /// Taslaktaki takma adı ve fotoğrafı kaydeder.
  ///
  /// Boş takma ad kayıtlı adı korur; kayıtlı ad da boşsa "User" + 6 rakam verilir.
  func saveDraft() {
    var updated = profile
    updated.nickname = Self.resolveNickname(draftNickname, current: profile.nickname)
    if updated != profile { userData.updateProfile(updated) }
    if isPhotoChanged { userData.setProfilePhoto(draftPhotoData) }
    isPhotoChanged = false
  }

  /// Taslak takma adı kırpar; boşsa kayıtlı adı, o da boşsa "User" + 6 rakamı döner.
  static func resolveNickname(
    _ draft: String, current: String, makeDefault: () -> String = makeDefaultNickname
  ) -> String {
    let trimmed = String(draft.prefix(nicknameLimit)).trimmingCharacters(
      in: .whitespacesAndNewlines)
    if !trimmed.isEmpty { return trimmed }
    let saved = current.trimmingCharacters(in: .whitespacesAndNewlines)
    return saved.isEmpty ? makeDefault() : saved
  }

  /// Rastgele varsayılan takma ad: "User" + 6 rakam (onboarding kuralı).
  nonisolated static func makeDefaultNickname() -> String {
    "User\(Int.random(in: 100_000...999_999))"
  }

  // MARK: - Badges

  /// Tüm rozetler: kazanılanlar, ardından hedefe en yakın olanlar.
  var badgeItems: [BadgeItem] { BadgeItem.all(badges: badges, snapshot: snapshot) }

  /// "7/15".
  var badgeCountText: String { "\(badges.count)/\(BadgeKind.allCases.count)" }

  /// Kazanılan rozetlerin oranı (0...1).
  var badgeProgress: Double {
    Double(badges.count) / Double(max(BadgeKind.allCases.count, 1))
  }

  /// Rozetin tarih metni ("3 Kas").
  func dateText(_ item: BadgeItem) -> String {
    item.earnedAt.map(DateText.dayMonthShort) ?? ""
  }

  // MARK: - Private helpers

  /// Kayıtlı veriyi yeniden okur.
  private func reload() {
    profile = userData.profile ?? profile
    let storedPhoto = userData.profilePhoto
    if storedPhoto != photoData {
      photoData = storedPhoto
      photo = storedPhoto.flatMap(UIImage.init(data:))
    }
    stats = userData.stats
    badges = userData.badges
    let finished = userData.allProgress().values.filter { $0.status == .finished }.map(\.puzzleId)
    snapshot = AchievementSnapshot(
      stats: stats, finishedPuzzleIds: finished,
      learnedWords: userData.notebook.filter(\.learned).count)
    isPremium = entitlements.isPremium
  }
}
