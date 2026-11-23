# PaywallModule

**Layer**: Modules
**Purpose**: Çengelish Plus paywall (GolBil sırası). Üstte kısa gradyanlı kahraman (taçlı
Kalemo, başlık, tek satır), hemen altında Plus'ın sundukları (`PaywallPerkList`; seçime göre
animasyonla değişir: Plus'ta 8 madde — sınav paketleri, tema paketleri, sınırsız ipucu, tekrar bulmacası, seri dondurma, özel bulmaca temaları, yeni paketler, Plus rozeti; yalnızca gerçekten Plus'a bağlı kurallar yazılır — ilk 6'sı görünür + "N avantaj daha"; sınav paketinde
paket içeriği ve "Bu pakette yok · Plus'ta var" bölümü), sonra "Planını seç": "Çengelish Plus |
Sınav paketleri" sekmeleri (tek satır: ömür boyu Plus, tek seferlik; Türk lirası fiyatı `regularLifetimePrice` (1.499,99 ₺)
altındayken "Lansmana özel" rozeti ve "sonra 1.499,99 ₺" — App Store Connect'te zamanlanan fiyat
artışıyla eşleşmeli; başka para biriminde lansman metni yok; 5 tek seferlik sınav
paketi — YDS, YÖKDİL, LGS, IELTS, TOEFL). Abonelik yok. Altta sabit: satın alma butonu (`.plus`), hemen altında
"Satın alımları geri yükle", yasal açıklama (tek seferlik ödeme, yenilenmez), Gizlilik · Kullanım
Koşulları. Sağ üstte kapat (X). Her yerden tam ekran modal açılır (`Routing.present`,
kapatma `dismissModal`); navigasyon yığınına push edilmez. StoreKit fiyatı yoksa örnek fiyatlar (Plus 999,99 / her sınav paketi 199,99 ₺).

**Üyelik durumu** (`PaywallStage`): Plus üyesi paywall'u açınca planlar yerine "Çengelish
Plus'sın!" kahramanı, üyelik kartı (plan "Çengelish Plus Ömür Boyu", satın alma tarihi —
`EntitlementProviding.plusPurchaseDate`, durum "Aktif · süresiz"), Plus ile açık olanlar ve "Devam et". Plus satın alınınca / geri yüklenince `.welcome`
("Hadi başlayalım"), sınav paketi satın alınınca `.packUnlocked` ("LGS Paketi senin!") —
ikisinde de konfeti (Hareket Azaltma'da yok) ve başarı titreşimi; ekran artık satın almada
kendiliğinden kapanmaz. Yalnızca paket geri yüklenirse mesaj gösterilir, planlar "Sende var" olur.

## Public API

```swift
@MainActor protocol PaywallModuleInterface: AnyObject
  func createPaywallView(highlightProductId:) -> AnyView   // sınav paketi → paket sekmesi + o paket seçili; nil → ömür boyu Plus; Plus üyesinde üyelik durumu
```

## Structure

```
InterfaceSources/PaywallModuleInterface.swift
Package.swift
Sources/PaywallCoordinator.swift          // @Inject Routing, EntitlementProviding, ContentProviding
Sources/Model/PaywallModels.swift         // PaywallTab, PlanOption, Benefit, PaywallStage, MembershipFact
Sources/Model/ContentFacts.swift          // paket sayıları (ContentProviding.packs()'ten; yoksa gömülü içerik değerleri)
Sources/Model/PaywallCatalog.swift        // Plus ve sınav paketi avantajları (tema sayısı + 3 örnek), sınav seviye aralığı, Türkçe liste
Sources/View/PaywallView.swift            // ekran sırası, sabit alt alan (satın alma / devam), konfeti, LegalLinks
Sources/View/PaywallHero.swift            // kısa gradyanlı kahraman (planlar ve açılmış durum)
Sources/View/PaywallPerkList.swift        // avantaj kartı + BenefitRow (altın simge karosu)
Sources/View/PaywallPlanPicker.swift      // "Planını seç", PaywallTabPicker, PlanRow
Sources/View/PaywallUnlockedView.swift    // üyelik kartı + açılan ayrıcalıklar
Sources/View/PaywallConfetti.swift        // tek seferlik konfeti
Sources/ViewModel/PaywallViewModel.swift  // aşama, sekme/seçim, planlar, avantajlar, CTA, açıklama, satın alma, geri yükleme, üyelik metinleri
Tests/PaywallViewModelTests.swift
```

Plus avantajlarındaki her madde uygulamadaki gerçek bir kurala dayanır: paket kilidi
(`canAccess`), `HintRules.freeDailyHints`, `StreakRules.monthlyFreezes`, defterden tekrar
bulmacası, `PuzzleTheme.isPremium` temaları, `UnlockRules` (taç, Gece/Mercan arka planı),
profildeki Plus rozeti. Sayılar içerikten (`ContentFacts`) okunur.

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, PurchaseKit, ContentKit, UserDataKit (ipucu/seri kuralları), PuzzleKit (bulmaca temaları)
