import Foundation

/// App Store Connect'te tanımlanacak ürün kimlikleri.
public enum ProductID {
  /// Çengelish+ aylık abonelik.
  public static let plusMonthly = "com.hasangurbuz.cengelish.plus.monthly"
  /// Çengelish+ yıllık abonelik (7 gün ücretsiz deneme).
  public static let plusYearly = "com.hasangurbuz.cengelish.plus.yearly"
  /// YDS paketi (tek seferlik).
  public static let packYDS = "com.hasangurbuz.cengelish.pack.yds"
  /// YÖKDİL paketi (tek seferlik).
  public static let packYOKDIL = "com.hasangurbuz.cengelish.pack.yokdil"
  /// LGS paketi (tek seferlik).
  public static let packLGS = "com.hasangurbuz.cengelish.pack.lgs"
  /// IELTS paketi (tek seferlik).
  public static let packIELTS = "com.hasangurbuz.cengelish.pack.ielts"
  /// TOEFL paketi (tek seferlik).
  public static let packTOEFL = "com.hasangurbuz.cengelish.pack.toefl"

  /// Abonelik ürünleri.
  public static let subscriptions: [String] = [plusYearly, plusMonthly]
  /// Tek seferlik sınav paketleri.
  public static let examPacks: [String] = [packYDS, packYOKDIL, packLGS, packIELTS, packTOEFL]
  /// Tüm ürünler.
  public static let all: [String] = subscriptions + examPacks

  /// Sınav paketi ürününün ekranda görünen sınav adı (YDS, YÖKDİL...); sınav paketi değilse nil.
  public static func examTitle(for productId: String) -> String? {
    switch productId {
    case packYDS: "YDS"
    case packYOKDIL: "YÖKDİL"
    case packLGS: "LGS"
    case packIELTS: "IELTS"
    case packTOEFL: "TOEFL"
    default: nil
    }
  }
}

/// Aktif Çengelish+ aboneliğinin özeti.
public struct ActiveSubscription: Equatable, Sendable {
  /// Abonelik ürün kimliği (`ProductID.plusYearly` / `plusMonthly`).
  public let productId: String
  /// Sonraki yenilenme (ya da yenilenmeyecekse bitiş) tarihi.
  public let renewalDate: Date?
  /// Dönem sonunda otomatik yenilenecek mi.
  public let willAutoRenew: Bool

  /// Abonelik özetini oluşturur.
  public init(productId: String, renewalDate: Date?, willAutoRenew: Bool = true) {
    self.productId = productId
    self.renewalDate = renewalDate
    self.willAutoRenew = willAutoRenew
  }

  /// Planın Türkçe adı ("Yıllık" / "Aylık").
  public var planTitle: String { productId == ProductID.plusYearly ? "Yıllık" : "Aylık" }
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
