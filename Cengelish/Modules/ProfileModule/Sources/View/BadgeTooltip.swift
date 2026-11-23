import DesignKit
import SwiftUI

/// Rozete dokununca açılan balon: anlamı, nasıl kazanıldığı, ilerleme ve ödülü.
struct BadgeTooltip: View {
  let item: BadgeItem
  /// Rozetin kazanılma tarihi metni ("3 Kas").
  let dateText: String

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 10) {
        BadgeMedal(symbol: item.symbol).frame(width: 34, height: 34)
        VStack(alignment: .leading, spacing: 1) {
          Text(item.title).font(AppFont.rounded(15, weight: .black))
          Text(item.isEarned ? "Kazanıldı · \(dateText)" : "Henüz kazanılmadı")
            .font(AppFont.rounded(11, weight: .bold))
            .foregroundStyle(item.isEarned ? BadgeColors.gold : .white.opacity(0.65))
        }
      }
      Text(item.meaning)
        .font(AppFont.rounded(12.5, weight: .semibold))
        .foregroundStyle(.white.opacity(0.88))
        .fixedSize(horizontal: false, vertical: true)
      VStack(alignment: .leading, spacing: 2) {
        Text("Nasıl kazanılır?")
          .font(AppFont.rounded(11, weight: .heavy))
          .foregroundStyle(.white.opacity(0.6))
        Text(item.requirement)
          .font(AppFont.rounded(12.5, weight: .bold))
          .fixedSize(horizontal: false, vertical: true)
      }
      if !item.isEarned { progress }
      if let reward = item.reward {
        Label(reward, systemImage: "gift.fill")
          .font(AppFont.rounded(11.5, weight: .bold))
          .foregroundStyle(BadgeColors.gold)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .foregroundStyle(.white)
    .padding(14)
    .frame(width: 240, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Self.bubble)
        .overlay(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(.white.opacity(0.12), lineWidth: 1))
    )
    .shadow(color: .black.opacity(0.28), radius: 16, y: 6)
    .accessibilityElement(children: .contain)
  }

  /// Sayaçlı rozette çubuk ve "7/10"; anlık rozette yalnızca not.
  private var progress: some View {
    VStack(alignment: .leading, spacing: 5) {
      if item.counter != nil {
        ProgressBar(value: item.progress, tint: BadgeColors.gold, height: 6)
          .accessibilityHidden(true)
      }
      Text(item.progressText)
        .font(AppFont.rounded(11.5, weight: .heavy))
        .foregroundStyle(.white.opacity(0.8))
        .monospacedDigit()
    }
  }

  /// Balonun zemini (iki modda da koyu, kart zemininden ayrışır).
  static let bubble = Palette.dynamic(0x24204D, 0x3A3175)
}

/// Balonu rozete bağlayan küçük üçgen ok (aşağı bakar).
struct BadgeTooltipArrow: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}
