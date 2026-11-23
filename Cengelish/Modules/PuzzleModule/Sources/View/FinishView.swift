import ContentKit
import DesignKit
import SwiftUI
import UserDataKit
import WordKit

/// Bitiş ekranı: kutlama (konfeti ve zıplayan yıldızlar), sonuçlar, rozetler ve kelimeler.
struct FinishView: View {
  @StateObject var viewModel: FinishViewModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  /// Kutlama animasyonu başladı mı.
  @State private var celebrates = false

  var body: some View {
    VStack(spacing: 0) {
      NavHeader("", leadingSymbol: "xmark", onLeading: viewModel.home) {
        Button(action: viewModel.share) { IconCircle("square.and.arrow.up") }
          .buttonStyle(.plain)
          .accessibilityLabel("Paylaş")
      }
      scroll
    }
    .safeAreaInset(edge: .bottom) { bottomBar }
    .overlay(alignment: .top) {
      if !reduceMotion {
        ConfettiView(isActive: celebrates).allowsHitTesting(false).ignoresSafeArea()
      }
    }
    .screenBackground()
    .sensoryFeedback(.success, trigger: celebrates)
    .onAppear { celebrates = true }
  }

  private var scroll: some View {
    ScrollView {
      VStack(spacing: 16) {
        hero
        stats.appearAnimation(index: 2)
        if !viewModel.result.newBadges.isEmpty { badges.appearAnimation(index: 3) }
        VStack(alignment: .leading, spacing: 0) {
          HStack {
            Text("Bu bulmacanın kelimeleri").font(AppFont.section).foregroundStyle(Palette.ink)
            Spacer()
            Text("\(viewModel.words.count) kelime").font(AppFont.caption).foregroundStyle(
              Palette.muted)
          }
          .padding(.bottom, 4)
          ForEach(viewModel.words) { word in
            WordRow(word: word, onSpeak: { viewModel.speak(word) }) {
              Button {
                viewModel.toggleNotebook(word)
              } label: {
                Pill(
                  viewModel.notebookIds.contains(word.id) ? "Defterde" : "Deftere ekle",
                  systemImage: viewModel.notebookIds.contains(word.id) ? "bookmark.fill" : "plus",
                  tone: viewModel.notebookIds.contains(word.id) ? .bad : .neutral)
              }
              .buttonStyle(.plain)
            }
            Divider().overlay(Palette.line)
          }
        }
        .card()
        .appearAnimation(index: 4)
      }
      .padding(.horizontal, Metrics.gutter)
      .padding(.bottom, 12)
      .frame(maxWidth: 640)
      .frame(maxWidth: .infinity)
    }
    .scrollIndicators(.hidden)
  }

  private var bottomBar: some View {
    HStack(spacing: 10) {
      Button(action: viewModel.share) {
        Label("Paylaş", systemImage: "square.and.arrow.up")
      }
      .buttonStyle(.chunkySecondary)
      Button(viewModel.hasNext ? "Sonraki bulmaca" : "Ana sayfaya dön", action: viewModel.next)
        .buttonStyle(.chunky)
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.vertical, 8)
    .frame(maxWidth: 640)
    .frame(maxWidth: .infinity)
    .background(Palette.background)
  }

  private var hero: some View {
    VStack(spacing: 8) {
      AvatarView(viewModel.avatar, size: 96)
        .scaleEffect(celebrates || reduceMotion ? 1 : 0.6)
        .animation(Motion.bouncy, value: celebrates)
      Text(viewModel.headline).font(AppFont.title).foregroundStyle(Palette.ink)
        .appearAnimation(index: 1)
      HStack(spacing: 4) {
        ForEach(0..<3, id: \.self) { index in
          let earned = index < viewModel.result.stars
          Image(systemName: earned ? "star.fill" : "star")
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(earned ? Palette.gold : Palette.lineStrong)
            .scaleEffect(starScale(earned: earned))
            .rotationEffect(.degrees(celebrates || reduceMotion || !earned ? 0 : -25))
            .animation(
              Motion.bouncy.delay(0.25 + Double(index) * 0.18), value: celebrates)
        }
      }
      .accessibilityLabel("\(viewModel.result.stars) yıldız")
      if let note = viewModel.starNote {
        Label(note, systemImage: "lightbulb")
          .font(AppFont.caption)
          .foregroundStyle(Palette.muted)
          .appearAnimation(index: 2)
      }
    }
    .padding(.top, 12)
  }

  /// Yıldızın ölçeği: kazanılan yıldızlar sırayla zıplayarak büyür.
  private func starScale(earned: Bool) -> CGFloat {
    guard earned, !reduceMotion else { return 1 }
    return celebrates ? 1 : 0.1
  }

  private var stats: some View {
    HStack(spacing: 10) {
      tile("\(viewModel.result.correct)/\(viewModel.result.total)", "doğru", Palette.good)
      tile(viewModel.durationText, "süre", Palette.accent)
      tile("\(viewModel.result.streak)", "gün seri", Palette.streak)
    }
  }

  private func tile(_ value: String, _ label: String, _ color: Color) -> some View {
    VStack(spacing: 2) {
      Text(value).font(AppFont.headline).foregroundStyle(color)
      Text(label).font(AppFont.tiny).foregroundStyle(Palette.muted)
    }
    .frame(maxWidth: .infinity)
    .card(padding: 12)
  }

  private var badges: some View {
    VStack(alignment: .leading, spacing: 10) {
      Eyebrow("Yeni rozet")
      ForEach(viewModel.result.newBadges, id: \.self) { badge in
        HStack(spacing: 12) {
          MedalView(systemImage: badge.symbol, color: badge.color, size: 48)
          VStack(alignment: .leading, spacing: 2) {
            Text(badge.title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
            Text(badge.reward.map { "Ödül: \($0)" } ?? badge.detail).font(AppFont.caption)
              .foregroundStyle(Palette.muted)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .card()
  }
}

/// Bitiş kutlaması: ekranın üstünden dökülen renkli konfeti (tek seferlik).
///
/// Hareketi Azalt açıkken gösterilmez (bkz. `FinishView`).
private struct ConfettiView: View {
  /// Konfeti dökülsün mü.
  let isActive: Bool
  /// Konfeti parçaları (sabit tohumla üretilir; her çizimde aynı kalır).
  private let pieces = ConfettiPiece.make(count: 44)

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .topLeading) {
        ForEach(pieces) { piece in
          RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(piece.color)
            .frame(width: piece.size.width, height: piece.size.height)
            .rotationEffect(.degrees(isActive ? piece.spin : 0))
            .position(
              x: piece.x * proxy.size.width + (isActive ? piece.drift : 0),
              y: isActive ? proxy.size.height * piece.fall : -20
            )
            .opacity(isActive ? 0 : 1)
            .animation(
              .easeIn(duration: piece.duration).delay(piece.delay), value: isActive)
        }
      }
    }
    .accessibilityHidden(true)
  }
}

/// Tek konfeti parçası.
private struct ConfettiPiece: Identifiable {
  let id: Int
  /// Yatay başlangıç (0…1).
  let x: CGFloat
  /// Düşüş sırasında yana kayma.
  let drift: CGFloat
  /// Düşüşün bittiği yükseklik oranı.
  let fall: CGFloat
  /// Dönüş açısı.
  let spin: Double
  let size: CGSize
  let color: Color
  let duration: Double
  let delay: Double

  /// Parçaları sabit bir sözde rastgele diziyle üretir.
  static func make(count: Int) -> [ConfettiPiece] {
    let colors = [Palette.gold, Palette.accent, Palette.good, Palette.streak, Palette.bad]
    var seed: UInt64 = 0x9E37_79B9_7F4A_7C15
    func next() -> Double {
      seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
      return Double(seed >> 11) / Double(UInt64(1) << 53)
    }
    return (0..<count).map { index in
      ConfettiPiece(
        id: index, x: next(), drift: (next() - 0.5) * 120, fall: 0.55 + next() * 0.45,
        spin: (next() - 0.5) * 720, size: CGSize(width: 6 + next() * 5, height: 9 + next() * 7),
        color: colors[index % colors.count], duration: 1.6 + next() * 1.2, delay: next() * 0.5)
    }
  }
}
