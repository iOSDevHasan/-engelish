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
OptionRow, RadioMark, Pill, Eyebrow, ProgressBar, NavHeader, SettingsGroup, SettingsRow, DisclosureValue
FlowLayout, TrailingIconLabelStyle, IconCircle
AvatarConfig(body, accessory, background), AvatarBody, AvatarAccessory, AvatarBackground
KalemoView, AvatarView, MedalView, BodyColorPicker, BackgroundPicker, AccessoryPicker
```

## Structure

Tokens/ · Components/ · Avatar/

## Dependencies

- Yok (sadece SwiftUI/UIKit)
