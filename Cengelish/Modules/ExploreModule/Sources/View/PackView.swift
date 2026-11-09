import ContentKit
import DesignKit
import SwiftUI

/// Paket detayı: ilerleme ve bulmaca kareleri.
struct PackView: View {
  @StateObject var viewModel: PackViewModel

  var body: some View {
    VStack(spacing: 0) {
      NavHeader("", onLeading: viewModel.back) {
        if viewModel.hasLockedTiles {
          Pill("Premium", systemImage: "crown.fill", tone: .gold)
        }
      }
      if let pack = viewModel.pack {
        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
              Eyebrow(PackRules.eyebrow(for: pack.kind))
              Text(pack.title).font(AppFont.title).foregroundStyle(Palette.ink)
              Text(viewModel.summary)
                .font(AppFont.caption).foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
              HStack {
                Text("\(viewModel.solved) / \(pack.puzzleIds.count) tamamlandı")
                  .font(AppFont.caption).foregroundStyle(Palette.ink)
                Spacer()
                Text("%\(Int((viewModel.progress * 100).rounded()))")
                  .font(AppFont.caption).foregroundStyle(Palette.muted)
              }
              .padding(.top, 6)
              ProgressBar(value: viewModel.progress)
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
        if let current = viewModel.currentTile, let title = viewModel.primaryTitle {
          Button(title) {
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

/// Bulmaca karesi: bitti (yıldızlar), sıradaki, açık ya da kilitli.
private struct TileView: View {
  let tile: PuzzleTile

  var body: some View {
    VStack(spacing: 2) {
      Text("\(tile.number)").font(AppFont.rounded(18, weight: .black))
      switch tile.state {
      case .done(let stars):
        HStack(spacing: 1) {
          ForEach(0..<3, id: \.self) { index in
            Image(systemName: "star.fill").font(.system(size: 8, weight: .bold))
              .foregroundStyle(Palette.streak.opacity(index < stars ? 1 : 0.25))
          }
        }
      case .current:
        Text("Sıradaki").font(.system(size: 9, weight: .black, design: .rounded))
          .lineLimit(1).minimumScaleFactor(0.7)
      case .open:
        EmptyView()
      case .locked:
        Image(systemName: "lock.fill").font(.system(size: 11, weight: .bold))
      }
    }
    .foregroundStyle(tile.state == .current ? Color.white : Palette.ink)
    .frame(maxWidth: .infinity)
    .aspectRatio(1, contentMode: .fit)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(background)
        .shadow(color: tile.state == .current ? Palette.buttonShadow : .clear, radius: 0, y: 4)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(border, lineWidth: 1.5)
    )
    .opacity(tile.state == .locked ? 0.5 : 1)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(label)
  }

  private var background: Color {
    switch tile.state {
    case .done: Palette.selection
    case .current: Palette.buttonFill
    case .open, .locked: Palette.surface
    }
  }

  private var border: Color {
    switch tile.state {
    case .done: .clear
    case .current: Palette.buttonFill
    case .open, .locked: Palette.line
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
