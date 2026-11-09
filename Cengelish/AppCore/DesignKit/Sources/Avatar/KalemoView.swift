import SwiftUI

/// Kalem maskotu Kalemo'yu verilen gövde rengi ve aksesuarla çizer.
public struct KalemoView: View {
  private let body_: AvatarBody
  private let accessory: AvatarAccessory

  /// Gövde rengi ve aksesuarla maskot oluşturur.
  public init(body: AvatarBody = .yellow, accessory: AvatarAccessory = .none) {
    self.body_ = body
    self.accessory = accessory
  }

  public var body: some View {
    Canvas { context, size in
      // Tasarımdaki SVG koordinatları: viewBox 0 -16 120 146.
      let scale = min(size.width / 120, size.height / 146)
      context.translateBy(x: (size.width - 120 * scale) / 2, y: (size.height - 146 * scale) / 2)
      context.scaleBy(x: scale, y: scale)
      context.translateBy(x: 0, y: 16)
      context.translateBy(x: 60, y: 65)
      context.rotate(by: .degrees(-14))
      context.translateBy(x: -60, y: -65)
      Self.drawPencil(in: &context, body: body_)
      Self.draw(accessory, in: &context)
    }
    .aspectRatio(120 / 146, contentMode: .fit)
    .accessibilityHidden(true)
  }

  // MARK: - Drawing

  private static let ink = Color(hex: 0x24204D)
  private static let blush = Color(hex: 0xFF8FA3)

  /// Kalem gövdesini, yüzünü ve ucunu çizer.
  private static func drawPencil(in ctx: inout GraphicsContext, body: AvatarBody) {
    ctx.fill(rounded(40, 22, 40, 66, 8), with: .color(body.color))
    ctx.fill(
      Path(CGRect(x: 40, y: 22, width: 13, height: 66)), with: .color(body.shade.opacity(0.45)))
    ctx.fill(rounded(40, 10, 40, 18, 8), with: .color(blush))
    ctx.fill(Path(CGRect(x: 40, y: 25, width: 40, height: 7)), with: .color(Color(hex: 0xC9CBE0)))
    ctx.fill(triangle((40, 86), (60, 116), (80, 86)), with: .color(Color(hex: 0xF6D7A7)))
    ctx.fill(triangle((53.5, 106), (60, 116), (66.5, 106)), with: .color(ink))
    for x in [51.0, 69.0] {
      ctx.fill(
        Path(ellipseIn: CGRect(x: x - 5.5, y: 47.5, width: 11, height: 13)), with: .color(ink))
      ctx.fill(circle(x + 2, 52, 2), with: .color(.white))
    }
    var smile = Path()
    smile.move(to: CGPoint(x: 52, y: 68))
    smile.addQuadCurve(to: CGPoint(x: 68, y: 68), control: CGPoint(x: 60, y: 75))
    ctx.stroke(smile, with: .color(ink), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
    ctx.fill(circle(45, 65, 4), with: .color(blush.opacity(0.6)))
    ctx.fill(circle(75, 65, 4), with: .color(blush.opacity(0.6)))
  }

  /// Seçili aksesuarı çizer.
  private static func draw(_ accessory: AvatarAccessory, in ctx: inout GraphicsContext) {
    switch accessory {
    case .none:
      break
    case .glasses:
      for x in [51.0, 69.0] {
        ctx.fill(circle(x, 54, 9), with: .color(.white.opacity(0.35)))
        ctx.stroke(circle(x, 54, 9), with: .color(ink), lineWidth: 2.8)
      }
      ctx.stroke(line((59.5, 53), (60.5, 53)), with: .color(ink), lineWidth: 2.8)
    case .cap:
      ctx.fill(rounded(47, 12, 26, 9, 2), with: .color(ink))
      ctx.fill(polygon([(34, 13), (60, 2), (86, 13), (60, 24)]), with: .color(ink))
      ctx.stroke(line((84, 13), (84, 26)), with: .color(Color(hex: 0xFF8A3D)), lineWidth: 2.4)
      ctx.fill(circle(84, 27, 3), with: .color(Color(hex: 0xFF8A3D)))
    case .headphones:
      var band = Path()
      band.move(to: CGPoint(x: 33, y: 52))
      band.addLine(to: CGPoint(x: 33, y: 38))
      band.addArc(
        center: CGPoint(x: 60, y: 38), radius: 27, startAngle: .degrees(180),
        endAngle: .degrees(0), clockwise: false)
      band.addLine(to: CGPoint(x: 87, y: 52))
      ctx.stroke(band, with: .color(ink), lineWidth: 4.5)
      ctx.fill(rounded(27, 43, 12, 20, 6), with: .color(Color(hex: 0x6C5CE7)))
      ctx.fill(rounded(81, 43, 12, 20, 6), with: .color(Color(hex: 0x6C5CE7)))
    case .bow:
      ctx.fill(triangle((72, 12), (58, 3), (58, 21)), with: .color(Color(hex: 0xFF5A8A)))
      ctx.fill(triangle((72, 12), (86, 3), (86, 21)), with: .color(Color(hex: 0xFF5A8A)))
      ctx.fill(circle(72, 12, 4), with: .color(Color(hex: 0xE0336A)))
    case .crown:
      let crown = polygon([(43, 13), (43, -1), (52, 6), (60, -7), (68, 6), (77, -1), (77, 13)])
      ctx.fill(crown, with: .color(Color(hex: 0xFFC93C)))
      ctx.stroke(
        crown, with: .color(Color(hex: 0xE0A000)),
        style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))
      ctx.fill(circle(60, 6, 2.6), with: .color(Color(hex: 0xFF5A8A)))
    }
  }

  // MARK: - Path helpers

  private static func rounded(
    _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ r: Double
  )
    -> Path
  {
    Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r)
  }

  private static func circle(_ x: Double, _ y: Double, _ r: Double) -> Path {
    Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
  }

  private static func triangle(
    _ a: (Double, Double), _ b: (Double, Double), _ c: (Double, Double)
  ) -> Path {
    polygon([a, b, c])
  }

  private static func polygon(_ points: [(Double, Double)]) -> Path {
    var path = Path()
    path.addLines(points.map { CGPoint(x: $0.0, y: $0.1) })
    path.closeSubpath()
    return path
  }

  private static func line(_ a: (Double, Double), _ b: (Double, Double)) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: a.0, y: a.1))
    path.addLine(to: CGPoint(x: b.0, y: b.1))
    return path
  }
}

/// Yuvarlak arka planlı kullanıcı avatarı.
public struct AvatarView: View {
  private let config: AvatarConfig
  private let size: CGFloat

  /// Avatar seçimi ve çapla oluşturur.
  public init(_ config: AvatarConfig, size: CGFloat = 56) {
    self.config = config
    self.size = size
  }

  public var body: some View {
    ZStack {
      Circle().fill(config.background.color)
      KalemoView(body: config.body, accessory: config.accessory)
        .frame(width: size * 0.78, height: size * 0.95)
        .offset(y: size * 0.04)
    }
    .frame(width: size, height: size)
    .clipShape(Circle())
    .accessibilityLabel("Avatar")
  }
}

/// Rozet madalyası.
public struct MedalView: View {
  private let systemImage: String
  private let color: Color
  private let size: CGFloat
  private let isLocked: Bool

  /// İkon, renk, boyut ve kilit durumuyla madalya oluşturur.
  public init(systemImage: String, color: Color, size: CGFloat = 56, isLocked: Bool = false) {
    self.systemImage = systemImage
    self.color = color
    self.size = size
    self.isLocked = isLocked
  }

  public var body: some View {
    ZStack {
      Circle()
        .fill(isLocked ? Palette.surface2 : color.opacity(0.18))
      Circle()
        .strokeBorder(isLocked ? Palette.lineStrong : color, lineWidth: size * 0.07)
      Image(systemName: isLocked ? "lock.fill" : systemImage)
        .font(.system(size: size * 0.38, weight: .bold))
        .foregroundStyle(isLocked ? Palette.muted : color)
    }
    .frame(width: size, height: size)
  }
}
