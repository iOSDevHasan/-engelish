import Combine
import ContentKit
import DesignKit
import Foundation
import PurchaseKit
import UserDataKit

/// Paket detayındaki bulmaca karesi.
struct PuzzleTile: Identifiable, Equatable {
  let id: String
  let number: Int
  let access: PuzzleAccess
}

/// Sıra kilitli bulmacaya dokununca gösterilen kısa uyarı.
struct SequenceNudge: Equatable {
  /// Sallanan karenin kimliği.
  let tileId: String
  /// Gösterilen mesaj ("Önce 3. bulmacayı bitir").
  let message: String
  /// Her dokunuşta artan sayaç (uyarının yeniden gösterilmesi ve titreşim için).
  let serial: Int
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
  /// Ekranda gösterilen sıra uyarısı.
  @Published private(set) var nudge: SequenceNudge?
  /// Kare kimliği → sallanma sayısı (her uyarıda artar, kare bir kez sallanır).
  @Published private(set) var shakes: [String: Int] = [:]
  private let packId: String
  private let coordinator: ExploreCoordinator
  private let content: any ContentProviding
  private let userData: any UserDataStoring
  private let entitlements: any EntitlementProviding
  private var nudgeSerial = 0
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

  // MARK: - State

  /// Sıradaki (ilk bitmemiş) bulmaca; hepsi bittiyse nil.
  var nextTile: PuzzleTile? {
    tiles.first { !$0.access.isFinished }
  }

  /// Tamamlanma oranı.
  var progress: Double { Double(solved) / Double(max(tiles.count, 1)) }

  /// Tamamlanma yüzdesi (0–100).
  var percent: Int { Int((progress * 100).rounded()) }

  /// Plus isteyen bulmaca sayısı.
  var plusLockedCount: Int { tiles.filter(\.access.showsPlusBadge).count }

  /// Paketin Plus isteyen bulmacası var mı (üst barda Plus rozeti ve tanıtım kartı).
  var hasPlusLockedTiles: Bool { plusLockedCount > 0 }

  /// Ana buton paywall'u mu açıyor (sıradaki bulmaca Plus istiyor).
  var primaryNeedsPlus: Bool { nextTile?.access == .needsPlus }

  /// Alttaki ana buton metni; paket bittiyse nil.
  var primaryTitle: String? {
    guard let tile = nextTile else { return nil }
    return tile.access == .needsPlus
      ? "Kilidi aç" : "Bulmaca \(TurkishText.accusative(tile.number)) çöz"
  }

  /// Başlık altındaki açıklama: "60 bulmaca · 1.200 kelime · B2–C1 · …".
  var summary: String {
    guard let pack else { return "" }
    let parts = [
      "\(TurkishText.number(pack.puzzleIds.count)) bulmaca",
      "\(TurkishText.number(pack.wordCount)) kelime", levelRange, pack.subtitle,
    ]
    return parts.filter { !$0.isEmpty }.joined(separator: " · ")
  }

  /// Plus tanıtım kartının başlığı.
  var promoTitle: String {
    pack?.kind == .exam ? "Paketin kilidini aç" : "Tüm bulmacaları aç"
  }

  /// Plus tanıtım kartının alt metni.
  var promoSubtitle: String {
    if pack?.kind == .exam {
      return "Paketi bir kez satın al ya da \(PlusBrand.name) ile tüm sınavlara eriş."
    }
    return "\(plusLockedCount) bulmaca daha \(PlusBrand.name) ile açılır."
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
    let stars: [Int?] = pack.puzzleIds.map { id in
      guard let item = progress[id], item.status == .finished else { return nil }
      return item.stars
    }
    let plusLocked = pack.puzzleIds.indices.map {
      PackRules.isPuzzlePlusLocked(pack, index: $0, entitlements: entitlements)
    }
    let access = PackRules.access(stars: stars, plusLocked: plusLocked)
    tiles = zip(pack.puzzleIds, access).enumerated().map { index, item in
      PuzzleTile(id: item.0, number: index + 1, access: item.1)
    }
    solved = tiles.filter(\.access.isFinished).count
  }

  /// Kareye dokununca bulmacayı ya da paywall'u açar; sıra kilitliyse uyarı gösterir.
  func open(_ tile: PuzzleTile) {
    switch tile.access {
    case .finished, .next:
      coordinator.showPuzzle(tile.id)
    case .needsPlus:
      openPaywall()
    case .needsPrevious(let blocker, _):
      nudgeSerial += 1
      shakes[tile.id, default: 0] += 1
      nudge = SequenceNudge(
        tileId: tile.id, message: PackRules.sequenceMessage(blocker: blocker),
        serial: nudgeSerial)
    }
  }

  /// Ana butona basınca sıradaki bulmacayı ya da paywall'u açar.
  func openNext() {
    guard let tile = nextTile else { return }
    open(tile)
  }

  /// Paywall'u paketin ürünüyle (seviye/temada ürünsüz) açar.
  func openPaywall() {
    coordinator.showPaywall(productId: pack.flatMap(PackRules.requiredProductId(for:)))
  }

  /// Süresi dolan uyarıyı kaldırır (arada yeni uyarı geldiyse dokunmaz).
  func dismissNudge(serial: Int) {
    guard nudge?.serial == serial else { return }
    nudge = nil
  }

  /// Geri gider.
  func back() {
    coordinator.back()
  }
}
