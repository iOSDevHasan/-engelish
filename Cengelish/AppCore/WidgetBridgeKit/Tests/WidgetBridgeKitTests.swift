import Foundation
import Testing

@testable import WidgetBridgeKit

@Suite("WidgetSnapshot")
struct WidgetSnapshotTests {

  @Test("Seri dün oynandıysa sürer, iki gün ara verildiyse 0 görünür")
  func streakContinuity() {
    var snapshot = WidgetSnapshot.sample()
    snapshot.lastPlayedDay = "2026-11-08"
    snapshot.streak = 5
    #expect(snapshot.streak(on: "2026-11-08") == 5)
    #expect(snapshot.streak(on: "2026-11-09") == 5)
    #expect(snapshot.streak(on: "2026-11-10") == 0)
  }

  @Test("Bugünkü sayaç sadece kendi gününde gösterilir")
  func solvedToday() {
    var snapshot = WidgetSnapshot.sample()
    snapshot.solvedToday = .init(day: "2026-11-09", count: 2)
    #expect(snapshot.solvedCount(on: "2026-11-09") == 2)
    #expect(snapshot.solvedCount(on: "2026-11-10") == 0)
  }

  @Test("Gün içeriği yoksa en yakın önceki gün kullanılır, bulmaca sadece kendi gününde")
  func contentFallback() {
    var snapshot = WidgetSnapshot.sample()
    snapshot.days = [
      .init(day: "2026-11-09", word: .init(en: "a", meaning: "", ipa: ""), puzzle: nil),
      .init(day: "2026-11-10", word: .init(en: "b", meaning: "", ipa: ""), puzzle: nil),
    ]
    #expect(snapshot.content(for: "2026-11-10")?.word?.en == "b")
    #expect(snapshot.content(for: "2026-11-12")?.word?.en == "b")
  }

  @Test("Depo yazar, okur ve değişmeyen içeriği yeniden yazmaz")
  func storeRoundTrip() throws {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("widget-\(UUID().uuidString).json")
    let store = WidgetSnapshotStore(fileURL: url)
    let snapshot = WidgetSnapshot.sample()
    #expect(store.save(snapshot))
    #expect(store.load() == snapshot)
    var later = snapshot
    later.generatedAt = snapshot.generatedAt.addingTimeInterval(60)
    #expect(store.save(later) == false)
    try? FileManager.default.removeItem(at: url)
  }

  @Test("Zaman çizelgesi şimdi ve sonraki gece yarıları için girdi üretir")
  func entryDates() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let dates = CengelishTimelineProvider.entryDates(from: now, dayCount: 3)
    #expect(dates.count == 3)
    #expect(dates.first == now)
    #expect(dates.dropFirst().allSatisfy { Calendar.current.startOfDay(for: $0) == $0 })
  }
}
