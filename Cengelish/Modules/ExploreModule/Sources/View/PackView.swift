import ContentKit
import DesignKit
import SwiftUI

/// Paket detayı: ilerleme ve bulmaca kareleri.
struct PackView: View {
  @StateObject var viewModel: PackViewModel

  var body: some View {
    VStack(spacing: 0) {
      NavHeader("", onLeading: viewModel.back) {
        if viewModel.tiles.contains(where: { $0.state == .locked }) {
          Pill("Premium", systemImage: "crown.fill", tone: .gold)
        }
      }
      if let pack = viewModel.pack {
        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
              Eyebrow(pack.kind == .exam ? "Sınav paketi" : "Seviye paketi")
              Text(pack.title).font(AppFont.title).foregroundStyle(Palette.ink)
              Text("\(pack.puzzleIds.count) bulmaca · \(pack.wordCount) kelime · \(pack.subtitle)")
                .font(AppFont.caption).foregroundStyle(Palette.muted)
              HStack {
                Text("\(viewModel.solved) / \(pack.puzzleIds.count) tamamlandı").font(
                  AppFont.caption)
                Spacer()
                Text(
                  "%\(Int(Double(viewModel.solved) / Double(max(pack.puzzleIds.count, 1)) * 100))"
                )
                .font(AppFont.caption).foregroundStyle(Palette.muted)
              }
              .padding(.top, 6)
              ProgressBar(value: Double(viewModel.solved) / Double(max(pack.puzzleIds.count, 1)))
            }
            LazyVGrid(
              columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10
            ) {
              ForEach(viewModel.tiles) { tile in
                Button {
                  viewModel.open(tile)
                } label: {
                  TileView(tile: tile)
                }
                .buttonStyle(.plain)
              }
            }
          }
          .padding(.horizontal, Metrics.gutter)
          .frame(maxWidth: 640)
          .frame(maxWidth: .infinity)
        }
        if let current = viewModel.currentTile {
          Button(current.state == .locked ? "Kilidi aç" : "Bulmaca \(current.number)'i çöz") {
            viewModel.open(current)
          }
          .buttonStyle(.chunky)
          .padding(.horizontal, Metrics.gutter)
          .padding(.bottom, 10)
          .frame(maxWidth: 640)
        }
      } else {
        ProgressView().frame(maxHeight: .infinity)
      }
    }
    .screenBackground()
    .task { await viewModel.load() }
  }
}

/// Bulmaca karesi.
private struct TileView: View {
  let tile: PuzzleTile

  var body: some View {
    VStack(spacing: 2) {
      Text("\(tile.number)").font(AppFont.headline)
      switch tile.state {
      case .done(let stars):
        HStack(spacing: 0) {
          ForEach(0..<3, id: \.self) { index in
            Image(systemName: "star.fill").font(.system(size: 8))
              .foregroundStyle(index < stars ? Palette.gold : Palette.lineStrong)
          }
        }
      case .current:
        Text("Sıradaki").font(.system(size: 9, weight: .heavy, design: .rounded))
          .lineLimit(1).minimumScaleFactor(0.7)
      case .open:
        EmptyView()
      case .locked:
        Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
      }
    }
    .foregroundStyle(foreground)
    .frame(maxWidth: .infinity, minHeight: 64)
    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(background))
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(tile.state == .current ? Palette.accent : .clear, lineWidth: 2)
    )
    .accessibilityLabel(label)
  }

  private var background: Color {
    switch tile.state {
    case .done: Palette.goodBackground
    case .current: Palette.selection
    case .open: Palette.surface
    case .locked: Palette.surface2
    }
  }

  private var foreground: Color {
    switch tile.state {
    case .done: Palette.good
    case .current: Palette.accent
    case .open: Palette.ink
    case .locked: Palette.muted
    }
  }

  private var label: String {
    switch tile.state {
    case .done(let stars): "Bulmaca \(tile.number), bitti, \(stars) yıldız"
    case .current: "Bulmaca \(tile.number), sıradaki"
    case .open: "Bulmaca \(tile.number)"
    case .locked: "Bulmaca \(tile.number), kilitli"
    }
  }
}
