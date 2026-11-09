import Foundation
import WidgetKit

/// Widget'ların ortak zaman çizelgesi girdisi.
public struct CengelishEntry: TimelineEntry, Sendable {
  /// Girdinin geçerli olduğu an.
  public let date: Date
  /// Uygulamanın yazdığı anlık görüntü.
  public let snapshot: WidgetSnapshot
  /// Girdinin günü (`yyyy-MM-dd`).
  public let day: String

  /// Girdiyi oluşturur.
  public init(date: Date, snapshot: WidgetSnapshot) {
    self.date = date
    self.snapshot = snapshot
    self.day = WidgetDay.string(from: date)
  }

  /// Günün kelimesi.
  public var word: WidgetSnapshot.WordInfo? { snapshot.content(for: day)?.word }

  /// Günün bulmacası (eski günün bulmacası yeni günde gösterilmez).
  public var puzzle: WidgetSnapshot.PuzzleInfo? {
    guard let content = snapshot.content(for: day), content.day == day else { return nil }
    return content.puzzle
  }

  /// Girdinin günündeki seri.
  public var streak: Int { snapshot.streak(on: day) }

  /// Girdinin gününde bitirilen bulmaca sayısı.
  public var solvedToday: Int { snapshot.solvedCount(on: day) }
}

/// Anlık görüntüden gece yarısı değişen girdiler üretir.
public struct CengelishTimelineProvider: TimelineProvider {
  /// Anlık görüntünün okunduğu depo.
  private let store: WidgetSnapshotStore

  /// Sağlayıcıyı oluşturur.
  public init(store: WidgetSnapshotStore = WidgetSnapshotStore()) {
    self.store = store
  }

  /// İlk çizim için anında örnek girdi.
  public func placeholder(in context: Context) -> CengelishEntry {
    CengelishEntry(date: .now, snapshot: .sample())
  }

  /// Galeri ve geçiş için tek girdi; veri yoksa örnek gösterir.
  public func getSnapshot(in context: Context, completion: @escaping (CengelishEntry) -> Void) {
    let snapshot = context.isPreview ? .sample() : (store.load() ?? .sample())
    completion(CengelishEntry(date: .now, snapshot: snapshot))
  }

  /// Bugün ve sonraki günlerin gece yarısı için girdiler.
  public func getTimeline(
    in context: Context, completion: @escaping (Timeline<CengelishEntry>) -> Void
  ) {
    let snapshot = store.load() ?? .sample()
    let dates = Self.entryDates(from: .now, dayCount: max(1, snapshot.days.count))
    let entries = dates.map { CengelishEntry(date: $0, snapshot: snapshot) }
    let reload = Calendar.current.date(byAdding: .day, value: 1, to: dates.last ?? .now) ?? .now
    completion(Timeline(entries: entries, policy: .after(Calendar.current.startOfDay(for: reload))))
  }

  /// Şimdi ve sonraki gece yarıları.
  static func entryDates(from now: Date, dayCount: Int, calendar: Calendar = .current) -> [Date] {
    let start = calendar.startOfDay(for: now)
    let midnights = (1..<max(dayCount, 1)).compactMap {
      calendar.date(byAdding: .day, value: $0, to: start)
    }
    return [now] + midnights
  }
}
