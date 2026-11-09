import DesignKit
import SwiftUI

/// Bulmaca ızgarasının görünüm teması. Uygulama görünümünden bağımsızdır.
public struct PuzzleTheme: Identifiable, Equatable, Sendable {
  /// Tema kimliği (ayarlarda saklanır).
  public let id: String
  /// Ekranda görünen ad.
  public let name: String
  /// Kısa açıklama.
  public let detail: String
  /// Çengelish+ gerektiriyor mu.
  public let isPremium: Bool
  /// Harf kutusu zemini.
  public let cell: Color
  /// İpucu kutusu zemini.
  public let clue: Color
  /// İpucu yazısı.
  public let clueInk: Color
  /// Izgara çizgisi (kutular arası boşluk rengi).
  public let line: Color
  /// Tükenmez kalem rengi.
  public let pen: Color
  /// Kurşun kalem rengi.
  public let pencil: Color
  /// Boş (blok) kutu zemini.
  public let blank: Color
  /// Blok kutularda çizgili desen kullanılsın mı.
  public let stripedBlanks: Bool
  /// Seçili kelime vurgusu.
  public let highlight: Color
  /// Aktif kutu.
  public let active: Color
  /// Aktif kutu çerçevesi (yoksa nil).
  public let activeRing: Color?
  /// İpucu oku.
  public let arrow: Color
  /// Kutular arası boşluk.
  public let gap: CGFloat
  /// Dış çerçeve kalınlığı.
  public let border: CGFloat
  /// Kutu köşe yarıçapı oranı (kutu boyuna göre).
  public let cornerRatio: CGFloat
  /// Cevap anahtarı harf rengi.
  public let keyInk: Color

  /// Temayı tüm renk ve ölçüleriyle oluşturur.
  public init(
    id: String, name: String, detail: String, isPremium: Bool, cell: Color, clue: Color,
    clueInk: Color, line: Color, pen: Color, pencil: Color, blank: Color, stripedBlanks: Bool,
    highlight: Color, active: Color, activeRing: Color?, arrow: Color, gap: CGFloat,
    border: CGFloat, cornerRatio: CGFloat, keyInk: Color
  ) {
    self.id = id
    self.name = name
    self.detail = detail
    self.isPremium = isPremium
    self.cell = cell
    self.clue = clue
    self.clueInk = clueInk
    self.line = line
    self.pen = pen
    self.pencil = pencil
    self.blank = blank
    self.stripedBlanks = stripedBlanks
    self.highlight = highlight
    self.active = active
    self.activeRing = activeRing
    self.arrow = arrow
    self.gap = gap
    self.border = border
    self.cornerRatio = cornerRatio
    self.keyInk = keyInk
  }

  // MARK: - Catalog

  /// Tüm temalar, gösterim sırasıyla.
  public static let all: [PuzzleTheme] = [canli, kagit, gece, okyanus, pastel, kareli]

  /// Kimliğe göre tema (bulunamazsa Canlı).
  public static func theme(id: String) -> PuzzleTheme {
    all.first { $0.id == id } ?? canli
  }

  /// Ayarlara göre gösterilecek temayı seçer.
  ///
  /// - Parameters:
  ///   - id: Seçili tema.
  ///   - isDark: Cihaz koyu modda mı.
  ///   - autoNight: Koyu modda Gece temasına geçilsin mi.
  ///   - highContrast: Yüksek kontrast açık mı.
  public static func resolve(
    id: String, isDark: Bool, autoNight: Bool, highContrast: Bool
  )
    -> PuzzleTheme
  {
    var theme = theme(id: id)
    if isDark, autoNight, theme.id != canli.id { theme = gece }
    return highContrast ? theme.highContrastVariant : theme
  }

  /// Varsayılan tema: uygulamanın renkleri, açık/koyu moda uyumlu.
  public static let canli = PuzzleTheme(
    id: "canli", name: "Canlı", detail: "Varsayılan · koyu modla uyumlu", isPremium: false,
    cell: Palette.dynamic(0xFFFFFF, 0x221F42), clue: Palette.dynamic(0xE9E4FF, 0x2C2766),
    clueInk: Palette.dynamic(0x3A2EA0, 0xD2CBFF), line: .clear,
    pen: Palette.dynamic(0x3427C2, 0xE8E4FF), pencil: Palette.dynamic(0xABA7CC, 0x77729F),
    blank: Palette.dynamic(0xECE7FF, 0x262249), stripedBlanks: true,
    highlight: Palette.dynamic(0xFFF0C0, 0x3B3217), active: Palette.dynamic(0xFFD45C, 0x6E5512),
    activeRing: Palette.dynamic(0xFFB020, 0xFFC93C), arrow: Palette.dynamic(0x6C5CE7, 0xA79BFF),
    gap: 4, border: 0, cornerRatio: 0.2, keyInk: Palette.keyInk)

  /// Gazete çengeli görünümü.
  public static let kagit = PuzzleTheme(
    id: "kagit", name: "Kağıt", detail: "Gazete çengeli hissi", isPremium: false,
    cell: Color(hex: 0xFBF8F0), clue: Color(hex: 0xEDE6D3), clueInk: Color(hex: 0x3A332A),
    line: Color(hex: 0x1C1A17), pen: Color(hex: 0x1E3A8A), pencil: Color(hex: 0x9C9585),
    blank: Color(hex: 0x1C1A17), stripedBlanks: false, highlight: Color(hex: 0xF4E7B8),
    active: Color(hex: 0xEBCB6A), activeRing: nil, arrow: Color(hex: 0x1C1A17), gap: 1,
    border: 2, cornerRatio: 0, keyInk: Color(hex: 0xC2410C))

  /// Göz yormayan koyu ızgara.
  public static let gece = PuzzleTheme(
    id: "gece", name: "Gece", detail: "Göz yormayan koyu ızgara", isPremium: false,
    cell: Color(hex: 0x0F141B), clue: Color(hex: 0x18202C), clueInk: Color(hex: 0xA9B8CC),
    line: Color(hex: 0x273142), pen: Color(hex: 0xF3EFE4), pencil: Color(hex: 0x6C798C),
    blank: Color(hex: 0x080B10), stripedBlanks: false, highlight: Color(hex: 0x2A2414),
    active: Color(hex: 0x4A3B19), activeRing: Color(hex: 0xE8C27A), arrow: Color(hex: 0xE8C27A),
    gap: 1, border: 1, cornerRatio: 0, keyInk: Color(hex: 0xFFB27A))

  /// Ferah mavi tonlar.
  public static let okyanus = PuzzleTheme(
    id: "okyanus", name: "Okyanus", detail: "Ferah mavi tonlar", isPremium: false,
    cell: Color(hex: 0xF4FAFC), clue: Color(hex: 0xCFE7EF), clueInk: Color(hex: 0x0B3D57),
    line: Color(hex: 0x0E6E8C), pen: Color(hex: 0x0B3D57), pencil: Color(hex: 0x7FA9B8),
    blank: Color(hex: 0x0E6E8C), stripedBlanks: false, highlight: Color(hex: 0xBFE3EE),
    active: Color(hex: 0x8FD0E3), activeRing: nil, arrow: Color(hex: 0x0E6E8C), gap: 1,
    border: 2, cornerRatio: 0, keyInk: Color(hex: 0xE4572E))

  /// Yumuşak pembe, yuvarlak kutular.
  public static let pastel = PuzzleTheme(
    id: "pastel", name: "Pastel", detail: "Yumuşak pembe, yuvarlak kutular", isPremium: true,
    cell: Color(hex: 0xFFFFFF), clue: Color(hex: 0xFFDCE8), clueInk: Color(hex: 0x8A2F5B),
    line: Color(hex: 0xFFC9DA), pen: Color(hex: 0x5A3D7A), pencil: Color(hex: 0xC9A8C9),
    blank: Color(hex: 0xFFE9F0), stripedBlanks: false, highlight: Color(hex: 0xFFF1B8),
    active: Color(hex: 0xFFC2D6), activeRing: Color(hex: 0xE26D9A), arrow: Color(hex: 0xE26D9A),
    gap: 2, border: 2, cornerRatio: 0.12, keyInk: Color(hex: 0xE26D9A))

  /// Okul defteri, kırmızı oklar.
  public static let kareli = PuzzleTheme(
    id: "kareli", name: "Kareli Defter", detail: "Okul defteri, kırmızı oklar", isPremium: true,
    cell: Color(hex: 0xFBFCF7), clue: Color(hex: 0xE3ECF8), clueInk: Color(hex: 0x1F2A44),
    line: Color(hex: 0x7FA7D9), pen: Color(hex: 0x1F2A44), pencil: Color(hex: 0x9DB0C8),
    blank: Color(hex: 0xC9D9EE), stripedBlanks: false, highlight: Color(hex: 0xFFF6B8),
    active: Color(hex: 0xFFE36E), activeRing: nil, arrow: Color(hex: 0xD64545), gap: 1,
    border: 1, cornerRatio: 0, keyInk: Color(hex: 0xD64545))

  /// Erişilebilirlik için yüksek kontrastlı sürüm.
  public var highContrastVariant: PuzzleTheme {
    PuzzleTheme(
      id: id, name: name, detail: detail, isPremium: isPremium, cell: .white, clue: .white,
      clueInk: .black, line: .black, pen: .black, pencil: Color(hex: 0x555555), blank: .black,
      stripedBlanks: false, highlight: Color(hex: 0xFFE500), active: Color(hex: 0xFFE500),
      activeRing: .black, arrow: .black, gap: 2, border: 3, cornerRatio: 0,
      keyInk: Color(hex: 0xD00000))
  }
}
