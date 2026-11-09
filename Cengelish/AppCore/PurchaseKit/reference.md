# PurchaseKit

**Layer**: AppCore
**Purpose**: StoreKit 2 ile Çengelish+ aboneliği ve sınav paketi satın alma; yetkiler cihazda, hesap yok.

## Public API

```swift
enum ProductID   // plusMonthly, plusYearly, packYDS/YOKDIL/LGS/IELTS/TOEFL, subscriptions, examPacks, all, examTitle(for:)
@MainActor protocol EntitlementProviding  // isPremium, ownedProductIds, products, activeSubscription (varsayılan nil), loadProducts(), purchase(_:), restore(), canAccess(productId:)
final class EntitlementStore: EntitlementProviding   // activeSubscription: Transaction.currentEntitlements + SubscriptionInfo.Status
struct ActiveSubscription  // productId, renewalDate, willAutoRenew, planTitle
StoreProduct, PurchaseOutcome
```

## Structure

Sources/

## Dependencies

- Yok (StoreKit). Yerel test: repo kökündeki StoreKit/Cengelish.storekit (şemaya bağlı; 2 abonelik + 5 sınav paketi)
