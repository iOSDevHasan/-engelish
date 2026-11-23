import DesignKit
import SwiftUI

/// Paywall'un üstündeki kısa kahraman alanı: taçlı Kalemo, başlık ve tek satırlık özet.
/// Mor-pembe gradyan durum çubuğunun arkasına uzanır; açılmış durumda maskot büyür ve zıplar.
struct PaywallHero: View {
  /// Başlık ("Çengelish Plus", "Çengelish Plus'sın!").
  let title: String
  /// Tek satırlık özet.
  let subtitle: String
  /// Plus açıldı mı (üyelik ya da satın alma sonrası): maskot büyür ve kutlama yapar.
  var isUnlocked = false
  /// Durum çubuğunun yüksekliği; gradyan onun arkasına uzanır, içerik altında başlar.
  var topInset: CGFloat = 0

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isFloating = false

  var body: some View {
    VStack(spacing: 6) {
      KalemoView(body: .yellow, accessory: .crown)
        .frame(height: isUnlocked ? 92 : 68)
        .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
        .offset(y: isFloating ? -3 : 3)
        .padding(.bottom, 4)
        .accessibilityHidden(true)
      Text(title)
        .font(AppFont.title)
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.8)
        .contentTransition(.opacity)
        .accessibilityAddTraits(.isHeader)
      Text(subtitle)
        .font(AppFont.body)
        .foregroundStyle(.white.opacity(0.88))
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .contentTransition(.opacity)
    }
    .padding(.horizontal, Metrics.gutter + 8)
    .padding(.top, 10 + topInset)
    .padding(.bottom, 22)
    .frame(maxWidth: .infinity)
    .background(alignment: .bottom) { backdrop }
    .onAppear {
      guard !reduceMotion else { return }
      withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
        isFloating = true
      }
    }
  }

  /// Altı yuvarlatılmış, yukarı taşan gradyan zemin ve süs parıltıları.
  ///
  /// Ekran aşağı çekilince (en üstte esneme) gradyan yukarı doğru uzar; kahramanın üstünde
  /// sayfa zemini görünmez. Uzama yalnızca çizimde yapılır (yerleşim ve durum değişmez); alt
  /// köşeler ölçeklenmeyen, yukarı taşan bir maskeyle yuvarlatılır.
  private var backdrop: some View {
    LinearGradient(
      colors: Palette.plusPromoGradient, startPoint: .topLeading, endPoint: .bottomTrailing
    )
    .visualEffect { content, proxy in
      let pull = max(0, proxy.frame(in: .scrollView(axis: .vertical)).minY)
      let height = max(proxy.size.height, 1)
      return content.scaleEffect(x: 1, y: (height + pull) / height, anchor: .bottom)
    }
    .mask(alignment: .bottom) {
      UnevenRoundedRectangle(
        bottomLeadingRadius: 28, bottomTrailingRadius: 28, style: .continuous
      )
      .padding(.top, -Self.overscrollAllowance)
    }
    .overlay(alignment: .bottomLeading) {
      Image(systemName: "sparkle")
        .font(.system(size: 20, weight: .bold))
        .foregroundStyle(.white.opacity(0.35))
        .padding(.leading, 30)
        .padding(.bottom, 54)
    }
    .overlay(alignment: .bottomTrailing) {
      Image(systemName: "sparkles")
        .font(.system(size: 24, weight: .bold))
        .foregroundStyle(.white.opacity(0.3))
        .padding(.trailing, 36)
        .padding(.bottom, 30)
    }
    .accessibilityHidden(true)
  }

  /// Maskenin kahramanın üstüne taşma payı (en uzun esnemeden fazla).
  private static let overscrollAllowance: CGFloat = 2000
}
