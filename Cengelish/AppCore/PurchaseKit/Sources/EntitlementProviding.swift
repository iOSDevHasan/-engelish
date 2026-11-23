import Combine
import Foundation

/// Çengelish Plus ve paket yetkilerinin okunduğu arayüz. Hesap gerekmez; yetkiler Apple
/// Kimliğine bağlıdır. Tüm ürünler tek seferliktir (abonelik yok).
@MainActor
public protocol EntitlementProviding: AnyObject {
  /// Yetkiler her değiştiğinde yayın yapar.
  var changes: AnyPublisher<Void, Never> { get }
  /// Çengelish Plus (ömür boyu) satın alınmış mı.
  var isPremium: Bool { get }
  /// Tek seferlik satın alınan paket ürünleri.
  var ownedProductIds: Set<String> { get }
  /// Paywall ürünleri (yüklenmediyse boş).
  var products: [StoreProduct] { get }
  /// Çengelish Plus'ın satın alındığı tarih; bilinmiyorsa ya da Plus yoksa nil.
  var plusPurchaseDate: Date? { get }
  /// Ürünleri App Store'dan yükler.
  func loadProducts() async
  /// Ürünü satın alır.
  func purchase(_ productId: String) async -> PurchaseOutcome
  /// Satın alımları geri yükler.
  func restore() async
}

extension EntitlementProviding {
  /// Varsayılan: satın alma tarihi yok (önizleme ve test sahteleri için).
  public var plusPurchaseDate: Date? { nil }

  /// Paketin açık olup olmadığı (Çengelish Plus alınmış ya da paket satın alınmış).
  public func canAccess(productId: String?) -> Bool {
    isPremium || productId.map { ownedProductIds.contains($0) } ?? false
  }
}
