import Combine
import ContentKit
import Foundation
import PurchaseKit
import UserDataKit

/// Keşfet ekranındaki paket kartı.
struct PackCard: Identifiable, Equatable {
  let pack: Pack
  let solved: Int
  let isLocked: Bool

  var id: String { pack.id }
  /// Tamamlanma oranı.
  var progress: Double { Double(solved) / Double(max(pack.puzzleIds.count, 1)) }
}

/// Henüz yayımlanmamış paketler (yakında).
struct UpcomingPack: Identifiable {
  let id: String
  let title: String
  let detail: String
}

/// Keşfet ekranının durumu.
@MainActor
final class ExploreViewModel: ObservableObject {

  // MARK: - Properties

  @Published private(set) var levels: [PackCard] = []
  @Published private(set) var exams: [PackCard] = []
  /// Yakında gelecek sınav paketleri.
  let upcomingExams = [
    UpcomingPack(id: "yokdil", title: "YÖKDİL", detail: "Akademik kelimeler · B2–C1"),
    UpcomingPack(id: "lgs", title: "LGS", detail: "8. sınıf kelimeleri · A2–B1"),
    UpcomingPack(id: "ielts", title: "IELTS", detail: "Band 6–7 kelimeleri · B2–C1"),
  ]
  /// Yakında gelecek tema paketleri.
  let upcomingThemes = [
    UpcomingPack(id: "mutfak", title: "Mutfak", detail: "Yemek ve tarifler"),
    UpcomingPack(id: "seyahat", title: "Seyahat", detail: "Havalimanı, otel, yol"),
    UpcomingPack(id: "futbol", title: "Futbol", detail: "Maç, takım, taraftar"),
  ]
  private let coordinator: ExploreCoordinator
  private let content: any ContentProviding
  private let userData: any UserDataStoring
  private let entitlements: any EntitlementProviding
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

  // MARK: - Intents

  /// Paketleri ve ilerlemeyi yükler.
  func load() async {
    let progress = userData.allProgress()
    let cards = await content.packs().map { pack in
      PackCard(
        pack: pack,
        solved: pack.puzzleIds.filter { progress[$0]?.status == .finished }.count,
        isLocked: pack.freeCount == 0 && !entitlements.canAccess(productId: pack.productId))
    }
    levels = cards.filter { $0.pack.kind == .level }
    exams = cards.filter { $0.pack.kind == .exam }
  }

  /// Paketi açar.
  func open(_ card: PackCard) {
    coordinator.showPack(card.pack.id)
  }
}
