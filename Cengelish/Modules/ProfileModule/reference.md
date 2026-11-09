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
Sources/Model/LevelProgress.swift      // seviye kartı formülü
Sources/Model/StreakMonth.swift        // aylık seri takvimi (çözülen / bugün / dondurulan)
Sources/Model/TurkishText.swift        // Türkçe ekler, "Ekim 2026'dan beri", "2 dk önce"
Sources/View/BadgesView.swift          // vitrin (3 rozet), kazanılanlar, sıradakiler
Sources/View/EditProfileView.swift     // önizleme + unvan, aksesuar notu, takma ad x/16
Sources/View/ProfileCard.swift         // kapak degradesi, kapak seçici, paylaşım kartı
Sources/View/ProfileView.swift
Sources/View/StreakCalendarCard.swift
Sources/ViewModel/ProfileViewModel.swift
Tests/ProfileViewModelTests.swift
```

## Notes

- Seviye ilerlemesi: `çalışılan = wordsSeen + defterde öğrenilen`; hedefler A1 300, A2 600,
  B1 1200, B2 2000, C1 3000; kalan = `max(0, hedef - çalışılan)`, çubuk = `çalışılan / hedef`.
- Seri dondurma: Çengelish+ kullanıcısında iki çözülen gün arasındaki tek boş gün dondurulmuş
  sayılır; aylık hak `ProfileViewModel.monthlyFreezeAllowance` (2).
- Profil paylaşımı: `ProfileShareCard` → `ImageRenderer` → `ShareLink`.

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PurchaseKit, SettingsModuleInterface, PaywallModuleInterface
