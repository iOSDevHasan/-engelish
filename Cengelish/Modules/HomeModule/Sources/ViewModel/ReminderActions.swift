import Foundation
import UserDataKit

/// Hatırlatıcı bildirimlerinin yan etkileri; testlerde sahteleri verilir.
struct ReminderActions {
  /// Bildirim izni ister.
  var requestPermission: @MainActor () async -> Bool
  /// Günlük hatırlatıcıyı ve seri uyarısını kurar.
  var apply: @MainActor (AppSettings, UserStats) -> Void
  /// Sadece "serin bozulmak üzere" uyarısını yeniler.
  var refreshStreakWarning: @MainActor (AppSettings, UserStats) -> Void

  /// `ReminderScheduler` ile gerçek bildirimler.
  static var live: ReminderActions {
    ReminderActions(
      requestPermission: { await ReminderScheduler.requestPermission() },
      apply: { ReminderScheduler.apply($0, stats: $1) },
      refreshStreakWarning: { ReminderScheduler.refreshStreakWarning(settings: $0, stats: $1) })
  }
}
