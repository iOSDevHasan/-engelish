import Combine
import ContentKit
import Foundation
import PurchaseKit
import UserDataKit

/// Keşfet ekranındaki paket kartı (seviye karesi, sınav kartı, tema karesi).
struct PackCard: Identifiable, Equatable {
  let pack: Pack
  let solved: Int
  let isLocked: Bool
  /// Seviye aralığı ("B2–C1").
  var levelRange: String = ""

  var id: String { pack.id }
  /// Paketteki bulmaca sayısı.
  var puzzleCount: Int { pack.puzzleIds.count }
  /// Tamamlanma oranı.
  var progress: Double { Double(solved) / Double(max(puzzleCount, 1)) }
  /// Tamamlanma yüzdesi (0–100).
  var percent: Int { Int((progress * 100).rounded()) }
  /// Kısa başlık ("YDS").
  var shortTitle: String { PackRules.shortTitle(for: pack) }
  /// Tema simgesi.
  var symbol: String { PackRules.themeSymbol(for: pack.id) }
}

/// Keşfet ekranındaki bölüm filtresi.
enum ExploreSegment: String, CaseIterable, Identifiable {
  case all = "Tümü"
  case levels = "Seviyeler"
  case exams = "Sınavlar"
  case themes = "Temalar"

  var id: String { rawValue }
}

/// Keşfet ekranının durumu.
@MainActor
final class ExploreViewModel: ObservableObject {

  // MARK: - Properties

  /// "Tümü" bölümünde gösterilen en fazla tema sayısı.
  static let themePreviewCount = 6

  @Published var segment: ExploreSegment = .all
  @Published private(set) var levels: [PackCard] = []
  @Published private(set) var exams: [PackCard] = []
  @Published private(set) var themes: [PackCard] = []
  /// Kullanıcının seviyesi ("B1"); profil yoksa nil.
  @Published private(set) var profileLevel: String?
  private let coordinator: ExploreCoordinator
  private let content: any ContentProviding
  private let userData: any UserDataStoring
  private let entitlements: any EntitlementProviding
  /// Paket kimliği → bulmacalardan türetilen seviye listesi (içerik değişmedikçe sabit).
  private var puzzleLevels: [String: [CEFRLevel]] = [:]
  private var cancellables: Set<AnyCancellable> = []

  // MARK: - Init

  init(
    coordinator: ExploreCoordinator, content: any ContentProviding, userData: any UserDataStoring,
    entitlements: any EntitlementProviding
  ) {
    self.coordinator = coordinator
    self.content = content
    self.userData = userData
    self.entitlements = entitlements
    userData.changes.merge(with: entitlements.changes)
      .sink { [weak self] in Task { await self?.load() } }
      .store(in: &cancellables)
  }

  // MARK: - Sections

  /// Seviyeler bölümü görünsün mü.
  var showsLevels: Bool { (segment == .all || segment == .levels) && !levels.isEmpty }
  /// Sınav paketleri bölümü görünsün mü.
  var showsExams: Bool { (segment == .all || segment == .exams) && !exams.isEmpty }
  /// Tema paketleri bölümü görünsün mü.
  var showsThemes: Bool { (segment == .all || segment == .themes) && !themes.isEmpty }
  /// Izgarada gösterilen temalar: "Tümü"de ilk altı, "Temalar"da hepsi.
  var visibleThemes: [PackCard] {
    segment == .all ? Array(themes.prefix(Self.themePreviewCount)) : themes
  }
  /// Hiçbir bölüm gösterilemiyor mu (içerik yok).
  var isEmpty: Bool { !showsLevels && !showsExams && !showsThemes }

  /// Seviye karesi kullanıcının seviyesi mi.
  func isCurrentLevel(_ card: PackCard) -> Bool {
    profileLevel == card.pack.level.rawValue
  }

  // MARK: - Intents

  /// Paketleri ve ilerlemeyi yükler. Bulmacası olmayan paketler gizlenir.
  func load() async {
    profileLevel = userData.profile?.level
    let progress = userData.allProgress()
    let packs = await content.packs().filter { !$0.puzzleIds.isEmpty }
    var cards: [PackCard] = []
    for pack in packs {
      let levels = await levels(of: pack)
      cards.append(
        PackCard(
          pack: pack,
          solved: pack.puzzleIds.filter { progress[$0]?.status == .finished }.count,
          isLocked: PackRules.isCardLocked(pack, entitlements: entitlements),
          levelRange: PackRules.levelRange(for: pack, puzzleLevels: levels)))
    }
    levels = cards.filter { $0.pack.kind == .level }
    exams = cards.filter { $0.pack.kind == .exam }
    themes = cards.filter { $0.pack.kind == .theme }
  }

  /// Paketi açar.
  func open(_ card: PackCard) {
    coordinator.showPack(card.pack.id)
  }

  /// Arama ekranını açar.
  func openSearch() {
    coordinator.showSearch()
  }

  /// Tüm tema paketleri listesini açar.
  func openAllThemes() {
    coordinator.showThemes(viewModel: self)
  }

  /// Tema listesinden geri döner.
  func back() {
    coordinator.back()
  }

  // MARK: - Helpers

  /// Paketin bulmaca seviyeleri; ilk okunuşta önbelleğe alınır.
  private func levels(of pack: Pack) async -> [CEFRLevel] {
    guard pack.kind != .level else { return [] }
    let key = "\(pack.id)#\(pack.contentVersion ?? 0)"
    if let cached = puzzleLevels[key] { return cached }
    let levels = await content.puzzles(inPack: pack.id).map(\.level)
    if !levels.isEmpty { puzzleLevels[key] = levels }
    return levels
  }
}
