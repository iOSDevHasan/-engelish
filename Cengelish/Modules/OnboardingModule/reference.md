# OnboardingModule

**Layer**: Modules
**Purpose**: Karşılama, profil oluşturma (avatar + takma ad), seviye, amaç/hatırlatıcı, veri tercihi (cihaz / iCloud).

## Public API

```swift
@MainActor protocol OnboardingModuleInterface: AnyObject
  func createOnboardingView(onFinish:) -> AnyView
```

## Structure

```
InterfaceSources/OnboardingModuleInterface.swift
Package.swift
Sources/OnboardingCoordinator.swift
Sources/View/OnboardingView.swift
Sources/ViewModel/OnboardingViewModel.swift
Tests/OnboardingViewModelTests.swift
```

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PuzzleKit
