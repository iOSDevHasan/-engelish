import Foundation
import UserNotifications

/// Günün Bulmacası hatırlatıcısını ve "serin bozulmak üzere" akşam bildirimini kurar.
///
/// Seri uyarısı tek seferlik bir bildirimdir: kullanıcı bugün oynadıysa yarın akşama, henüz
/// oynamadıysa bugün akşama kurulur. Bu yüzden bir bulmaca bitince, uygulama açılınca ve
/// hatırlatıcı ayarı değişince `refreshStreakWarning(settings:stats:now:)` çağrılmalıdır.
public enum ReminderScheduler {

  // MARK: - Types

  /// Kurulacak seri uyarısı.
  public struct StreakWarning: Equatable, Sendable {
    /// Bildirimin gösterileceği an.
    public let fireDate: Date
    /// Bildirimde yazan seri (gün).
    public let streak: Int

    /// Bildirim metni.
    public var body: String { "\(streak) günlük serin bozulmak üzere! Bugünün bulmacasını çöz." }
  }

  // MARK: - Properties

  private static let identifier = "cengelish.daily"
  private static let streakIdentifier = "cengelish.streak"
  /// Seri uyarısının varsayılan saati (dakika cinsinden, 21:30).
  public static let streakWarningMinutes = 21 * 60 + 30
  /// Seri uyarısının en geç saati (dakika cinsinden, 23:45).
  private static let latestWarningMinutes = 23 * 60 + 45

  // MARK: - Permission

  /// Bildirim izni ister; verildiyse true döner.
  public static func requestPermission() async -> Bool {
    (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]))
      ?? false
  }

  // MARK: - Scheduling

  /// Ayarlara göre günlük hatırlatıcıyı kurar ya da kaldırır; kapalıysa seri uyarısını da kaldırır.
  public static func apply(_ settings: AppSettings) {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [identifier])
    guard settings.reminderEnabled else {
      center.removePendingNotificationRequests(withIdentifiers: [streakIdentifier])
      return
    }
    let content = UNMutableNotificationContent()
    content.title = "Günün Bulmacası hazır"
    content.body = "Kalemini al, serini koru. Bugünün kelimeleri seni bekliyor."
    content.sound = .default
    var time = DateComponents()
    time.hour = settings.reminderHour
    time.minute = settings.reminderMinute
    let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
    center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
  }

  /// Günlük hatırlatıcıyı ve seri uyarısını birlikte günceller.
  public static func apply(_ settings: AppSettings, stats: UserStats, now: Date = .now) {
    apply(settings)
    refreshStreakWarning(settings: settings, stats: stats, now: now)
  }

  /// "Serin bozulmak üzere" bildirimini mevcut seriye göre yeniden kurar ya da kaldırır.
  ///
  /// Bir bulmaca bitince (bugün oynandı → uyarı yarın akşama kayar), uygulama açılınca ve
  /// hatırlatıcı ayarı değişince çağrılmalıdır.
  public static func refreshStreakWarning(
    settings: AppSettings, stats: UserStats, now: Date = .now
  ) {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [streakIdentifier])
    guard let warning = streakWarning(settings: settings, stats: stats, now: now) else { return }
    let content = UNMutableNotificationContent()
    content.title = "Serini koru"
    content.body = warning.body
    content.sound = .default
    let parts = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute], from: warning.fireDate)
    let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
    center.add(
      UNNotificationRequest(identifier: streakIdentifier, content: content, trigger: trigger))
  }

  /// Seri uyarısının ne zaman ve hangi seriyle kurulacağını hesaplar; gerekmiyorsa nil.
  ///
  /// - Hatırlatıcı kapalıysa ya da seri yoksa uyarı kurulmaz.
  /// - Bugün oynandıysa uyarı yarın akşama kurulur.
  /// - Dün oynanıp bugün oynanmadıysa uyarı bugün akşama kurulur (saat geçtiyse kurulmaz).
  /// - Uyarı 21:30'da; hatırlatıcı daha geçse hatırlatıcıdan bir saat sonra (en geç 23:45).
  public static func streakWarning(
    settings: AppSettings, stats: UserStats, now: Date, calendar: Calendar = .current
  ) -> StreakWarning? {
    guard settings.reminderEnabled, stats.streak > 0, let lastDay = stats.lastPlayedDay else {
      return nil
    }
    let reminderMinutes = settings.reminderHour * 60 + settings.reminderMinute
    let minutes = min(max(streakWarningMinutes, reminderMinutes + 60), latestWarningMinutes)
    let startOfToday = calendar.startOfDay(for: now)
    let dayOffset: Int
    switch lastDay {
    case DayMath.key(now, calendar): dayOffset = 1
    case DayMath.key(now, calendar, offset: -1): dayOffset = 0
    default: return nil
    }
    guard
      let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday),
      let fireDate = calendar.date(byAdding: .minute, value: minutes, to: day),
      fireDate > now
    else { return nil }
    return StreakWarning(fireDate: fireDate, streak: stats.streak)
  }
}
