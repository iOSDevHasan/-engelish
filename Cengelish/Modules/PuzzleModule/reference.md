# PuzzleModule

**Layer**: Modules
**Purpose**: Bulmaca çözme: PencilKit ile kalem/kurşun/silgi, iki parmakla zoom, odak modu, ipucu ve tema panelleri, cevap anahtarı (✓/✗), bitiş ve paylaşım kartı.

## Public API

```swift
@MainActor protocol PuzzleModuleInterface: AnyObject
  func createPuzzleView(puzzleId:) -> AnyView
```

## Structure

```
InterfaceSources/PuzzleModuleInterface.swift
Package.swift
Sources/Canvas/DrawingCanvas.swift      # PencilKit alanı; onViewport ile zoom / görünen alan bildirir
Sources/Canvas/StrokeMath.swift
Sources/Model/PuzzleSession.swift
Sources/Model/PuzzlePresentation.swift  # PuzzleLayoutMode, EntryNavigation, MarkSummary, ZoomText, ShareText
Sources/PuzzleCoordinator.swift         # bulmaca → anahtar → bitiş → paylaş
Sources/View/AnswerKeyView.swift
Sources/View/FinishView.swift
Sources/View/FocusView.swift            # FocusView + FoldFocusPanel ve ortak parçalar (FocusBoxes…)
Sources/View/PuzzlePanels.swift         # CluePanel (iPad), ZoomOverlay (yüzde, mini harita, ipucu)
Sources/View/PuzzleSheets.swift
Sources/View/PuzzleView.swift           # telefon / iPad / katlanabilir yerleşimler, PuzzleToolbar
Sources/View/ShareView.swift            # ShareView, ShareCardView, ShareStoryView (9:16)
Sources/ViewModel/AnswerKeyViewModel.swift
Sources/ViewModel/FinishViewModel.swift
Sources/ViewModel/PuzzleViewModel.swift
Sources/ViewModel/ShareViewModel.swift  # ShareCard, PhotoSaving / PhotoLibrarySaver
Sources/ViewModel/ZoomState.swift       # CanvasViewport, tek seferlik zoom ipucu (UserDefaults)
Tests/PuzzlePresentationTests.swift
Tests/PuzzleViewModelTests.swift
```

## Notes

- Yerleşim: genişlik ≥ 600 ve en/boy 0.8–1.3 → katlanabilir (ızgara + yan odak alanı, yazılar
  ızgaraya anında yansır); değilse regular genişlikte iPad, aksi halde telefon.
- Kaydet (Fotoğraflar) için uygulama Info.plist'inde `NSPhotoLibraryAddUsageDescription` gerekir;
  anahtar yoksa izin istenmez, kullanıcıya "Kaydedilemedi" bildirilir.

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PurchaseKit, PuzzleKit, WordKit, PaywallModuleInterface, SettingsModuleInterface
