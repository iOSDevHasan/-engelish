import SwiftUI
import WidgetKit

/// Günün kelimesi (küçük, Ana Ekran).
public struct WordOfDayWidget: Widget {
  /// Widget'ı oluşturur.
  public init() {}

  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: WidgetShared.wordKind, provider: CengelishTimelineProvider()) {
      WordOfDayWidgetView(entry: $0)
    }
    .configurationDisplayName("Günün kelimesi")
    .description("Her gün yeni bir İngilizce kelime, anlamı ve telaffuzu.")
    .supportedFamilies([.systemSmall])
  }
}

/// Seri (küçük, Ana Ekran).
public struct StreakWidget: Widget {
  /// Widget'ı oluşturur.
  public init() {}

  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: WidgetShared.streakKind, provider: CengelishTimelineProvider()) {
      StreakWidgetView(entry: $0)
    }
    .configurationDisplayName("Serin")
    .description("Kaç gündür bulmaca çözdüğünü ve bugünkü hedefini gösterir.")
    .supportedFamilies([.systemSmall])
  }
}

/// Günün bulmacası (orta, Ana Ekran).
public struct DailyPuzzleWidget: Widget {
  /// Widget'ı oluşturur.
  public init() {}

  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: WidgetShared.dailyKind, provider: CengelishTimelineProvider()) {
      DailyPuzzleWidgetView(entry: $0)
    }
    .configurationDisplayName("Günün Bulmacası")
    .description("Bugünün bulmacası ve ne kadarını çözdüğün. Dokun, kaldığın yerden devam et.")
    .supportedFamilies([.systemMedium])
  }
}

/// Seri (yuvarlak, Kilit Ekranı).
public struct LockStreakWidget: Widget {
  /// Widget'ı oluşturur.
  public init() {}

  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: WidgetShared.lockStreakKind, provider: CengelishTimelineProvider()) {
      LockStreakWidgetView(entry: $0)
    }
    .configurationDisplayName("Seri")
    .description("Kilit ekranında serin.")
    .supportedFamilies([.accessoryCircular])
  }
}

/// Günün kelimesi (dikdörtgen, Kilit Ekranı).
public struct LockWordWidget: Widget {
  /// Widget'ı oluşturur.
  public init() {}

  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: WidgetShared.lockWordKind, provider: CengelishTimelineProvider()) {
      LockWordWidgetView(entry: $0)
    }
    .configurationDisplayName("Günün kelimesi")
    .description("Kilit ekranında günün kelimesi ve anlamı.")
    .supportedFamilies([.accessoryRectangular])
  }
}

// MARK: - Previews

#Preview("Kelime", as: .systemSmall) {
  WordOfDayWidget()
} timeline: {
  CengelishEntry(date: .now, snapshot: .sample())
}

#Preview("Seri", as: .systemSmall) {
  StreakWidget()
} timeline: {
  CengelishEntry(date: .now, snapshot: .sample())
}

#Preview("Bulmaca", as: .systemMedium) {
  DailyPuzzleWidget()
} timeline: {
  CengelishEntry(date: .now, snapshot: .sample())
}
