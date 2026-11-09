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
Sources/Canvas/DrawingCanvas.swift
Sources/Canvas/StrokeMath.swift
Sources/Model/PuzzleSession.swift
Sources/PuzzleCoordinator.swift
Sources/View/AnswerKeyView.swift
Sources/View/FinishView.swift
Sources/View/FocusView.swift
Sources/View/PuzzleSheets.swift
Sources/View/PuzzleView.swift
Sources/ViewModel/AnswerKeyViewModel.swift
Sources/ViewModel/FinishViewModel.swift
Sources/ViewModel/PuzzleViewModel.swift
Tests/PuzzleViewModelTests.swift
```

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PurchaseKit, PuzzleKit, WordKit, PaywallModuleInterface, SettingsModuleInterface
