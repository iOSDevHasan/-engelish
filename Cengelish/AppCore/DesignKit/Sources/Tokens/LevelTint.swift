import SwiftUI

/// CEFR seviyelerinin renk kimliği (kolaydan zora yeşil → turuncu). Keşfet'teki seviye kartları
/// ve profildeki seviye kartı aynı renkleri kullanır.
public enum LevelTint {

  /// Seviye rengi; kod "A1"…"C1" (büyük/küçük harf fark etmez), bilinmiyorsa vurgu rengi.
  public static func color(code: String) -> Color {
    switch code.uppercased() {
    case "A1": Color(hex: 0x1FB57A)
    case "A2": Color(hex: 0x3C9BE0)
    case "B1": Color(hex: 0x6C5CE7)
    case "B2": Color(hex: 0xA55EEA)
    case "C1": Color(hex: 0xFF8A3D)
    default: Palette.accent
    }
  }

  /// Seviye renginin koyu "kabartma" alt kenarı.
  public static func ledge(code: String) -> Color {
    switch code.uppercased() {
    case "A1": Color(hex: 0x16915F)
    case "A2": Color(hex: 0x2A7AB8)
    case "B1": Color(hex: 0x4A3BC0)
    case "B2": Color(hex: 0x7F3FC2)
    case "C1": Color(hex: 0xD9682A)
    default: Palette.buttonFill
    }
  }
}
