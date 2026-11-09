import Foundation

/// Tarihleri her zaman Türkçe biçimleyen yardımcılar (cihaz bölgesinden bağımsız).
public enum DateText {
  /// Türkçe yerel ayar.
  public static let locale = Locale(identifier: "tr_TR")

  /// "9 Kasım" biçimi.
  public static func dayMonth(_ date: Date) -> String {
    date.formatted(.dateTime.day().month(.wide).locale(locale))
  }

  /// "9 Kas" biçimi.
  public static func dayMonthShort(_ date: Date) -> String {
    date.formatted(.dateTime.day().month(.abbreviated).locale(locale))
  }
}
