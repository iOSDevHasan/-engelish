# WidgetBridgeKit

**Layer**: AppCore
**Purpose**: Uygulama ile widget eklentisi (`CengelishWidgets/`) arasındaki köprü. Uygulama App Group'a
bir anlık görüntü (`WidgetSnapshot`) yazar; widget'lar sadece onu okur. Widget görünümleri ve
`Widget` tanımları da burada, eklenti hedefi sadece `WidgetBundle` içerir.

## Public API

```swift
enum WidgetShared { appGroup; wordKind; streakKind; dailyKind; lockStreakKind; lockWordKind; homeURL; dailyURL }
enum WidgetDay { string(from:); date(from:) }               // yyyy-MM-dd
struct WidgetSnapshot: Codable { … days: [Day]; streak(on:); solvedCount(on:); week(containing:); hasSameStatus(as:); empty(); sample() }
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

Uygulama tarafı: `Composition/Sources/Shell/WidgetPublisher.swift` (veri değişince yazar; widget'ları
yalnızca görünen durum — bitti, seri, günlük sayaç, gün — değişince yeniler, arka plana geçerken her
zaman yeniler ve yazma bitene kadar arka plan süresi ister; çözerken her kalem kaydında yenilemek
sistemin yenilemeleri kısmasına yol açıyordu), `DailyPuzzleLauncher` (`cengelish://daily`).

Veri yoksa widget sahte örnek değil boş durum (`WidgetSnapshot.empty()`) gösterir; örnek veri yalnızca
galeri önizlemesinde. Orta widget'taki küçük ızgara alana oranını koruyarak sığar (satır sayısı
yazıları kaydırmaz).

## Dependencies

- DesignKit (renkler, yazı tipleri, Kalemo avatarı), WidgetKit
