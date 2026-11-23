import SwiftUI

/// Uygulama genelindeki animasyon eğrileri.
public enum Motion {
  /// Kısa, yaylanan geçiş (seçim, buton).
  public static let snappy = Animation.spring(response: 0.32, dampingFraction: 0.78)
  /// Yumuşak giriş (kartlar, listeler).
  public static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.85)
  /// Kutlama zıplaması.
  public static let bouncy = Animation.spring(response: 0.42, dampingFraction: 0.55)
}

/// Basınca hafifçe küçülen buton stili.
public struct PressScaleButtonStyle: ButtonStyle {
  /// Stili oluşturur.
  public init() {}

  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(Motion.snappy, value: configuration.isPressed)
  }
}

/// Görünüm ilk belirdiğinde aşağıdan süzülerek gelir.
private struct AppearModifier: ViewModifier {
  let delay: Double
  @State private var isShown = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func body(content: Content) -> some View {
    content
      .opacity(isShown ? 1 : 0)
      .offset(y: isShown || reduceMotion ? 0 : 14)
      .onAppear {
        withAnimation(Motion.gentle.delay(delay)) { isShown = true }
      }
  }
}

/// Üzerinden soldan sağa geçen parıltı.
private struct ShimmerModifier: ViewModifier {
  @State private var phase: CGFloat = -1
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func body(content: Content) -> some View {
    content.overlay {
      if !reduceMotion {
        GeometryReader { proxy in
          LinearGradient(
            colors: [.clear, .white.opacity(0.35), .clear], startPoint: .leading,
            endPoint: .trailing
          )
          .frame(width: proxy.size.width * 0.45)
          .rotationEffect(.degrees(18))
          .offset(x: phase * proxy.size.width * 1.6)
          .allowsHitTesting(false)
        }
        .onAppear {
          withAnimation(.easeInOut(duration: 1.6).delay(1.2).repeatForever(autoreverses: false)) {
            phase = 1
          }
        }
      }
    }
  }
}

extension View {
  /// İlk belirişte aşağıdan süzülerek gelir; `index` sıralı (kademeli) gecikme verir.
  public func appearAnimation(index: Int = 0) -> some View {
    modifier(AppearModifier(delay: Double(index) * 0.05))
  }

  /// Görünüme tekrarlayan bir parıltı ekler (Plus çağrıları için).
  public func shimmer() -> some View {
    modifier(ShimmerModifier())
  }
}
