# PaywallModule

**Layer**: Modules
**Purpose**: Çengelish+ paywall: yıllık / aylık / YDS paketi, geri yükleme.

## Public API

```swift
@MainActor protocol PaywallModuleInterface: AnyObject
  func createPaywallView(highlightProductId:) -> AnyView
```

## Structure

```
InterfaceSources/PaywallModuleInterface.swift
Package.swift
Sources/PaywallCoordinator.swift
Sources/View/PaywallView.swift
Sources/ViewModel/PaywallViewModel.swift
Tests/PaywallViewModelTests.swift
```

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, PurchaseKit
