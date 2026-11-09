# WidgetBridgeKit

**Layer**: AppCore
**Purpose**: Uygulama ile widget eklentisi (`CengelishWidgets/`) arasındaki köprü. Uygulama App Group'a
bir anlık görüntü (`WidgetSnapshot`) yazar; widget'lar sadece onu okur. Widget görünümleri ve
`Widget` tanımları da burada, eklenti hedefi sadece `WidgetBundle` içerir.

## Public API

```swift
enum WidgetShared { appGroup; wordKind; streakKind; dailyKind; lockStreakKind; lockWordKind; homeURL; dailyURL }
enum WidgetDay { string(from:); date(from:) }               // yyyy-MM-dd
struct WidgetSnapshot: Codable { … days: [Day]; streak(on:); solvedCount(on:); week(containing:); sample() }
struct WidgetSnapshotStore { load(); save(_:) -> Bool }     // App Group JSON, değişmediyse yazmaz
struct CengelishEntry: TimelineEntry; struct CengelishTimelineProvider: TimelineProvider
struct WordOfDayWidget, StreakWidget, DailyPuzzleWidget, LockStreakWidget, LockWordWidget: Widget
```

## Structure

```
Sources/WidgetSnapshot.swift        model + türetilmiş değerler + örnek veri
Sources/WidgetSnapshotStore.swift   App Group dosyası, sabitler, gün anahtarları
Sources/WidgetTimeline.swift        girdi + zaman çizelgesi (gece yarısı girdileri)
Sources/WidgetViews.swift           küçük / orta / kilit ekranı görünümleri
Sources/CengelishWidgets.swift      Widget tanımları + önizlemeler
```

Uygulama tarafı: `Composition/Sources/Shell/WidgetPublisher.swift` (veri değişince ve arka plana
geçerken yazar, `WidgetCenter.reloadAllTimelines()`), `DailyPuzzleLauncher` (`cengelish://daily`).

## Dependencies

- DesignKit (renkler, yazı tipleri, Kalemo avatarı), WidgetKit
