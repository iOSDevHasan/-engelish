# HomeModule

**Layer**: Modules
**Purpose**: Ana Sayfa: selamlama, seri kartı, Günün Bulmacası, kaldığın yerden devam, günün kelimesi.

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
Tests/HomeViewModelTests.swift
```

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PurchaseKit, PuzzleKit, WordKit, PuzzleModuleInterface, ExploreModuleInterface
