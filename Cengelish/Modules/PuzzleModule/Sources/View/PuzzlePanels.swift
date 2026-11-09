import ContentKit
import DesignKit
import PuzzleKit
import SwiftUI

// MARK: - Clue panel (iPad)

/// iPad yan panelinin sekmesi.
enum CluePanelTab: String, CaseIterable, Identifiable {
  case clues = "İpuçları"
  case words = "Kelimeler"

  var id: String { rawValue }
}

/// iPad'de ızgaranın yanındaki panel: ipuçları / kelime desenleri, ✓ ve kurşun kalem ipucu.
struct CluePanel: View {
  let layout: CrosswordLayout
  let selected: PuzzleEntry?
  let revealed: Set<GridPoint>
  let isDone: (PuzzleEntry) -> Bool
  let onSelect: (PuzzleEntry) -> Void
  @State private var tab: CluePanelTab = .clues

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Picker("Liste", selection: $tab) {
        ForEach(CluePanelTab.allCases) { Text($0.rawValue).tag($0) }
      }
      .pickerStyle(.segmented)
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          section("Soldan sağa →", .across)
          section("Yukarıdan aşağı ↓", .down)
        }
      }
      tipCard
    }
    .padding(18)
    .background(
      RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous).fill(Palette.surface)
        .shadow(color: Palette.cardShadow, radius: 0, y: 2)
    )
  }

  private func section(_ title: String, _ dir: Direction) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Eyebrow(title).padding(.bottom, 4)
      ForEach(layout.puzzle.entries.filter { $0.dir == dir }) { entry in
        row(entry)
      }
    }
  }

  private func row(_ entry: PuzzleEntry) -> some View {
    let done = isDone(entry)
    return Button {
      onSelect(entry)
    } label: {
      HStack(spacing: 8) {
        VStack(alignment: .leading, spacing: 2) {
          if tab == .clues {
            Text(entry.clue).font(AppFont.bodyBold)
          } else {
            Text(EntryNavigation.pattern(entry, revealed: revealed))
              .font(AppFont.bodyBold.monospaced())
            Text(entry.clue).font(AppFont.tiny).foregroundStyle(Palette.muted)
          }
        }
        .strikethrough(done)
        .opacity(done ? 0.5 : 1)
        Spacer(minLength: 6)
        Text("\(entry.answer.count) harf").font(AppFont.caption).foregroundStyle(Palette.muted)
        if done {
          Image(systemName: "checkmark").font(.system(size: 13, weight: .black))
            .foregroundStyle(Palette.good)
        }
      }
      .foregroundStyle(Palette.ink)
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(selected == entry ? PuzzleColors.highlight : .clear)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(
      "\(entry.clue), \(entry.answer.count) harf, \(entry.dir.title)\(done ? ", tamam" : "")"
    )
    .accessibilityAddTraits(selected == entry ? .isSelected : [])
  }

  private var tipCard: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("İpucu").font(AppFont.caption.weight(.heavy)).foregroundStyle(Palette.ink)
      Text("Emin olmadığın harfi kurşun kalemle yaz. Emin olunca tükenmezle üstüne geç.")
        .font(AppFont.caption).foregroundStyle(Palette.muted)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .padding(.leading, 4)
    .background(Palette.surface2)
    .overlay(alignment: .leading) { Rectangle().fill(Palette.accent).frame(width: 4) }
    .clipShape(RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous))
  }
}

/// Modül içi ortak renkler.
enum PuzzleColors {
  /// Seçili satır / etkin kutu vurgusu (tasarımdaki `--hl`).
  static let highlight = Palette.dynamic(0xFFF0C0, 0x3B3217)
}

// MARK: - Zoom overlay

/// Yakınlaştırınca çıkan göstergeler: tek seferlik ipucu, yüzde ve mini harita.
struct ZoomOverlay: View {
  @ObservedObject var zoom: ZoomState
  let puzzle: Puzzle
  let theme: PuzzleTheme
  let highlighted: Set<GridPoint>

  var body: some View {
    ZStack {
      if zoom.showsTip {
        toast(Label("İki parmakla gezin · tek parmakla yaz", systemImage: "hand.draw"))
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
          .transition(.opacity.combined(with: .move(edge: .top)))
      }
      if zoom.isZoomed {
        toast(Label(zoom.percentText, systemImage: "plus.magnifyingglass"))
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
          .accessibilityLabel("Yakınlaştırma \(zoom.percentText)")
        Minimap(zoom: zoom, puzzle: puzzle, theme: theme, highlighted: highlighted)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
      }
    }
    .padding(10)
    .animation(.easeOut(duration: 0.2), value: zoom.isZoomed)
    .animation(.easeOut(duration: 0.25), value: zoom.showsTip)
    .allowsHitTesting(false)
  }

  private func toast(_ label: some View) -> some View {
    label
      .font(.system(size: 12.5, weight: .heavy, design: .rounded))
      .foregroundStyle(Palette.background)
      .padding(.horizontal, 14)
      .padding(.vertical, 9)
      .background(Capsule().fill(Palette.ink))
      .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
  }
}

/// Mini harita: küçük ızgara ve görünen alanın çerçevesi.
///
/// Izgara görünen alanı izlemez; kaydırırken sadece çerçeve yeniden çizilir.
private struct Minimap: View {
  let zoom: ZoomState
  let puzzle: Puzzle
  let theme: PuzzleTheme
  let highlighted: Set<GridPoint>

  var body: some View {
    MiniGridView(puzzle: puzzle, theme: theme, cellSize: 10, highlighted: highlighted)
      .overlay { ViewportFrame(zoom: zoom) }
      .padding(5)
      .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Palette.surface))
      .shadow(color: .black.opacity(0.3), radius: 8, y: 6)
      .accessibilityHidden(true)
  }
}

/// Mini haritada görünen alanın çerçevesi.
private struct ViewportFrame: View {
  @ObservedObject var zoom: ZoomState

  var body: some View {
    GeometryReader { proxy in
      let rect = zoom.visible
      RoundedRectangle(cornerRadius: 3)
        .strokeBorder(Palette.accent, lineWidth: 2)
        .frame(width: rect.width * proxy.size.width, height: rect.height * proxy.size.height)
        .offset(x: rect.minX * proxy.size.width, y: rect.minY * proxy.size.height)
    }
  }
}
