# ProfileModule

**Layer**: Modules
**Purpose**: Profil (kapak, avatar, unvan, istatistik, rozet vitrini), profili düzenle, rozetler.

## Public API

```swift
@MainActor protocol ProfileModuleInterface: AnyObject
  func createProfileView() -> AnyView
```

## Structure

```
InterfaceSources/ProfileModuleInterface.swift
Package.swift
Sources/ProfileCoordinator.swift
Sources/View/BadgesView.swift
Sources/View/EditProfileView.swift
Sources/View/ProfileView.swift
Sources/ViewModel/ProfileViewModel.swift
Tests/ProfileViewModelTests.swift
```

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PurchaseKit, SettingsModuleInterface, PaywallModuleInterface
