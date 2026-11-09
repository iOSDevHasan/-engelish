import ContentKit
import DesignKit
import Foundation
import PencilKit
import UserDataKit
import WordKit

/// Bitiş ekranı: sonuç, yeni rozetler, kelime listesi ve paylaşım.
@MainActor
final class FinishViewModel: ObservableObject {

  // MARK: - Properties

  @Published private(set) var notebookIds: Set<String> = []
  /// Bulmaca durumu.
  let session: PuzzleSession
  /// Kayıt sonucu.
  let result: FinishResult
  /// Kullanıcının avatarı.
  let avatar: AvatarConfig
  /// Kullanıcının adı.
  let name: String
  /// Cevap anahtarındaki işaretler (kelime kimliği → doğru mu).
  let marks: [String: Bool]
  /// Bitiş anı.
  let finishedAt: Date
  private let coordinator: PuzzleCoordinator
  private let userData: any UserDataStoring
  private let pronouncer: any Pronouncing

  // MARK: - Init

  init(
    session: PuzzleSession, result: FinishResult, marks: [String: Bool],
    coordinator: PuzzleCoordinator, userData: any UserDataStoring, pronouncer: any Pronouncing,
    finishedAt: Date = .now
  ) {
    self.session = session
    self.result = result
    self.marks = marks
    self.finishedAt = finishedAt
    self.coordinator = coordinator
    self.userData = userData
    self.pronouncer = pronouncer
    self.avatar = userData.profile?.avatar ?? AvatarConfig()
    self.name = userData.profile?.displayName ?? "Kalemci"
    refreshNotebook()
  }

  // MARK: - Derived

  /// Bulmacadaki kelimeler, bulmacadaki sırayla.
  var words: [Word] {
    var seen = Set<String>()
    return session.puzzle.entries.compactMap { entry in
      guard seen.insert(entry.wordId).inserted else { return nil }
      return session.words[entry.wordId]
    }
  }

  /// Sonuç başlığı.
  var headline: String {
    switch result.stars {
    case 3: "Harika iş!"
    case 2: "Çok iyi!"
    default: "Bitti, aferin!"
    }
  }

  /// Süre metni.
  var durationText: String {
    String(format: "%d:%02d", session.durationSec / 60, session.durationSec % 60)
  }

  /// Sonraki bulmaca var mı.
  var hasNext: Bool { session.nextPuzzleId != nil }

  /// Paylaşım kartının verisi (cevaplar yok).
  var shareCard: ShareCard {
    ShareCard(
      layout: session.layout, title: session.title,
      owner: ShareText.owner(name: name, level: session.puzzle.level.rawValue), avatar: avatar,
      date: finishedAt, results: ShareText.results(entries: session.puzzle.entries, marks: marks),
      duration: durationText, correct: result.correct, total: result.total,
      streak: result.streak)
  }

  // MARK: - Intents

  /// Kelimeyi okur.
  func speak(_ word: Word) {
    pronouncer.speak(word.en, language: userData.settings.accent.languageCode)
  }

  /// Kelimeyi deftere ekler ya da çıkarır.
  func toggleNotebook(_ word: Word) {
    if notebookIds.contains(word.id) {
      userData.removeFromNotebook(wordId: word.id)
    } else {
      userData.addToNotebook(wordId: word.id, source: session.puzzle.id)
    }
    refreshNotebook()
  }

  /// Paylaş ekranını açar.
  func share() {
    coordinator.showShare(card: shareCard)
  }

  /// Sonraki bulmacayı açar.
  func next() {
    guard let id = session.nextPuzzleId else { return home() }
    coordinator.openNext(puzzleId: id)
  }

  /// Ana sayfaya döner.
  func home() {
    coordinator.home()
  }

  private func refreshNotebook() {
    notebookIds = Set(userData.notebook.map(\.wordId))
  }
}
