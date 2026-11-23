import DesignKit
import SwiftUI

/// Plus'ın (ya da seçili sınav paketinin) sunduklarını gösteren kart; kahramanın hemen altında
/// durur ve seçime göre animasyonla değişir. Uzun Plus listesi ilk altı maddeyle başlar.
struct PaywallPerkList: View {
  @ObservedObject var viewModel: PaywallViewModel

  var body: some View {
    let visible = viewModel.visibleBenefits
    let included = visible.filter(\.isIncluded)
    let excluded = visible.filter { !$0.isIncluded }
    VStack(alignment: .leading, spacing: 14) {
      Text(viewModel.benefitsTitle)
        .font(AppFont.section)
        .foregroundStyle(Palette.ink)
        .contentTransition(.opacity)
        .accessibilityAddTraits(.isHeader)
      ForEach(included) { benefit in
        BenefitRow(benefit: benefit).transition(Self.rowTransition)
      }
      if !excluded.isEmpty {
        Eyebrow("Bu pakette yok · Plus'ta var", color: Palette.muted)
          .padding(.top, 4)
          .transition(.opacity)
        ForEach(excluded) { benefit in
          BenefitRow(benefit: benefit).transition(Self.rowTransition)
        }
      }
      if viewModel.canToggleBenefits {
        expandButton.transition(.opacity)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .card()
    .animation(Motion.snappy, value: viewModel.selected)
    .animation(Motion.snappy, value: viewModel.isBenefitsExpanded)
    .animation(Motion.gentle, value: viewModel.facts)
  }

  /// "5 avantaj daha" / "Daha az göster" düğmesi.
  private var expandButton: some View {
    Button(action: viewModel.toggleBenefits) {
      HStack(spacing: 6) {
        Text(
          viewModel.isBenefitsExpanded
            ? "Daha az göster" : "\(viewModel.hiddenBenefitCount) avantaj daha"
        )
        .contentTransition(.numericText())
        Image(systemName: "chevron.down")
          .font(.system(size: 11, weight: .black))
          .rotationEffect(.degrees(viewModel.isBenefitsExpanded ? 180 : 0))
      }
      .font(AppFont.caption.weight(.heavy))
      .foregroundStyle(Palette.accent)
      .frame(maxWidth: .infinity, minHeight: 40)
      .background(Capsule().fill(Palette.selection))
      .contentShape(Capsule())
    }
    .buttonStyle(PressScaleButtonStyle())
  }

  /// Avantaj satırlarının giriş/çıkış geçişi.
  private static let rowTransition = AnyTransition.asymmetric(
    insertion: .opacity.combined(with: .offset(y: 8)), removal: .opacity)
}

/// Avantaj satırı: dahil olanlar altın simge karosu ve onay taşır; dahil olmayanlar soluk
/// görünür ve sağında Plus rozeti taşır.
struct BenefitRow: View {
  let benefit: Benefit

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: benefit.systemImage)
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(benefit.isIncluded ? Palette.goldInk : Palette.muted)
        .frame(width: 34, height: 34)
        .background(tile)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        Text(benefit.title)
          .font(AppFont.bodyBold)
          .foregroundStyle(benefit.isIncluded ? Palette.ink : Palette.muted)
          .fixedSize(horizontal: false, vertical: true)
          .contentTransition(.numericText())
        Text(benefit.detail)
          .font(AppFont.caption)
          .foregroundStyle(Palette.muted)
          .fixedSize(horizontal: false, vertical: true)
          .contentTransition(.opacity)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      if benefit.isIncluded {
        Image(systemName: "checkmark")
          .font(.system(size: 13, weight: .black))
          .foregroundStyle(Palette.accent)
          .padding(.top, 10)
          .accessibilityHidden(true)
      } else {
        PlusBadge(compact: true).padding(.top, 8)
      }
    }
    .accessibilityElement(children: .combine)
  }

  /// Simge karosu: dahilse altın geçiş, değilse sade yüzey.
  @ViewBuilder
  private var tile: some View {
    let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
    if benefit.isIncluded {
      shape.fill(
        LinearGradient(
          colors: Palette.plusGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
    } else {
      shape.fill(Palette.surface2)
    }
  }
}
