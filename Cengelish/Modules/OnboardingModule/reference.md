# OnboardingModule

**Layer**: Modules
**Purpose**: Karşılama, takma ad (avatar her zaman kalem maskotu `AvatarConfig.mascot`; boş bırakılırsa "User" + 6 rakam, ör. "User482913"), seviye (+ 10 soruluk uyarlanabilir seviye testi), amaç/günlük hedef/hatırlatıcı, veri tercihi (cihaz / iCloud); bitişte Çengelish Plus paywall'u bir kez (kapatılabilir) açılır.

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
Sources/View/LevelTestView.swift          — seviye testi alt paneli (.appSheet, soru, şıklar, sonuç)
Sources/View/OnboardingLayout.swift       — ortak yerleşim: readableWidth() (gutter + iPad'de 560 pt), PinnedFooter
Sources/View/OnboardingView.swift         — adımlar; ScrollView + safeAreaInset ile sabit alt buton
Sources/ViewModel/LevelTestViewModel.swift — kelime havuzu ContentProviding paketlerinden; doğruda bir üst, yanlışta bir alt seviye
Sources/ViewModel/OnboardingViewModel.swift — adım/yön, takma ad (defaultNickname, resolvedNickname), kayıt
Tests/OnboardingViewModelTests.swift
```

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PurchaseKit, PuzzleKit, PaywallModuleInterface

## Notes

- Yerleşim: her adım kendi `ScrollView`'unda; üstte adım çubuğu, altta birincil buton `safeAreaInset`
  ile sabit (klavye açılınca butonla birlikte yukarı kalkar). Kısa ekranlarda (< 700 pt, iPhone SE)
  karşılama ızgarası ve maskot küçülür.
- Animasyon: adım geçişi `Motion.gentle` (yeni adım yön tarafından kayarak, eskisi solarak),
  seçimler `Motion.snappy` + seçim titreşimi, maskot `Motion.bouncy` ile girer. Hareketi Azalt
  açıksa yalnızca solma kullanılır.
