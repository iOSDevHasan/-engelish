# ContentKit

**Layer**: AppCore
**Purpose**: Kelime/bulmaca/paket modelleri; tüm içerik uygulamaya gömülü (starter.json: paketler, bulmacalar, 365 günlük takvim); ağ kullanmaz. Takvim bitince Günün Bulmacası cihazda üretilir ve önbelleğe yazılır.

## Public API

```swift
Word, CEFRLevel, Puzzle, PuzzleEntry, GridPoint, Direction, Pack, PackKind, DailyEntry
ContentBundle, PackPayload, DailyPayload
protocol ContentProviding   // packs(), pack(id:), puzzle(id:), puzzles(inPack:), words(ids:), dailyPuzzle(for:)
                            // wordPool(), registerTransient(_:words:) (+ registerTransient(_:)); varsayılan uygulamalı
struct ReviewPuzzleBuilder  // init(seed:) / init(); build(dueWords:pool:now:) -> Puzzle?  (packId "review", id "review_<ms>")
extension Puzzle { var isReview: Bool }
struct SeededGenerator: RandomNumberGenerator   // SplitMix64, tohumlu
struct DailyPuzzleBuilder  // init(words:); build(dayKey:) -> Puzzle?  (id "daily_<yyyy-MM-dd>", kind .daily)
actor ContentStore: ContentProviding   // init(cacheDirectory:)
enum DayKey, enum Gzip
```

## Structure

Model/ · Store/ · Review/ (cihazda tekrar bulmacası üretici: generate.py ile aynı İsveç tipi
şablon + geri izlemeli doldurma; 7×7 / 7×9, 3–7 harf) · Daily/ (cihazda günlük bulmaca) ·
Resources/starter.json (tools/content/generate.py üretir; 365 günlük takvim dahil)

## Günün Bulmacası (internetsiz)

`dailyPuzzle(for:)` sırası: önbellek/gömülü takvim (`dailies`) → yoksa `DailyPuzzleBuilder`
ile cihazda üretim → o da olmazsa gömülü günlüklerden tarihe göre biri.

- Üretim belirlenimcidir: tohum gün anahtarının FNV-1a özeti, havuz yalnızca **gömülü**
  kelimeler (A1–B1, sınav etiketsiz, 3–7 harf). Aynı gün herkes aynı bulmacayı alır. Günler
  A2/B1 dönüşümlüdür; her gün 6 "öne çıkan" kelime, seviyenin sabit karışık listesinde kayan
  pencereden seçilir (ardışık günler tekrar etmez). Izgarayı `ReviewPuzzleBuilder` kurar.
- Kimlik `daily_<gün>` (gömülü günlüklerle aynı biçim; rozet sayımı ve ilerleme
  aynı çalışır). `puzzle(id:)` ve `words(ids:)` üretilen bulmacayı bulur.
- Bugün ve geçmiş günler için üretilen bulmaca önbelleğe `gendaily-<gün>.json` olarak yazılır;
  sonraki sürümlerde gömülü içerik değişse de oynanan bulmaca (ve kalem çizimi) değişmez.
  Gelecek günler (widget) yalnızca bellekte üretilir; yeni bir sürümün gömülü takvimi onların
  yerini alabilir. Eski sürümlerin Firebase'den indirip önbelleğe yazdığı `pack-*` / `daily-*`
  dosyaları da (oynanmış ilerleme bozulmasın diye) okunmaya devam eder.

Geçici bulmacalar (`registerTransient`) yalnızca bellekte tutulur; uygulama kapanınca silinir.
Eski önbellek dosyaları gömülü içerikte olmayan kayıtları ekler; gömülü paketlerin yerini almaz.

`Tests/ContentIntegrityTests.swift` gömülü bulmacaların tamamını cevaplarla "çözer": kesişimler,
ipucu kutusu konumları, cevap–kelime eşleşmesi, ipucunun cevabı ele vermemesi, bulmaca içinde
tekrar eden kelime / ipucu ya da birbirini içeren cevap (TOAST / TOASTER) olmaması, paket ve
takvim bağlantıları. `generate.py` aynı kuralları üretirken uygular.

## Dependencies

- Yok
