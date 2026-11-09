# SettingsModule

**Layer**: Modules
**Purpose**: Ayarlar, uygulama görünümü, Bulmaca teması ekranı, veri ve yedekleme (iCloud, dışa/içe aktarma, silme).

## Public API

```swift
@MainActor protocol SettingsModuleInterface: AnyObject
  func createSettingsView() / createPuzzleThemeView() -> AnyView
```

## Structure

```
InterfaceSources/SettingsModuleInterface.swift
Package.swift
Sources/SettingsCoordinator.swift
Sources/View/AppearanceView.swift
Sources/View/DataView.swift
Sources/View/PuzzleThemeView.swift
Sources/View/SettingsView.swift
Sources/ViewModel/SettingsViewModel.swift
Tests/SettingsViewModelTests.swift
```

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PurchaseKit, PuzzleKit, PaywallModuleInterface
