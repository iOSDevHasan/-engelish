import DesignKit
import Foundation

/// Sayılarla biten adlara gelen Türkçe ekler (okunuşun son hecesine göre).
enum TurkishSuffix {

  /// Yönelme eki: "B2'ye", "C1'e".
  static func dative(_ text: String) -> String {
    switch text.last {
    case "1", "3", "4", "5", "8": "'e"
    case "2", "7": "'ye"
    case "6": "'ya"
    case "9", "0": "'a"
    default: "'e"
    }
  }

  /// Çıkma eki: "2026'dan", "2025'ten", "2030'dan".
  static func ablative(_ number: Int) -> String {
    let units = number % 10
    let tens = (number / 10) % 10
    if units != 0 {
      return ["", "'den", "'den", "'ten", "'ten", "'ten", "'dan", "'den", "'den", "'dan"][units]
    }
    if tens != 0 {
      return ["", "'dan", "'den", "'dan", "'tan", "'den", "'tan", "'ten", "'den", "'dan"][tens]
    }
    return "'den"
  }
}

/// Profil ekranındaki tarih metinleri.
enum ProfileDateText {

  /// "Ekim 2026'dan beri".
  static func since(_ date: Date, calendar: Calendar) -> String {
    let month = monthName(date, calendar: calendar)
    let year = calendar.component(.year, from: date)
    return "\(month) \(year)\(TurkishSuffix.ablative(year)) beri"
  }

  /// "Kasım 2026".
  static func monthYear(_ date: Date, calendar: Calendar) -> String {
    "\(monthName(date, calendar: calendar)) \(calendar.component(.year, from: date))"
  }

  /// Takvimin saat dilimine göre Türkçe ay adı ("Kasım").
  static func monthName(_ date: Date, calendar: Calendar) -> String {
    var style = Date.FormatStyle.dateTime.month(.wide).locale(DateText.locale)
    style.calendar = calendar
    style.timeZone = calendar.timeZone
    return date.formatted(style)
  }

  /// "az önce", "2 dk önce", "3 sa önce", "4 gün önce" ya da "9 Kasım".
  static func relative(_ date: Date, now: Date) -> String {
    let seconds = max(0, Int(now.timeIntervalSince(date)))
    switch seconds {
    case ..<60: return "az önce"
    case ..<3_600: return "\(seconds / 60) dk önce"
    case ..<86_400: return "\(seconds / 3_600) sa önce"
    case ..<(86_400 * 30): return "\(seconds / 86_400) gün önce"
    default: return DateText.dayMonth(date)
    }
  }
}
