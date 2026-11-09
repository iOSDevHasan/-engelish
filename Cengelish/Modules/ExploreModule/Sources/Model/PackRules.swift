import ContentKit
import Foundation
import PurchaseKit

/// Paket kilidi, seviye aralığı ve tema simgesi kuralları (görünümden bağımsız, test edilebilir).
enum PackRules {

  // MARK: - Access

  /// Paketin tamamını açan ürün: sınavlarda paketin ürünü, seviye/temada yalnızca Çengelish+.
  static func requiredProductId(for pack: Pack) -> String? {
    pack.kind == .exam ? pack.productId : nil
  }

  /// Kullanıcı paketin tüm bulmacalarına erişebiliyor mu.
  @MainActor
  static func canAccessAll(_ pack: Pack, entitlements: any EntitlementProviding) -> Bool {
    entitlements.canAccess(productId: requiredProductId(for: pack))
  }

  /// Verilen sıradaki bulmaca kilitli mi (ücretsiz değil ve erişim yok).
  @MainActor
  static func isPuzzleLocked(
    _ pack: Pack, index: Int, entitlements: any EntitlementProviding
  ) -> Bool {
    !pack.isFree(index: index) && !canAccessAll(pack, entitlements: entitlements)
  }

  /// Keşfet kartında kilit gösterilsin mi. Sınav kartı erişim yoksa hep kilitli görünür;
  /// seviye ve tema kartı ise hiç ücretsiz bulmacası yoksa.
  @MainActor
  static func isCardLocked(_ pack: Pack, entitlements: any EntitlementProviding) -> Bool {
    let canAccess = canAccessAll(pack, entitlements: entitlements)
    return pack.kind == .exam ? !canAccess : pack.freeCount == 0 && !canAccess
  }

  // MARK: - Level range

  /// İçerikten türetilemediğinde kullanılan sınav seviye aralıkları.
  static let knownRanges: [String: String] = [
    "yds": "B2–C1", "yokdil": "B2–C1", "lgs": "A2–B1", "ielts": "B1–C1", "toefl": "B1–C1",
  ]

  /// Paketin seviye aralığı ("B2–C1"). Seviye paketleri kendi seviyesini gösterir; diğerleri
  /// bulmacalarının seviyelerinden türetilir, türetilemezse bilinen aralık ya da paket seviyesi.
  static func levelRange(for pack: Pack, puzzleLevels: [CEFRLevel]) -> String {
    if pack.kind == .level { return pack.level.rawValue }
    if let low = puzzleLevels.min(), let high = puzzleLevels.max(), low != high {
      return "\(low.rawValue)–\(high.rawValue)"
    }
    if let known = knownRanges[pack.id] { return known }
    return (puzzleLevels.min() ?? pack.level).rawValue
  }

  // MARK: - Theme symbol

  /// Tema paketinin SF Symbol adı; bilinmeyen temalarda genel simge.
  static func themeSymbol(for packId: String) -> String {
    switch packId {
    case "mutfak": "fork.knife"
    case "seyahat": "airplane"
    case "is": "briefcase.fill"
    case "futbol": "soccerball"
    case "doga": "leaf.fill"
    case "teknoloji": "cpu"
    default: "square.grid.2x2.fill"
    }
  }

  // MARK: - Titles

  /// Kartta gösterilen kısa başlık ("YDS Kelime Paketi" → "YDS").
  static func shortTitle(for pack: Pack) -> String {
    pack.title.replacingOccurrences(of: " Kelime Paketi", with: "")
  }

  /// Paket detayındaki üst başlık.
  static func eyebrow(for kind: PackKind) -> String {
    switch kind {
    case .level: "Seviye paketi"
    case .exam: "Sınav paketi"
    case .theme: "Tema paketi"
    }
  }
}

/// Türkçe metin yardımcıları: sayı biçimi, belirtme hâli eki ve arama normalizasyonu.
enum TurkishText {
  /// Türkçe yerel ayarı.
  static let locale = Locale(identifier: "tr_TR")

  /// Binlik ayraçlı sayı ("1.200").
  static func number(_ value: Int) -> String {
    value.formatted(.number.locale(locale))
  }

  /// Sayıya belirtme hâli eki ekler ("15'i", "2'yi", "40'ı").
  static func accusative(_ value: Int) -> String {
    "\(value)'\(accusativeSuffix(value))"
  }

  /// Sayının okunuşuna göre belirtme hâli eki.
  static func accusativeSuffix(_ value: Int) -> String {
    let number = abs(value)
    if number == 0 { return "ı" }
    if number % 1000 == 0 { return "i" }
    if number % 100 == 0 { return "ü" }
    if number % 10 == 0 {
      let tens = ["u", "yi", "u", "ı", "yi", "ı", "i", "i", "ı"]
      return tens[(number % 100) / 10 - 1]
    }
    let units = ["i", "yi", "ü", "ü", "i", "yı", "yi", "i", "u"]
    return units[number % 10 - 1]
  }

  /// Aramada büyük/küçük harf ve Türkçe karakter farkını yok sayan anahtar.
  static func searchKey(_ text: String) -> String {
    text.lowercased(with: locale)
      .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: locale)
      .replacingOccurrences(of: "ı", with: "i")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
