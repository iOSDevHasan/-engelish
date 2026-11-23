import SwiftUI

/// Çengelish Plus marka adları.
public enum PlusBrand {
  /// Plus markasının tam adı.
  public static let name = "Çengelish Plus"
  /// Rozet ve kısa etiketlerde kullanılan ad.
  public static let short = "Plus"
}

/// Plus gerektiren öğelerin köşesine konan altın "PLUS" rozeti.
public struct PlusBadge: View {
  private let compact: Bool

  /// Rozeti oluşturur; `compact` küçük kartlar içindir.
  public init(compact: Bool = false) {
    self.compact = compact
  }

  public var body: some View {
    HStack(spacing: 3) {
      Image(systemName: "crown.fill").font(.system(size: compact ? 8 : 10, weight: .black))
      Text(PlusBrand.short.uppercased(with: Locale(identifier: "tr_TR")))
        .font(.system(size: compact ? 9 : 11, weight: .black, design: .rounded))
        .tracking(0.6)
    }
    .foregroundStyle(Palette.goldInk)
    .padding(.horizontal, compact ? 6 : 8)
    .frame(height: compact ? 18 : 22)
    .background(
      Capsule().fill(
        LinearGradient(
          colors: Palette.plusGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
    )
    .overlay(Capsule().strokeBorder(.white.opacity(0.55), lineWidth: 1))
    .shadow(color: Color(hex: 0xFF9F43).opacity(0.35), radius: 4, y: 2)
    .fixedSize()
    .accessibilityLabel(PlusBrand.name)
  }
}

extension View {
  /// Plus gerekiyorsa sağ üst köşeye Plus rozeti ekler.
  public func plusCorner(_ isShown: Bool, compact: Bool = true, inset: CGFloat = 8) -> some View {
    overlay(alignment: .topTrailing) {
      if isShown {
        PlusBadge(compact: compact).padding(inset)
          .allowsHitTesting(false)
          .transition(.scale.combined(with: .opacity))
      }
    }
  }
}

/// Paywall'a giden dikkat çekici kart: mor-pembe geçiş, taç, parıltı ve çağrı.
public struct PlusPromoCard: View {
  private let title: String
  private let subtitle: String
  private let cta: String
  private let action: () -> Void

  /// Başlık, alt metin, buton yazısı ve dokunma eylemiyle kart oluşturur.
  public init(
    title: String, subtitle: String, cta: String = "Plus'a geç",
    action: @escaping () -> Void
  ) {
    self.title = title
    self.subtitle = subtitle
    self.cta = cta
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack(alignment: .top, spacing: 14) {
        Image(systemName: "crown.fill")
          .font(.system(size: 20, weight: .black))
          .foregroundStyle(Palette.goldInk)
          .frame(width: 44, height: 44)
          .background(
            Circle().fill(
              LinearGradient(
                colors: Palette.plusGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
          )
          .symbolEffect(.bounce, options: .repeat(.periodic(delay: 3)))
        // Metin tüm genişliği kullanır; çağrı altta durur, böylece dar ekranda sıkışmaz.
        VStack(alignment: .leading, spacing: 4) {
          Text(title).font(AppFont.bodyBold).foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
          Text(subtitle).font(AppFont.caption).foregroundStyle(.white.opacity(0.85))
            .fixedSize(horizontal: false, vertical: true)
          HStack(spacing: 4) {
            Text(cta)
            Image(systemName: "chevron.right").font(.system(size: 11, weight: .black))
          }
          .font(AppFont.caption.weight(.black))
          .foregroundStyle(Palette.goldInk)
          .padding(.horizontal, 14)
          .frame(height: 32)
          .background(Capsule().fill(Palette.gold))
          .padding(.top, 6)
        }
        Spacer(minLength: 0)
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
          .fill(
            LinearGradient(
              colors: Palette.plusPromoGradient, startPoint: .topLeading,
              endPoint: .bottomTrailing))
      )
      .shimmer()
      .clipShape(RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous))
      .shadow(color: Color(hex: 0x6C5CE7).opacity(0.35), radius: 12, y: 8)
    }
    .buttonStyle(PressScaleButtonStyle())
  }
}

/// Altın geçişli, parıltılı Plus çağrı butonu stili.
public struct PlusButtonStyle: ButtonStyle {
  /// Stili oluşturur.
  public init() {}

  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(AppFont.bodyBold)
      .foregroundStyle(Palette.goldInk)
      .padding(.horizontal, 20)
      .frame(maxWidth: .infinity, minHeight: 54)
      .background(
        RoundedRectangle(cornerRadius: Metrics.buttonRadius, style: .continuous)
          .fill(
            LinearGradient(
              colors: Palette.plusGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
          )
          .shadow(
            color: Color(hex: 0xD9822B), radius: 0, y: configuration.isPressed ? 0 : 4)
      )
      .shimmer()
      .clipShape(RoundedRectangle(cornerRadius: Metrics.buttonRadius, style: .continuous))
      .offset(y: configuration.isPressed ? 4 : 0)
      .animation(.spring(duration: 0.18), value: configuration.isPressed)
  }
}

extension ButtonStyle where Self == PlusButtonStyle {
  /// Altın Plus çağrı butonu.
  public static var plus: PlusButtonStyle { PlusButtonStyle() }
}
