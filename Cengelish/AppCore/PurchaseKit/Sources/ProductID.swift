import Foundation

/// App Store Connect'te tanımlanacak ürün kimlikleri. Hepsi tek seferlik (non-consumable);
/// uygulamada abonelik yoktur.
public enum ProductID {
  /// Plus'ın marka adı.
  public static let plusName = "Çengelish Plus"
  /// Çengelish Plus ömür boyu erişim (tek seferlik): tüm bulmacalar ve sınav paketleri.
  public static let plusLifetime = "com.hasangurbuz.cengelish.plus.lifetime"
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

  /// Tek seferlik sınav paketleri.
  public static let examPacks: [String] = [packYDS, packYOKDIL, packLGS, packIELTS, packTOEFL]
  /// Tüm ürünler (önce Plus, sonra sınav paketleri).
  public static let all: [String] = [plusLifetime] + examPacks

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

  /// Ürünün ekranda görünen tam adı ("Çengelish Plus Ömür Boyu", "YDS Paketi"); bilinmiyorsa nil.
  public static func displayTitle(for productId: String) -> String? {
    switch productId {
    case plusLifetime: "\(plusName) Ömür Boyu"
    default: examTitle(for: productId).map { "\($0) Paketi" }
    }
  }
}

/// Paywall'da gösterilen ürün bilgisi.
public struct StoreProduct: Identifiable, Equatable, Sendable {
  /// Ürün kimliği.
  public let id: String
  /// Ad.
  public let title: String
  /// Yerel para biriminde fiyat.
  public let displayPrice: String
  /// Sayısal fiyat (lansman fiyatı karşılaştırması için); bilinmiyorsa nil.
  public let price: Decimal?
  /// Fiyatın para birimi ("TRY"); bilinmiyorsa nil.
  public let currencyCode: String?

  /// Ürün bilgisini oluşturur.
  public init(
    id: String, title: String, displayPrice: String, price: Decimal? = nil,
    currencyCode: String? = nil
  ) {
    self.id = id
    self.title = title
    self.displayPrice = displayPrice
    self.price = price
    self.currencyCode = currencyCode
  }
}

/// Satın alma sonucu.
public enum PurchaseOutcome: Equatable, Sendable {
  case purchased
  case pending
  case cancelled
  case failed(String)
}
