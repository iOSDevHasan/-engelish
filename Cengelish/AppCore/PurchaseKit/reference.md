# PurchaseKit

**Layer**: AppCore
**Purpose**: StoreKit 2 ile Çengelish+ aboneliği ve sınav paketi satın alma; yetkiler cihazda, hesap yok.

## Public API

```swift
enum ProductID   // plusMonthly, plusYearly, packYDS
@MainActor protocol EntitlementProviding  // isPremium, ownedProductIds, products, loadProducts(), purchase(_:), restore(), canAccess(productId:)
final class EntitlementStore: EntitlementProviding
StoreProduct, PurchaseOutcome
```

## Structure

Sources/

## Dependencies

- Yok (StoreKit). Yerel test: repo kökündeki StoreKit/Cengelish.storekit (şemaya bağlı)
