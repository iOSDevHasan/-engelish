# ContentKit

**Layer**: AppCore
**Purpose**: Kelime/bulmaca/paket modelleri; gömülü başlangıç içeriği (starter.json); uzak kaynaktan inen paketleri cihazda kalıcı saklar.

## Public API

```swift
Word, CEFRLevel, Puzzle, PuzzleEntry, GridPoint, Direction, Pack, PackKind, DailyEntry
ContentBundle, PackPayload, DailyPayload
protocol ContentProviding   // packs(), pack(id:), puzzle(id:), puzzles(inPack:), words(ids:), dailyPuzzle(for:), refreshFromRemote(entitledPackIds:)
protocol RemoteContentSource // fetchManifest(), downloadPack(_:), fetchDailies(from:limit:)
actor ContentStore: ContentProviding   // init(remote:cacheDirectory:)
enum DayKey, enum Gzip
```

## Structure

Model/ · Store/ · Resources/starter.json (tools/content/generate.py üretir)

## Dependencies

- Yok
