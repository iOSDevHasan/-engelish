# HomeModule

**Layer**: Modules
**Purpose**: Ana Sayfa: "Merhaba {ad}!" + günlük hedef, sağ üstte taçlı "PLUS" butonu
(`HomePlusButton`; Plus olmayanlarda yüzey dairesi + altın çerçeve ve zıplayan taç, üyede altın
dolgulu parlayan görünüm; her zaman paywall'u açar, paywall üyede üyelik durumunu gösterir),
seri kartı (Plus'ta seri dondurma ipucu, değilse Plus rozetli seri dondurma tanıtımı → paywall;
altta hatırlatıcı kısayolu "Hatırlatıcı her gün 20:00" / "Günlük hatırlatıcı kur" → hatırlatıcı
paneli, `appBottomSheet`), Günün Bulmacası (tüm kart dokunulabilir, basınca küçülür), Plus
olmayanlara Günün Bulmacası'nın altında `PlusPromoCard` → paywall, kaldığın yerden devam, günün
kelimesi. Kartlar kademeli girer (`appearAnimation`), seri sayısı `numericText` ile değişir.
Her yüklemede "serin bozulmak üzere" bildirimini yeniler. Hatırlatıcı Ayarlar'dan da yönetilir.

## Public API

```swift
@MainActor protocol HomeModuleInterface: AnyObject
  func createHomeView() -> AnyView
```

## Structure

```
InterfaceSources/HomeModuleInterface.swift
Package.swift
Sources/HomeCoordinator.swift
Sources/View/HomeView.swift              — ekran + ReminderSheet (appBottomSheet içeriği)
Sources/View/HomePlusButton.swift        — sağ üstteki taçlı Plus butonu (üye / üye değil)
Sources/ViewModel/HomeViewModel.swift      — HomeViewModel + HomeRouting (showPuzzle, showPaywall)
Sources/ViewModel/ReminderActions.swift   — ReminderScheduler yan etkileri (testte sahte)
Tests/HomeViewModelTests.swift
```

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PurchaseKit, PuzzleKit, WordKit, PuzzleModuleInterface,
  ExploreModuleInterface, PaywallModuleInterface
