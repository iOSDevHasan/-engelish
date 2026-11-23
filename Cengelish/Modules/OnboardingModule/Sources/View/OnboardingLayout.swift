import DesignKit
import SwiftUI

/// Onboarding ekranlarının ortak yerleşim değerleri.
enum OnboardingLayout {
  /// iPad'de içeriğin en fazla genişliği.
  static let maxContentWidth: CGFloat = 560
  /// Bu yükseklikten kısa ekranlar (iPhone SE) sıkışık sayılır.
  static let compactHeight: CGFloat = 700
}

extension View {
  /// İçeriğe yatay kenar boşluğu verir, iPad'de genişliği sınırlar ve ortalar.
  func readableWidth() -> some View {
    padding(.horizontal, Metrics.gutter)
      .frame(maxWidth: OnboardingLayout.maxContentWidth)
      .frame(maxWidth: .infinity)
  }
}

/// Ekranın altına sabitlenen buton alanı (`safeAreaInset` içinde kullanılır).
struct PinnedFooter<Content: View>: View {
  private let content: Content

  /// İçerikle alt alan oluşturur.
  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    VStack(spacing: 10) { content }
      .readableWidth()
      .padding(.top, 10)
      .padding(.bottom, 12)
      .background {
        Palette.background
          .ignoresSafeArea()
          .shadow(color: Palette.background, radius: 10, y: -8)
      }
  }
}
