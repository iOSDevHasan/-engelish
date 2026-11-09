import ContentKit
import Testing
@testable import WordKit

struct WordKitTests {

  @Test("Sözcük türü Türkçe kısaltmaya çevrilir")
  func posTitle() {
    let word = Word(
      id: "w_x", en: "run", level: .a1, pos: "verb", clue: "Koşmak", meaning: "koşmak",
      ipa: "/rʌn/", example: "I run.")
    #expect(word.posTitle == "fiil")
  }
}
