import Testing
@testable import PurchaseKit

struct PurchaseKitTests {

  @Test("Ürün kimlikleri benzersizdir ve abonelikler listede önce gelir")
  func productIds() {
    #expect(Set(ProductID.all).count == ProductID.all.count)
    #expect(ProductID.all.first == ProductID.plusYearly)
  }
}
