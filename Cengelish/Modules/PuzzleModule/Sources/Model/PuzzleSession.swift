import ContentKit
import Foundation
import PuzzleKit

/// Cevap anahtarı ve bitiş ekranlarına aktarılan bulmaca durumu.
struct PuzzleSession {
  /// Bulmaca.
  let puzzle: Puzzle
  /// Ekranda gösterilecek başlık.
  let title: String
  /// Bulmacadaki kelimeler (kimlik → kelime).
  let words: [String: Word]
  /// Kullanıcının çizimi.
  let drawingData: Data
  /// İpucuyla açılan kutular.
  let revealed: Set<GridPoint>
  /// Kayıtlı işaretler.
  let marks: [String: Bool]
  /// Geçen süre.
  let durationSec: Int
  /// Paketteki sonraki bulmaca.
  let nextPuzzleId: String?

  /// Izgara düzeni.
  var layout: CrosswordLayout { CrosswordLayout(puzzle: puzzle) }
}

/// Çizim katmanının sabit (ölçek 1) geometrisi.
enum CanvasMetrics {
  /// Izgara kutusunun çizim koordinatındaki boyu.
  static let gridCell: CGFloat = 60
  /// Odak modundaki kutunun boyu.
  static let focusCell: CGFloat = 100
  /// Odak kutuları arası boşluk.
  static let focusSpacing: CGFloat = 16
  /// Odak alanının kenar boşluğu.
  static let focusPadding: CGFloat = 10

  /// Izgara geometrisi.
  static let grid = GridGeometry(cell: gridCell)

  /// Odak modunda bir satırdaki kutu sayısı.
  static func focusPerRow(_ count: Int) -> Int {
    count <= 5 ? count : Int((Double(count) / 2).rounded(.up))
  }

  /// Odak modunda `index`. kutunun çerçevesi.
  static func focusRect(index: Int, count: Int) -> CGRect {
    let perRow = focusPerRow(count)
    return CGRect(
      x: focusPadding + CGFloat(index % perRow) * (focusCell + focusSpacing),
      y: focusPadding + CGFloat(index / perRow) * (focusCell + focusSpacing),
      width: focusCell, height: focusCell)
  }

  /// Odak alanının toplam boyutu.
  static func focusSize(count: Int) -> CGSize {
    let perRow = focusPerRow(count)
    let rows = Int((Double(count) / Double(perRow)).rounded(.up))
    return CGSize(
      width: focusPadding * 2 + CGFloat(perRow) * focusCell + CGFloat(perRow - 1) * focusSpacing,
      height: focusPadding * 2 + CGFloat(rows) * focusCell + CGFloat(rows - 1) * focusSpacing)
  }
}
