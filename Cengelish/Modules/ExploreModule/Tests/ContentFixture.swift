import Combine
import ContentKit
import Foundation
import PaywallModuleInterface
import PurchaseKit
import PuzzleModuleInterface
import RouterKitInterface
import SwiftUI
import WordKit

/// Testler için örnek içerik: seviye, sınav ve tema paketleri.
enum ContentFixture {
  /// Kısmen ücretsiz seviye paketi.
  static let pack = Pack(
    id: "a1", title: "A1 · Başlangıç", subtitle: "Renkler, sayılar, aile", kind: .level,
    level: .a1, order: 0, freeCount: 4, productId: nil, puzzleIds: (1...12).map { "a1_\($0)" },
    wordCount: 40)

  /// Tüm paketler (bulmacası olmayan `c1` gizlenmeli).
  static let packs: [Pack] = [
    pack,
    makePack("b1", "B1 · Orta", "Duygular, iş, toplum", .level, .b1, free: 0, count: 6),
    makePack("c1", "C1 · İleri", "Akademik", .level, .c1, free: 0, count: 0),
    makePack(
      "yds", "YDS Kelime Paketi", "YDS'de sık çıkan akademik kelimeler", .exam, .c1, free: 0,
      count: 4, productId: ProductID.packYDS),
    makePack(
      "lgs", "LGS Kelime Paketi", "8. sınıf kelimeleri", .exam, .b1, free: 0, count: 3,
      productId: ProductID.packLGS),
    makePack("mutfak", "Mutfak", "Yemek ve tarifler", .theme, .a2, free: 3, count: 3),
    makePack("teknoloji", "Teknoloji", "Bilgisayar ve internet", .theme, .b1, free: 0, count: 3),
    makePack("seyahat", "Seyahat", "Havalimanı, otel", .theme, .a2, free: 2, count: 2),
    makePack("is", "İş", "Ofis ve toplantı", .theme, .b1, free: 0, count: 2),
    makePack("futbol", "Futbol", "Maç ve takım", .theme, .a2, free: 0, count: 2),
    makePack("doga", "Doğa", "Orman ve deniz", .theme, .a2, free: 0, count: 2),
    makePack("uzay", "Uzay", "Gezegenler", .theme, .b1, free: 0, count: 2),
  ]

  /// Örnek kelimeler.
  static let words: [Word] = [
    makeWord("w_house", "house", "ev"),
    makeWord("w_job", "job", "iş"),
    makeWord("w_kitchen", "kitchen", "mutfak"),
    makeWord("w_child", "child", "çocuk"),
    makeWord("w_whouse", "warehouse", "depo"),
  ]

  /// Bulmaca seviyeleri: YDS B2 ve C1 karışık, LGS tek seviye.
  static func puzzles(inPack packId: String) -> [Puzzle] {
    guard let pack = packs.first(where: { $0.id == packId }) else { return [] }
    return pack.puzzleIds.enumerated().map { index, id in
      let level: CEFRLevel = packId == "yds" ? (index.isMultiple(of: 2) ? .b2 : .c1) : pack.level
      let word = words[index % words.count]
      let entry = PuzzleEntry(
        wordId: word.id, answer: word.en.uppercased(), clue: word.clue, row: 0, col: 1,
        dir: .across, clueRow: 0, clueCol: 0)
      return Puzzle(
        id: id, packId: packId, kind: .pack, level: level, width: 10, height: 1, entries: [entry])
    }
  }

  private static func makePack(
    _ id: String, _ title: String, _ subtitle: String, _ kind: PackKind, _ level: CEFRLevel,
    free: Int, count: Int, productId: String? = nil
  ) -> Pack {
    Pack(
      id: id, title: title, subtitle: subtitle, kind: kind, level: level, order: 0,
      freeCount: free, productId: productId, puzzleIds: (0..<count).map { "\(id)_\($0 + 1)" },
      wordCount: count * 10)
  }

  private static func makeWord(_ id: String, _ en: String, _ meaning: String) -> Word {
    Word(
      id: id, en: en, level: .a1, pos: "noun", clue: meaning, meaning: meaning, ipa: "/x/",
      example: "Example.")
  }
}

// MARK: - Stubs

/// İçerik servisinin sahte uygulaması.
struct ContentStub: ContentProviding {
  func packs() async -> [Pack] { ContentFixture.packs }
  func pack(id: String) async -> Pack? { ContentFixture.packs.first { $0.id == id } }
  func puzzle(id: String) async -> Puzzle? { nil }
  func puzzles(inPack packId: String) async -> [Puzzle] { ContentFixture.puzzles(inPack: packId) }
  func words(ids: [String]) async -> [Word] {
    ids.compactMap { id in ContentFixture.words.first { $0.id == id } }
  }
  func dailyPuzzle(for date: Date) async -> Puzzle? { nil }
  func refreshFromRemote(entitledPackIds: Set<String>) async {}
}

/// Ayarlanabilir yetki servisi.
@MainActor
final class EntitlementStub: EntitlementProviding {
  var changes: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
  var isPremium = false
  var ownedProductIds: Set<String> = []
  var products: [StoreProduct] = []
  func loadProducts() async {}
  func purchase(_ productId: String) async -> PurchaseOutcome { .cancelled }
  func restore() async {}
}

/// Paywall'un hangi ürünle açıldığını kaydeder.
@MainActor
final class PaywallSpy: PaywallModuleInterface {
  private(set) var highlights: [String?] = []
  func createPaywallView(highlightProductId: String?) -> AnyView {
    highlights.append(highlightProductId)
    return AnyView(EmptyView())
  }
}

/// Bulmaca açılışlarını kaydeder.
@MainActor
final class PuzzleSpy: PuzzleModuleInterface {
  private(set) var opened: [String] = []
  func createPuzzleView(puzzleId: String) -> AnyView {
    opened.append(puzzleId)
    return AnyView(EmptyView())
  }
}

/// Sessiz telaffuz.
@MainActor
final class SilentPronouncer: Pronouncing {
  func speak(_ text: String, language: String) {}
}

/// Gezinme çağrılarını sayar.
@MainActor
final class NavSpy: Routing {
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
