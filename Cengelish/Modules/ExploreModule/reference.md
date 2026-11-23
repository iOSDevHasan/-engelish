# ExploreModule

**Layer**: Modules
**Purpose**: Keşfet (arama, Tümü/Seviyeler/Sınavlar/Temalar filtresi, seviye kareleri, sınav ve tema
paketleri, Plus tanıtımı, tüm temalar listesi) ve paket detayı (sırayla açılan bulmaca kareleri,
Plus kilidi, paywall).

## Public API

```swift
@MainActor protocol ExploreModuleInterface: AnyObject
  func createExploreView() / createPackView(packId:) -> AnyView
```

Arama ve tema listesi ekranları modül içinden (`ExploreCoordinator.showSearch()` /
`showThemes(viewModel:)`) açılır; arayüze eklenmedi.

## Rules

- Tüm paketler `ContentProviding.packs()`'ten gelir (`.level`, `.exam`, `.theme`); bulmacası olmayan
  paket gizlenir.
- Plus kilidi (`PackRules`): sınav paketi `canAccess(productId: pack.productId)`; seviye/tema paketi
  yalnızca Çengelish Plus (`canAccess(productId: nil)`). Bulmaca `pack.isFree(index:)` ise Plus
  istemez. Seviye paketleri (A1–C1) içerikte tamamen ücretsizdir (`freeCount` = bulmaca sayısı);
  Plus yalnızca sınav ve tema paketlerini açar. Paywall sınavda paketin ürünüyle, seviye/temada `nil` ile açılır. Plus gereken her kart
  ve satırda kilit/"Premium" yerine DesignKit `PlusBadge` (`.plusCorner`) gösterilir; bulmaca
  karelerinde sağ üst köşeye yaslı, karenin şekliyle kırpılan altın `PlusCornerTab`
  (`.plusCornerTab(_:cornerRadius:)`).
- Sıralı oynama (`PackRules.access(stars:plusLocked:) -> [PuzzleAccess]`): bitmiş bulmaca hep tekrar
  oynanır (`.finished`); ilk bitmemiş bulmaca `.next` ("Sıradaki", vurgulu, nabız halkası) ya da Plus
  istiyorsa `.needsPlus` (altta "Plus"); sonraki bitmemişler `.needsPrevious(blocker:needsPlus:)`
  (soluk kare, kilit; Plus da gerekiyorsa ayrıca köşe sekmesi). Sıradaki Plus istiyorsa ondan sonraki Plus'lı
  bulmacalar da `.needsPlus` olur (ilerlemenin tek yolu Plus). Sıra kilitli kareye dokununca kare
  sallanır, uyarı titreşimi ve "Önce N. bulmacayı bitir" baloncuğu (~2 sn) çıkar.
- Paywall girişleri öne çıkar: Keşfet'te (Tümü) ve tema listesinde `PlusPromoCard` (Plus yoksa),
  sınav başlığında dokunulabilir `PlusBadge`, paket detayında üst barda `PlusBadge`, Plus'lı bulmaca
  varsa `PlusPromoCard`, sıradaki Plus istiyorsa ana buton `.buttonStyle(.plus)` "Kilidi aç".
- Seviye aralığı: seviye paketinde kendi seviyesi; diğerlerinde bulmaca seviyelerinin min–max'ı,
  tek seviyeyse bilinen sınav aralığı (`yds/yokdil B2–C1`, `lgs A2–B1`, `ielts/toefl B1–C1`).
- Arama: paket başlığı/açıklaması ve kelimenin İngilizcesi/Türkçe anlamı (büyük-küçük harf ve Türkçe
  karakter duyarsız); kelime dizini paketlerin bulmacalarındaki kelimelerden kurulur. Kelimeye
  dokununca WordKit `WordDetailSheet` DesignKit `.appBottomSheet(item:)` ile açılır (panel kendisi
  kaydırır; defter rozeti yalnızca kelime zaten defterdeyse).
- Seviye kartı (`LevelCardView`, Duolingo tarzı "kabartma" anatomi): seviye renginde madalyon (A1,
  alt kenarı koyu), Türkçe ad, "N bulmaca" (seviye renginde), konular (2 satır yer ayrılır), seviye
  renginde dolan ilerleme + "3/12"; yüzey seviye rengiyle hafif boyalı, köşede soluk büyük kod.
  Kullanıcının seviyesi renkli 2 pt kenar ve üst kenardan sarkan "SENİN SEVİYEN" etiketi. Renk
  kimliği `PackStyle` (A1 yeşil, A2 mavi, B1 mor, B2 eflatun, C1 turuncu; sınavda `ExamStyle`,
  temada vurgu); paket detayındaki ilerleme çubuğu da paketin rengindedir.
- Yerleşim: seviyeler "Tümü"de kenardan kenara yatay şerit (kart 160 pt, `viewAligned`, açılışta
  kullanıcının seviyesine kayar — `showsLevelCarousel`, `currentLevelId`), "Seviyeler" bölümünde
  `adaptive(min 150)` ızgara; sınav kartları `adaptive(min 148)`, tema kareleri `adaptive(min 104)`,
  bulmaca kareleri `adaptive(72–104)` (her iPhone'da 4, iPad'de daha fazla; 26 pt numara, 12 pt
  durum metni, küçültme yok); içerik genişliği Keşfet 760, paket 640, liste 680 pt ile sınırlı.
  Metinler `lineLimit` / `ViewThatFits` ile kelime ortasında kesilmez.
- Animasyon: kartlarda `appearAnimation(index:)` kademeli giriş; paket detayındaki kare ızgarası tembel değildir (kareler bir kez kurulur, kaydırınca yeniden oluşmaz) ve giriş animasyonu ızgaranın tamamında bir kez oynar; `PressScaleButtonStyle`,
  bölüm değişiminde kayarak geçiş, `FillingProgressBar` ile dolan ilerleme; Hareketi Azalt'a uyar.

## Structure

```
InterfaceSources/ExploreModuleInterface.swift
Package.swift
Sources/ExploreCoordinator.swift
Sources/Model/PackRules.swift          // PackRules (Plus kilidi, sıralı oynama, aralık, simge),
                                       // PuzzleAccess, TurkishText
Sources/View/ExploreView.swift
Sources/View/ExploreComponents.swift   // SectionHeader, LevelCardView, PackStyle, ExamCardView,
                                       // ExamStyle, ThemeTileView, FillingProgressBar, ShakeEffect,
                                       // NudgeToast, PlusCornerTab
Sources/View/PackView.swift            // PuzzleTileView
Sources/View/SearchView.swift
Sources/View/ThemeListView.swift
Sources/ViewModel/ExploreViewModel.swift   // PackCard, ExploreSegment
Sources/ViewModel/PackViewModel.swift      // PuzzleTile, SequenceNudge
Sources/ViewModel/SearchViewModel.swift    // WordIndexEntry
Tests/ContentFixture.swift
Tests/ExploreViewModelTests.swift
```

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PurchaseKit, PuzzleKit, WordKit, PuzzleModuleInterface,
  PaywallModuleInterface
- Injected services: `ContentProviding`, `UserDataStoring`, `EntitlementProviding`, `Pronouncing`
