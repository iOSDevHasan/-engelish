import SwiftUI

/// Kart görünümü: yüzey rengi, yuvarlak köşe ve yumuşak gölge.
public struct CardModifier: ViewModifier {
  private let padding: CGFloat
  private let fill: Color

  /// İç boşluk ve dolgu rengiyle kart stili oluşturur.
  public init(padding: CGFloat, fill: Color) {
    self.padding = padding
    self.fill = fill
  }

  public func body(content: Content) -> some View {
    content
      .padding(padding)
      .background(
        RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
          .fill(fill)
          .shadow(color: Palette.cardShadow, radius: 0, y: 2)
          .shadow(color: Color.black.opacity(0.06), radius: 14, y: 10)
      )
  }
}

extension View {
  /// Görünümü Çengelish kartı içine alır.
  public func card(padding: CGFloat = 16, fill: Color = Palette.surface) -> some View {
    modifier(CardModifier(padding: padding, fill: fill))
  }

  /// Ekranın standart arka planını uygular.
  public func screenBackground() -> some View {
    background(Palette.background.ignoresSafeArea())
  }
}

/// Seçilebilir seçenek satırı (seviye, amaç, paket planı).
public struct OptionRow<Content: View>: View {
  private let isSelected: Bool
  private let content: Content

  /// Seçim durumu ve içerikle satır oluşturur.
  public init(isSelected: Bool, @ViewBuilder content: () -> Content) {
    self.isSelected = isSelected
    self.content = content()
  }

  public var body: some View {
    HStack(spacing: 12) { content }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
      .background(
        RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
          .fill(isSelected ? Palette.selection : Palette.surface)
          .overlay(
            RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
              .strokeBorder(isSelected ? Palette.accent : Palette.line, lineWidth: 2)
          )
          .shadow(color: isSelected ? Palette.selectionShadow : Palette.line, radius: 0, y: 3)
      )
  }
}

/// Seçenek satırlarındaki yuvarlak radyo işareti.
public struct RadioMark: View {
  private let isOn: Bool

  /// Seçim durumuyla radyo işareti oluşturur.
  public init(isOn: Bool) {
    self.isOn = isOn
  }

  public var body: some View {
    Circle()
      .strokeBorder(isOn ? Palette.accent : Palette.lineStrong, lineWidth: isOn ? 7 : 2)
      .frame(width: 22, height: 22)
  }
}
