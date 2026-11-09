import Testing
@testable import PurchaseKit

struct PurchaseKitTests {

  @Test("Ürün kimlikleri benzersizdir ve abonelikler listede önce gelir")
  func productIds() {
    #expect(Set(ProductID.all).count == ProductID.all.count)
    #expect(ProductID.all.first == ProductID.plusYearly)
  }

  @Test("Sınav paketi ürünleri sınav adına çevrilir")
  func examTitles() {
    #expect(ProductID.examPacks.compactMap(ProductID.examTitle(for:)).count == 5)
    #expect(ProductID.examTitle(for: ProductID.packYOKDIL) == "YÖKDİL")
    #expect(ProductID.examTitle(for: ProductID.plusYearly) == nil)
  }

  @Test("Abonelik özeti plan adını verir")
  func planTitle() {
    #expect(
      ActiveSubscription(productId: ProductID.plusYearly, renewalDate: nil).planTitle == "Yıllık")
    #expect(
      ActiveSubscription(productId: ProductID.plusMonthly, renewalDate: nil).planTitle == "Aylık")
  }
}
