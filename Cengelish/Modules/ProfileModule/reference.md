# ProfileModule

**Layer**: Modules
**Purpose**: Sade profil (sayaçlı kimlik kartı, İngilizce seviyesi kartı, tüm rozetler),
fotoğraf + takma ad düzenleme paneli ve GolBil tarzı rozet ızgarası (15 rozet).

## Public API

```swift
@MainActor protocol ProfileModuleInterface: AnyObject
  func createProfileView() -> AnyView
```

## Structure

```
InterfaceSources/ProfileModuleInterface.swift
Package.swift
Sources/ProfileCoordinator.swift          // profil, ayarlar (settings.createSettingsView())
Sources/Model/BadgeItem.swift             // rozet + ilerleme (7/10, halka ≤ %93), sıralama, anlamlar
Sources/Model/LevelProgress.swift         // seviye kartı formülü
Sources/Model/TurkishText.swift           // Türkçe ekler, "Ekim 2026'dan beri"
Sources/View/BadgeGrid.swift              // madalya ızgarası + dokununca ipucu balonu (yukarı/aşağı)
Sources/View/BadgeMedal.swift             // BadgeMedalCell (disk/halka), BadgeMedal (altın mühür), BadgeSeal
Sources/View/BadgeTooltip.swift           // anlam, nasıl kazanılır, ilerleme, ödül
Sources/View/EditProfileSheet.swift       // appBottomSheet: fotoğraf seç/kaldır (PhotosPicker) + takma ad x/16
Sources/View/ProfileCover.swift           // kapak degradesi
Sources/View/ProfileView.swift
Sources/ViewModel/ProfileViewModel.swift
Tests/ProfileViewModelTests.swift
```

## Notes

- Avatar: profil fotoğrafı varsa o, yoksa kalem maskotu (Kalemo). Maskot/kapak/unvan seçimi yok.
  Avatarın sağ altındaki kalem (ya da avatara dokunmak) `appBottomSheet` açar: fotoğraf seç /
  değiştir / kaldır ve takma ad. Seçilen fotoğraf `ProfilePhoto.normalized` ile arka planda
  512 px JPEG'e çevrilir, Kaydet'e basınca `setProfilePhoto` ile saklanır (Vazgeç saklamaz).
- Takma ad: en fazla 16 karakter, kırpılır; boşsa kayıtlı ad korunur, o da boşsa "User" + 6 rakam.
- Unvan seçilmez: açılmış unvanların en yükseği (`UserTitle.allCases` sırası) gösterilir.
- Rozetler: kazanılan = koyu disk üstünde altın mühür (hafif nefes alan parıltı), kazanılmayan =
  ilerleme halkası (`BadgeItem.maxRingFraction` 0.93) içinde soluk madalya. Dokununca balon
  (anlam, nasıl kazanılır, ilerleme, ödül). Vitrin yok: profilde tüm rozetler listelenir (ayrı
  rozet ekranı da yok). `UserProfile.showcaseBadges` alanı veri uyumu için durur, kullanılmaz.
- Sıra: kimlik kartı (kapak + desen, ortada kalemli avatar, ad, unvan, seviye, üyelik, altta 4
  sayaç), seviye kartı (DesignKit `LevelTint` renginde kabartmalı seviye rozeti + çubuk), "Rozetler"
  kartı (sayaç, ilerleme çubuğu, 3 sütunlu ızgarada 15 rozetin tamamı: önce kazanılanlar, sonra
  hedefe en yakınlar).
- Seviye ilerlemesi: `çalışılan = wordsSeen + defterde öğrenilen`; hedefler A1 300, A2 600,
  B1 1200, B2 2000, C1 3000; kalan = `max(0, hedef - çalışılan)`, çubuk = `çalışılan / hedef`.

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PurchaseKit, SettingsModuleInterface
