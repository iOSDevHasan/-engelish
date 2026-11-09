# ContentKit

**Layer**: AppCore
**Purpose**: Kelime/bulmaca/paket modelleri; gömülü başlangıç içeriği (starter.json); uzak kaynaktan inen paketleri cihazda kalıcı saklar.

## Public API

```swift
Word, CEFRLevel, Puzzle, PuzzleEntry, GridPoint, Direction, Pack, PackKind, DailyEntry
ContentBundle, PackPayload, DailyPayload
protocol ContentProviding   // packs(), pack(id:), puzzle(id:), puzzles(inPack:), words(ids:), dailyPuzzle(for:), refreshFromRemote(entitledPackIds:)
                            // wordPool(), registerTransient(_:words:) (+ registerTransient(_:)); varsayılan uygulamalı
struct ReviewPuzzleBuilder  // init(seed:) / init(); build(dueWords:pool:now:) -> Puzzle?  (packId "review", id "review_<ms>")
extension Puzzle { var isReview: Bool }
struct SeededGenerator: RandomNumberGenerator   // SplitMix64, tohumlu
protocol RemoteContentSource // fetchManifest(), downloadPack(_:), fetchDailies(from:limit:)
actor ContentStore: ContentProviding   // init(remote:cacheDirectory:)
enum DayKey, enum Gzip
```

## Structure

Model/ · Store/ · Review/ (cihazda tekrar bulmacası üretici: generate.py ile aynı İsveç tipi
şablon + geri izlemeli doldurma; 7×7 / 7×9, 3–7 harf) · Resources/starter.json (tools/content/generate.py üretir)

Geçici bulmacalar (`registerTransient`) yalnızca bellekte tutulur; uygulama kapanınca silinir.

## Dependencies

- Yok
