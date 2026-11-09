import Combine
import ContentKit
import Foundation
import PurchaseKit
import UserDataKit

/// Paket detayındaki bulmaca karesi.
struct PuzzleTile: Identifiable, Equatable {
  enum State: Equatable {
    case done(stars: Int)
    case current
    case open
    case locked
  }

  let id: String
  let number: Int
  let state: State
}

/// Paket detay ekranının durumu.
@MainActor
final class PackViewModel: ObservableObject {

  // MARK: - Properties

  @Published private(set) var pack: Pack?
  @Published private(set) var tiles: [PuzzleTile] = []
  @Published private(set) var solved = 0
  /// Seviye aralığı ("B2–C1").
  @Published private(set) var levelRange = ""
  private let packId: String
  private let coordinator: ExploreCoordinator
  private let content: any ContentProviding
  private let userData: any UserDataStoring
  private let entitlements: any EntitlementProviding
  private var cancellables: Set<AnyCancellable> = []

  // MARK: - Init

  init(
    packId: String, coordinator: ExploreCoordinator, content: any ContentProviding,
    userData: any UserDataStoring, entitlements: any EntitlementProviding
  ) {
    self.packId = packId
    self.coordinator = coordinator
    self.content = content
    self.userData = userData
    self.entitlements = entitlements
    userData.changes.merge(with: entitlements.changes)
      .sink { [weak self] in Task { await self?.load() } }
      .store(in: &cancellables)
  }

  // MARK: - Intents

  /// Paketi ve kare durumlarını yükler.
  func load() async {
    guard let pack = await content.pack(id: packId) else { return }
    self.pack = pack
    let progress = userData.allProgress()
    if levelRange.isEmpty {
      let levels = await content.puzzles(inPack: pack.id).map(\.level)
      levelRange = PackRules.levelRange(for: pack, puzzleLevels: levels)
    }
    var foundCurrent = false
    tiles = pack.puzzleIds.enumerated().map { index, id in
      let state: PuzzleTile.State
      if let item = progress[id], item.status == .finished {
        state = .done(stars: item.stars)
      } else if PackRules.isPuzzleLocked(pack, index: index, entitlements: entitlements) {
        state = .locked
      } else if !foundCurrent {
        foundCurrent = true
        state = .current
      } else {
        state = .open
      }
      return PuzzleTile(id: id, number: index + 1, state: state)
    }
    solved = tiles.filter { if case .done = $0.state { true } else { false } }.count
  }

  /// Kareye dokununca bulmacayı ya da paywall'u açar.
  func open(_ tile: PuzzleTile) {
    if tile.state == .locked {
      coordinator.showPaywall(productId: pack.flatMap(PackRules.requiredProductId(for:)))
    } else {
      coordinator.showPuzzle(tile.id)
    }
  }

  /// Sıradaki bulmaca.
  var currentTile: PuzzleTile? {
    tiles.first { $0.state == .current } ?? tiles.first { $0.state == .locked }
  }

  /// Tamamlanma oranı.
  var progress: Double { Double(solved) / Double(max(tiles.count, 1)) }

  /// Paketin kilitli bulmacası var mı (üst barda "Premium" rozeti).
  var hasLockedTiles: Bool { tiles.contains { $0.state == .locked } }

  /// Başlık altındaki açıklama: "60 bulmaca · 1.200 kelime · B2–C1 · …".
  var summary: String {
    guard let pack else { return "" }
    let parts = [
      "\(TurkishText.number(pack.puzzleIds.count)) bulmaca",
      "\(TurkishText.number(pack.wordCount)) kelime", levelRange, pack.subtitle,
    ]
    return parts.filter { !$0.isEmpty }.joined(separator: " · ")
  }

  /// Alttaki ana buton metni.
  var primaryTitle: String? {
    guard let tile = currentTile else { return nil }
    return tile.state == .locked
      ? "Kilidi aç" : "Bulmaca \(TurkishText.accusative(tile.number)) çöz"
  }

  /// Geri gider.
  func back() {
    coordinator.back()
  }
}
