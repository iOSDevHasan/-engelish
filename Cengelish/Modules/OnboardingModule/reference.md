# OnboardingModule

**Layer**: Modules
**Purpose**: Karşılama, profil oluşturma (avatar + takma ad), seviye (+ 10 soruluk uyarlanabilir seviye testi), amaç/günlük hedef/hatırlatıcı, veri tercihi (cihaz / iCloud); bitişte Çengelish+ paywall'u bir kez (kapatılabilir) açılır.

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
Sources/View/LevelTestView.swift          — seviye testi (soru, şıklar, sonuç)
Sources/View/OnboardingView.swift
Sources/ViewModel/LevelTestViewModel.swift — kelime havuzu ContentProviding paketlerinden; doğruda bir üst, yanlışta bir alt seviye
Sources/ViewModel/OnboardingViewModel.swift
Tests/OnboardingViewModelTests.swift
```

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PurchaseKit, PuzzleKit, PaywallModuleInterface
