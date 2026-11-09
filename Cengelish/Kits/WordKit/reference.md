# WordKit

**Layer**: Kits
**Purpose**: Kelime satırı, kelime detay paneli ve cihazda telaffuz (AVSpeechSynthesizer).

## Public API

```swift
@MainActor protocol Pronouncing; final class Pronouncer
WordRow, WordDetailSheet   // init(word:boxLabel:onSpeak:primaryTitle:onPrimary:accent:onSpeakAccent:notebook:)
enum WordAccent            // .american / .british, languageCode, isBritish, init(languageCode:)
struct WordNotebookStatus  // firstSeen, box, maxBox, learned, onKeepReviewing, onLearned, onRemove
SegmentBar<Value>          // tasarımdaki bölmeli seçici (compact: küçük)
BoxDots, SpeakerButton     // Leitner kutu ilerlemesi (5 nokta), köşeli telaffuz butonu
```

## Structure

Sources/WordViews.swift (WordRow, WordDetailSheet) · Sources/WordSheetSupport.swift · Sources/Pronouncer.swift

## Dependencies

- ContentKit, DesignKit
