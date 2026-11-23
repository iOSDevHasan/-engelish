# PuzzleKit

**Layer**: Kits
**Purpose**: Çengel ızgara modeli ve çizimi, 18 bulmaca teması (6 ücretsiz, 12 Çengelish Plus), kalem renkleri, tema kartı.

## Public API

```swift
struct CrosswordLayout   // kind(at:), entries(at:), entry(at:preferring:), entry(after:step:), answer(at:)
struct PuzzleGridView     // letters (ipucu/anahtar/dolgu) + typed (klavye harfleri, el yazısı) + typedInk;
                          // harfler belirirken büyür / zıplar (Hareketi Azalt'ta sadece saydamlık)
struct GridGeometry       // sabit çizim geometrisi
struct MiniGridView      // init(puzzle:theme:cellSize:highlighted:active:) — vurgu verilmezse ilk yatay kelime
struct PuzzleTheme      // all (gösterim sırası), theme(id:), resolve(id:isDark:autoNight:highContrast:)
                        // ücretsiz: canli, kagit, gece, okyanus
                        // Plus (*): pastel, kareli, orman, gunbatimi, sepya ("Retro Gazete"),
                        //           gecemavisi, karatahta, neon
                        // keepsInDarkMode: koyu görünümü olan tema "Koyu modda Gece" ile değişmez
                        // (canli, gece ve yeni 6 Plus tema; orman/gunbatimi/sepya açık+koyu dinamik)
                        // "Koyu modda Gece" varsayılan kapalı; koyu görünümü olmayan tema elle
                        // seçilince kapanır; tema seçmek yüksek kontrastı da kapatır (Puzzle/Settings
                        // selectTheme) — seçim hep uygulanır
enum PenStyle, PenColorRow, SamplePuzzles.demo
struct ThemeOptionCard   // Plus temalarında sağ üstte PlusBadge (plusCorner), seçim işareti sol üstte
View.themePreviewBackdrop()   // tema önizlemesini ekran zemini renginde altlığa koyar (beyaz kutular kaybolmaz)
```

## Structure

```
Sources/CrosswordLayout.swift
Sources/PenStyle.swift        # PenStyle, PenColorRow, ThemeOptionCard
Sources/PuzzleGridView.swift  # PuzzleGridView, MiniGridView, GridGeometry
Sources/PuzzleTheme.swift     # tema kataloğu
Sources/SamplePuzzles.swift
Tests/PuzzleKitTests.swift    # ızgara + tema kataloğu (benzersiz kimlik, Plus, WCAG kontrast)
```

## Notes

- Tema kimlikleri ayarlarda saklanır; değiştirilmez. Yeni tema `all`'a eklenince Ayarlar'daki
  tema ızgarası, bulmacadaki tema paneli ve paywall avantaj listesi otomatik görür.
- Testler her temada kalem/kutu, kalem/vurgu, kalem/etkin ve ipucu yazısı için açık+koyu modda
  ≥ 4.5:1 kontrast ister.

## Dependencies

- ContentKit, DesignKit
