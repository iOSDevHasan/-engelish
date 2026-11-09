# ExploreModule

**Layer**: Modules
**Purpose**: Keşfet (seviye ve sınav paketleri) ve paket detayı (bulmaca kareleri, kilit, paywall).

## Public API

```swift
@MainActor protocol ExploreModuleInterface: AnyObject
  func createExploreView() / createPackView(packId:) -> AnyView
```

## Structure

```
InterfaceSources/ExploreModuleInterface.swift
Package.swift
Sources/ExploreCoordinator.swift
Sources/View/ExploreView.swift
Sources/View/PackView.swift
Sources/ViewModel/ExploreViewModel.swift
Sources/ViewModel/PackViewModel.swift
Tests/ContentFixture.swift
Tests/ExploreViewModelTests.swift
```

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PurchaseKit, PuzzleKit, PuzzleModuleInterface, PaywallModuleInterface
