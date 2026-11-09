import CoreGraphics
import PencilKit
import PuzzleKit

/// Çizgileri kutulara atama ve kutular arası taşıma hesapları.
enum StrokeMath {

  /// Çizgilerden merkezi verilen dikdörtgenlerden birine düşenleri ayırır.
  ///
  /// - Returns: Her dikdörtgen için çizgiler ve kalan çizgiler.
  static func split(
    _ strokes: [PKStroke], into rects: [CGRect]
  ) -> (matched: [[PKStroke]], rest: [PKStroke]) {
    var matched = Array(repeating: [PKStroke](), count: rects.count)
    var rest: [PKStroke] = []
    for stroke in strokes {
      let bounds = stroke.renderBounds
      let center = CGPoint(x: bounds.midX, y: bounds.midY)
      if let index = rects.firstIndex(where: { $0.contains(center) }) {
        matched[index].append(stroke)
      } else {
        rest.append(stroke)
      }
    }
    return (matched, rest)
  }

  /// `from` dikdörtgenini `to` dikdörtgenine eşleyen dönüşüm.
  static func transform(from: CGRect, to: CGRect) -> CGAffineTransform {
    let scale = min(to.width / from.width, to.height / from.height)
    return CGAffineTransform(translationX: -from.midX, y: -from.midY)
      .concatenating(CGAffineTransform(scaleX: scale, y: scale))
      .concatenating(CGAffineTransform(translationX: to.midX, y: to.midY))
  }

  /// Çizgiyi verilen dönüşümle taşır.
  static func move(_ stroke: PKStroke, by transform: CGAffineTransform) -> PKStroke {
    var moved = stroke
    moved.transform = stroke.transform.concatenating(transform)
    return moved
  }
}
