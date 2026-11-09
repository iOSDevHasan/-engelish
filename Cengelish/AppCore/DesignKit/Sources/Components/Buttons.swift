import SwiftUI

/// Çengelish buton türleri.
public enum ChunkyButtonKind: Sendable {
  case primary
  case secondary
  case ghost
}

/// Alt gölgesi basınca kaybolan, tasarımdaki "tok" buton stili.
public struct ChunkyButtonStyle: ButtonStyle {
  private let kind: ChunkyButtonKind
  private let fullWidth: Bool
  private let compact: Bool

  /// Buton stilini tür, genişlik ve boyutla oluşturur.
  public init(_ kind: ChunkyButtonKind = .primary, fullWidth: Bool = true, compact: Bool = false) {
    self.kind = kind
    self.fullWidth = fullWidth
    self.compact = compact
  }

  public func makeBody(configuration: Configuration) -> some View {
    let pressed = configuration.isPressed
    let depth: CGFloat = kind == .ghost ? 0 : 4
    return configuration.label
      .font(compact ? AppFont.caption.weight(.heavy) : AppFont.bodyBold)
      .foregroundStyle(foreground)
      .padding(.horizontal, compact ? 14 : 20)
      .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: compact ? 36 : 52)
      .background(
        RoundedRectangle(cornerRadius: Metrics.buttonRadius, style: .continuous)
          .fill(fill)
          .shadow(color: shadow, radius: 0, y: pressed ? 0 : depth)
      )
      .offset(y: pressed ? depth : 0)
      .animation(.spring(duration: 0.18), value: pressed)
      .contentShape(Rectangle())
  }

  private var fill: Color {
    switch kind {
    case .primary: Palette.buttonFill
    case .secondary: Palette.surface
    case .ghost: .clear
    }
  }

  private var foreground: Color {
    switch kind {
    case .primary: .white
    case .secondary: Palette.ink
    case .ghost: Palette.muted
    }
  }

  private var shadow: Color {
    switch kind {
    case .primary: Palette.buttonShadow
    case .secondary: Palette.secondaryShadow
    case .ghost: .clear
    }
  }
}

extension ButtonStyle where Self == ChunkyButtonStyle {
  /// Mor dolgulu ana buton.
  public static var chunky: ChunkyButtonStyle { ChunkyButtonStyle(.primary) }
  /// Beyaz ikincil buton.
  public static var chunkySecondary: ChunkyButtonStyle { ChunkyButtonStyle(.secondary) }
}

/// Yuvarlak ikon butonu (geri, kapat, daha fazla).
public struct IconCircle: View {
  private let systemName: String
  private let size: CGFloat
  private let accent: Bool

  /// SF Symbol adı, çap ve vurgu bilgisiyle ikon oluşturur.
  public init(_ systemName: String, size: CGFloat = 40, accent: Bool = false) {
    self.systemName = systemName
    self.size = size
    self.accent = accent
  }

  public var body: some View {
    Image(systemName: systemName)
      .font(.system(size: size * 0.42, weight: .bold))
      .foregroundStyle(accent ? Color.white : Palette.ink)
      .frame(width: size, height: size)
      .background(Circle().fill(accent ? Palette.buttonFill : Palette.surface))
      .shadow(color: accent ? Palette.buttonShadow : Palette.cardShadow, radius: 0, y: 2)
  }
}
