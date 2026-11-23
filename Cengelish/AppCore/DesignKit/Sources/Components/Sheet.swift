import SwiftUI

extension View {
  /// Uygulamanın alt panel (bottom sheet) görünümü: zemin, köşe, tutamak ve yükseklikler.
  ///
  /// Panel içeriğinin kökünde kullanılır; içerik kaydırılabilir olmalı ve üstte 8 pt boşluk
  /// bırakmalıdır.
  public func appSheet(
    detents: Set<PresentationDetent> = [.medium, .large]
  ) -> some View {
    self
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .scrollIndicators(.hidden)
      .presentationDetents(detents)
      .presentationDragIndicator(.visible)
      .presentationCornerRadius(28)
      .presentationBackground(Palette.background)
      .presentationContentInteraction(.scrolls)
  }
}
