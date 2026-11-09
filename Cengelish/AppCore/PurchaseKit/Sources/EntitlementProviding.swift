import Combine
import Foundation

/// Premium yetkilerinin okunduğu arayüz. Hesap gerekmez; yetkiler Apple Kimliğine bağlıdır.
@MainActor
public protocol EntitlementProviding: AnyObject {
  /// Yetkiler her değiştiğinde yayın yapar.
  var changes: AnyPublisher<Void, Never> { get }
  /// Çengelish+ aktif mi.
  var isPremium: Bool { get }
  /// Tek seferlik satın alınan paket ürünleri.
  var ownedProductIds: Set<String> { get }
  /// Paywall ürünleri (yüklenmediyse boş).
  var products: [StoreProduct] { get }
  /// Aktif Çengelish+ aboneliği (plan ve yenilenme tarihi); yoksa nil.
  var activeSubscription: ActiveSubscription? { get }
  /// Ürünleri App Store'dan yükler.
  func loadProducts() async
  /// Ürünü satın alır.
  func purchase(_ productId: String) async -> PurchaseOutcome
  /// Satın alımları geri yükler.
  func restore() async
}

extension EntitlementProviding {
  /// Varsayılan: abonelik bilgisi yok (önizleme ve test sahteleri için).
  public var activeSubscription: ActiveSubscription? { nil }

  /// Paketin açık olup olmadığı (premium ya da paket satın alınmış).
  public func canAccess(productId: String?) -> Bool {
    isPremium || productId.map { ownedProductIds.contains($0) } ?? false
  }
}
