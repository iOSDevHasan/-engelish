import Foundation

/// App Store Connect'te tanımlanacak ürün kimlikleri.
public enum ProductID {
  /// Çengelish+ aylık abonelik.
  public static let plusMonthly = "com.hasangurbuz.cengelish.plus.monthly"
  /// Çengelish+ yıllık abonelik (7 gün ücretsiz deneme).
  public static let plusYearly = "com.hasangurbuz.cengelish.plus.yearly"
  /// YDS paketi (tek seferlik).
  public static let packYDS = "com.hasangurbuz.cengelish.pack.yds"

  /// Abonelik ürünleri.
  public static let subscriptions: [String] = [plusYearly, plusMonthly]
  /// Tüm ürünler.
  public static let all: [String] = subscriptions + [packYDS]
}

/// Paywall'da gösterilen ürün bilgisi.
public struct StoreProduct: Identifiable, Equatable, Sendable {
  /// Ürün kimliği.
  public let id: String
  /// Ad.
  public let title: String
  /// Yerel para biriminde fiyat.
  public let displayPrice: String
  /// Aylık karşılığı (yıllık plan için).
  public let monthlyEquivalent: String?
  /// Ücretsiz deneme açıklaması.
  public let trialText: String?
  /// Abonelik mi.
  public let isSubscription: Bool

  /// Ürün bilgisini oluşturur.
  public init(
    id: String, title: String, displayPrice: String, monthlyEquivalent: String?,
    trialText: String?, isSubscription: Bool
  ) {
    self.id = id
    self.title = title
    self.displayPrice = displayPrice
    self.monthlyEquivalent = monthlyEquivalent
    self.trialText = trialText
    self.isSubscription = isSubscription
  }
}

/// Satın alma sonucu.
public enum PurchaseOutcome: Equatable, Sendable {
  case purchased
  case pending
  case cancelled
  case failed(String)
}
