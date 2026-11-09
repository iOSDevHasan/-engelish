import SwiftUI

/// Yazı ölçeği. Tasarımdaki Nunito yerine sistemin yuvarlak (rounded) yazı tipi kullanılır.
public enum AppFont {

  /// Büyük başlık (onboarding, bitiş).
  public static let display = Font.system(size: 34, weight: .black, design: .rounded)
  /// Ekran başlığı.
  public static let title = Font.system(size: 26, weight: .black, design: .rounded)
  /// Bölüm başlığı.
  public static let headline = Font.system(size: 20, weight: .heavy, design: .rounded)
  /// Kart başlığı.
  public static let section = Font.system(size: 16, weight: .heavy, design: .rounded)
  /// Gövde metni.
  public static let body = Font.system(size: 15, weight: .semibold, design: .rounded)
  /// Kalın gövde metni.
  public static let bodyBold = Font.system(size: 15, weight: .heavy, design: .rounded)
  /// Küçük açıklama.
  public static let caption = Font.system(size: 13, weight: .bold, design: .rounded)
  /// En küçük metin.
  public static let tiny = Font.system(size: 11, weight: .bold, design: .rounded)
  /// Büyük harfli üst başlık (eyebrow).
  public static let eyebrow = Font.system(size: 11, weight: .black, design: .rounded)

  /// El yazısı görünümlü harf (cevap anahtarı, örnek harfler).
  public static func hand(size: CGFloat) -> Font {
    .custom("Noteworthy-Bold", size: size)
  }

  /// Verilen boyutta yuvarlak yazı tipi döner.
  public static func rounded(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
    .system(size: size, weight: weight, design: .rounded)
  }
}

/// Boşluk ve köşe yarıçapı tokenları.
public enum Metrics {
  /// Kart köşe yarıçapı.
  public static let radius: CGFloat = 22
  /// Buton köşe yarıçapı.
  public static let buttonRadius: CGFloat = 18
  /// Ekran kenar boşluğu.
  public static let gutter: CGFloat = 18
}
