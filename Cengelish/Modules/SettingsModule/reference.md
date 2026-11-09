# SettingsModule

**Layer**: Modules
**Purpose**: Ayarlar (profili düzenle, abonelik planı + yenilenme tarihi), uygulama görünümü, Bulmaca teması ekranı, veri ve yedekleme (iCloud, son yedek + Şimdi yedekle, dışa/içe aktarma, eski çizimler, silme).

## Public API

```swift
@MainActor protocol SettingsModuleInterface: AnyObject
  func createSettingsView() / createPuzzleThemeView() -> AnyView
  func createSettingsView(onEditProfile: (@MainActor () -> Void)?) -> AnyView
  // Ayarlar Profil modülünü tanımaz (Profil → Settings arayüzü; tersi paket döngüsü olurdu).
  // Profil ayarları açarken kendi düzenleme ekranını kancayla verir; kanca yoksa satır
  // takma adı küçük bir pencerede düzenler. Varsayılan uygulama createSettingsView()'a düşer.
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
