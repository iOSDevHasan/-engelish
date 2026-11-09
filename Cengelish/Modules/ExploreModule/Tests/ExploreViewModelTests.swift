import Testing
@testable import ExploreModule

struct ExploreViewModelTests {

  @Test("Paket kartının ilerleme oranı çözülen / toplam bulmacadır")
  func progressRatio() {
    let pack = ContentFixture.pack
    let card = PackCard(pack: pack, solved: 3, isLocked: false)
    #expect(card.progress == 0.25)
  }
}
