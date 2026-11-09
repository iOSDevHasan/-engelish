import ContentKit
import DesignKit
import PuzzleKit
import SwiftUI

/// Cevap anahtarı ve kendi kendine işaretleme ekranı.
struct AnswerKeyView: View {
  @StateObject var viewModel: AnswerKeyViewModel
  let theme: (ColorScheme) -> PuzzleTheme
  @Environment(\.colorScheme) private var scheme
  @Environment(\.displayScale) private var displayScale

  var body: some View {
    VStack(spacing: 0) {
      NavHeader("Cevap Anahtarı", onLeading: viewModel.back)
      ScrollView {
        VStack(spacing: 14) {
          Picker("Görünüm", selection: $viewModel.mode) {
            ForEach(KeyMode.allCases) { Text($0.rawValue).tag($0) }
          }
          .pickerStyle(.segmented)
          grid
          HStack {
            Text("Kendini kontrol et").font(AppFont.section).foregroundStyle(Palette.ink)
            Spacer()
            Text("\(viewModel.markedCount)/\(viewModel.session.puzzle.entries.count) işaretli")
              .font(AppFont.caption).foregroundStyle(Palette.muted)
          }
          VStack(spacing: 8) {
            ForEach(viewModel.session.puzzle.entries) { entry in
              MarkRow(
                entry: entry, mark: viewModel.marks[entry.id],
                onMark: { viewModel.mark(entry, correct: $0) })
            }
          }
          Text("Doğru yazdıklarına ✓, yanlışlara ✗ koy. Yanlışlar Kelime Defterine eklenir.")
            .font(AppFont.tiny).foregroundStyle(Palette.muted)
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 16)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
      }
      Button("Sonuçları kaydet", action: viewModel.finish)
        .buttonStyle(.chunky)
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 10)
        .frame(maxWidth: 640)
    }
    .screenBackground()
  }

  private var grid: some View {
    GeometryReader { proxy in
      let layout = viewModel.session.layout
      let base = CanvasMetrics.grid.size(rows: layout.rows, columns: layout.columns)
      let scale = min(proxy.size.width / base.width, 1.2)
      ZStack(alignment: .topLeading) {
        PuzzleGridView(
          layout: layout, theme: theme(scheme), cellSize: CanvasMetrics.gridCell * scale,
          letters: viewModel.letters, geometry: CanvasMetrics.grid.scaled(by: scale))
        if viewModel.showsDrawing {
          Image(uiImage: viewModel.drawingImage(scale: displayScale))
            .resizable()
            .frame(width: base.width * scale, height: base.height * scale)
            .allowsHitTesting(false)
        }
      }
      .frame(width: proxy.size.width, alignment: .center)
    }
    .aspectRatio(aspect, contentMode: .fit)
    .accessibilityLabel("Cevap anahtarı ızgarası")
  }

  private var aspect: CGFloat {
    let layout = viewModel.session.layout
    let size = CanvasMetrics.grid.size(rows: layout.rows, columns: layout.columns)
    return size.width / size.height
  }
}

/// Kelime satırı: ipucu, doğru cevap ve ✓ / ✗ butonları.
private struct MarkRow: View {
  let entry: PuzzleEntry
  let mark: Bool?
  let onMark: (Bool) -> Void

  var body: some View {
    HStack(spacing: 10) {
      VStack(alignment: .leading, spacing: 2) {
        Text(entry.answer).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
        Text("\(entry.dir == .across ? "→" : "↓") \(entry.clue)").font(AppFont.caption)
          .foregroundStyle(Palette.muted)
      }
      Spacer()
      markButton(correct: true)
      markButton(correct: false)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(
          mark == true
            ? Palette.goodBackground : mark == false ? Palette.badBackground : Palette.surface))
  }

  private func markButton(correct: Bool) -> some View {
    let isOn = mark == correct
    let tint = correct ? Palette.good : Palette.bad
    return Button {
      onMark(correct)
    } label: {
      Image(systemName: correct ? "checkmark" : "xmark")
        .font(.system(size: 15, weight: .black))
        .foregroundStyle(isOn ? .white : tint)
        .frame(width: 40, height: 40)
        .background(Circle().fill(isOn ? tint : tint.opacity(0.12)))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(correct ? "\(entry.answer) doğru" : "\(entry.answer) yanlış")
    .accessibilityAddTraits(isOn ? .isSelected : [])
  }
}
