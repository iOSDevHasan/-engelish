import DesignKit
import SwiftUI

/// Kalem rengi ve kalınlık seçenekleri.
public enum PenStyle {

  /// Kalem rengi kimlikleri; `auto` temanın kendi kalem rengidir.
  public static let colorIds = ["auto", "1C1A17", "B23A2E", "2F6B3A", "6C5CE7"]

  /// Kalınlık çarpanları ve adları.
  public static let widths: [(value: Double, title: String)] = [
    (0.7, "İnce"), (1, "Orta"), (1.4, "Kalın"),
  ]

  /// Kimliğe göre kalem rengi.
  public static func color(id: String, theme: PuzzleTheme) -> Color {
    guard id != "auto", let hex = UInt32(id, radix: 16) else { return theme.pen }
    return Color(hex: hex)
  }

  /// Kalınlık adı.
  public static func widthTitle(_ value: Double) -> String {
    widths.min { abs($0.value - value) < abs($1.value - value) }?.title ?? "Orta"
  }
}

/// Kalem rengi seçici satırı.
public struct PenColorRow: View {
  private let selection: String
  private let theme: PuzzleTheme
  private let onSelect: (String) -> Void

  /// Seçili renk, tema ve seçim eylemiyle oluşturur.
  public init(selection: String, theme: PuzzleTheme, onSelect: @escaping (String) -> Void) {
    self.selection = selection
    self.theme = theme
    self.onSelect = onSelect
  }

  public var body: some View {
    HStack(spacing: 10) {
      ForEach(PenStyle.colorIds, id: \.self) { id in
        Button {
          onSelect(id)
        } label: {
          Circle().fill(PenStyle.color(id: id, theme: theme))
            .frame(width: 28, height: 28)
            .overlay(Circle().strokeBorder(Palette.lineStrong, lineWidth: 1))
            .overlay(
              Circle().strokeBorder(Palette.accent, lineWidth: selection == id ? 2.5 : 0)
                .padding(-4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(id == "auto" ? "Tema rengi" : "Kalem rengi")
        .accessibilityAddTraits(selection == id ? .isSelected : [])
      }
    }
  }
}

/// Tema seçim kartı: mini ızgara, ad, kilit ve seçim işareti.
public struct ThemeOptionCard: View {
  private let theme: PuzzleTheme
  private let isSelected: Bool
  private let isLocked: Bool
  private let cellSize: CGFloat

  /// Tema, seçim, kilit ve kutu boyuyla oluşturur.
  public init(theme: PuzzleTheme, isSelected: Bool, isLocked: Bool, cellSize: CGFloat = 12) {
    self.theme = theme
    self.isSelected = isSelected
    self.isLocked = isLocked
    self.cellSize = cellSize
  }

  public var body: some View {
    VStack(spacing: 6) {
      MiniGridView(puzzle: SamplePuzzles.demo, theme: theme, cellSize: cellSize)
      Text(theme.name).font(AppFont.tiny.weight(.black)).foregroundStyle(Palette.ink)
        .lineLimit(1).minimumScaleFactor(0.8)
    }
    .padding(.vertical, 10)
    .padding(.horizontal, 4)
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Palette.surface)
        .overlay(
          RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(isSelected ? Palette.accent : Palette.line, lineWidth: isSelected ? 3 : 2)
        )
    )
    .overlay(alignment: .topLeading) {
      if isLocked {
        Pill("", systemImage: "crown.fill", tone: .gold).padding(5)
      }
    }
    .overlay(alignment: .topTrailing) {
      if isSelected {
        Image(systemName: "checkmark").font(.system(size: 11, weight: .black))
          .foregroundStyle(.white)
          .frame(width: 22, height: 22)
          .background(Circle().fill(Palette.accent))
          .offset(x: 7, y: -7)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(theme.name)\(isLocked ? ", Çengelish+" : "")")
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}
