# NotebookModule

**Layer**: Modules
**Purpose**: Kelime Defterim: özet (kelime / bugün tekrar / öğrenildi), Tümü / Tekrar / Öğrendim
bölmeleri, elle kelime ekleme (+), bulmacayla tekrar (Çengelish+; `ReviewPuzzleBuilder` ile cihazda
üretilir, `registerTransient` ile kaydedilip PuzzleModule'de açılır; ücretsizde paywall), kartla
tekrar, kelime detayı (aksan, örnek çevirisi, ilk görüldüğü yer, kutu, Öğrendim / Tekrarda kalsın).

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
