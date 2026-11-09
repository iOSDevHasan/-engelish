# ExploreModule

**Layer**: Modules
**Purpose**: Keşfet (arama, Tümü/Seviyeler/Sınavlar/Temalar filtresi, seviye kareleri, sınav ve tema
paketleri, tüm temalar listesi) ve paket detayı (bulmaca kareleri, kilit, paywall).

## Public API

```swift
@MainActor protocol ExploreModuleInterface: AnyObject
  func createExploreView() / createPackView(packId:) -> AnyView
```

Arama ve tema listesi ekranları modül içinden (`ExploreCoordinator.showSearch()` /
`showThemes(viewModel:)`) açılır; arayüze eklenmedi.

## Rules

- Tüm paketler `ContentProviding.packs()`'ten gelir (`.level`, `.exam`, `.theme`); bulmacası olmayan
  paket gizlenir.
- Kilit (`PackRules`): sınav paketi `canAccess(productId: pack.productId)`; seviye/tema paketi yalnızca
  Çengelish+ (`canAccess(productId: nil)`). Bulmaca `pack.isFree(index:)` ise her zaman açık.
  Kilitli bulmaca paywall'u sınavda paketin ürünüyle, seviye/temada `nil` ile açar.
- Seviye aralığı: seviye paketinde kendi seviyesi; diğerlerinde bulmaca seviyelerinin min–max'ı,
  tek seviyeyse bilinen sınav aralığı (`yds/yokdil B2–C1`, `lgs A2–B1`, `ielts/toefl B1–C1`).
- Arama: paket başlığı/açıklaması ve kelimenin İngilizcesi/Türkçe anlamı (büyük-küçük harf ve Türkçe
  karakter duyarsız); kelime dizini paketlerin bulmacalarındaki kelimelerden kurulur. Kelimeye
  dokununca WordKit `WordDetailSheet` açılır ("Deftere ekle").

## Structure

```
InterfaceSources/ExploreModuleInterface.swift
Package.swift
Sources/ExploreCoordinator.swift
Sources/Model/PackRules.swift          // PackRules (kilit, aralık, simge), TurkishText
Sources/View/ExploreView.swift
Sources/View/ExploreComponents.swift   // SectionHeader, LevelTileView, ExamCardView, ThemeTileView
Sources/View/PackView.swift
Sources/View/SearchView.swift
Sources/View/ThemeListView.swift
Sources/ViewModel/ExploreViewModel.swift   // PackCard, ExploreSegment
Sources/ViewModel/PackViewModel.swift
Sources/ViewModel/SearchViewModel.swift    // WordIndexEntry
Tests/ContentFixture.swift
Tests/ExploreViewModelTests.swift
```

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PurchaseKit, PuzzleKit, WordKit, PuzzleModuleInterface,
  PaywallModuleInterface
- Injected services: `ContentProviding`, `UserDataStoring`, `EntitlementProviding`, `Pronouncing`
