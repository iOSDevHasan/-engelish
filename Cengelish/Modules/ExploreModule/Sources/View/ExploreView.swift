import ContentKit
import DesignKit
import SwiftUI

/// Keşfet sekmesi: seviyeler, sınav paketleri, tema paketleri.
struct ExploreView: View {
  @StateObject var viewModel: ExploreViewModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        Text("Keşfet").font(AppFont.title).foregroundStyle(Palette.ink).padding(.top, 8)
        section("Seviyeler")
        ForEach(Array(viewModel.levels.enumerated()), id: \.element.id) { index, card in
          Button {
            viewModel.open(card)
          } label: {
            LevelCard(card: card, tint: Palette.pastels[index % 6])
          }
          .buttonStyle(.plain)
        }
        section("Sınav paketleri")
        LazyVGrid(
          columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12
        ) {
          ForEach(viewModel.exams) { card in
            Button {
              viewModel.open(card)
            } label: {
              ExamCard(
                title: card.pack.title.replacingOccurrences(of: " Kelime Paketi", with: ""),
                detail: "\(card.pack.wordCount) kelime · \(card.pack.puzzleIds.count) bulmaca",
                level: card.pack.level.rawValue, isLocked: card.isLocked, index: 0)
            }
            .buttonStyle(.plain)
          }
          ForEach(Array(viewModel.upcomingExams.enumerated()), id: \.element.id) { index, item in
            ExamCard(
              title: item.title, detail: item.detail, level: "Yakında", isLocked: false,
              index: index + 1
            )
            .opacity(0.6)
          }
        }
        section("Tema paketleri")
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            ForEach(Array(viewModel.upcomingThemes.enumerated()), id: \.element.id) { index, item in
              VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(AppFont.headline)
                Text(item.detail).font(AppFont.caption).opacity(0.8)
                Spacer()
                Pill("Yakında")
              }
              .foregroundStyle(Palette.ink)
              .padding(14)
              .frame(width: 150, height: 130, alignment: .topLeading)
              .background(
                RoundedRectangle(cornerRadius: Metrics.radius).fill(
                  Palette.pastels[(index + 2) % 6]))
            }
          }
        }
      }
      .padding(.horizontal, Metrics.gutter)
      .padding(.bottom, 24)
      .frame(maxWidth: 760)
      .frame(maxWidth: .infinity)
    }
    .screenBackground()
    .task { await viewModel.load() }
  }

  private func section(_ title: String) -> some View {
    Text(title).font(AppFont.section).foregroundStyle(Palette.ink)
  }
}

/// Seviye paketi kartı.
private struct LevelCard: View {
  let card: PackCard
  let tint: Color

  var body: some View {
    HStack(spacing: 14) {
      Text(card.pack.level.rawValue)
        .font(AppFont.rounded(18, weight: .black))
        .foregroundStyle(.white)
        .frame(width: 52, height: 52)
        .background(RoundedRectangle(cornerRadius: 16).fill(Palette.accent))
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Text(card.pack.title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
          if card.isLocked { Pill("Çengelish+", systemImage: "crown.fill", tone: .gold) }
          if card.pack.freeCount > 0 && !card.pack.isFullyFree {
            Pill("\(card.pack.freeCount) ücretsiz", tone: .good)
          }
        }
        Text(card.pack.subtitle).font(AppFont.caption).foregroundStyle(Palette.muted)
        HStack(spacing: 8) {
          ProgressBar(value: card.progress, height: 6)
          Text("\(card.solved)/\(card.pack.puzzleIds.count)").font(AppFont.tiny)
            .foregroundStyle(Palette.muted)
        }
      }
      Image(systemName: "chevron.right").foregroundStyle(Palette.lineStrong)
    }
    .card(padding: 14)
  }
}

/// Sınav paketi kartı.
private struct ExamCard: View {
  let title: String
  let detail: String
  let level: String
  let isLocked: Bool
  let index: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(title).font(AppFont.title)
        Spacer()
        if isLocked { Image(systemName: "lock.fill").font(.system(size: 14, weight: .bold)) }
      }
      Text(detail).font(AppFont.caption).lineLimit(2)
      Spacer(minLength: 0)
      Text(level).font(AppFont.tiny.weight(.black))
        .padding(.horizontal, 8).frame(height: 22)
        .background(Capsule().fill(.white.opacity(0.25)))
    }
    .foregroundStyle(.white)
    .padding(14)
    .frame(height: 140, alignment: .topLeading)
    .frame(maxWidth: .infinity)
    .background(RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous).fill(gradient))
  }

  private var gradient: LinearGradient {
    let colors: [[UInt32]] = [
      [0x6C5CE7, 0x9B8CFF], [0xFF8A3D, 0xFFB36B], [0x1FB57A, 0x5ED6A5], [0x3C9BE0, 0x6EC1FF],
    ]
    let pair = colors[index % colors.count]
    return LinearGradient(
      colors: [Color(hex: pair[0]), Color(hex: pair[1])], startPoint: .topLeading,
      endPoint: .bottomTrailing)
  }
}
