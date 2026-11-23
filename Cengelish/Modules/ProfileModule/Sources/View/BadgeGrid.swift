import DesignKit
import SwiftUI

/// Rozet madalyası ızgarası; dokunulan rozetin üstünde (yer yoksa altında) ipucu balonu açılır.
///
/// Balon ızgaranın dışına taşar. SwiftUI taşan kısma dokunuş iletmediği için balon ızgarada
/// değil, ızgarayı içeren kaydırma içeriğinin üstünde (`badgeTooltipHost()`) çizilir; ızgara
/// yalnızca seçili rozetin yerini ve balonun eylemlerini `BadgeTooltipKey` ile bildirir.
struct BadgeGrid: View {
  let items: [BadgeItem]
  /// Kaydırma görünümünün koordinat alanı adı (balonun yönünü seçmek için).
  let space: String
  var columns = 3
  var medalSize: CGFloat = 84
  /// Kazanılma tarihi metni.
  var dateText: (BadgeItem) -> String = { _ in "" }

  @State private var selected: BadgeItem.ID?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack(spacing: 20) {
      ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
        HStack(alignment: .top, spacing: 8) {
          ForEach(0..<columns, id: \.self) { column in
            if column < row.count {
              cell(row[column], column: column)
                .frame(maxWidth: .infinity)
                .appearAnimation(index: rowIndex * columns + column)
            } else {
              Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
            }
          }
        }
      }
    }
    .contentShape(Rectangle())
    .onTapGesture { select(nil) }
  }

  // MARK: - Cells

  /// Dokunulabilir rozet; seçiliyse balonun yerini bildirir.
  private func cell(_ item: BadgeItem, column: Int) -> some View {
    let isSelected = selected == item.id
    // Kenar sütunlar balonu dış kenara yaslar, ekrandan taşmaz.
    let edge: HorizontalAlignment =
      column == 0 ? .leading : column == columns - 1 ? .trailing : .center
    return Button {
      select(isSelected ? nil : item.id)
    } label: {
      BadgeMedalCell(item: item, isSelected: isSelected, size: medalSize)
    }
    .buttonStyle(PressScaleButtonStyle())
    .background {
      if isSelected {
        GeometryReader { proxy in
          let upward = proxy.frame(in: .named(space)).minY > Self.tooltipClearance
          Color.clear.anchorPreference(key: BadgeTooltipKey.self, value: .bounds) { anchor in
            BadgeTooltipRequest(
              item: item, anchor: anchor, edge: edge, upward: upward,
              dateText: dateText(item), onClose: { select(nil) })
          }
        }
      }
    }
  }

  // MARK: - Selection

  /// Bir seferde tek balon açar; `nil` kapatır.
  private func select(_ id: BadgeItem.ID?) {
    withAnimation(reduceMotion ? nil : Motion.snappy) { selected = id }
  }

  /// `columns` genişliğinde satırlar.
  private var rows: [[BadgeItem]] {
    stride(from: 0, to: items.count, by: columns).map {
      Array(items[$0..<min($0 + columns, items.count)])
    }
  }

  /// Balonun yukarı açılması için kaydırma alanında gereken boşluk.
  private static let tooltipClearance: CGFloat = 290
}

// MARK: - Tooltip host

/// Seçili rozetin balonu için gereken her şey: rozetin yeri, yönü ve kapatma eylemi.
struct BadgeTooltipRequest {
  let item: BadgeItem
  /// Rozet hücresinin çerçevesi.
  let anchor: Anchor<CGRect>
  /// Balonun rozete göre yaslanacağı kenar.
  let edge: HorizontalAlignment
  /// Balon rozetin üstünde mi açılır.
  let upward: Bool
  let dateText: String
  let onClose: () -> Void
}

/// Izgaradan balonu çizen kaba seçili rozeti iletir.
struct BadgeTooltipKey: PreferenceKey {
  static var defaultValue: BadgeTooltipRequest? { nil }

  static func reduce(value: inout BadgeTooltipRequest?, nextValue: () -> BadgeTooltipRequest?) {
    value = value ?? nextValue()
  }
}

extension View {
  /// İçindeki `BadgeGrid`'in balonunu bu görünümün üstünde çizer. Balonun tamamı bu görünümün
  /// sınırları içinde kalacak kadar dış bir kaba (kaydırma içeriğine) uygulanır.
  func badgeTooltipHost() -> some View {
    overlayPreferenceValue(BadgeTooltipKey.self) { request in
      GeometryReader { proxy in
        if let request {
          BadgeTooltipBubble(request: request, cell: proxy[request.anchor])
        }
      }
    }
  }
}

/// Rozet hücresinin üstüne (ya da altına) yerleşen ok ve balon.
private struct BadgeTooltipBubble: View {
  let request: BadgeTooltipRequest
  /// Rozet hücresinin kap içindeki çerçevesi.
  let cell: CGRect
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    // Hizalama kapanışları ana aktör dışında çalışır; kullandıkları değerler önceden alınır.
    let cell = cell
    let upward = request.upward
    let edge = request.edge
    let arrow = Self.arrowSize
    let arrowGap = Self.arrowGap
    let bubbleGap = Self.bubbleGap
    return ZStack(alignment: .topLeading) {
      Color.clear
      BadgeTooltipArrow()
        .fill(BadgeTooltip.bubble)
        .frame(width: arrow.width, height: arrow.height)
        .rotationEffect(.degrees(upward ? 0 : 180))
        .alignmentGuide(.leading) { _ in -(cell.midX - arrow.width / 2) }
        .alignmentGuide(.top) { _ in
          upward ? -(cell.minY - arrowGap - arrow.height) : -(cell.maxY + arrowGap)
        }
      BadgeTooltip(item: request.item, dateText: request.dateText)
        .onTapGesture(perform: request.onClose)
        .alignmentGuide(.leading) { size in
          Self.leadingGuide(width: size.width, edge: edge, cell: cell)
        }
        .alignmentGuide(.top) { size in
          upward ? size.height - cell.minY + bubbleGap : -(cell.maxY + bubbleGap)
        }
    }
    .transition(
      reduceMotion
        ? .opacity
        : .scale(scale: 0.88, anchor: upward ? .bottom : .top).combined(with: .opacity))
  }

  /// Balonu kenar sütunlarda rozetin dış kenarına, ortada rozetin ortasına yaslar.
  nonisolated private static func leadingGuide(
    width: CGFloat, edge: HorizontalAlignment, cell: CGRect
  ) -> CGFloat {
    switch edge {
    case .leading: -cell.minX
    case .trailing: width - cell.maxX
    default: width / 2 - cell.midX
    }
  }

  /// Okun boyutu.
  nonisolated private static let arrowSize = CGSize(width: 18, height: 9)
  /// Okun rozet kenarına uzaklığı.
  nonisolated private static let arrowGap: CGFloat = 2
  /// Balonun rozet kenarına uzaklığı.
  nonisolated private static let bubbleGap: CGFloat = 10
}
