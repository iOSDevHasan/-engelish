import DesignKit
import SwiftUI
import UIKit

/// Açılış animasyonu: uygulama ikonundaki krem kutu zıplayarak gelir, mor "Ç" kalemle yazılır,
/// köşedeki altın ipucu üçgeni açılır, ardından "Çengelish" harfleri bulmaca kutularına dolar.
///
/// Zaman çizelgesi `start` anından ölçülür; böylece kabuk animasyonun ne zaman biteceğini bilir.
/// Hareketi azalt açıksa doğrudan son kare gösterilir.
struct SplashView: View {
  /// Animasyonun başladığı an.
  let start: Date
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isSettled = false

  /// Animasyonun toplam süresi (saniye).
  static let duration: TimeInterval = 2.4

  var body: some View {
    TimelineView(.animation(minimumInterval: nil, paused: isSettled || reduceMotion)) { context in
      let elapsed = context.date.timeIntervalSince(start)
      SplashFrame(time: reduceMotion ? Self.duration : min(max(elapsed, 0), Self.duration))
    }
    .ignoresSafeArea()
    .accessibilityElement()
    .accessibilityLabel("Çengelish. Kalemle çöz, İngilizce öğren")
    .task { await play() }
  }

  /// Kutu yere değdiğinde hafif titreşim verir, animasyon bitince zaman çizelgesini durdurur.
  private func play() async {
    guard !reduceMotion else {
      isSettled = true
      return
    }
    let untilLanding = 0.42 - Date().timeIntervalSince(start)
    if untilLanding > 0 { try? await Task.sleep(for: .seconds(untilLanding)) }
    guard !Task.isCancelled else { return }
    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    let remaining = Self.duration - Date().timeIntervalSince(start)
    if remaining > 0 { try? await Task.sleep(for: .seconds(remaining)) }
    guard !Task.isCancelled else { return }
    isSettled = true
  }
}

// MARK: - Frame

/// Verilen andaki tek kare.
private struct SplashFrame: View {
  let time: TimeInterval

  /// Kutunun kenar uzunluğu.
  private static let tileSide: CGFloat = 168
  /// Logo yazısı.
  private static let wordmark = Array("Çengelish")

  var body: some View {
    ZStack {
      Color(uiColor: .systemBackground)
      LinearGradient(
        colors: SplashColors.background, startPoint: .topLeading, endPoint: .bottomTrailing
      )
      .opacity(Ease.out(progress(0, 0.4)))
      VStack(spacing: 30) {
        tile
        wordmarkRow
        tagline
      }
      .padding(.bottom, 40)
    }
  }

  // MARK: Tile

  /// İkondaki kutu: yan yüz, ön yüz, altın köşe, ok ve yazılan "Ç".
  private var tile: some View {
    let entrance = progress(0.08, 0.62)
    let side = Self.tileSide
    let scale = side / 620
    return ZStack {
      IconShape(.tile)
        .fill(LinearGradient(colors: SplashColors.side, startPoint: .top, endPoint: .bottom))
        .offset(y: 40 * scale)
      IconShape(.tile)
        .fill(LinearGradient(colors: SplashColors.face, startPoint: .top, endPoint: .bottom))
      IconShape(.corner)
        .fill(LinearGradient(colors: SplashColors.gold, startPoint: .top, endPoint: .bottom))
        .clipShape(IconShape(.tile))
        .scaleEffect(Ease.back(progress(1.25, 1.6)), anchor: .topTrailing)
      IconShape(.arrow)
        .trim(from: 0, to: Ease.inOut(progress(1.45, 1.75)))
        .stroke(
          SplashColors.arrow,
          style: StrokeStyle(lineWidth: 14 * scale, lineCap: .round, lineJoin: .round))
      letterStroke(.letter, width: 78 * scale, from: 0.48, to: 1.12)
      letterStroke(.tail, width: 42 * scale, from: 1.08, to: 1.34)
      IconShape(.gloss)
        .trim(from: 0, to: Ease.out(progress(1.15, 1.4)))
        .stroke(.white.opacity(0.35), style: StrokeStyle(lineWidth: 14 * scale, lineCap: .round))
      IconShape(.tile).stroke(.white.opacity(0.8), lineWidth: 6 * scale)
    }
    .frame(width: side, height: side)
    .shadow(color: SplashColors.shadow.opacity(0.35), radius: 22, y: 14)
    .scaleEffect(0.55 + 0.45 * Ease.back(entrance))
    .rotationEffect(.degrees(-10 * (1 - Ease.out(entrance))))
    .offset(y: 40 * (1 - Ease.out(entrance)))
    .opacity(min(1, entrance * 3))
  }

  /// Kalemle yazılıyormuş gibi uzayan mor harf çizgisi.
  private func letterStroke(
    _ part: IconShape.Part, width: CGFloat, from: Double, to: Double
  )
    -> some View
  {
    IconShape(part)
      .trim(from: 0, to: Ease.inOut(progress(from, to)))
      .stroke(
        LinearGradient(
          colors: SplashColors.ink, startPoint: .topLeading, endPoint: .bottomTrailing),
        style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
  }

  // MARK: Wordmark

  /// Harfleri sırayla bulmaca kutularına dolan logo yazısı.
  private var wordmarkRow: some View {
    HStack(spacing: 5) {
      ForEach(Array(Self.wordmark.enumerated()), id: \.offset) { index, letter in
        let pop = progress(1.4 + Double(index) * 0.06, 1.72 + Double(index) * 0.06)
        Text(String(letter))
          .font(AppFont.rounded(22, weight: .black))
          .foregroundStyle(SplashColors.letter)
          .frame(width: 31, height: 37)
          .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(.white.opacity(0.95))
              .shadow(color: SplashColors.shadow.opacity(0.25), radius: 0, y: 3)
          )
          .scaleEffect(0.3 + 0.7 * Ease.back(pop))
          .opacity(min(1, pop * 2.5))
      }
    }
  }

  /// Alt slogan.
  private var tagline: some View {
    let fade = Ease.out(progress(1.95, 2.35))
    return Text("Kalemle çöz, İngilizce öğren")
      .font(AppFont.bodyBold)
      .foregroundStyle(.white.opacity(0.92))
      .opacity(fade)
      .offset(y: 8 * (1 - fade))
  }

  // MARK: Timing

  /// `time`'ın [from, to] aralığındaki 0…1 ilerlemesi.
  private func progress(_ from: TimeInterval, _ to: TimeInterval) -> Double {
    min(max((time - from) / (to - from), 0), 1)
  }
}

// MARK: - Easing

/// Basit yumuşatma eğrileri.
private enum Ease {
  /// Yavaşlayarak biter.
  static func out(_ x: Double) -> Double { 1 - pow(1 - x, 3) }

  /// Yavaş başlar, yavaş biter.
  static func inOut(_ x: Double) -> Double {
    x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
  }

  /// Hedefi biraz aşıp geri döner (zıplama).
  static func back(_ x: Double) -> Double {
    let overshoot = 1.70158
    return 1 + (overshoot + 1) * pow(x - 1, 3) + overshoot * pow(x - 1, 2)
  }
}

// MARK: - Colors

/// İkondaki renkler (design/icon-options/option-c.svg).
private enum SplashColors {
  static let background = [
    Color(hex: 0xFFB03D), Color(hex: 0xFF7A6B), Color(hex: 0xE35FB0), Color(hex: 0x6C5CE7),
  ]
  static let face = [Color(hex: 0xFFFFFF), Color(hex: 0xFFEFD9)]
  static let side = [Color(hex: 0xE9C9A6), Color(hex: 0xD6A57E)]
  static let gold = [Color(hex: 0xFFE07A), Color(hex: 0xFFB524)]
  static let ink = [Color(hex: 0x8E7CF8), Color(hex: 0x4E3DD0)]
  static let arrow = Color(hex: 0x24204D)
  static let letter = Color(hex: 0x4E3DD0)
  static let shadow = Color(hex: 0x3B2DAE)
}

// MARK: - Icon geometry

/// İkon SVG'sindeki yollar; 1024'lük tuvaldeki kutu (202…822) çizim alanına ölçeklenir.
private struct IconShape: Shape {
  /// İkonun parçaları.
  enum Part {
    case tile, corner, arrow, letter, tail, gloss
  }

  let part: Part

  init(_ part: Part) {
    self.part = part
  }

  func path(in rect: CGRect) -> Path {
    let scale = rect.width / 620
    let transform = CGAffineTransform(translationX: -202, y: -168)
      .concatenating(CGAffineTransform(scaleX: scale, y: scale))
      .concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY))
    return Self.raw(part).applying(transform)
  }

  /// Parçanın SVG koordinatlarındaki yolu.
  private static func raw(_ part: Part) -> Path {
    var path = Path()
    switch part {
    case .tile:
      path.addRoundedRect(
        in: CGRect(x: 202, y: 168, width: 620, height: 620),
        cornerSize: CGSize(width: 140, height: 140))
    case .corner:
      path.move(to: CGPoint(x: 612, y: 168))
      path.addLine(to: CGPoint(x: 822, y: 168))
      path.addLine(to: CGPoint(x: 822, y: 378))
      path.closeSubpath()
    case .arrow:
      path.move(to: CGPoint(x: 730, y: 208))
      path.addLine(to: CGPoint(x: 730, y: 256))
      path.addLine(to: CGPoint(x: 776, y: 256))
      path.move(to: CGPoint(x: 760, y: 240))
      path.addLine(to: CGPoint(x: 778, y: 256))
      path.addLine(to: CGPoint(x: 760, y: 272))
    case .letter:
      path.move(to: CGPoint(x: 652, y: 352))
      path.addCurve(
        to: CGPoint(x: 440, y: 318), control1: CGPoint(x: 600, y: 290),
        control2: CGPoint(x: 500, y: 282))
      path.addCurve(
        to: CGPoint(x: 352, y: 500), control1: CGPoint(x: 370, y: 360),
        control2: CGPoint(x: 346, y: 440))
      path.addCurve(
        to: CGPoint(x: 512, y: 640), control1: CGPoint(x: 360, y: 590),
        control2: CGPoint(x: 430, y: 640))
      path.addCurve(
        to: CGPoint(x: 656, y: 576), control1: CGPoint(x: 570, y: 640),
        control2: CGPoint(x: 620, y: 616))
    case .tail:
      path.move(to: CGPoint(x: 514, y: 650))
      path.addCurve(
        to: CGPoint(x: 503, y: 694), control1: CGPoint(x: 512, y: 668),
        control2: CGPoint(x: 508, y: 682))
      path.addCurve(
        to: CGPoint(x: 564, y: 740), control1: CGPoint(x: 550, y: 690),
        control2: CGPoint(x: 576, y: 712))
      path.addCurve(
        to: CGPoint(x: 470, y: 760), control1: CGPoint(x: 552, y: 768),
        control2: CGPoint(x: 506, y: 774))
    case .gloss:
      path.move(to: CGPoint(x: 430, y: 340))
      path.addCurve(
        to: CGPoint(x: 372, y: 470), control1: CGPoint(x: 384, y: 372),
        control2: CGPoint(x: 372, y: 424))
    }
    return path
  }
}
