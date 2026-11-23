import ContentKit
import DesignKit
import SwiftUI

// MARK: - Section header

/// Bölüm başlığı: solda başlık, sağda not / rozet / bağlantı.
struct SectionHeader<Trailing: View>: View {
  private let title: String
  private let trailing: Trailing

  /// Başlık ve sağ içerikle bölüm başlığı oluşturur.
  init(_ title: String, @ViewBuilder trailing: () -> Trailing) {
    self.title = title
    self.trailing = trailing()
  }

  var body: some View {
    HStack(spacing: 8) {
      Text(title).font(AppFont.section).foregroundStyle(Palette.ink)
        .lineLimit(1).minimumScaleFactor(0.8)
        .accessibilityAddTraits(.isHeader)
      Spacer(minLength: 8)
      trailing
    }
  }
}

// MARK: - Level card

/// Seviye kartı: seviye renginde kabartma madalyon (A1), Türkçe ad, bulmaca sayısı, konular ve
/// seviye renginde dolan ilerleme. Kullanıcının seviyesi renkli kenar ve üst kenardan sarkan
/// "Senin seviyen" etiketiyle; Plus gerekiyorsa sağ üst köşede Plus rozetiyle gösterilir.
struct LevelCardView: View {
  let card: PackCard
  let isCurrent: Bool

  private var level: CEFRLevel { card.pack.level }
  private var tint: Color { PackStyle.tint(for: level) }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      medallion
      Text(level.title)
        .font(AppFont.rounded(17, weight: .heavy))
        .foregroundStyle(Palette.ink)
        .lineLimit(1)
        .padding(.top, 12)
      Text(PackStyle.puzzleCount(card))
        .font(AppFont.caption)
        .foregroundStyle(tint)
        .lineLimit(1)
        .padding(.top, 2)
      Text(card.pack.subtitle)
        .font(AppFont.tiny)
        .foregroundStyle(Palette.muted)
        .lineLimit(2, reservesSpace: true)
        .padding(.top, 4)
      Spacer(minLength: 10)
      HStack(spacing: 8) {
        FillingProgressBar(value: card.progress, tint: tint, height: 6)
        Text(card.progressText)
          .font(AppFont.tiny.weight(.black))
          .foregroundStyle(Palette.muted)
          .monospacedDigit()
          .lineLimit(1)
          .fixedSize()
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background { background }
    .overlay {
      RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
        .strokeBorder(isCurrent ? tint : Palette.cardBorder, lineWidth: isCurrent ? 2 : 1)
    }
    .plusCorner(card.isLocked)
    .overlay(alignment: .top) { currentTag }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityText)
  }

  // MARK: - Pieces

  /// Seviye renginde, alt kenarı koyu "kabartma" madalyon.
  private var medallion: some View {
    Text(level.rawValue)
      .font(AppFont.rounded(22, weight: .black))
      .foregroundStyle(.white)
      .frame(width: 52, height: 46)
      .background {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(tint)
          .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .fill(PackStyle.ledge(for: level))
              .offset(y: 3)
          }
      }
      .padding(.bottom, 3)
  }

  /// Seviye rengiyle hafifçe boyanmış yüzey, köşede soluk büyük seviye kodu ve alt gölge.
  private var background: some View {
    RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
      .fill(Palette.surface)
      .overlay {
        LinearGradient(
          colors: [tint.opacity(0.16), tint.opacity(0.03)], startPoint: .top,
          endPoint: .bottom)
      }
      .overlay(alignment: .bottomTrailing) {
        Text(level.rawValue)
          .font(AppFont.rounded(64, weight: .black))
          .foregroundStyle(tint.opacity(0.09))
          .fixedSize()
          .offset(x: 10, y: 14)
          .accessibilityHidden(true)
      }
      .clipShape(RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous))
      .shadow(
        color: isCurrent ? PackStyle.ledge(for: level).opacity(0.45) : Palette.cardShadow,
        radius: 0, y: 3)
  }

  /// Kullanıcının seviyesinde üst kenardan sarkan etiket.
  @ViewBuilder private var currentTag: some View {
    if isCurrent {
      Text("SENİN SEVİYEN")
        .font(.system(size: 9, weight: .black, design: .rounded))
        .tracking(0.5)
        .foregroundStyle(.white)
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 8)
        .frame(height: 18)
        .background(Capsule().fill(tint))
        .overlay(Capsule().strokeBorder(.white.opacity(0.6), lineWidth: 1))
        .offset(y: -9)
        .allowsHitTesting(false)
    }
  }

  private var accessibilityText: String {
    var parts = [
      "\(level.rawValue) \(level.title) seviyesi", PackStyle.puzzleCount(card),
      "\(card.solved) bulmaca tamamlandı",
    ]
    if isCurrent { parts.append("senin seviyen") }
    if card.isLocked { parts.append("\(PlusBrand.name) gerekli") }
    return parts.joined(separator: ", ")
  }
}

/// Paketlerin renk kimliği: her seviyenin kendi rengi (kolaydan zora yeşil → turuncu), sınav
/// paketlerinin düz renkleri.
enum PackStyle {
  /// Seviye rengi (DesignKit `LevelTint`).
  static func tint(for level: CEFRLevel) -> Color {
    LevelTint.color(code: level.rawValue)
  }

  /// Seviye renginin koyu "kabartma" alt kenarı.
  static func ledge(for level: CEFRLevel) -> Color {
    LevelTint.ledge(code: level.rawValue)
  }

  /// Paket detayındaki vurgu rengi: seviyede seviye rengi, sınavda kart rengi, temada vurgu.
  static func tint(for pack: Pack) -> Color {
    switch pack.kind {
    case .level: tint(for: pack.level)
    case .exam: ExamStyle.color(for: pack.id)
    case .theme: Palette.accent
    }
  }

  /// "12 bulmaca".
  static func puzzleCount(_ card: PackCard) -> String {
    "\(card.puzzleCount) bulmaca"
  }
}

// MARK: - Exam card

/// Sınav paketi kartı: düz renk, kelime/bulmaca sayısı, seviye aralığı; erişim yoksa köşede Plus
/// rozeti.
struct ExamCardView: View {
  let card: PackCard

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(card.shortTitle).font(AppFont.rounded(22, weight: .black))
        .lineLimit(1).minimumScaleFactor(0.6)
        .padding(.trailing, card.isLocked ? 48 : 0)
      // Her kartta aynı iki satır: ızgaradaki kartlar aynı hizada kalır.
      VStack(alignment: .leading, spacing: 1) {
        Text(words)
        Text(puzzles)
      }
      .lineLimit(1).minimumScaleFactor(0.8)
      .font(AppFont.caption).opacity(0.92)
      Spacer(minLength: 0)
      HStack(spacing: 8) {
        Text(card.levelRange).font(AppFont.tiny.weight(.black))
          .lineLimit(1).fixedSize()
          .padding(.horizontal, 8).frame(height: 22)
          .background(Capsule().fill(.white.opacity(0.25)))
        if !card.isLocked && card.solved > 0 {
          Text("%\(card.percent)").font(AppFont.tiny.weight(.black)).lineLimit(1)
        }
      }
    }
    .foregroundStyle(.white)
    .padding(.vertical, 12)
    .padding(.horizontal, 13)
    .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
    .background(
      RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
        .fill(ExamStyle.color(for: card.pack.id))
        .shadow(color: .black.opacity(0.14), radius: 0, y: 4)
    )
    .overlay(
      RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
        .strokeBorder(.white.opacity(0.18), lineWidth: 1)
    )
    .plusCorner(card.isLocked)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "\(card.shortTitle), \(words), \(puzzles), \(card.levelRange)"
        + (card.isLocked ? ", \(PlusBrand.name) gerekli" : ""))
  }

  /// "1.200 kelime".
  private var words: String { "\(TurkishText.number(card.pack.wordCount)) kelime" }
  /// "20 bulmaca".
  private var puzzles: String { "\(card.puzzleCount) bulmaca" }
}

/// Sınav paketlerinin tasarımdaki düz renkleri.
enum ExamStyle {
  /// Paket kimliğine göre kart rengi; bilinmeyenlerde vurgu rengi.
  static func color(for packId: String) -> Color {
    switch packId {
    case "yds": Color(hex: 0x6C5CE7)
    case "yokdil": Color(hex: 0xFF8A3D)
    case "lgs": Color(hex: 0x1FB57A)
    case "ielts": Color(hex: 0xFF5A8A)
    case "toefl": Color(hex: 0x3C9BE0)
    default: Palette.accent
    }
  }
}

// MARK: - Theme tile

/// Tema paketi karesi: simge, başlık, bulmaca sayısı ve ücretsiz durumu; Plus gerekiyorsa
/// köşede Plus rozeti.
struct ThemeTileView: View {
  let card: PackCard
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Image(systemName: card.symbol)
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(Palette.ink.opacity(0.8))
      Spacer(minLength: 6)
      Text(card.pack.title).font(AppFont.rounded(14, weight: .black))
        .lineLimit(2).minimumScaleFactor(0.85)
        .fixedSize(horizontal: false, vertical: true)
      // Durum satırının yeri her karoda ayrılır; satırdaki başlıklar aynı hizada kalır.
      VStack(alignment: .leading, spacing: 1) {
        Text(ThemeText.count(card))
        Text(ThemeText.status(card) ?? " ")
          .foregroundStyle(Palette.good)
          .opacity(ThemeText.status(card) == nil ? 0 : 1)
          .accessibilityHidden(true)
      }
      .lineLimit(1).minimumScaleFactor(0.8)
      .font(.system(size: 10, weight: .bold, design: .rounded))
      .foregroundStyle(Palette.ink.opacity(0.72))
    }
    .foregroundStyle(Palette.ink)
    .padding(.vertical, 10)
    .padding(.horizontal, 11)
    .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
    .background(
      RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous).fill(tint)
        .shadow(color: Palette.cardShadow, radius: 0, y: 2)
    )
    .overlay(
      RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
        .strokeBorder(Palette.cardBorder, lineWidth: 1)
    )
    .plusCorner(card.isLocked)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(card.pack.title), \(ThemeText.spokenDetail(card))")
  }
}

/// Tema paketi durum metinleri.
enum ThemeText {
  /// Bulmaca sayısı ("24 bulmaca").
  static func count(_ card: PackCard) -> String {
    "\(card.puzzleCount) bulmaca"
  }

  /// Tamamen ücretsizse "Ücretsiz", değilse nil.
  static func status(_ card: PackCard) -> String? {
    card.pack.isFullyFree ? "Ücretsiz" : nil
  }

  /// Tek satırlık metin: "24 bulmaca · Ücretsiz" ya da "20 bulmaca".
  static func detail(_ card: PackCard) -> String {
    [count(card), status(card)].compactMap { $0 }.joined(separator: " · ")
  }

  /// Erişilebilirlik metni: Plus gerekiyorsa "Plus" da okunur.
  static func spokenDetail(_ card: PackCard) -> String {
    card.isLocked ? "\(count(card)) · \(PlusBrand.short)" : detail(card)
  }
}

// MARK: - Shared pieces

/// İlk belirişte ve değer değişince yumuşakça dolan ilerleme çubuğu.
struct FillingProgressBar: View {
  let value: Double
  var tint: Color = Palette.accent
  var height: CGFloat = 8
  @State private var shown = 0.0
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    ProgressBar(value: shown, tint: tint, height: height)
      .onAppear { fill() }
      .onChange(of: value) { fill() }
  }

  /// Çubuğu hedef değere doldurur (Hareketi Azalt açıksa animasyonsuz).
  private func fill() {
    guard !reduceMotion else {
      shown = value
      return
    }
    withAnimation(Motion.gentle.delay(0.15)) { shown = value }
  }
}

/// Dokunulan kareyi yatayda kısa bir süre sallar (her artışta bir kez).
struct ShakeEffect: GeometryEffect {
  var shakes: CGFloat

  var animatableData: CGFloat {
    get { shakes }
    set { shakes = newValue }
  }

  func effectValue(size: CGSize) -> ProjectionTransform {
    ProjectionTransform(CGAffineTransform(translationX: 7 * sin(shakes * .pi * 4), y: 0))
  }
}

/// Kısa uyarı baloncuğu ("Önce 3. bulmacayı bitir").
struct NudgeToast: View {
  let text: String

  var body: some View {
    Label(text, systemImage: "lock.fill")
      .font(AppFont.caption.weight(.heavy))
      .foregroundStyle(Palette.ink)
      .lineLimit(2)
      .multilineTextAlignment(.center)
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(
        Capsule().fill(Palette.surface)
          .overlay(Capsule().strokeBorder(Palette.cardBorder, lineWidth: 1))
          .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
      )
      .accessibilityAddTraits(.isStaticText)
  }
}

/// Kare köşesine tam oturan Plus sekmesi: karenin şekliyle kırpılır, böylece sağ üst köşeyi
/// köşe yarıçapıyla birlikte doldurur.
struct PlusCornerTab: View {
  /// Kırpılan karenin köşe yarıçapı.
  let cornerRadius: CGFloat

  var body: some View {
    Image(systemName: "crown.fill")
      .font(.system(size: 10, weight: .black))
      .foregroundStyle(Palette.goldInk)
      .frame(width: 26, height: 20)
      .background(
        UnevenRoundedRectangle(bottomLeadingRadius: 10, style: .continuous)
          .fill(
            LinearGradient(
              colors: Palette.plusGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
      .allowsHitTesting(false)
      .accessibilityHidden(true)
  }
}

extension View {
  /// Plus gerekiyorsa karenin sağ üst köşesine, köşeye yaslı Plus sekmesi ekler.
  func plusCornerTab(_ isShown: Bool, cornerRadius: CGFloat) -> some View {
    overlay {
      if isShown {
        PlusCornerTab(cornerRadius: cornerRadius).transition(.opacity)
      }
    }
  }
}
