# NotebookModule

**Layer**: Modules
**Purpose**: Kelime Defterim: Leitner kutuları, bugünün tekrarları (kart), kelime detayı.

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
- DesignKit, ContentKit, UserDataKit, WordKit
