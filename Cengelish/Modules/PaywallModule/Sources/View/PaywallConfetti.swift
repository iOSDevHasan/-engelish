import DesignKit
import SwiftUI

/// Satın alma sonrası ekrana bir kez yağan altın, mor ve pembe konfeti. Hareket azaltma açıkken
/// gösterilmez (çağıran taraf kontrol eder).
struct PaywallConfetti: View {
  /// Tek bir konfeti parçası.
  private struct Piece: Identifiable {
    let id: Int
    let x: CGFloat
    let delay: Double
    let spin: Double
    let color: Color
    let size: CGSize
  }

  @State private var hasFallen = false
  /// Rastgele yerleşim bir kez çizilir; üst görünüm yenilense de parçalar karışmaz.
  @State private var pieces = Self.makePieces()

  var body: some View {
    GeometryReader { geometry in
      ForEach(pieces) { piece in
        RoundedRectangle(cornerRadius: 2)
          .fill(piece.color)
          .frame(width: piece.size.width, height: piece.size.height)
          .rotationEffect(.degrees(hasFallen ? piece.spin : 0))
          .position(
            x: piece.x * geometry.size.width,
            y: hasFallen ? geometry.size.height + 40 : -30
          )
          .animation(.easeIn(duration: 1.9).delay(piece.delay), value: hasFallen)
      }
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
    .onAppear { hasFallen = true }
  }

  /// Konfeti parçalarını rastgele dağıtır.
  private static func makePieces() -> [Piece] {
    let colors = Palette.plusGradient + Palette.plusPromoGradient + [.white]
    return (0..<30).map { index in
      Piece(
        id: index,
        x: .random(in: 0.04...0.96),
        delay: .random(in: 0...0.5),
        spin: .random(in: -540...540),
        color: colors.randomElement() ?? .white,
        size: CGSize(width: .random(in: 6...10), height: .random(in: 10...16)))
    }
  }
}
