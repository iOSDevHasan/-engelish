import Testing

@testable import PurchaseKit

struct PurchaseKitTests {

  @Test("Ürün kimlikleri benzersizdir ve ömür boyu Plus listede önce gelir")
  func productIds() {
    #expect(Set(ProductID.all).count == ProductID.all.count)
    #expect(ProductID.all.first == ProductID.plusLifetime)
    #expect(ProductID.all.count == 1 + ProductID.examPacks.count)
  }

  @Test("Sınav paketi ürünleri sınav adına çevrilir")
  func examTitles() {
    #expect(ProductID.examPacks.compactMap(ProductID.examTitle(for:)).count == 5)
    #expect(ProductID.examTitle(for: ProductID.packYOKDIL) == "YÖKDİL")
    #expect(ProductID.examTitle(for: ProductID.plusLifetime) == nil)
  }

  @Test("Ürünlerin ekrandaki adı Çengelish Plus markasını kullanır")
  func displayTitles() {
    #expect(ProductID.displayTitle(for: ProductID.plusLifetime) == "Çengelish Plus Ömür Boyu")
    #expect(ProductID.displayTitle(for: ProductID.packLGS) == "LGS Paketi")
    #expect(ProductID.displayTitle(for: "bilinmeyen") == nil)
  }

  @Test("Sayısal fiyat isteğe bağlıdır")
  func storeProductPrice() {
    let product = StoreProduct(id: ProductID.plusLifetime, title: "", displayPrice: "999,99 ₺")
    #expect(product.price == nil)
  }
}
