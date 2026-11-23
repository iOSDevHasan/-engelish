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
  /// Çengelish Plus gerektiriyor mu.
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
  /// Koyu modda kendi görünümü var mı; varsa "Koyu modda Gece teması" ayarı bu temayı değiştirmez.
  ///
  /// Zaten koyu olan ya da renkleri açık/koyu moda uyan temalarda `true` olur.
  public let keepsInDarkMode: Bool

  /// Temayı tüm renk ve ölçüleriyle oluşturur.
  public init(
    id: String, name: String, detail: String, isPremium: Bool, cell: Color, clue: Color,
    clueInk: Color, line: Color, pen: Color, pencil: Color, blank: Color, stripedBlanks: Bool,
    highlight: Color, active: Color, activeRing: Color?, arrow: Color, gap: CGFloat,
    border: CGFloat, cornerRatio: CGFloat, keyInk: Color, keepsInDarkMode: Bool = false
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
    self.keepsInDarkMode = keepsInDarkMode
  }

  // MARK: - Catalog

  /// Tüm temalar, gösterim sırasıyla (önce ücretsizler, sonra Çengelish Plus temaları).
  public static let all: [PuzzleTheme] = [
    canli, kagit, gece, okyanus, nane, limonata, pastel, kareli, orman, gunBatimi, sepya,
    geceMavisi, karaTahta, neon, lavanta, kahve, buzul, altin,
  ]

  /// Kimliğe göre tema (bulunamazsa Canlı).
  public static func theme(id: String) -> PuzzleTheme {
    all.first { $0.id == id } ?? canli
  }

  /// Ayarlara göre gösterilecek temayı seçer.
  ///
  /// - Parameters:
  ///   - id: Seçili tema.
  ///   - isDark: Cihaz koyu modda mı.
  ///   - autoNight: Koyu modda Gece temasına geçilsin mi (koyu görünümü olan temalar hariç).
  ///   - highContrast: Yüksek kontrast açık mı.
  public static func resolve(
    id: String, isDark: Bool, autoNight: Bool, highContrast: Bool
  )
    -> PuzzleTheme
  {
    var theme = theme(id: id)
    if isDark, autoNight, !theme.keepsInDarkMode { theme = gece }
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
    gap: 4, border: 0, cornerRatio: 0.2, keyInk: Palette.keyInk, keepsInDarkMode: true)

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
    gap: 1, border: 1, cornerRatio: 0, keyInk: Color(hex: 0xFFB27A), keepsInDarkMode: true)

  /// Ferah mavi tonlar.
  public static let okyanus = PuzzleTheme(
    id: "okyanus", name: "Okyanus", detail: "Ferah mavi tonlar", isPremium: false,
    cell: Color(hex: 0xF4FAFC), clue: Color(hex: 0xCFE7EF), clueInk: Color(hex: 0x0B3D57),
    line: Color(hex: 0x0E6E8C), pen: Color(hex: 0x0B3D57), pencil: Color(hex: 0x7FA9B8),
    blank: Color(hex: 0x0E6E8C), stripedBlanks: false, highlight: Color(hex: 0xBFE3EE),
    active: Color(hex: 0x8FD0E3), activeRing: nil, arrow: Color(hex: 0x0E6E8C), gap: 1,
    border: 2, cornerRatio: 0, keyInk: Color(hex: 0xE4572E))

  /// Ferah nane yeşili, yuvarlak kutular; koyu modda koyu yeşil.
  public static let nane = PuzzleTheme(
    id: "nane", name: "Nane", detail: "Ferah nane yeşili, yuvarlak kutular", isPremium: false,
    cell: Palette.dynamic(0xFFFFFF, 0x10241E), clue: Palette.dynamic(0xD4F3E6, 0x17362C),
    clueInk: Palette.dynamic(0x0F5A43, 0xBFEFD9), line: Palette.dynamic(0x9ED9C1, 0x2E6B56),
    pen: Palette.dynamic(0x113D33, 0xEAFBF3), pencil: Palette.dynamic(0x8DB5A8, 0x6E9586),
    blank: Palette.dynamic(0xDFF4EB, 0x0A1813), stripedBlanks: true,
    highlight: Palette.dynamic(0xFFF3B5, 0x2C3A1E), active: Palette.dynamic(0xBDEFD9, 0x23533F),
    activeRing: Palette.dynamic(0x1A9A6E, 0x5FE0B0), arrow: Palette.dynamic(0x15805E, 0x6FE3B8),
    gap: 3, border: 0, cornerRatio: 0.2, keyInk: Palette.dynamic(0xC93D0A, 0xFFA36B),
    keepsInDarkMode: true)

  /// Limon sarısı ipuçları, güneşli sabah; koyu modda koyu hardal.
  public static let limonata = PuzzleTheme(
    id: "limonata", name: "Limonata", detail: "Limon sarısı, güneşli sabah", isPremium: false,
    cell: Palette.dynamic(0xFFFDF2, 0x26220F), clue: Palette.dynamic(0xFFEC94, 0x3A3313),
    clueInk: Palette.dynamic(0x5C4A00, 0xFFEFA0), line: Palette.dynamic(0xE5C23A, 0x6B5C1C),
    pen: Palette.dynamic(0x2D2A6E, 0xFFF8DC), pencil: Palette.dynamic(0xB9AE80, 0x8F8661),
    blank: Palette.dynamic(0xFFE36A, 0x171408), stripedBlanks: false,
    highlight: Palette.dynamic(0xFFE0B8, 0x433816), active: Palette.dynamic(0xFFD27A, 0x5E4C12),
    activeRing: Palette.dynamic(0xB87900, 0xFFD24D), arrow: Palette.dynamic(0x8F5F00, 0xFFD24D),
    gap: 2, border: 2, cornerRatio: 0.14, keyInk: Palette.dynamic(0xC73A3A, 0xFF9E7A),
    keepsInDarkMode: true)

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

  // MARK: - Plus themes

  /// Yosun yeşili kutular, pas rengi anahtar; koyu modda gece ormanı.
  public static let orman = PuzzleTheme(
    id: "orman", name: "Orman", detail: "Yosun yeşili, sakin orman", isPremium: true,
    cell: Palette.dynamic(0xF6F8EF, 0x13201A), clue: Palette.dynamic(0xDCE8CF, 0x1D3326),
    clueInk: Palette.dynamic(0x1F3D25, 0xCFE6C8), line: Palette.dynamic(0x3D6B45, 0x2E4E37),
    pen: Palette.dynamic(0x1E3A24, 0xEAF3E2), pencil: Palette.dynamic(0x8FA48F, 0x6E8A72),
    blank: Palette.dynamic(0x3D6B45, 0x0B140F), stripedBlanks: false,
    highlight: Palette.dynamic(0xE9F0C6, 0x2A3A1E), active: Palette.dynamic(0xCFE08F, 0x48602A),
    activeRing: Palette.dynamic(0x4E8A34, 0xA9D46B), arrow: Palette.dynamic(0x2F6B3A, 0x9CCB7E),
    gap: 1, border: 2, cornerRatio: 0.08, keyInk: Palette.dynamic(0xB5541C, 0xFFA66B),
    keepsInDarkMode: true)

  /// Şeftali kutular, mercan bloklar; koyu modda alacakaranlık moru.
  public static let gunBatimi = PuzzleTheme(
    id: "gunbatimi", name: "Gün Batımı", detail: "Şeftali ve mor, sıcak akşam", isPremium: true,
    cell: Palette.dynamic(0xFFF8F1, 0x2A1B33), clue: Palette.dynamic(0xFFDCC7, 0x46263F),
    clueInk: Palette.dynamic(0x7A2E3A, 0xFFD9C2), line: Palette.dynamic(0xF2A98A, 0x6A3557),
    pen: Palette.dynamic(0x4A2366, 0xFFEBDC), pencil: Palette.dynamic(0xC7A2B0, 0x8E6F8A),
    blank: Palette.dynamic(0xE98A6B, 0x1A1022), stripedBlanks: false,
    highlight: Palette.dynamic(0xFFEBB0, 0x48311F), active: Palette.dynamic(0xFFC979, 0x744620),
    activeRing: Palette.dynamic(0xE2574C, 0xFFB86B), arrow: Palette.dynamic(0xD9473D, 0xFF8A6B),
    gap: 2, border: 2, cornerRatio: 0.16, keyInk: Palette.dynamic(0xC2362E, 0xFFB25C),
    keepsInDarkMode: true)

  /// Sararmış eski gazete: sepya kâğıt, taralı bloklar; koyu modda koyu kahve.
  public static let sepya = PuzzleTheme(
    id: "sepya", name: "Retro Gazete", detail: "Sararmış kâğıt, sepya mürekkep", isPremium: true,
    cell: Palette.dynamic(0xF4E8CC, 0x2B2219), clue: Palette.dynamic(0xE4D2A8, 0x3B2F22),
    clueInk: Palette.dynamic(0x45301C, 0xE8D5B0), line: Palette.dynamic(0x5B4128, 0x5A4630),
    pen: Palette.dynamic(0x33241A, 0xF2E5C9), pencil: Palette.dynamic(0x9E8A6A, 0x857359),
    blank: Palette.dynamic(0x8A6C47, 0x7A6346), stripedBlanks: true,
    highlight: Palette.dynamic(0xEDD995, 0x463718), active: Palette.dynamic(0xDDB85E, 0x6B5120),
    activeRing: nil, arrow: Palette.dynamic(0x7A2E1E, 0xE0A56B), gap: 1, border: 3,
    cornerRatio: 0, keyInk: Palette.dynamic(0x9A2A1A, 0xFF9F6B), keepsInDarkMode: true)

  /// Lacivert gökyüzü, yuvarlak kutular ve yıldız sarısı etkin kutu.
  public static let geceMavisi = PuzzleTheme(
    id: "gecemavisi", name: "Gece Mavisi", detail: "Lacivert gökyüzü, yıldız ışığı",
    isPremium: true, cell: Color(hex: 0x101A3A), clue: Color(hex: 0x1B2752),
    clueInk: Color(hex: 0xC9D6FF), line: Color(hex: 0x2A3A72), pen: Color(hex: 0xF4F6FF),
    pencil: Color(hex: 0x7181B5), blank: Color(hex: 0x0A1128), stripedBlanks: false,
    highlight: Color(hex: 0x222F5E), active: Color(hex: 0x34407A),
    activeRing: Color(hex: 0xFFD86B), arrow: Color(hex: 0x9CC3FF), gap: 2, border: 2,
    cornerRatio: 0.18, keyInk: Color(hex: 0xFFB08A), keepsInDarkMode: true)

  /// Yeşil okul tahtası: tebeşir beyazı yazı, sarı tebeşir oklar.
  public static let karaTahta = PuzzleTheme(
    id: "karatahta", name: "Kara Tahta", detail: "Yeşil tahta, tebeşir yazısı", isPremium: true,
    cell: Color(hex: 0x24392F), clue: Color(hex: 0x2E4A3D), clueInk: Color(hex: 0xF2F0E6),
    line: Color(hex: 0x6E8C7D), pen: Color(hex: 0xF7F5EC), pencil: Color(hex: 0x9DB3A6),
    blank: Color(hex: 0x16241D), stripedBlanks: false, highlight: Color(hex: 0x3A4F2E),
    active: Color(hex: 0x56592C), activeRing: Color(hex: 0xF2D66B), arrow: Color(hex: 0xF2D66B),
    gap: 1, border: 2, cornerRatio: 0, keyInk: Color(hex: 0xFFA3A3), keepsInDarkMode: true)

  /// Karanlıkta parlayan pembe çizgiler, camgöbeği ipuçları.
  public static let neon = PuzzleTheme(
    id: "neon", name: "Neon", detail: "Karanlıkta parlayan çizgiler", isPremium: true,
    cell: Color(hex: 0x0D0B1A), clue: Color(hex: 0x22144A), clueInk: Color(hex: 0x7DF9FF),
    line: Color(hex: 0xFF2E97), pen: Color(hex: 0xF5F3FF), pencil: Color(hex: 0x7A6FA0),
    blank: Color(hex: 0x07060F), stripedBlanks: false, highlight: Color(hex: 0x28154A),
    active: Color(hex: 0x3F1B66), activeRing: Color(hex: 0x00F0FF), arrow: Color(hex: 0xFF2E97),
    gap: 1, border: 2, cornerRatio: 0.1, keyInk: Color(hex: 0xFFE14D), keepsInDarkMode: true)

  /// Lila tonlar, mor bloklar; koyu modda gece moru.
  public static let lavanta = PuzzleTheme(
    id: "lavanta", name: "Lavanta", detail: "Lila tonlar, sakin akşam", isPremium: true,
    cell: Palette.dynamic(0xFBF9FF, 0x1C1733), clue: Palette.dynamic(0xE6DDFF, 0x2B2350),
    clueInk: Palette.dynamic(0x3E2A86, 0xDCD2FF), line: Palette.dynamic(0xB3A0EE, 0x4A3F85),
    pen: Palette.dynamic(0x2E2370, 0xF3EFFF), pencil: Palette.dynamic(0xA79FCB, 0x8077AD),
    blank: Palette.dynamic(0xB9A5EE, 0x120E24), stripedBlanks: false,
    highlight: Palette.dynamic(0xFFF0C7, 0x3A2F55), active: Palette.dynamic(0xD9CCFF, 0x46397E),
    activeRing: Palette.dynamic(0x6B4FD8, 0xB9A5FF), arrow: Palette.dynamic(0x5B3FC8, 0xB9A5FF),
    gap: 2, border: 2, cornerRatio: 0.18, keyInk: Palette.dynamic(0xB8306F, 0xFF9EC8),
    keepsInDarkMode: true)

  /// Sütlü kahve tonları, kahverengi bloklar; koyu modda koyu kavrulmuş.
  public static let kahve = PuzzleTheme(
    id: "kahve", name: "Kahve Molası", detail: "Sütlü kahve, sıcak tonlar", isPremium: true,
    cell: Palette.dynamic(0xFFF9F2, 0x221812), clue: Palette.dynamic(0xEBD9C4, 0x34261C),
    clueInk: Palette.dynamic(0x4A2E1A, 0xF0DCC6), line: Palette.dynamic(0xB08960, 0x6B5038),
    pen: Palette.dynamic(0x3B2414, 0xFFF4E8), pencil: Palette.dynamic(0xA89078, 0x8E7A68),
    blank: Palette.dynamic(0x6F4E37, 0x140D09), stripedBlanks: false,
    highlight: Palette.dynamic(0xF5E2B8, 0x3D2C17), active: Palette.dynamic(0xE8C48C, 0x5A3E1E),
    activeRing: Palette.dynamic(0x9C5B2E, 0xE0A86B), arrow: Palette.dynamic(0x8A4B22, 0xE0A86B),
    gap: 1, border: 2, cornerRatio: 0.06, keyInk: Palette.dynamic(0xB83A1E, 0xFF9F7A),
    keepsInDarkMode: true)

  /// Buz mavisi, kristal gibi yuvarlak kutular; koyu modda kutup gecesi.
  public static let buzul = PuzzleTheme(
    id: "buzul", name: "Buzul", detail: "Buz mavisi, kristal kutular", isPremium: true,
    cell: Palette.dynamic(0xFFFFFF, 0x0E1E2B), clue: Palette.dynamic(0xD8F0FA, 0x15303F),
    clueInk: Palette.dynamic(0x0B4A63, 0xC4ECFA), line: Palette.dynamic(0x8FCFE8, 0x2A5770),
    pen: Palette.dynamic(0x0D2F4F, 0xEEF9FF), pencil: Palette.dynamic(0x93B4C6, 0x6C8EA1),
    blank: Palette.dynamic(0xCDEFFA, 0x08141D), stripedBlanks: true,
    highlight: Palette.dynamic(0xE8F7D0, 0x1E3A2E), active: Palette.dynamic(0xB8E6F7, 0x1F4A63),
    activeRing: Palette.dynamic(0x1E8FC2, 0x7DD6F5), arrow: Palette.dynamic(0x177AA8, 0x7DD6F5),
    gap: 3, border: 0, cornerRatio: 0.22, keyInk: Palette.dynamic(0xC93A53, 0xFF9AAE),
    keepsInDarkMode: true)

  /// Siyah zemin, altın çizgiler ve ipuçları.
  public static let altin = PuzzleTheme(
    id: "altin", name: "Altın", detail: "Siyah zemin, altın çizgiler", isPremium: true,
    cell: Color(hex: 0x121212), clue: Color(hex: 0x2A2312), clueInk: Color(hex: 0xF2D58A),
    line: Color(hex: 0xB8902F), pen: Color(hex: 0xFFF8E6), pencil: Color(hex: 0x8A7F66),
    blank: Color(hex: 0x050505), stripedBlanks: false, highlight: Color(hex: 0x33290F),
    active: Color(hex: 0x3D3214), activeRing: Color(hex: 0xE8C04A), arrow: Color(hex: 0xE8C04A),
    gap: 1, border: 2, cornerRatio: 0.06, keyInk: Color(hex: 0xFF8F6B), keepsInDarkMode: true)

  // MARK: - Accessibility

  /// Erişilebilirlik için yüksek kontrastlı sürüm.
  public var highContrastVariant: PuzzleTheme {
    PuzzleTheme(
      id: id, name: name, detail: detail, isPremium: isPremium, cell: .white, clue: .white,
      clueInk: .black, line: .black, pen: .black, pencil: Color(hex: 0x555555), blank: .black,
      stripedBlanks: false, highlight: Color(hex: 0xFFE500), active: Color(hex: 0xFFE500),
      activeRing: .black, arrow: .black, gap: 2, border: 3, cornerRatio: 0,
      keyInk: Color(hex: 0xD00000), keepsInDarkMode: keepsInDarkMode)
  }
}
