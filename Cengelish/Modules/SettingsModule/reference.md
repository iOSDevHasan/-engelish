# SettingsModule

**Layer**: Modules
**Purpose**: Ayarlar (Çengelish Plus kartı ya da "Ömür boyu" + satın alma tarihi; dokununca paywall üyelik durumu, açıklama balonlu ayar
satırları), uygulama görünümü, Bulmaca teması ekranı, veri ve yedekleme (iCloud, cihazdaki alan,
en altta "Tüm verileri sil" onay paneli).

## Public API

```swift
@MainActor protocol SettingsModuleInterface: AnyObject
  func createSettingsView() -> AnyView
  func createPuzzleThemeView() -> AnyView
```

## Structure

```
InterfaceSources/SettingsModuleInterface.swift
Package.swift
Sources/SettingsCoordinator.swift
Sources/View/AppearanceView.swift
Sources/View/DataView.swift             // iCloud, alan kullanımı, en altta yalnızca "Tüm verileri sil"
Sources/View/DeleteDataSheet.swift      // appBottomSheet onayı: uyarı, silinecekler, satın alım notu
Sources/View/PuzzleThemeView.swift      // Plus temalarında PlusBadge köşesi, PlusPromoCard
Sources/View/SettingInfoRow.swift       // SettingInfoRow, SettingInfoBubble, SettingInfo (metinler)
Sources/View/SettingsView.swift
Sources/ViewModel/SettingsViewModel.swift
Tests/SettingsViewModelTests.swift
```

## Notes

- `SettingInfoRow`: başlığa (ikon + başlık + ⓘ) dokununca `.popover` +
  `.presentationCompactAdaptation(.popover)` ile iPhone'da da gerçek balon açılır; sağdaki
  anahtar / seçici / tarih seçici bağımsız çalışır. `action` verilirse başlığın sağındaki alan
  (değer + ok) gezinmeyi yapar. Açıklamalar `SettingInfo` içinde (1–2 cümle).
- Profil düzenleme Ayarlar'da yok; fotoğraf ve takma ad Profil'deki kimlik kartından düzenlenir.
- Plus olmayan kullanıcıda Plus satırı yerine en üstte `PlusPromoCard` (paywall) görünür.
- Tema adları `PuzzleTheme.theme(id:).name`'den; tema ekranındaki Plus kartı Plus tema sayısını
  gösterir.
- Tüm verileri sil: `DeleteDataSheet` onaylanınca panel kapanır, kapanış bitince
  `SettingsViewModel.eraseAllData()` → `UserDataStoring.deleteAll()` + `applyReminder` (bekleyen
  bildirimler kalkar). Depo `dataErased` yayınlar; açılış ekranı + onboarding'i kabuk gösterir.
- Dosyaya dışa/içe aktarma, "Şimdi yedekle" ve eski çizimleri temizleme kaldırıldı.

## Dependencies

- RouterKit, InjectionKit (backbone)
- DesignKit, ContentKit, UserDataKit, PurchaseKit, PuzzleKit, PaywallModuleInterface
