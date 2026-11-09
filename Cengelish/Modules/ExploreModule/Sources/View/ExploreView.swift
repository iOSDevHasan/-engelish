import ContentKit
import DesignKit
import SwiftUI

/// Keşfet sekmesi: seviyeler, sınav paketleri, tema paketleri.
struct ExploreView: View {
  @StateObject var viewModel: ExploreViewModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header
        Picker("Bölüm", selection: $viewModel.segment) {
          ForEach(ExploreSegment.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        if viewModel.showsLevels { levels }
        if viewModel.showsExams { exams }
        if viewModel.showsThemes { themes }
      }
      .padding(.horizontal, Metrics.gutter)
      .padding(.bottom, 24)
      .frame(maxWidth: 760)
      .frame(maxWidth: .infinity)
      .animation(.snappy, value: viewModel.segment)
    }
    .screenBackground()
    .task { await viewModel.load() }
  }

  // MARK: - Sections

  /// Başlık ve arama butonu.
  private var header: some View {
    HStack {
      Text("Keşfet").font(AppFont.title).foregroundStyle(Palette.ink)
      Spacer()
      Button(action: viewModel.openSearch) { IconCircle("magnifyingglass") }
        .buttonStyle(.plain)
        .accessibilityLabel("Ara")
    }
    .padding(.top, 8)
  }

  /// A1–C1 seviye kareleri.
  private var levels: some View {
    VStack(alignment: .leading, spacing: 10) {
      SectionHeader("Seviyeler") {
        if let level = viewModel.profileLevel {
          Text("Sen: \(level)").font(AppFont.caption).foregroundStyle(Palette.muted)
        }
      }
      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8
      ) {
        ForEach(viewModel.levels) { card in
          Button {
            viewModel.open(card)
          } label: {
            LevelTileView(card: card, isCurrent: viewModel.isCurrentLevel(card))
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  /// Sınav paketi kartları.
  private var exams: some View {
    VStack(alignment: .leading, spacing: 10) {
      SectionHeader("Sınav paketleri") {
        Pill("Premium", systemImage: "crown.fill", tone: .gold)
      }
      LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
        ForEach(viewModel.exams) { card in
          Button {
            viewModel.open(card)
          } label: {
            ExamCardView(card: card)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  /// Tema paketi kareleri.
  private var themes: some View {
    VStack(alignment: .leading, spacing: 10) {
      SectionHeader("Tema paketleri") {
        Button(action: viewModel.openAllThemes) {
          Text("Tümü ›").font(AppFont.caption).foregroundStyle(Palette.muted)
        }
        .buttonStyle(.plain)
      }
      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8
      ) {
        ForEach(Array(viewModel.visibleThemes.enumerated()), id: \.element.id) { index, card in
          Button {
            viewModel.open(card)
          } label: {
            ThemeTileView(card: card, tint: Palette.pastels[index % Palette.pastels.count])
          }
          .buttonStyle(.plain)
        }
      }
    }
  }
}
