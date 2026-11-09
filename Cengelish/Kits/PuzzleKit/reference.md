# PuzzleKit

**Layer**: Kits
**Purpose**: Çengel ızgara modeli ve çizimi, 6 bulmaca teması, kalem renkleri, tema kartı.

## Public API

```swift
struct CrosswordLayout   // kind(at:), entries(at:), entry(at:preferring:), entry(after:step:), answer(at:)
struct PuzzleGridView, MiniGridView, GridGeometry (sabit çizim geometrisi)
struct PuzzleTheme      // canli, kagit, gece, okyanus, pastel*, kareli*; resolve(id:isDark:autoNight:highContrast:)
enum PenStyle, PenColorRow, ThemeOptionCard, SamplePuzzles.demo
```

## Structure

Sources/

## Dependencies

- ContentKit, DesignKit
