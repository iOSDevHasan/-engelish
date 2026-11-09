import ContentKit
import Foundation
import Testing
import UserDataKit
import WordKit
@testable import NotebookModule

@Suite("NotebookViewModel")
@MainActor
struct NotebookViewModelTests {

  @Test("Tekrar oturumu bugünkü kelimelerle başlar ve cevaplandıkça biter")
  func reviewFlow() async {
    let store = UserDataStore(inMemory: true)
    store.addToNotebook(wordId: "w_house")
    let sut = NotebookViewModel(
      content: ContentStub(), userData: store, pronouncer: SilentPronouncer())
    await sut.load()
    #expect(sut.dueCount == 1)
    sut.startReview()
    #expect(sut.isReviewing)
    sut.answer(knew: true)
    #expect(!sut.isReviewing)
    #expect(store.notebook.first?.box == 2)
  }
}

private struct ContentStub: ContentProviding {
  func packs() async -> [Pack] { [] }
  func pack(id: String) async -> Pack? { nil }
  func puzzle(id: String) async -> Puzzle? { nil }
  func puzzles(inPack packId: String) async -> [Puzzle] { [] }
  func words(ids: [String]) async -> [Word] {
    ids.map {
      Word(
        id: $0, en: "house", level: .a1, pos: "noun", clue: "Ev", meaning: "ev", ipa: "/haʊs/",
        example: "A house.")
    }
  }
  func dailyPuzzle(for date: Date) async -> Puzzle? { nil }
  func refreshFromRemote(entitledPackIds: Set<String>) async {}
}

@MainActor
private final class SilentPronouncer: Pronouncing {
  func speak(_ text: String, language: String) {}
}
