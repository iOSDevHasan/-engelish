# NotebookModule

**Layer**: Modules
**Purpose**: Kelime Defterim: yalnızca bulmacalarda yanlış yapılan / bilinmeyen kelimeler
(`UserDataStore.finish` ekler; elle ekleme yok, eski `manual` kayıtlar görünmeye devam eder).
Özet (kelime / bugün tekrar / öğrenildi), Tümü / Tekrar / Öğrendim bölmeleri (satırlar animasyonla
girer/çıkar), boş durumda defterin nasıl dolduğunu anlatan kart, bulmacayla tekrar (Çengelish Plus,
Plus rozetli; Plus değilse altın `.plus` butonu paywall'u açar; `ReviewPuzzleBuilder` ile cihazda
üretilir, kalan kutular kelime havuzuyla dolar, `registerTransient` ile kaydedilip PuzzleModule'de
açılır; kurulamazsa ya da tekrar kelimelerinin hiçbiri sığmazsa `NotebookViewModel.Notice`
açıklaması uyarıda gösterilir), kelime detayı (WordKit `WordDetailSheet`, DesignKit
`.appBottomSheet(item:)` ile: aksan, örnek çevirisi, ilk görüldüğü yer, kutu, Öğrendim / Tekrarda
kalsın / Defterden çıkar). Kartla tekrar akışı kaldırıldı.

`NotebookViewModel` yönlendiriciyi (`NotebookCoordinator`) **güçlü** tutar: koordinatör DI'da
`factory` kayıtlı ve sekme görünümü yeniden kurulunca yenisi çözülür; zayıf tutulursa düşer ve
bulmaca / paywall butonu sessizce hiçbir şey yapmaz.

## Public API

```swift
@MainActor protocol NotebookModuleInterface: AnyObject
  func createNotebookView() -> AnyView
```

## Structure

```
InterfaceSources/NotebookModuleInterface.swift
Package.swift
Sources/NotebookCoordinator.swift
Sources/View/NotebookView.swift
Sources/ViewModel/NotebookViewModel.swift
Tests/NotebookViewModelTests.swift
```

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, WordKit, PurchaseKit
- PuzzleModuleInterface, PaywallModuleInterface
