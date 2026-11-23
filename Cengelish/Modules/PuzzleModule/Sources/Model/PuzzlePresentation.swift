import ContentKit
import CoreGraphics
import Foundation
import PuzzleKit

// MARK: - Layout mode

/// Bulmaca ekranının yerleşimi: telefon, iPad (geniş) ya da katlanabilir (kareye yakın, geniş).
enum PuzzleLayoutMode: Equatable {
  case phone
  case tablet
  case fold

  /// Katlanabilir yerleşim için gereken en küçük genişlik.
  static let foldMinWidth: CGFloat = 600
  /// Katlanabilir yerleşimde kabul edilen en/boy oranı aralığı.
  static let foldAspect: ClosedRange<CGFloat> = 0.8...1.3

  /// Kapsayıcı boyutu ve yatay boyut sınıfına göre yerleşimi seçer.
  static func resolve(size: CGSize, isRegularWidth: Bool) -> PuzzleLayoutMode {
    guard size.width > 0, size.height > 0 else { return isRegularWidth ? .tablet : .phone }
    let aspect = size.width / size.height
    if size.width >= foldMinWidth, foldAspect.contains(aspect) { return .fold }
    return isRegularWidth ? .tablet : .phone
  }
}

// MARK: - Entry helpers

/// Kelime gezinme ve doluluk hesapları.
enum EntryNavigation {
  /// Seçili kelimenin önceki ve sonraki komşularının ipuçları (odak modu butonları).
  static func neighbourLabels(
    in layout: CrosswordLayout, around entry: PuzzleEntry
  ) -> (previous: String, next: String) {
    (
      layout.entry(after: entry, step: -1).clue,
      layout.entry(after: entry, step: 1).clue
    )
  }

  /// Kelimenin tüm kutuları yazılmış ya da ipucuyla açılmışsa veya doğru işaretlendiyse `true`.
  static func isDone(
    _ entry: PuzzleEntry, filled: Set<GridPoint>, revealed: Set<GridPoint>,
    marks: [String: Bool]
  ) -> Bool {
    if marks[entry.id] == true { return true }
    return entry.cells.allSatisfy { filled.contains($0) || revealed.contains($0) }
  }

  /// Kelimenin harf deseni: açılan harfler görünür, diğerleri `_` (cevabı açık etmez).
  static func pattern(_ entry: PuzzleEntry, revealed: Set<GridPoint>) -> String {
    entry.cells.map { cell in
      revealed.contains(cell) ? entry.letter(at: cell).map(String.init) ?? "_" : "_"
    }
    .joined(separator: " ")
  }

  /// Kesişen kelimelerin ipuçları.
  static func crossingText(_ entry: PuzzleEntry, in layout: CrosswordLayout) -> String {
    var seen = Set<String>()
    let others = entry.cells.flatMap { layout.entries(at: $0) }
      .filter { $0 != entry && seen.insert($0.id).inserted }
    guard !others.isEmpty else { return "Kesişen kelime yok" }
    let arrow = entry.dir == .across ? "↓" : "→"
    return "Kesişen: " + others.map { "\($0.clue) \(arrow)" }.joined(separator: " · ")
  }
}

// MARK: - Keyboard

/// Klavye girişi ve kutu ilerleme hesapları.
enum TypedInput {
  /// Yazılan metnin son karakterini İngilizce büyük harfe çevirir (ı/i → I); harf değilse nil.
  static func letter(from text: String) -> Character? {
    guard let last = text.last else { return nil }
    let mapped: Character =
      switch last {
      case "ı", "i", "İ": "I"
      default: Character(String(last).uppercased(with: Locale(identifier: "en_US_POSIX")))
      }
    guard mapped.isASCII, mapped.isLetter else { return nil }
    return mapped
  }

  /// Kelimede `from` kutusundan (dahil) başlayıp ileri doğru ilk açılmamış kutu.
  static func writableCell(
    in entry: PuzzleEntry, from cell: GridPoint?, revealed: Set<GridPoint>
  ) -> GridPoint? {
    let start = cell.flatMap { entry.cells.firstIndex(of: $0) } ?? 0
    return entry.cells[start...].first { !revealed.contains($0) }
  }

  /// `cell` kutusundan sonraki ilk açılmamış kutu; yoksa nil.
  static func nextCell(
    in entry: PuzzleEntry, after cell: GridPoint, revealed: Set<GridPoint>
  ) -> GridPoint? {
    guard let index = entry.cells.firstIndex(of: cell) else { return nil }
    return entry.cells[(index + 1)...].first { !revealed.contains($0) }
  }

  /// `cell` kutusundan önceki ilk açılmamış kutu; yoksa nil.
  static func previousCell(
    in entry: PuzzleEntry, before cell: GridPoint, revealed: Set<GridPoint>
  ) -> GridPoint? {
    guard let index = entry.cells.firstIndex(of: cell) else { return nil }
    return entry.cells[..<index].last { !revealed.contains($0) }
  }
}

// MARK: - Hints

/// İpucuyla açılacak kutuların seçimi.
enum HintPicker {
  /// "Bir harf aç" için kutu: seçili kutu açılmamışsa o; değilse önce boş, sonra herhangi bir
  /// açılmamış kutu. Kelimenin tamamı açıksa nil (hak harcanmaz).
  static func letterTarget(
    in entry: PuzzleEntry, active: GridPoint?, revealed: Set<GridPoint>, filled: Set<GridPoint>
  ) -> GridPoint? {
    if let active, entry.cells.contains(active), !revealed.contains(active) { return active }
    let hidden = entry.cells.filter { !revealed.contains($0) }
    return hidden.first { !filled.contains($0) } ?? hidden.first
  }

  /// "Kelimeyi göster" için açılmamış kutular.
  static func wordTargets(in entry: PuzzleEntry, revealed: Set<GridPoint>) -> [GridPoint] {
    entry.cells.filter { !revealed.contains($0) }
  }
}

// MARK: - Answer key

/// Cevap anahtarındaki işaret özeti.
enum MarkSummary {
  /// "{x} doğru · {y} yanlış" metni.
  static func text(_ marks: [String: Bool]) -> String {
    let correct = marks.values.filter { $0 }.count
    return "\(correct) doğru · \(marks.count - correct) yanlış"
  }
}

// MARK: - Zoom

/// Yakınlaştırma metinleri.
enum ZoomText {
  /// Sığdırma ölçeğine göre yakınlaştırma yüzdesi ("%185").
  static func percent(_ zoom: CGFloat) -> String {
    "%\(Int((zoom * 100).rounded()))"
  }
}

// MARK: - Share

/// Paylaşım metinleri ve bağlantısı.
enum ShareText {
  /// Uygulama bağlantısı.
  static let link = "https://cengelish.app"
  /// Mesajla paylaşılan metin.
  static let message = "Ben bugünün Çengelish bulmacasını çözdüm! Sen de çöz: \(link)"
  /// Kartın alt yazısı.
  static let footer = "Cevaplar gizli · Sen de çöz → Çengelish"

  /// Kelime sırasına göre sonuç kareleri (işaretsiz kelime doğru sayılır).
  static func results(entries: [PuzzleEntry], marks: [String: Bool]) -> [Bool] {
    entries.map { marks[$0.id] ?? true }
  }

  /// Karttaki "Ad · Seviye" satırı.
  static func owner(name: String, level: String) -> String {
    "\(name) · \(level)"
  }
}
