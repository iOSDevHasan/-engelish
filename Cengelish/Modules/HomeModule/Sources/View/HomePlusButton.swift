import DesignKit
import SwiftUI

/// Ana Sayfa'nın sağ üstündeki taçlı "PLUS" butonu; her zaman Çengelish Plus paywall'unu açar.
/// Plus olmayanlarda yüzey rengi daire, altın taç ve altın çerçeve; üyede altın dolgulu,
/// parlayan "üye" görünümü.
struct HomePlusButton: View {
  /// Kullanıcının Çengelish Plus'ı var mı.
  let isMember: Bool
  /// Dokununca çalışır (paywall'u açar).
  let action: () -> Void

  /// Dairenin çapı; aynı zamanda en küçük dokunma alanı.
  private static let diameter: CGFloat = 44
  /// Köşe rozetinin dairenin sağından taştığı mesafe.
  private static let badgeOverhang: CGFloat = 7

  var body: some View {
    Button(action: action) {
      crown
        .frame(width: Self.diameter, height: Self.diameter)
        .background(disc)
        .plusCorner(true, inset: -7)
        .contentShape(Circle())
        // Köşedeki "PLUS" rozeti daireden taşar; rozet sayfa kenar boşluğunu aşmasın.
        .padding(.trailing, Self.badgeOverhang)
    }
    .buttonStyle(PressScaleButtonStyle())
    .animation(Motion.gentle, value: isMember)
    .accessibilityLabel(isMember ? "\(PlusBrand.name) üyeliğin" : "\(PlusBrand.name)'a geç")
    .accessibilityHint(
      isMember ? "Üyelik durumunu gösterir" : "Sınav ve tema paketleri, sınırsız ipucu")
  }

  /// Taç simgesi: üyede koyu altın mürekkep, değilse altın geçiş; periyodik zıplar.
  @ViewBuilder
  private var crown: some View {
    let image = Image(systemName: "crown.fill").font(.system(size: 18, weight: .black))
    if isMember {
      image.foregroundStyle(Palette.goldInk)
    } else {
      image
        .foregroundStyle(
          LinearGradient(colors: Palette.plusGradient, startPoint: .top, endPoint: .bottom)
        )
        .symbolEffect(.bounce, options: .repeat(.periodic(delay: 4)))
    }
  }

  /// Daire zemini: üyede altın dolgu ve parıltı, değilse yüzey rengi ve altın çerçeve.
  @ViewBuilder
  private var disc: some View {
    if isMember {
      Circle()
        .fill(
          LinearGradient(
            colors: Palette.plusGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 1.5))
        .shadow(color: Color(hex: 0xFF9F43).opacity(0.45), radius: 8, y: 3)
    } else {
      Circle()
        .fill(Palette.surface)
        .overlay(
          Circle().strokeBorder(
            LinearGradient(
              colors: Palette.plusGradient, startPoint: .topLeading, endPoint: .bottomTrailing),
            lineWidth: 2)
        )
        .shadow(color: Palette.cardShadow, radius: 0, y: 2)
    }
  }
}
