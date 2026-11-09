# HomeModule

**Layer**: Modules
**Purpose**: Ana Sayfa: "Merhaba {ad}!" + günlük hedef, zil → hatırlatıcı paneli, seri kartı (premium seri dondurma ipucu), Günün Bulmacası, kaldığın yerden devam, günün kelimesi. Her yüklemede "serin bozulmak üzere" bildirimini yeniler.

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
Sources/View/HomeView.swift
Sources/ViewModel/HomeViewModel.swift
Sources/ViewModel/ReminderActions.swift   — ReminderScheduler yan etkileri (testte sahte)
Tests/HomeViewModelTests.swift
```

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PurchaseKit, PuzzleKit, WordKit, PuzzleModuleInterface, ExploreModuleInterface
