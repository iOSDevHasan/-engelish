import Foundation
import UserNotifications

/// Günün Bulmacası için yerel hatırlatıcıyı kurar.
public enum ReminderScheduler {
  private static let identifier = "cengelish.daily"

  /// Bildirim izni ister; verildiyse true döner.
  public static func requestPermission() async -> Bool {
    (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]))
      ?? false
  }

  /// Ayarlara göre günlük hatırlatıcıyı kurar ya da kaldırır.
  public static func apply(_ settings: AppSettings) {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [identifier])
    guard settings.reminderEnabled else { return }
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
}
