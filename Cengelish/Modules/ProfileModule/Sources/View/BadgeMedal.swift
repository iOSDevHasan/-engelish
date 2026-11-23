import DesignKit
import SwiftUI

/// Izgaradaki rozet: kazanılan rozet koyu bir disk üstünde parlar, diğerleri ilerleme halkası
/// içinde soluk görünür.
struct BadgeMedalCell: View {
  let item: BadgeItem
  let isSelected: Bool
  /// Halka / disk çapı.
  var size: CGFloat = 84

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isGlowing = false

  var body: some View {
    VStack(spacing: 8) {
      ZStack {
        if item.isEarned {
          earnedBackdrop
        } else {
          progressRing
        }
        BadgeMedal(symbol: item.symbol)
          .frame(width: medalSize, height: medalSize)
          .saturation(item.isEarned ? 1 : 0.15)
          .opacity(item.isEarned ? 1 : 0.55)
          .shadow(color: .black.opacity(item.isEarned ? 0.25 : 0.08), radius: 4, y: 2)
      }
      .frame(width: size, height: size)
      .scaleEffect(isSelected ? 1.06 : 1)
      .animation(Motion.snappy, value: isSelected)

      Text(item.title)
        .font(AppFont.rounded(size < 80 ? 11.5 : 12.5, weight: .heavy))
        .foregroundStyle(item.isEarned ? Palette.ink : Palette.muted)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .frame(maxWidth: .infinity)
    .contentShape(Rectangle())
    .onAppear {
      guard item.isEarned, !reduceMotion else { return }
      withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
        isGlowing = true
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(item.title)
    .accessibilityValue(item.isEarned ? "Kazanıldı" : item.progressText)
    .accessibilityHint("Rozetin anlamını ve nasıl kazanıldığını gösterir")
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }

  // MARK: - Parts

  /// Kazanılan rozetin koyu diski ve altın parıltısı.
  private var earnedBackdrop: some View {
    ZStack {
      Circle()
        .fill(BadgeColors.gold.opacity(isGlowing ? 0.45 : 0.25))
        .blur(radius: size * 0.12)
        .scaleEffect(isGlowing ? 1.08 : 0.96)
      Circle().fill(BadgeColors.disc)
      Circle().strokeBorder(BadgeColors.gold.opacity(0.55), lineWidth: 1.5)
    }
  }

  /// Kazanılmamış rozetin ilerleme halkası (asla tamamlanmış görünmez).
  private var progressRing: some View {
    ZStack {
      Circle().stroke(BadgeColors.track, lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: item.ringFraction)
        .stroke(Palette.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(-90))
    }
    .padding(lineWidth / 2)
  }

  /// Madalya çapı: kazanılan rozette daha büyük.
  private var medalSize: CGFloat { size * (item.isEarned ? 0.67 : 0.55) }

  /// Halka kalınlığı (84 pt'de 7 pt).
  private var lineWidth: CGFloat { size / 12 }
}

/// Dilimli altın mühür ve ortasında rozet simgesi.
struct BadgeMedal: View {
  let symbol: String

  var body: some View {
    GeometryReader { proxy in
      // Oranlı boşluklar madalyayı her boyutta (34 pt balon, 56 pt ızgara) aynı gösterir.
      let size = min(proxy.size.width, proxy.size.height)
      ZStack {
        BadgeSeal()
          .fill(
            LinearGradient(
              colors: [BadgeColors.sealLight, BadgeColors.sealDark], startPoint: .topLeading,
              endPoint: .bottomTrailing))
        Circle()
          .fill(
            LinearGradient(
              colors: [BadgeColors.coreDark, BadgeColors.coreLight], startPoint: .top,
              endPoint: .bottom)
          )
          .padding(size * 0.14)
        Circle()
          .stroke(BadgeColors.rim, lineWidth: 1)
          .padding(size * 0.18)
        Image(systemName: symbol)
          .resizable()
          .scaledToFit()
          .fontWeight(.bold)
          .foregroundStyle(BadgeColors.glyph)
          .shadow(color: BadgeColors.glyphShadow, radius: 0, y: 1)
          .frame(width: size * 0.4, height: size * 0.4)
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
    }
    .accessibilityHidden(true)
  }
}

/// Rozet madalyalarının renkleri (açık ve koyu modda okunur).
enum BadgeColors {
  /// Kazanılan rozetin arkasındaki koyu disk.
  static let disc = Palette.dynamic(0x2B2563, 0x4B3FA8)
  /// Halkanın dolmamış izi.
  static let track = Palette.dynamic(0xE9E5FF, 0x3A356E)
  /// Parıltı ve vurgu altını.
  static let gold = Color(hex: 0xFFC857)
  /// Mühür degradesinin açık ucu.
  static let sealLight = Color(hex: 0xFFD66E)
  /// Mühür degradesinin koyu ucu.
  static let sealDark = Color(hex: 0xF5A028)
  /// Göbek degradesinin üstü.
  static let coreDark = Color(hex: 0xEE8C1E)
  /// Göbek degradesinin altı.
  static let coreLight = Color(hex: 0xF8AA37)
  /// Göbeğin ince kenarı.
  static let rim = Color(hex: 0xFFE2A0, opacity: 0.8)
  /// Simge rengi.
  static let glyph = Color(hex: 0xFFEECC)
  /// Simgenin alt gölgesi.
  static let glyphShadow = Color(hex: 0xBE640A)
}

/// Rozet madalyalarının on dilimli mühür çerçevesi.
struct BadgeSeal: Shape {
  func path(in rect: CGRect) -> Path {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let outer = min(rect.width, rect.height) / 2
    let inner = outer * 0.86
    let lobes = 10
    var path = Path()
    for step in 0...(lobes * 2) {
      let angle = Double(step) * .pi / Double(lobes) - .pi / 2
      let radius = step.isMultiple(of: 2) ? outer : inner
      let point = CGPoint(
        x: center.x + radius * CGFloat(cos(angle)), y: center.y + radius * CGFloat(sin(angle)))
      guard step > 0 else {
        path.move(to: point)
        continue
      }
      // İki yarıçap arasındaki eğri her dilimi yuvarlatır.
      let previous = Double(step - 1) * .pi / Double(lobes) - .pi / 2
      let control = CGPoint(
        x: center.x + outer * 1.02 * CGFloat(cos((angle + previous) / 2)),
        y: center.y + outer * 1.02 * CGFloat(sin((angle + previous) / 2)))
      path.addQuadCurve(to: point, control: control)
    }
    path.closeSubpath()
    return path
  }
}
