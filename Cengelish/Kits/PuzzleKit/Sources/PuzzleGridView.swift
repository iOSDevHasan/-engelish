import ContentKit
import DesignKit
import SwiftUI

/// Izgarada kutu içine yazılacak harf türü.
public enum GridLetterStyle: Equatable, Sendable {
  /// İpucuyla açılmış harf (anahtar renginde).
  case revealed
  /// Cevap anahtarı: kutunun köşesinde küçük harf.
  case key
  /// Paylaşım kartı: harf yerine dolu kutu.
  case filled
}

/// Çengel ızgarasını çizer: ipucu kutuları, harf kutuları ve bloklar.
///
/// El yazısı bu görünümün üstündeki çizim katmanında durur; bu görünüm sadece zemini çizer.
public struct PuzzleGridView: View {

  // MARK: - Properties

  private let layout: CrosswordLayout
  private let theme: PuzzleTheme
  private let cellSize: CGFloat
  private let highlighted: Set<GridPoint>
  private let active: GridPoint?
  private let activeClue: GridPoint?
  private let letters: [GridPoint: (Character, GridLetterStyle)]
  private let showsClueText: Bool
  private let geometry: GridGeometry

  // MARK: - Init

  /// Izgarayı düzen, tema, kutu boyu ve vurgularla oluşturur.
  public init(
    layout: CrosswordLayout,
    theme: PuzzleTheme,
    cellSize: CGFloat,
    highlighted: Set<GridPoint> = [],
    active: GridPoint? = nil,
    activeClue: GridPoint? = nil,
    letters: [GridPoint: (Character, GridLetterStyle)] = [:],
    showsClueText: Bool = true,
    geometry: GridGeometry? = nil
  ) {
    self.layout = layout
    self.theme = theme
    self.cellSize = cellSize
    self.highlighted = highlighted
    self.active = active
    self.activeClue = activeClue
    self.letters = letters
    self.showsClueText = showsClueText
    self.geometry = geometry ?? GridGeometry(cell: cellSize, gap: theme.gap, border: theme.border)
  }

  // MARK: - Body

  public var body: some View {
    VStack(spacing: geometry.gap) {
      ForEach(0..<layout.rows, id: \.self) { row in
        HStack(spacing: geometry.gap) {
          ForEach(0..<layout.columns, id: \.self) { col in
            cell(GridPoint(row: row, col: col))
          }
        }
      }
    }
    .padding(geometry.border)
    .background(theme.line)
    .fixedSize()
  }

  /// Tek kutuyu türüne göre çizer.
  @ViewBuilder
  private func cell(_ point: GridPoint) -> some View {
    let radius = cellSize * theme.cornerRatio
    let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
    switch layout.kind(at: point) {
    case .blank:
      BlankCell(theme: theme, size: geometry.cell, radius: radius)
    case .clue(let entries):
      ClueCell(
        entries: entries, theme: theme, size: cellSize, showsText: showsClueText,
        isActive: activeClue == point
      )
      .clipShape(shape)
    case .letter:
      ZStack {
        shape.fill(fill(for: point))
        if point == active, let ring = theme.activeRing {
          shape.strokeBorder(ring, lineWidth: max(2, cellSize * 0.06))
        }
        if let (char, style) = letters[point] {
          LetterMark(char: char, style: style, theme: theme, size: cellSize)
        }
      }
      .frame(width: cellSize, height: cellSize)
    }
  }

  private func fill(for point: GridPoint) -> Color {
    if point == active { return theme.active }
    if highlighted.contains(point) { return theme.highlight }
    if case .filled = letters[point]?.1 { return theme.pen }
    return theme.cell
  }
}

// MARK: - Cells

/// Blok kutu (Canlı temada çizgili).
private struct BlankCell: View {
  let theme: PuzzleTheme
  let size: CGFloat
  let radius: CGFloat

  var body: some View {
    RoundedRectangle(cornerRadius: radius, style: .continuous)
      .fill(theme.stripedBlanks ? Color.clear : theme.blank)
      .overlay {
        if theme.stripedBlanks {
          Canvas { ctx, canvas in
            var x = -canvas.height
            while x < canvas.width {
              var path = Path()
              path.move(to: CGPoint(x: x, y: canvas.height))
              path.addLine(to: CGPoint(x: x + canvas.height, y: 0))
              ctx.stroke(path, with: .color(theme.blank), lineWidth: 3)
              x += 7
            }
          }
          .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
      }
      .frame(width: size, height: size)
  }
}

/// İpucu kutusu: Türkçe ipucu ve yön oku.
private struct ClueCell: View {
  let entries: [PuzzleEntry]
  let theme: PuzzleTheme
  let size: CGFloat
  let showsText: Bool
  let isActive: Bool

  var body: some View {
    ZStack {
      (isActive ? theme.highlight : theme.clue)
      if showsText {
        VStack(spacing: 1) {
          ForEach(entries) { entry in
            Text(entry.clue)
              .font(.system(size: max(7, size * 0.17), weight: .heavy, design: .rounded))
              .multilineTextAlignment(.center)
              .lineLimit(3)
              .minimumScaleFactor(0.55)
              .foregroundStyle(theme.clueInk)
          }
        }
        .padding(.horizontal, size * 0.06)
        .padding(.trailing, size * 0.06)
        .padding(.bottom, size * 0.06)
      }
      ForEach(entries) { entry in
        ArrowMark(direction: entry.dir, color: theme.arrow, size: size)
      }
    }
    .frame(width: size, height: size)
  }
}

/// İpucu kutusunun kenarındaki küçük ok.
private struct ArrowMark: View {
  let direction: Direction
  let color: Color
  let size: CGFloat

  var body: some View {
    let s = max(4, size * 0.11)
    Path { p in
      if direction == .across {
        p.move(to: CGPoint(x: size - s, y: size / 2 - s * 0.8))
        p.addLine(to: CGPoint(x: size - 1.5, y: size / 2))
        p.addLine(to: CGPoint(x: size - s, y: size / 2 + s * 0.8))
      } else {
        p.move(to: CGPoint(x: size / 2 - s * 0.8, y: size - s))
        p.addLine(to: CGPoint(x: size / 2, y: size - 1.5))
        p.addLine(to: CGPoint(x: size / 2 + s * 0.8, y: size - s))
      }
      p.closeSubpath()
    }
    .fill(color)
    .frame(width: size, height: size)
  }
}

/// Kutuya basılı harf (ipucu harfi ya da cevap anahtarı).
private struct LetterMark: View {
  let char: Character
  let style: GridLetterStyle
  let theme: PuzzleTheme
  let size: CGFloat

  var body: some View {
    switch style {
    case .revealed:
      Text(String(char))
        .font(.system(size: size * 0.55, weight: .heavy, design: .rounded))
        .foregroundStyle(theme.keyInk)
    case .key:
      Text(String(char))
        .font(.system(size: max(8, size * 0.26), weight: .black, design: .rounded))
        .foregroundStyle(theme.keyInk)
        .frame(width: size, height: size, alignment: .bottomTrailing)
        .padding(.trailing, size * 0.1)
        .padding(.bottom, size * 0.04)
    case .filled:
      EmptyView()
    }
  }
}

/// Küçük ızgara önizlemesi (ana sayfa, tema kartı, paket kartı).
public struct MiniGridView: View {
  private let layout: CrosswordLayout
  private let theme: PuzzleTheme
  private let cellSize: CGFloat
  private let highlighted: Set<GridPoint>
  private let active: GridPoint?

  /// Bulmaca, tema ve kutu boyuyla önizleme oluşturur.
  ///
  /// `highlighted` verilmezse ilk soldan sağa kelime vurgulanır; `active` etkin kutuyu işaretler.
  public init(
    puzzle: Puzzle,
    theme: PuzzleTheme,
    cellSize: CGFloat = 12,
    highlighted: Set<GridPoint>? = nil,
    active: GridPoint? = nil
  ) {
    self.layout = CrosswordLayout(puzzle: puzzle)
    self.theme = theme
    self.cellSize = cellSize
    self.highlighted =
      highlighted ?? Set(puzzle.entries.first { $0.dir == .across }?.cells ?? [])
    self.active = active
  }

  public var body: some View {
    PuzzleGridView(
      layout: layout, theme: theme, cellSize: cellSize,
      highlighted: highlighted, active: active, showsClueText: false
    )
    .accessibilityHidden(true)
  }
}

/// Izgaranın piksel geometrisi; çizim katmanı kutu konumlarını buradan hesaplar.
public struct GridGeometry: Equatable, Sendable {
  /// Etkileşimli ızgarada temadan bağımsız sabit boşluk (çizimler temalar arasında kaymaz).
  public static let fixedGap: CGFloat = 3
  /// Etkileşimli ızgarada sabit dış çerçeve.
  public static let fixedBorder: CGFloat = 2

  /// Kutu boyu.
  public let cell: CGFloat
  /// Kutular arası boşluk.
  public let gap: CGFloat
  /// Dış çerçeve.
  public let border: CGFloat

  /// Geometriyi oluşturur.
  public init(cell: CGFloat, gap: CGFloat = fixedGap, border: CGFloat = fixedBorder) {
    self.cell = cell
    self.gap = gap
    self.border = border
  }

  /// Tüm ölçüleri verilen oranla büyütülmüş geometri.
  public func scaled(by factor: CGFloat) -> GridGeometry {
    GridGeometry(cell: cell * factor, gap: gap * factor, border: border * factor)
  }

  /// Kutunun çerçevesi.
  public func rect(for point: GridPoint) -> CGRect {
    CGRect(
      x: border + CGFloat(point.col) * (cell + gap),
      y: border + CGFloat(point.row) * (cell + gap),
      width: cell, height: cell)
  }

  /// Noktanın düştüğü kutu (boşluklar en yakın kutuya yuvarlanır).
  public func point(at location: CGPoint, rows: Int, columns: Int) -> GridPoint? {
    let col = Int(((location.x - border) / (cell + gap)).rounded(.down))
    let row = Int(((location.y - border) / (cell + gap)).rounded(.down))
    guard (0..<rows).contains(row), (0..<columns).contains(col) else { return nil }
    return GridPoint(row: row, col: col)
  }

  /// Tüm ızgaranın boyutu.
  public func size(rows: Int, columns: Int) -> CGSize {
    CGSize(
      width: border * 2 + CGFloat(columns) * cell + CGFloat(columns - 1) * gap,
      height: border * 2 + CGFloat(rows) * cell + CGFloat(rows - 1) * gap)
  }
}
