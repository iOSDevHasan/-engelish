import DesignKit
import SwiftUI

/// Plus üyesi paywall'u açınca ya da satın alma / geri yükleme sonrası planların yerine
/// gösterilen içerik: üyelik kartı (plan, satın alma tarihi, durum) ve açılan ayrıcalıkların listesi.
struct PaywallUnlockedView: View {
  /// Plan ve satın alma bilgisi; boşsa kart gösterilmez.
  let facts: [MembershipFact]
  /// Ayrıcalık listesinin başlığı.
  let benefitsTitle: String
  /// Açılan ayrıcalıklar.
  let benefits: [Benefit]

  var body: some View {
    VStack(spacing: 16) {
      if !facts.isEmpty {
        membershipCard.appearAnimation(index: 1)
      }
      perksCard.appearAnimation(index: 2)
    }
  }

  /// Plan, satın alma tarihi ve durum satırları; köşesinde Plus rozeti.
  private var membershipCard: some View {
    VStack(spacing: 0) {
      ForEach(Array(facts.enumerated()), id: \.element.id) { index, fact in
        if index > 0 {
          Rectangle().fill(Palette.line).frame(height: 1).padding(.leading, 46)
        }
        HStack(spacing: 12) {
          Image(systemName: fact.systemImage)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Palette.goldInk)
            .frame(width: 34, height: 34)
            .background(
              RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                  LinearGradient(
                    colors: Palette.plusGradient, startPoint: .topLeading,
                    endPoint: .bottomTrailing))
            )
            .accessibilityHidden(true)
          Text(fact.label)
            .font(AppFont.caption)
            .foregroundStyle(Palette.muted)
          Spacer(minLength: 8)
          Text(fact.value)
            .font(AppFont.bodyBold)
            .foregroundStyle(Palette.ink)
            .multilineTextAlignment(.trailing)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
      }
    }
    .card(padding: 14)
    .plusCorner(true, compact: false, inset: -8)
  }

  /// Açılan ayrıcalıklar: yeşil onaylı, sık satırlar.
  private var perksCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(benefitsTitle)
        .font(AppFont.section)
        .foregroundStyle(Palette.ink)
        .accessibilityAddTraits(.isHeader)
      ForEach(benefits) { benefit in
        HStack(alignment: .firstTextBaseline, spacing: 10) {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Palette.good)
            .accessibilityHidden(true)
          Text(benefit.title)
            .font(AppFont.body)
            .foregroundStyle(Palette.ink)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .card()
  }
}
