import ContentKit
import DesignKit
import SwiftUI

/// Tüm tema paketleri listesi ("Tümü ›").
struct ThemeListView: View {
  @ObservedObject var viewModel: ExploreViewModel

  var body: some View {
    VStack(spacing: 0) {
      NavHeader("Tema paketleri", onLeading: viewModel.back)
      ScrollView {
        VStack(spacing: 10) {
          ForEach(Array(viewModel.themes.enumerated()), id: \.element.id) { index, card in
            Button {
              viewModel.open(card)
            } label: {
              ThemeRow(card: card, tint: Palette.pastels[index % Palette.pastels.count])
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 6)
        .padding(.bottom, 24)
        .frame(maxWidth: 680)
        .frame(maxWidth: .infinity)
      }
    }
    .screenBackground()
  }
}

/// Tema listesindeki satır: pastel simge karesi, başlık, açıklama, durum.
private struct ThemeRow: View {
  let card: PackCard
  let tint: Color

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: card.symbol)
        .font(.system(size: 22, weight: .bold))
        .foregroundStyle(Palette.ink.opacity(0.8))
        .frame(width: 52, height: 52)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(tint))
      VStack(alignment: .leading, spacing: 4) {
        Text(card.pack.title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
        if !card.pack.subtitle.isEmpty {
          Text(card.pack.subtitle).font(AppFont.caption).foregroundStyle(Palette.muted)
            .lineLimit(2)
        }
        HStack(spacing: 8) {
          ProgressBar(value: card.progress, height: 5)
          Text("\(card.solved)/\(card.puzzleCount)").font(AppFont.tiny)
            .foregroundStyle(Palette.muted)
        }
      }
      if card.pack.isFullyFree {
        Pill("Ücretsiz", tone: .good)
      } else if card.isLocked {
        Pill("Premium", systemImage: "lock.fill", tone: .gold)
      }
      Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
        .foregroundStyle(Palette.lineStrong)
    }
    .card(padding: 14)
    .contentShape(Rectangle())
  }
}
