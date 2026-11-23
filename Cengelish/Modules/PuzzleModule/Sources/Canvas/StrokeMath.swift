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

  /// Çizgileri verilen dikdörtgenlere (harf kutularına) kırpar.
  ///
  /// Her çizginin noktaları sırayla test edilir; aynı kutuda kalan ardışık noktalar yeni bir çizgi
  /// olur, kutu dışına (ipucu, blok, boşluk ya da ızgara dışı) düşen noktalar atılır. Böylece bir
  /// kutudan taşan yazı komşu kutuda ayrı bir çizgi olarak kalır, ızgara dışındaki mürekkep
  /// kaydedilmez. Tamamı tek kutuda kalan çizgi hiç değiştirilmez.
  ///
  /// - Parameters:
  ///   - strokes: Çizim koordinatındaki çizgiler.
  ///   - rects: İzin verilen kutular (çizim koordinatında).
  ///   - minExtent: Bundan küçük kırıntılar (taşan uç) atılır.
  /// - Returns: Kırpılmış çizgiler ve bir değişiklik olup olmadığı.
  static func clip(
    _ strokes: [PKStroke], to rects: [CGRect], minExtent: CGFloat = 5
  ) -> (strokes: [PKStroke], changed: Bool) {
    var result: [PKStroke] = []
    var changed = false
    for stroke in strokes {
      let pieces = clip(stroke, to: rects, minExtent: minExtent)
      if pieces.count != 1 || pieces.first?.path.count != stroke.path.count { changed = true }
      result += pieces
    }
    return (result, changed)
  }

  /// Tek çizgiyi kutulara göre parçalara ayırır (bkz. `clip(_:to:minExtent:)`).
  static func clip(_ stroke: PKStroke, to rects: [CGRect], minExtent: CGFloat = 5) -> [PKStroke] {
    let bounds = stroke.renderBounds
    if rects.contains(where: { $0.contains(bounds) }) { return [stroke] }
    var runs: [[PKStrokePoint]] = []
    var current: [PKStrokePoint] = []
    var currentRect: Int?
    for point in stroke.path {
      let location = point.location.applying(stroke.transform)
      let index = rects.firstIndex { $0.contains(location) }
      if index != currentRect || index == nil {
        if !current.isEmpty { runs.append(current) }
        current = []
      }
      currentRect = index
      if index != nil { current.append(point) }
    }
    if !current.isEmpty { runs.append(current) }
    if runs.count == 1, runs[0].count == stroke.path.count { return [stroke] }
    return runs.compactMap { piece(of: stroke, points: $0, minExtent: minExtent) }
  }

  /// Noktalardan, kaynak çizginin mürekkebi ve dönüşümüyle yeni çizgi üretir; çok küçükse nil.
  private static func piece(
    of stroke: PKStroke, points: [PKStrokePoint], minExtent: CGFloat
  ) -> PKStroke? {
    guard points.count >= 2 else { return nil }
    let locations = points.map { $0.location.applying(stroke.transform) }
    let xs = locations.map(\.x)
    let ys = locations.map(\.y)
    guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max(),
      max(maxX - minX, maxY - minY) >= minExtent
    else { return nil }
    let path = PKStrokePath(controlPoints: points, creationDate: stroke.path.creationDate)
    var piece = PKStroke(
      ink: stroke.ink, path: path, transform: stroke.transform, mask: stroke.mask)
    piece.randomSeed = stroke.randomSeed
    return piece
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
