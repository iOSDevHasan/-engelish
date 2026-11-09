import SwiftUI
import UIKit

/// Çengelish renk tokenları; her renk açık ve koyu mod için ayrı değer taşır.
public enum Palette {

  // MARK: - Surfaces

  /// Ekran arka planı.
  public static let background = dynamic(0xFFF8EE, 0x121027)
  /// Kart ve panel yüzeyi.
  public static let surface = dynamic(0xFFFFFF, 0x1D1A38)
  /// İkincil yüzey (seçili satır, gri kutular).
  public static let surface2 = dynamic(0xF1EEFF, 0x29254A)
  /// İnce ayırıcı çizgi.
  public static let line = dynamic(0xECE8FA, 0x2C2850)
  /// Belirgin çizgi ve pasif kontrol rengi.
  public static let lineStrong = dynamic(0xD3CDF0, 0x433E72)

  // MARK: - Text

  /// Ana metin rengi.
  public static let ink = dynamic(0x24204D, 0xF3F1FF)
  /// İkincil metin rengi.
  public static let muted = dynamic(0x7C78A3, 0xA5A1CC)

  // MARK: - Brand

  /// Vurgu (mor) rengi.
  public static let accent = dynamic(0x6C5CE7, 0x8E80FF)
  /// Birincil buton dolgusu.
  public static let buttonFill = dynamic(0x6C5CE7, 0x7C6CF5)
  /// Birincil butonun alt gölgesi.
  public static let buttonShadow = dynamic(0x4A3BC0, 0x3B2EA3)
  /// İkincil butonun alt gölgesi.
  public static let secondaryShadow = dynamic(0xDCD5F7, 0x100E24)
  /// Seçili seçenek arka planı.
  public static let selection = dynamic(0xF1EEFF, 0x2A2558)
  /// Seçili seçeneğin alt gölgesi.
  public static let selectionShadow = dynamic(0xC9C0FA, 0x4B42A0)
  /// Kart gölgesi çizgisi.
  public static let cardShadow = dynamic(0xECE7FB, 0x0E0C22)

  // MARK: - Status

  /// Doğru / başarı rengi.
  public static let good = dynamic(0x1FB57A, 0x3DD69A)
  /// Doğru rozet zemini.
  public static let goodBackground = dynamic(0xDDF6EC, 0x1C3B30)
  /// Yanlış / hata rengi.
  public static let bad = dynamic(0xFF5A5F, 0xFF6B70)
  /// Yanlış rozet zemini.
  public static let badBackground = dynamic(0xFFE4E4, 0x3D2335)
  /// Altın (premium) zemin.
  public static let gold = Color(hex: 0xFFC93C)
  /// Altın zemin üzerindeki yazı.
  public static let goldInk = Color(hex: 0x3B2A00)
  /// Seri (alev) rengi.
  public static let streak = dynamic(0xFF8A3D, 0xFF9E5E)
  /// Seri kartı zemini.
  public static let streakBackground = dynamic(0xFFF1E6, 0x2B2033)
  /// Cevap anahtarı harf rengi.
  public static let keyInk = dynamic(0xFF6B2C, 0xFFB27A)

  // MARK: - Puzzle chrome

  /// İpucu çubuğu zemini.
  public static let clueBar = dynamic(0x6C5CE7, 0x5B4BE0)
  /// İpucu çubuğundaki yön oku.
  public static let clueBarArrow = Color(hex: 0xFFC93C)

  // MARK: - Pastels

  /// Kart ve paket kapakları için pastel renkler.
  public static let pastels: [Color] = [
    dynamic(0xFFE3D3, 0x3A2A2A), dynamic(0xD9F0FF, 0x1F3346), dynamic(0xE8E3FF, 0x2C2858),
    dynamic(0xD6F5E6, 0x1C3B30), dynamic(0xEAF7D2, 0x2A3A20), dynamic(0xFFE0EC, 0x3D2335),
  ]

  // MARK: - Helpers

  /// Açık ve koyu moda göre değişen bir renk üretir.
  public static func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
    Color(
      uiColor: UIColor { traits in
        UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
      })
  }
}

extension Color {
  /// 0xRRGGBB biçimindeki onaltılık değerden renk üretir.
  public init(hex: UInt32, opacity: Double = 1) {
    self.init(uiColor: UIColor(hex: hex, alpha: opacity))
  }
}

extension UIColor {
  /// 0xRRGGBB biçimindeki onaltılık değerden renk üretir.
  public convenience init(hex: UInt32, alpha: Double = 1) {
    self.init(
      red: CGFloat((hex >> 16) & 0xFF) / 255,
      green: CGFloat((hex >> 8) & 0xFF) / 255,
      blue: CGFloat(hex & 0xFF) / 255,
      alpha: alpha
    )
  }
}
