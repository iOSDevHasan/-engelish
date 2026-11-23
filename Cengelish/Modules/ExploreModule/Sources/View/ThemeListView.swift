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
        VStack(spacing: 12) {
          if viewModel.showsPlusPromo {
            PlusPromoCard(
              title: "Tüm temaları aç",
              subtitle: "Bütün tema paketleri \(PlusBrand.name)'ta.",
              action: viewModel.openPaywall
            )
            .appearAnimation(index: 0)
          }
          ForEach(Array(viewModel.themes.enumerated()), id: \.element.id) { index, card in
            Button {
              viewModel.open(card)
            } label: {
              ThemeRow(card: card, tint: Palette.pastels[index % Palette.pastels.count])
            }
            .buttonStyle(PressScaleButtonStyle())
            .appearAnimation(index: index + 1)
          }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 6)
        .padding(.bottom, 24)
        .frame(maxWidth: 680)
        .frame(maxWidth: .infinity)
      }
      .scrollIndicators(.hidden)
    }
    .screenBackground()
  }
}

/// Tema listesindeki satır: pastel simge karesi, başlık, açıklama, ilerleme; Plus gerekiyorsa
/// köşede Plus rozeti.
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
        HStack(spacing: 6) {
          Text(card.pack.title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
            .lineLimit(1).minimumScaleFactor(0.8)
          if card.pack.isFullyFree {
            Pill("Ücretsiz", tone: .good)
          }
        }
        .padding(.trailing, card.isLocked ? 44 : 0)
        if !card.pack.subtitle.isEmpty {
          Text(card.pack.subtitle).font(AppFont.caption).foregroundStyle(Palette.muted)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
        }
        HStack(spacing: 8) {
          FillingProgressBar(value: card.progress, height: 5)
          Text("\(card.solved)/\(card.puzzleCount)").font(AppFont.tiny)
            .foregroundStyle(Palette.muted)
            .lineLimit(1).fixedSize()
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
        .foregroundStyle(Palette.lineStrong)
    }
    .card(padding: 14)
    .plusCorner(card.isLocked)
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
    .accessibilityHint(card.isLocked ? "\(PlusBrand.name) gerekli" : "")
  }
}
