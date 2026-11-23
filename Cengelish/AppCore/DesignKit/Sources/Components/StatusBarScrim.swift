import SwiftUI

extension View {
  /// Durum çubuğunun (saat, pil) arkasını ekran zeminiyle örter; gezinme çubuğu olmayan
  /// kaydırmalı ekranlarda içerik saatin altına karışmaz.
  ///
  /// Sıfır yükseklikli üst ek alanın zemini güvenli alanın üstüne taşar, yani yalnızca durum
  /// çubuğunu kaplar; içeriğin yerleşimi değişmez.
  public func statusBarScrim() -> some View {
    safeAreaInset(edge: .top, spacing: 0) {
      Color.clear
        .frame(height: 0)
        .background(Palette.background.ignoresSafeArea(edges: .top))
        .allowsHitTesting(false)
    }
  }
}
