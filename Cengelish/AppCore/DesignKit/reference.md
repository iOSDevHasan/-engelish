# DesignKit

**Layer**: AppCore
**Purpose**: Renk/yazı tokenları (açık+koyu), ortak bileşenler, Kalemo avatarı ve rozet madalyası.

## Public API

```swift
enum Palette            // dinamik renk tokenları (background, surface, ink, accent, good, bad, streak...)
enum AppFont, Metrics    // yuvarlak yazı ölçeği, köşe/kenar tokenları
enum DateText            // her zaman Türkçe tarih biçimleri
struct ChunkyButtonStyle // .chunky / .chunkySecondary / .ghost
View.card(), .screenBackground(), .chromeless()
View.statusBarScrim()   // gezinme çubuğu olmayan kaydırmalı ekranlarda durum çubuğunun arkasını örter
OptionRow, RadioMark, Pill, Eyebrow, ProgressBar, NavHeader, SettingsGroup, SettingsRow, DisclosureValue
FlowLayout, TrailingIconLabelStyle, IconCircle
PlusBrand (name/short), PlusBadge, View.plusCorner(_:), PlusPromoCard, PlusButtonStyle (.plus)
Motion (snappy/gentle/bouncy), PressScaleButtonStyle, View.appearAnimation(index:), View.shimmer()
UserAvatarView(photo:avatar:size:)  // profil fotoğrafı varsa o, yoksa Kalemo maskotu
View.appBottomSheet(isPresented:content:) / appBottomSheet(item:content:)
                          // kenarlara yapışık özel alt panel (içeriğe göre boy, %88'den uzunsa kaydırır;
                          // içerik kendi ScrollView'unu içermez); içeriden kapatma: @Environment(\.dismissAppSheet)
                          // içerik ölçülünce tam boyuyla aşağıdan kayarak açılır (.smooth 0.45 sn);
                          // sistem paneli gibi aşağı çekerek kapanır: tutamaktan ya da içerik en üstteyken her yerden
View.appSheet(detents:)   // yalnızca tam ekran (.large) sistem paneli için (seviye testi)
Palette.cardBorder, Palette.plusGradient, Palette.plusPromoGradient
LevelTint.color(code:) / ledge(code:)   // CEFR seviye renkleri (Keşfet seviye kartları, profil seviye kartı)
AvatarConfig(body, accessory, background), AvatarBody, AvatarAccessory, AvatarBackground
KalemoView, AvatarView, MedalView, BodyColorPicker, BackgroundPicker, AccessoryPicker
```

## Structure

Tokens/ · Components/ · Avatar/

## Dependencies

- Yok (sadece SwiftUI/UIKit)
