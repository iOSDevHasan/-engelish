import ContentKit
import DesignKit
import SwiftUI

/// Keşfet sekmesi: seviyeler, sınav paketleri, tema paketleri.
struct ExploreView: View {
  @StateObject var viewModel: ExploreViewModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        header
        Picker("Bölüm", selection: $viewModel.segment.animation(Motion.snappy)) {
          ForEach(ExploreSegment.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        if viewModel.showsLevels { levels.transition(sectionTransition) }
        if viewModel.segment == .all && viewModel.showsPlusPromo {
          plusPromo.transition(sectionTransition)
        }
        if viewModel.showsExams { exams.transition(sectionTransition) }
        if viewModel.showsThemes { themes.transition(sectionTransition) }
      }
      .padding(.horizontal, Metrics.gutter)
      .padding(.bottom, 24)
      .frame(maxWidth: 760)
      .frame(maxWidth: .infinity)
    }
    .scrollIndicators(.hidden)
    .statusBarScrim()
    .screenBackground()
    .task { await viewModel.load() }
  }

  /// Bölüm değişince içeri kayarak gelen, sönerek çıkan geçiş.
  private var sectionTransition: AnyTransition {
    .asymmetric(
      insertion: .opacity.combined(with: .offset(y: 16)), removal: .opacity)
  }

  // MARK: - Sections

  /// Başlık ve arama butonu.
  private var header: some View {
    HStack {
      Text("Keşfet").font(AppFont.title).foregroundStyle(Palette.ink)
        .lineLimit(1).minimumScaleFactor(0.8)
      Spacer()
      Button(action: viewModel.openSearch) { IconCircle("magnifyingglass") }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("Ara")
    }
    .padding(.top, 8)
  }

  /// Seviye kartları: "Tümü"de yatay kayan şerit, "Seviyeler" bölümünde ızgara.
  private var levels: some View {
    VStack(alignment: .leading, spacing: 10) {
      SectionHeader("Seviyeler") {
        if let level = viewModel.profileLevel {
          Text("Sen: \(level)").font(AppFont.caption).foregroundStyle(Palette.muted)
            .lineLimit(1)
        }
      }
      if viewModel.showsLevelCarousel {
        levelCarousel
      } else {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 22) {
          ForEach(Array(viewModel.levels.enumerated()), id: \.element.id) { index, card in
            levelButton(card, index: index)
          }
        }
        .padding(.top, 10)
      }
    }
  }

  /// Kenardan kenara kayan seviye şeridi; açılışta kullanıcının seviyesine kayar.
  private var levelCarousel: some View {
    ScrollViewReader { proxy in
      ScrollView(.horizontal) {
        HStack(spacing: 12) {
          ForEach(Array(viewModel.levels.enumerated()), id: \.element.id) { index, card in
            levelButton(card, index: index)
              .frame(width: Self.levelCardWidth)
              .id(card.id)
          }
        }
        .fixedSize(horizontal: false, vertical: true)
        .scrollTargetLayout()
        // Üst kenardan sarkan "Senin seviyen" etiketi ve alt gölge kırpılmasın.
        .padding(.top, 12)
        .padding(.bottom, 6)
      }
      .scrollTargetBehavior(.viewAligned)
      .scrollIndicators(.hidden)
      .contentMargins(.horizontal, Metrics.gutter, for: .scrollContent)
      .padding(.horizontal, -Metrics.gutter)
      .onAppear {
        if let id = viewModel.currentLevelId { proxy.scrollTo(id, anchor: .center) }
      }
    }
  }

  /// Seviye kartının genişliği (küçük iPhone'da iki kart ve bir sonrakinin ucu görünür).
  private static let levelCardWidth: CGFloat = 160

  /// Paketi açan seviye kartı.
  private func levelButton(_ card: PackCard, index: Int) -> some View {
    Button {
      viewModel.open(card)
    } label: {
      LevelCardView(card: card, isCurrent: viewModel.isCurrentLevel(card))
    }
    .buttonStyle(PressScaleButtonStyle())
    .appearAnimation(index: index)
  }

  /// Plus yoksa Keşfet'teki tanıtım kartı.
  private var plusPromo: some View {
    PlusPromoCard(
      title: "Sınav ve tema paketlerini aç",
      subtitle: "Seviyeler herkese açık; sınav ve tema paketlerinin hepsi \(PlusBrand.name)'ta.",
      action: viewModel.openPaywall
    )
    .appearAnimation(index: 2)
  }

  /// Sınav paketi kartları.
  private var exams: some View {
    VStack(alignment: .leading, spacing: 10) {
      SectionHeader("Sınav paketleri") {
        if viewModel.showsPlusPromo {
          Button(action: viewModel.openPaywall) { PlusBadge() }
            .buttonStyle(PressScaleButtonStyle())
            .accessibilityLabel("\(PlusBrand.name)'ı incele")
        }
      }
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 148), spacing: 10)], spacing: 10) {
        ForEach(Array(viewModel.exams.enumerated()), id: \.element.id) { index, card in
          Button {
            viewModel.open(card)
          } label: {
            ExamCardView(card: card)
          }
          .buttonStyle(PressScaleButtonStyle())
          .appearAnimation(index: index)
        }
      }
    }
  }

  /// Tema paketi kareleri.
  private var themes: some View {
    VStack(alignment: .leading, spacing: 10) {
      SectionHeader("Tema paketleri") {
        Button(action: viewModel.openAllThemes) {
          Text("Tümü ›").font(AppFont.caption).foregroundStyle(Palette.accent)
            .lineLimit(1)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleButtonStyle())
      }
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
        ForEach(Array(viewModel.visibleThemes.enumerated()), id: \.element.id) { index, card in
          Button {
            viewModel.open(card)
          } label: {
            ThemeTileView(card: card, tint: Palette.pastels[index % Palette.pastels.count])
          }
          .buttonStyle(PressScaleButtonStyle())
          .appearAnimation(index: index)
        }
      }
    }
  }
}
