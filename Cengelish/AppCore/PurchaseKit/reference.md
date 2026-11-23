# PurchaseKit

**Layer**: AppCore
**Purpose**: StoreKit 2 ile tek seferlik satın alma: Çengelish Plus ömür boyu erişim ve ayrı ayrı sınav paketleri. Abonelik yok; yetkiler cihazda, hesap yok.

## Public API

```swift
enum ProductID   // plusName ("Çengelish Plus"), plusLifetime, packYDS/YOKDIL/LGS/IELTS/TOEFL,
                 // examPacks, all (önce Plus), examTitle(for:), displayTitle(for:)
@MainActor protocol EntitlementProviding  // isPremium, ownedProductIds, products, plusPurchaseDate (varsayılan nil), loadProducts(), purchase(_:), restore(), canAccess(productId:)
final class EntitlementStore: EntitlementProviding   // Transaction.currentEntitlements: plusLifetime → isPremium + originalPurchaseDate, diğerleri ownedProductIds
StoreProduct     // id, title, displayPrice, price (Decimal?), currencyCode ("TRY")
PurchaseOutcome
```

## Structure

Sources/

## Dependencies

- Yok (StoreKit). Yerel test: repo kökündeki StoreKit/Cengelish.storekit (şemaya bağlı; 6 non-consumable: ömür boyu Plus + 5 sınav paketi, abonelik grubu yok). Ürün kimlik dizeleri değişmez; marka adı yalnızca ekranda "Çengelish Plus".
