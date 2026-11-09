import Foundation

/// Seri hesabı.
public enum StreakRules {

  /// Bugün bir bulmaca bitince yeni seriyi hesaplar.
  ///
  /// - Parameters:
  ///   - current: Mevcut seri.
  ///   - lastDay: Son oynanan gün (`yyyy-MM-dd`).
  ///   - today: Bugün (`yyyy-MM-dd`).
  ///   - yesterday: Dün (`yyyy-MM-dd`).
  ///   - dayBefore: Önceki gün; Çengelish+ seri dondurma ile bir gün boşluk affedilir.
  ///   - canFreeze: Seri dondurma kullanılabilir mi.
  /// - Returns: Yeni seri.
  public static func next(
    current: Int, lastDay: String?, today: String, yesterday: String, dayBefore: String,
    canFreeze: Bool
  ) -> Int {
    switch lastDay {
    case today: max(current, 1)
    case yesterday: current + 1
    case dayBefore where canFreeze: current + 1
    default: 1
    }
  }

  /// Seri bugün ya da dün oynanmadıysa ekranda 0 gösterilir.
  public static func visibleStreak(
    _ streak: Int, lastDay: String?, today: String, yesterday: String
  ) -> Int {
    lastDay == today || lastDay == yesterday ? streak : 0
  }
}

/// Aralıklı tekrar (Leitner) kuralları: 1 / 3 / 7 / 14 / 30 gün.
public enum LeitnerRules {

  /// Kutuya göre bekleme süresi (gün).
  public static let intervals = [1, 3, 7, 14, 30]

  /// Tekrar sonrası yeni kutu ve sonraki tarih.
  public static func review(
    box: Int, knew: Bool, now: Date
  ) -> (box: Int, next: Date, learned: Bool) {
    let newBox = knew ? min(box + 1, 6) : 1
    if newBox > intervals.count {
      return (intervals.count, now, true)
    }
    let days = intervals[newBox - 1]
    return (newBox, now.addingTimeInterval(TimeInterval(days * 86_400)), false)
  }

  /// Kutu numarasının Türkçe açıklaması.
  public static func label(box: Int, learned: Bool) -> String {
    learned ? "Öğrenildi" : "Kutu \(box)"
  }
}

/// İpucu hakkı kuralları.
public enum HintRules {
  /// Ücretsiz kullanıcının günlük ipucu hakkı.
  public static let freeDailyHints = 3
  /// Harf açmanın bedeli.
  public static let letterCost = 1
  /// Kelimeyi açmanın bedeli.
  public static let wordCost = 3
}

/// Yıldız hesabı.
public enum StarRules {

  /// Doğru oranı ve ipucu kullanımına göre 0–3 yıldız.
  public static func stars(correct: Int, total: Int, hints: Int) -> Int {
    guard total > 0 else { return 0 }
    let ratio = Double(correct) / Double(total)
    let base = ratio >= 1 ? 3 : ratio >= 0.7 ? 2 : ratio >= 0.4 ? 1 : 0
    return max(base - (hints >= 3 ? 1 : 0), correct > 0 ? 1 : 0)
  }
}
