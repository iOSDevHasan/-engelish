import Foundation

/// Aylık seri takviminde bir günün durumu.
enum StreakDayState: Equatable {
  /// Bulmaca çözüldü.
  case solved
  /// Çözülmedi ama Çengelish+ seri dondurmasıyla seri bozulmadı.
  case frozen
  /// Çözülmeyen geçmiş gün.
  case missed
  /// Henüz gelmemiş gün.
  case future
}

/// Aylık seri takviminde bir gün.
struct StreakDay: Identifiable, Equatable {
  /// `yyyy-MM-dd` anahtarı.
  let id: String
  /// Ayın günü.
  let day: Int
  /// Durum.
  let state: StreakDayState
  /// Bugün mü.
  let isToday: Bool
}

/// Aylık seri takvimi (plan §6.4): çözülen günler, bugün ve dondurulan günler.
struct StreakMonth: Equatable {

  // MARK: - Properties

  /// "Kasım 2026".
  let title: String
  /// Ayın ilk gününden önceki boş hücre sayısı (hafta pazartesi başlar).
  let leadingBlanks: Int
  /// Ayın günleri.
  let days: [StreakDay]

  /// Hafta günü başlıkları.
  static let weekdays = ["Pt", "Sa", "Ça", "Pe", "Cu", "Ct", "Pz"]

  // MARK: - Derived

  /// Bu ay çözülen gün sayısı.
  var solvedCount: Int { days.filter { $0.state == .solved }.count }
  /// Bu ay dondurulan gün sayısı.
  var frozenCount: Int { days.filter { $0.state == .frozen }.count }

  // MARK: - Builder

  /// Verilen tarihin ayını kurar.
  ///
  /// Dondurma, yalnızca Çengelish+ kullanıcılarında, iki çözülen gün arasındaki tek günlük boşluk
  /// olarak gösterilir (`StreakRules.next` ile aynı kural: bir gün boşluk affedilir).
  static func make(
    containing date: Date, solvedDays: Set<String>, today: Date, canFreeze: Bool,
    calendar: Calendar
  ) -> StreakMonth {
    var calendar = calendar
    calendar.firstWeekday = 2
    let start = calendar.dateInterval(of: .month, for: date)?.start ?? date
    let count = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
    let weekday = calendar.component(.weekday, from: start)
    let blanks = (weekday - calendar.firstWeekday + 7) % 7
    let todayKey = key(today, calendar)
    let days = (0..<count).map { offset -> StreakDay in
      let day = calendar.date(byAdding: .day, value: offset, to: start) ?? start
      let id = key(day, calendar)
      let state: StreakDayState
      if solvedDays.contains(id) {
        state = .solved
      } else if id > todayKey {
        state = .future
      } else if canFreeze, id < todayKey,
        solvedDays.contains(key(day, calendar, offset: -1)),
        solvedDays.contains(key(day, calendar, offset: 1))
      {
        state = .frozen
      } else {
        state = .missed
      }
      return StreakDay(id: id, day: offset + 1, state: state, isToday: id == todayKey)
    }
    return StreakMonth(
      title: ProfileDateText.monthYear(start, calendar: calendar), leadingBlanks: blanks,
      days: days)
  }

  /// Tarihi (isteğe bağlı gün kaydırmasıyla) `yyyy-MM-dd` anahtarına çevirir.
  static func key(_ date: Date, _ calendar: Calendar, offset: Int = 0) -> String {
    let shifted = calendar.date(byAdding: .day, value: offset, to: date) ?? date
    let parts = calendar.dateComponents([.year, .month, .day], from: shifted)
    return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
  }
}
