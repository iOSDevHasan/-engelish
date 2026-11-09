import Combine
import ContentKit
import Foundation
import PurchaseKit
import UserDataKit
import WordKit

/// Arama dizinindeki tek kelime: normalleştirilmiş İngilizce ve Türkçe anahtarlar.
struct WordIndexEntry: Identifiable, Equatable {
  let word: Word
  let enKey: String
  let meaningKey: String

  var id: String { word.id }

  /// Kelimeden dizin kaydı oluşturur.
  init(word: Word) {
    self.word = word
    enKey = TurkishText.searchKey(word.en)
    meaningKey = TurkishText.searchKey(word.meaning)
  }
}

/// Keşfet araması: paket (başlık/açıklama) ve kelime (İngilizce/Türkçe anlam) arar.
@MainActor
final class SearchViewModel: ObservableObject {

  // MARK: - Properties

  /// Gösterilen en fazla kelime sonucu.
  static let wordLimit = 60

  @Published var query = ""
  /// Detay panelinde açık kelime.
  @Published var selectedWord: Word?
  @Published private(set) var packs: [PackCard] = []
  @Published private(set) var index: [WordIndexEntry] = []
  @Published private(set) var isLoading = false
  private let coordinator: ExploreCoordinator
  private let content: any ContentProviding
  private let userData: any UserDataStoring
  private let entitlements: any EntitlementProviding
  private let pronouncer: any Pronouncing
  private var cancellables: Set<AnyCancellable> = []

  // MARK: - Init

  init(
    coordinator: ExploreCoordinator, content: any ContentProviding, userData: any UserDataStoring,
    entitlements: any EntitlementProviding, pronouncer: any Pronouncing
  ) {
    self.coordinator = coordinator
    self.content = content
    self.userData = userData
    self.entitlements = entitlements
    self.pronouncer = pronouncer
    userData.changes.merge(with: entitlements.changes)
      .sink { [weak self] in self?.objectWillChange.send() }
      .store(in: &cancellables)
  }

  // MARK: - Results

  /// Normalleştirilmiş arama metni.
  private var key: String { TurkishText.searchKey(query) }

  /// Arama metni boş mu.
  var isQueryEmpty: Bool { key.isEmpty }

  /// Başlığı ya da açıklaması eşleşen paketler.
  var packResults: [PackCard] {
    let key = key
    guard !key.isEmpty else { return [] }
    return packs.filter {
      TurkishText.searchKey($0.pack.title).contains(key)
        || TurkishText.searchKey($0.pack.subtitle).contains(key)
    }
  }

  /// İngilizcesi ya da Türkçe anlamı eşleşen kelimeler; önce baştan eşleşenler.
  var wordResults: [Word] {
    let key = key
    guard !key.isEmpty else { return [] }
    let ranked: [(rank: Int, entry: WordIndexEntry)] = index.compactMap { entry in
      if entry.enKey == key { return (0, entry) }
      if entry.enKey.hasPrefix(key) { return (1, entry) }
      if entry.meaningKey.hasPrefix(key) { return (2, entry) }
      if entry.enKey.contains(key) { return (3, entry) }
      if entry.meaningKey.contains(key) { return (4, entry) }
      return nil
    }
    return
      ranked
      .sorted { ($0.rank, $0.entry.enKey) < ($1.rank, $1.entry.enKey) }
      .prefix(Self.wordLimit)
      .map(\.entry.word)
  }

  /// Hiç sonuç yok mu.
  var hasNoResults: Bool { !isQueryEmpty && packResults.isEmpty && wordResults.isEmpty }

  /// Kelime defterde mi.
  func isInNotebook(_ word: Word) -> Bool {
    userData.notebook.contains { $0.wordId == word.id }
  }

  // MARK: - Intents

  /// Paketleri ve kelime dizinini yükler (bulmacası olan paketlerin kelimeleri).
  func load() async {
    guard index.isEmpty else { return }
    isLoading = true
    defer { isLoading = false }
    let allPacks = await content.packs().filter { !$0.puzzleIds.isEmpty }
    packs = allPacks.map {
      PackCard(
        pack: $0, solved: 0, isLocked: PackRules.isCardLocked($0, entitlements: entitlements))
    }
    var seen: Set<String> = []
    var wordIds: [String] = []
    for pack in allPacks {
      for puzzle in await content.puzzles(inPack: pack.id) {
        for id in puzzle.wordIds where seen.insert(id).inserted {
          wordIds.append(id)
        }
      }
    }
    index = await content.words(ids: wordIds).map(WordIndexEntry.init(word:))
  }

  /// Paketi açar.
  func open(_ card: PackCard) {
    coordinator.showPack(card.pack.id)
  }

  /// Kelime detay panelini açar.
  func select(_ word: Word) {
    selectedWord = word
  }

  /// Kelimeyi sesli okur.
  func speak(_ word: Word) {
    pronouncer.speak(word.en, language: userData.settings.accent.languageCode)
  }

  /// Kelimeyi deftere ekler ve paneli kapatır.
  func addToNotebook(_ word: Word) {
    userData.addToNotebook(wordId: word.id, source: "manual")
    selectedWord = nil
  }

  /// Geri gider.
  func back() {
    coordinator.back()
  }
}
