import ContentKit
import Foundation
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

  @Test("Aksan IPA ve dil kodunu seçer")
  func accent() {
    let word = Word(
      id: "w_x", en: "tomato", level: .a1, pos: "noun", clue: "Domates", meaning: "domates",
      ipa: "/təˈmeɪ.toʊ/", example: "A tomato.", ipaUK: "/təˈmɑː.təʊ/")
    #expect(word.ipa(british: WordAccent.british.isBritish) == "/təˈmɑː.təʊ/")
    #expect(word.ipa(british: WordAccent.american.isBritish) == "/təˈmeɪ.toʊ/")
    #expect(WordAccent(languageCode: "en-GB") == .british)
    #expect(WordAccent.american.languageCode == "en-US")
  }

  @Test("Örnek cümlede kelime kalın yazılır")
  func highlight() {
    let text = WordDetailSheet.highlighted("Stress can make an Ulcer worse.", word: "ulcer")
    let bold = text.runs.filter { $0.inlinePresentationIntent == .stronglyEmphasized }
    #expect(bold.count == 1)
    #expect(String(text.characters).hasPrefix("“"))
  }
}
