import Foundation
import Testing
@testable import ContentKit

@Suite("ContentStore")
struct ContentKitTests {

  @Test("Gömülü içerik çözülür ve her bulmacanın kelimeleri havuzda vardır")
  func starterBundleIsConsistent() throws {
    let bundle = try ContentStore.loadStarterBundle()
    let wordIds = Set(bundle.words.map(\.id))
    #expect(!bundle.packs.isEmpty)
    #expect(!bundle.dailies.isEmpty)
    for puzzle in bundle.puzzles {
      for entry in puzzle.entries {
        #expect(wordIds.contains(entry.wordId))
      }
    }
  }

  @Test("Kesişen kutularda iki kelimenin harfi aynıdır ve ipucu kutuları harf kutusu değildir")
  func gridsAreValid() throws {
    let bundle = try ContentStore.loadStarterBundle()
    for puzzle in bundle.puzzles {
      var letters: [GridPoint: Character] = [:]
      let clues = Set(puzzle.entries.map(\.clueCell))
      for entry in puzzle.entries {
        for (point, char) in zip(entry.cells, entry.answer) {
          if let existing = letters[point] { #expect(existing == char) }
          letters[point] = char
          #expect(point.row < puzzle.height && point.col < puzzle.width)
        }
      }
      #expect(clues.isDisjoint(with: letters.keys))
    }
  }

  @Test("Takvimde olmayan bir gün için de günlük bulmaca döner")
  func dailyFallback() async {
    let store = ContentStore(
      cacheDirectory: URL.temporaryDirectory.appending(path: UUID().uuidString))
    let far = Date(timeIntervalSince1970: 4_000_000_000)
    #expect(await store.dailyPuzzle(for: far) != nil)
  }

  @Test("Gzip: üretici aracın yazdığı paket dosyası açılır ve çözülür")
  func gzipRoundTrip() throws {
    // python3 -c "import gzip;print(list(gzip.compress(b'{\"a\":1}',mtime=0)))"
    let bytes: [UInt8] = [
      31, 139, 8, 0, 0, 0, 0, 0, 2, 255, 171, 86, 74, 84, 178, 50, 172, 5, 0, 175, 172, 27, 86,
      7, 0, 0, 0,
    ]
    let json = try Gzip.decompress(Data(bytes))
    #expect(String(data: json, encoding: .utf8) == "{\"a\":1}")
  }
}
