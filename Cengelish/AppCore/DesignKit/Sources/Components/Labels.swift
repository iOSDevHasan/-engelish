import SwiftUI

/// Rozet (pill) renk tonu.
public enum PillTone: Sendable {
  case neutral
  case accent
  case gold
  case good
  case bad
}

/// Küçük bilgi rozeti: "B1", "3 hak", "Premium".
public struct Pill: View {
  private let text: String
  private let systemImage: String?
  private let tone: PillTone

  /// Metin, isteğe bağlı ikon ve renk tonuyla rozet oluşturur.
  public init(_ text: String, systemImage: String? = nil, tone: PillTone = .neutral) {
    self.text = text
    self.systemImage = systemImage
    self.tone = tone
  }

  public var body: some View {
    HStack(spacing: 4) {
      if let systemImage {
        Image(systemName: systemImage).font(.system(size: 10, weight: .bold))
      }
      Text(text).lineLimit(1)
    }
    .font(AppFont.tiny.weight(.black))
    .foregroundStyle(foreground)
    .padding(.horizontal, 8)
    .frame(height: 22)
    .background(Capsule().fill(background))
    .fixedSize()
  }

  private var background: Color {
    switch tone {
    case .neutral: Palette.surface2
    case .accent: Palette.accent
    case .gold: Palette.gold
    case .good: Palette.goodBackground
    case .bad: Palette.badBackground
    }
  }

  private var foreground: Color {
    switch tone {
    case .neutral: Palette.ink
    case .accent: .white
    case .gold: Palette.goldInk
    case .good: Palette.good
    case .bad: Palette.bad
    }
  }
}

/// Büyük harfli küçük üst başlık.
public struct Eyebrow: View {
  private let text: String
  private let color: Color

  /// Metin ve renkle üst başlık oluşturur.
  public init(_ text: String, color: Color = Palette.accent) {
    self.text = text
    self.color = color
  }

  public var body: some View {
    Text(text.uppercased(with: Locale(identifier: "tr_TR")))
      .font(AppFont.eyebrow)
      .tracking(1.4)
      .foregroundStyle(color)
  }
}

/// İlerleme çubuğu.
public struct ProgressBar: View {
  private let value: Double
  private let tint: Color
  private let height: CGFloat

  /// 0...1 aralığındaki değer, renk ve yükseklikle çubuk oluşturur.
  public init(value: Double, tint: Color = Palette.accent, height: CGFloat = 8) {
    self.value = value
    self.tint = tint
    self.height = height
  }

  public var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .leading) {
        Capsule().fill(Palette.surface2)
        Capsule().fill(tint)
          .frame(width: max(height, proxy.size.width * min(max(value, 0), 1)))
      }
    }
    .frame(height: height)
  }
}

/// Ekran üst barı: geri butonu, ortada başlık, sağda isteğe bağlı içerik.
public struct NavHeader<Trailing: View>: View {
  private let title: String
  private let leadingSymbol: String
  private let onLeading: () -> Void
  private let trailing: Trailing

  /// Başlık, sol buton ve sağ içerikle üst bar oluşturur.
  public init(
    _ title: String,
    leadingSymbol: String = "chevron.left",
    onLeading: @escaping () -> Void,
    @ViewBuilder trailing: () -> Trailing
  ) {
    self.title = title
    self.leadingSymbol = leadingSymbol
    self.onLeading = onLeading
    self.trailing = trailing()
  }

  public var body: some View {
    HStack {
      Button(action: onLeading) { IconCircle(leadingSymbol) }
        .buttonStyle(.plain)
        .accessibilityLabel(leadingSymbol == "xmark" ? "Kapat" : "Geri")
      Spacer()
      Text(title).font(AppFont.section).foregroundStyle(Palette.ink).lineLimit(1)
      Spacer()
      trailing.frame(minWidth: 40, alignment: .trailing)
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.top, 4)
    .padding(.bottom, 6)
  }
}

extension NavHeader where Trailing == EmptyView {
  /// Sağ içeriği olmayan üst bar oluşturur.
  public init(
    _ title: String, leadingSymbol: String = "chevron.left", onLeading: @escaping () -> Void
  ) {
    self.init(title, leadingSymbol: leadingSymbol, onLeading: onLeading) { EmptyView() }
  }
}

/// Ayar grubu başlığı ve kartı.
public struct SettingsGroup<Content: View>: View {
  private let title: String?
  private let content: Content

  /// Başlık ve satırlarla grup oluşturur.
  public init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      if let title {
        Text(title.uppercased(with: Locale(identifier: "tr_TR")))
          .font(AppFont.tiny.weight(.black))
          .tracking(1)
          .foregroundStyle(Palette.muted)
          .padding(.leading, 6)
      }
      VStack(spacing: 0) { content }
        .padding(.horizontal, 14)
        .background(
          RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
            .fill(Palette.surface)
            .shadow(color: Palette.cardShadow, radius: 0, y: 2)
        )
    }
  }
}

/// Ayar satırı: ikon, başlık ve sağda değer ya da kontrol.
public struct SettingsRow<Accessory: View>: View {
  private let systemImage: String
  private let title: String
  private let tint: Color
  private let accessory: Accessory

  /// İkon, başlık, renk ve sağ içerikle satır oluşturur.
  public init(
    _ systemImage: String, _ title: String, tint: Color = Palette.ink,
    @ViewBuilder accessory: () -> Accessory
  ) {
    self.systemImage = systemImage
    self.title = title
    self.tint = tint
    self.accessory = accessory()
  }

  public var body: some View {
    HStack(spacing: 12) {
      Image(systemName: systemImage)
        .font(.system(size: 17, weight: .semibold))
        .frame(width: 24)
      Text(title).font(AppFont.body)
      Spacer(minLength: 8)
      accessory
    }
    .foregroundStyle(tint)
    .frame(minHeight: 48)
    .contentShape(Rectangle())
    .overlay(alignment: .bottom) { Rectangle().fill(Palette.line).frame(height: 1) }
  }
}

/// Ayar satırının sağındaki gri değer ve ok.
public struct DisclosureValue: View {
  private let value: String

  /// Gösterilecek değerle oluşturur.
  public init(_ value: String = "") {
    self.value = value
  }

  public var body: some View {
    HStack(spacing: 6) {
      Text(value).font(AppFont.caption).foregroundStyle(Palette.muted)
      Image(systemName: "chevron.right")
        .font(.system(size: 13, weight: .bold))
        .foregroundStyle(Palette.lineStrong)
    }
  }
}

/// İkonu metnin sağına koyan etiket stili ("Çöz ›").
public struct TrailingIconLabelStyle: LabelStyle {
  /// Stili oluşturur.
  public init() {}

  public func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 4) {
      configuration.title
      configuration.icon.imageScale(.small)
    }
  }
}
