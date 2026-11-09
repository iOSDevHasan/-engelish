import Foundation

/// Uygulama ile widget eklentisinin ortak sabitleri.
public enum WidgetShared {
  /// Ortak App Group kimliği (uygulama ve eklenti entitlement'larında aynı).
  public static let appGroup = "group.com.hasangurbuz.cengelish"
  /// Günün kelimesi widget'ı.
  public static let wordKind = "CengelishWordOfDay"
  /// Seri widget'ı.
  public static let streakKind = "CengelishStreak"
  /// Günün bulmacası widget'ı.
  public static let dailyKind = "CengelishDailyPuzzle"
  /// Kilit ekranı seri widget'ı.
  public static let lockStreakKind = "CengelishLockStreak"
  /// Kilit ekranı kelime widget'ı.
  public static let lockWordKind = "CengelishLockWord"
  /// Uygulamayı Ana Sayfa'da açan bağlantı.
  public static let homeURL = URL(string: "cengelish://home")
  /// Günün bulmacasını açan bağlantı.
  public static let dailyURL = URL(string: "cengelish://daily")
}

/// `yyyy-MM-dd` gün anahtarları (yerel saat).
public enum WidgetDay {

  /// Tarihi gün anahtarına çevirir.
  public static func string(from date: Date, calendar: Calendar = .current) -> String {
    let parts = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
  }

  /// Gün anahtarını günün başlangıcına çevirir.
  public static func date(from key: String, calendar: Calendar = .current) -> Date? {
    let parts = key.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
  }
}

/// Anlık görüntüyü App Group kapsayıcısında JSON olarak saklar.
public struct WidgetSnapshotStore: Sendable {
  /// Dosyanın konumu; App Group yoksa nil.
  private let fileURL: URL?

  /// Ortak App Group kapsayıcısını kullanan depo.
  public init() {
    let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: WidgetShared.appGroup)
    fileURL = container?.appendingPathComponent("widget-snapshot.json")
  }

  /// Verilen dosyayı kullanan depo (testler için).
  public init(fileURL: URL?) {
    self.fileURL = fileURL
  }

  /// Kayıtlı anlık görüntüyü okur.
  public func load() -> WidgetSnapshot? {
    guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
    return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
  }

  /// Anlık görüntüyü yazar; içerik değişmediyse false döner.
  @discardableResult
  public func save(_ snapshot: WidgetSnapshot) -> Bool {
    guard let fileURL else { return false }
    var comparable = snapshot
    if var previous = load() {
      previous.generatedAt = snapshot.generatedAt
      comparable.generatedAt = snapshot.generatedAt
      if previous == comparable { return false }
    }
    guard let data = try? JSONEncoder().encode(snapshot) else { return false }
    return (try? data.write(to: fileURL, options: .atomic)) != nil
  }
}
