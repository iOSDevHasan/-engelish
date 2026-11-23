import Combine
import CoreGraphics
import DesignKit
import Foundation
import ImageIO
import PurchaseKit
import Testing
import UniformTypeIdentifiers
import UserDataKit

@testable import ProfileModule

@MainActor
struct ProfileViewModelTests {

  /// Sabit (UTC) takvim.
  private static var utc: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
  }

  /// 2026 içinde verilen günün öğlesi.
  private static func date(month: Int = 11, day: Int, hour: Int = 12) -> Date {
    utc.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour)) ?? .now
  }

  private func makeViewModel(store: UserDataStore, premium: Bool = false) -> ProfileViewModel {
    let entitlements = EntitlementStub()
    entitlements.isPremium = premium
    return ProfileViewModel(
      coordinator: ProfileCoordinator(), userData: store, entitlements: entitlements,
      calendar: Self.utc)
  }

  // MARK: - Level progress

  @Test("Seviye: kalan = hedef - (görülen + öğrenilen), çubuk = çalışılan / hedef")
  func levelProgress() {
    let b1 = LevelProgress(levelId: "B1", wordsSeen: 800, learnedWords: 64)
    #expect(b1.practiced == 864)
    #expect(b1.target == 1_200)
    #expect(b1.remaining == 336)
    #expect(abs(b1.fraction - 0.72) < 0.0001)
    #expect(b1.headline == "B1 · Orta")
    #expect(b1.detail == "B2'ye 336 kelime")
  }

  @Test("Seviye: hedefe ulaşınca hazırsın, C1 en üst, bilinmeyen seviye A1 sayılır")
  func levelEdges() {
    #expect(LevelProgress(levelId: "A2", wordsSeen: 700, learnedWords: 0).detail == "B1'e hazırsın")
    #expect(LevelProgress(levelId: "A2", wordsSeen: 700, learnedWords: 0).fraction == 1)
    #expect(
      LevelProgress(levelId: "C1", wordsSeen: 120, learnedWords: 0).detail == "120/3000 kelime")
    #expect(LevelProgress(levelId: "x", wordsSeen: 0, learnedWords: 0).detail == "A2'ye 300 kelime")
  }

  // MARK: - Turkish text

  @Test("Yıl ekleri okunuşa göre seçilir")
  func ablative() {
    #expect(TurkishSuffix.ablative(2026) == "'dan")
    #expect(TurkishSuffix.ablative(2025) == "'ten")
    #expect(TurkishSuffix.ablative(2027) == "'den")
    #expect(TurkishSuffix.ablative(2030) == "'dan")
    #expect(TurkishSuffix.ablative(2040) == "'tan")
    #expect(
      ProfileDateText.since(Self.date(month: 10, day: 3), calendar: Self.utc)
        == "Ekim 2026'dan beri")
  }

  // MARK: - Profile

  @Test("Profil satırı: Türkçe ay, rozet sayısı, açılmış en yüksek unvan")
  func profileTexts() {
    let store = UserDataStore(inMemory: true, calendar: Self.utc)
    store.createProfile(
      UserProfile(
        nickname: "Deniz", avatar: AvatarConfig(), titleId: "kurt",
        createdAt: Self.date(month: 10, day: 5)))
    _ = store.finish(
      puzzleId: "a1_01", marks: ["e1": true], wordIdsByEntry: ["e1": "w_a"], isPremium: false,
      now: Self.date(day: 9))
    let viewModel = makeViewModel(store: store)
    #expect(viewModel.title == .yeniKalem)
    let count = store.badges.count
    #expect(count > 0)
    #expect(viewModel.memberSinceText == "Ekim 2026'dan beri")
    #expect(viewModel.badgeCountText == "\(count)/15")
  }

  @Test("Takma ad 16 karakterle sınırlanır ve sayaç gösterilir")
  func nicknameLimit() {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    let viewModel = makeViewModel(store: store)
    #expect(viewModel.nicknameCounter == "5/16")
    viewModel.beginEditing()
    viewModel.draftNickname = String(repeating: "a", count: 20)
    viewModel.limitNickname()
    #expect(viewModel.nicknameCounter == "16/16")
  }

  @Test("Düzenleme takma adı kırpar; boş ad kayıtlı adı korur, o da yoksa User + 6 rakam")
  func saveDraft() {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    let viewModel = makeViewModel(store: store)
    viewModel.beginEditing()
    #expect(viewModel.draftNickname == "Deniz")
    viewModel.draftNickname = "  Ada  "
    viewModel.saveDraft()
    #expect(store.profile?.nickname == "Ada")
    viewModel.beginEditing()
    viewModel.draftNickname = "   "
    #expect(viewModel.draftDisplayName == "Ada")
    viewModel.saveDraft()
    #expect(store.profile?.nickname == "Ada")
    #expect(
      ProfileViewModel.resolveNickname(" ", current: "", makeDefault: { "User123456" })
        == "User123456")
    let generated = ProfileViewModel.makeDefaultNickname()
    #expect(generated.hasPrefix("User") && generated.count == 10)
    #expect(Int(generated.dropFirst(4)) != nil)
  }

  @Test("Unvan, açılmış unvanların en yükseğidir")
  func automaticTitle() {
    let store = UserDataStore(inMemory: true, calendar: Self.utc)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig(), titleId: "usta"))
    #expect(makeViewModel(store: store).title == .yeniKalem)
    _ = store.finish(
      puzzleId: "a1_01", marks: ["e1": true], wordIdsByEntry: ["e1": "w_a"], isPremium: false,
      now: Self.date(day: 9, hour: 23))
    #expect(makeViewModel(store: store).title == .geceKusu)
  }

  // MARK: - Photo

  @Test("Seçilen fotoğraf küçültülür, Kaydet ile saklanır; Vazgeç kaydetmez")
  func photoDraft() async throws {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    let viewModel = makeViewModel(store: store)
    #expect(viewModel.photo == nil)
    viewModel.beginEditing()
    await viewModel.pickPhoto(try Self.png(width: 1_600, height: 1_200))
    let preview = try #require(viewModel.draftPhoto)
    #expect(max(preview.size.width * preview.scale, preview.size.height * preview.scale) == 512)
    #expect(store.profilePhoto == nil)
    viewModel.saveDraft()
    #expect(store.profilePhoto != nil)
    #expect(viewModel.photo != nil)

    viewModel.beginEditing()
    viewModel.removeDraftPhoto()
    #expect(viewModel.draftPhoto == nil)
    viewModel.beginEditing()
    #expect(viewModel.draftPhoto != nil)
    viewModel.removeDraftPhoto()
    viewModel.saveDraft()
    #expect(store.profilePhoto == nil)
    #expect(viewModel.photo == nil)
  }

  @Test("Okunamayan fotoğraf hata gösterir ve taslağı değiştirmez")
  func photoError() async {
    let store = UserDataStore(inMemory: true)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    let viewModel = makeViewModel(store: store)
    viewModel.beginEditing()
    await viewModel.pickPhoto(Data("foto değil".utf8))
    #expect(viewModel.photoError != nil)
    #expect(viewModel.draftPhoto == nil)
    #expect(!viewModel.isPreparingPhoto)
  }

  // MARK: - Badges

  @Test("Rozet: sayaçlı ilerleme metni, halka %93'te durur, kazanılan tam dolar")
  func badgeItem() {
    var stats = UserStats()
    stats.puzzlesSolved = 7
    let snapshot = AchievementSnapshot(stats: stats)
    let ten = BadgeItem.make(.puzzles10, earnedAt: nil, snapshot: snapshot)
    #expect(ten.progressText == "7/10")
    #expect(abs(ten.progress - 0.7) < 0.0001)
    #expect(!ten.isEarned)
    stats.puzzlesSolved = 10
    let full = BadgeItem.make(
      .puzzles10, earnedAt: nil, snapshot: AchievementSnapshot(stats: stats))
    #expect(full.ringFraction == BadgeItem.maxRingFraction)
    let earned = BadgeItem.make(.puzzles10, earnedAt: .now, snapshot: snapshot)
    #expect(earned.ringFraction == 1)
    let owl = BadgeItem.make(.nightOwl, earnedAt: nil, snapshot: snapshot)
    #expect(owl.counter == nil)
    #expect(owl.progress == 0)
    #expect(owl.progressText == "Tek bulmacada kazanılır")
    #expect(BadgeKind.allCases.allSatisfy { !$0.meaning.isEmpty })
  }

  @Test("Rozet sırası: kazanılanlar tarih sırasıyla, sonra hedefe en yakınlar, anlıklar sonda")
  func badgeOrder() {
    var stats = UserStats()
    stats.puzzlesSolved = 1
    stats.longestStreak = 6
    let earnedAt: [BadgeKind: Date] = [
      .speed: Self.date(day: 2), .firstPuzzle: Self.date(day: 1),
    ]
    let items = BadgeItem.all(badges: earnedAt, snapshot: AchievementSnapshot(stats: stats))
    #expect(items.count == BadgeKind.allCases.count)
    #expect(items.prefix(2).map(\.kind) == [.firstPuzzle, .speed])
    #expect(items[2].kind == .streak7)
    #expect(items.last?.counter == nil)
  }

  @Test("Profil tüm rozetleri listeler; sayaç ve ilerleme kazanılanlardan hesaplanır")
  func allBadgesListed() {
    let store = UserDataStore(inMemory: true, calendar: Self.utc)
    store.createProfile(UserProfile(nickname: "Deniz", avatar: AvatarConfig()))
    let empty = makeViewModel(store: store)
    #expect(empty.badgeItems.count == BadgeKind.allCases.count)
    #expect(empty.badgeProgress == 0)
    #expect(empty.badgeCountText == "0/\(BadgeKind.allCases.count)")
    _ = store.finish(
      puzzleId: "a1_01", marks: ["e1": true], wordIdsByEntry: ["e1": "w_a"], isPremium: false,
      now: Self.date(day: 9))
    let viewModel = makeViewModel(store: store)
    #expect(viewModel.badgeItems.count == BadgeKind.allCases.count)
    #expect(viewModel.badgeItems.first?.isEarned == true)
    #expect(viewModel.badgeProgress > 0)
    #expect(Set(viewModel.badgeItems.map(\.id)).count == viewModel.badgeItems.count)
  }
}

extension ProfileViewModelTests {
  /// Verilen boyutta düz renkli PNG üretir.
  fileprivate static func png(width: Int, height: Int) throws -> Data {
    let context = try #require(
      CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.setFillColor(CGColor(red: 1, green: 0.8, blue: 0.2, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let image = try #require(context.makeImage())
    let output = NSMutableData()
    let destination = try #require(
      CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(destination, image, nil)
    _ = CGImageDestinationFinalize(destination)
    return output as Data
  }
}

@MainActor
private final class EntitlementStub: EntitlementProviding {
  var changes: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
  var isPremium = false
  var ownedProductIds: Set<String> = []
  var products: [StoreProduct] = []
  func loadProducts() async {}
  func purchase(_ productId: String) async -> PurchaseOutcome { .cancelled }
  func restore() async {}
}
