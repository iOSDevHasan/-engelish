# WordKit

**Layer**: Kits
**Purpose**: Kelime satırı, kelime detay paneli ve cihazda telaffuz (AVSpeechSynthesizer).

## Public API

```swift
@MainActor protocol Pronouncing; final class Pronouncer
WordRow, WordDetailSheet   // init(word:boxLabel:onSpeak:primaryTitle:onPrimary:accent:onSpeakAccent:notebook:)
                           // WordDetailSheet düz içeriktir (ScrollView / .appSheet / ölçüm yok);
                           // sunan taraf .appBottomSheet(item:) { WordDetailSheet(...) } der,
                           // panel içeriğe göre boylanır ve gerekirse kendisi kaydırır
enum WordAccent            // .american / .british, languageCode, isBritish, init(languageCode:)
struct WordNotebookStatus  // firstSeen, box, maxBox, learned, onKeepReviewing, onLearned, onRemove
SegmentBar<Value>          // bölmeli seçici (compact: küçük); seçim kayarak geçer + dokunsal geri bildirim
BoxDots                    // Leitner kutu ilerlemesi (5 nokta)
SpeakerButton              // init(word:size:isRound:accent:label:action:) köşeli ya da yuvarlak
                           // telaffuz butonu; dokununca zıplar, küçülür, dokunsal geri bildirim
```

## Structure

Sources/WordViews.swift (WordRow, WordDetailSheet) · Sources/WordSheetSupport.swift · Sources/Pronouncer.swift

## Dependencies

- ContentKit, DesignKit
