# PaywallModule

**Layer**: Modules
**Purpose**: Çengelish+ paywall: yıllık / aylık / tek seferlik sınav paketi (açılışta seçili sınav paketi, yoksa YDS), geri yükleme. StoreKit fiyatı yoksa örnek fiyatlar (74,99 / 449,99 / 199,99, LGS 129,99 ₺).

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
