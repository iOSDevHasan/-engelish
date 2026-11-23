import ContentKit
import DesignKit
import SwiftUI

/// Paket detayı: ilerleme, Plus tanıtımı ve sırayla açılan bulmaca kareleri.
struct PackView: View {
  @StateObject var viewModel: PackViewModel
  /// Izgaranın genişliği (sütun sayısı için).
  @State private var gridWidth: CGFloat = 0

  var body: some View {
    VStack(spacing: 0) {
      NavHeader("", onLeading: viewModel.back) {
        if viewModel.hasPlusLockedTiles {
          Button(action: viewModel.openPaywall) { PlusBadge() }
            .buttonStyle(PressScaleButtonStyle())
            .accessibilityLabel("\(PlusBrand.name) ile kilidi aç")
            .transition(.scale.combined(with: .opacity))
        }
      }
      if let pack = viewModel.pack {
        ScrollView {
          content(pack)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottom) { nudge }
        footer
      } else {
        ProgressView().frame(maxHeight: .infinity)
      }
    }
    .screenBackground()
    .animation(Motion.snappy, value: viewModel.hasPlusLockedTiles)
    .animation(Motion.snappy, value: viewModel.nudge)
    .sensoryFeedback(.warning, trigger: viewModel.nudge?.serial) { _, new in new != nil }
    .task { await viewModel.load() }
    .task(id: viewModel.nudge?.serial) {
      guard let serial = viewModel.nudge?.serial else { return }
      try? await Task.sleep(for: .seconds(2.2))
      viewModel.dismissNudge(serial: serial)
    }
  }

  // MARK: - Content

  /// Başlık, ilerleme, Plus kartı ve bulmaca ızgarası.
  private func content(_ pack: Pack) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      summary(pack)
      if viewModel.hasPlusLockedTiles {
        PlusPromoCard(
          title: viewModel.promoTitle, subtitle: viewModel.promoSubtitle, cta: "Kilidi aç",
          action: viewModel.openPaywall
        )
        .appearAnimation(index: 1)
      }
      Label("Bulmacalar sırayla açılır", systemImage: "arrow.forward.circle.fill")
        .font(AppFont.caption)
        .foregroundStyle(Palette.muted)
        .lineLimit(2)
      grid
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.top, 4)
    .padding(.bottom, 24)
    .frame(maxWidth: 640)
    .frame(maxWidth: .infinity)
  }

  /// Üst başlık, paket adı, açıklama ve ilerleme.
  private func summary(_ pack: Pack) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Eyebrow(PackRules.eyebrow(for: pack.kind))
      Text(pack.title).font(AppFont.title).foregroundStyle(Palette.ink)
        .minimumScaleFactor(0.8)
        .fixedSize(horizontal: false, vertical: true)
      Text(viewModel.summary)
        .font(AppFont.caption).foregroundStyle(Palette.muted)
        .fixedSize(horizontal: false, vertical: true)
      HStack {
        Text("\(viewModel.solved) / \(pack.puzzleIds.count) tamamlandı")
          .font(AppFont.caption).foregroundStyle(Palette.ink)
          .contentTransition(.numericText())
        Spacer(minLength: 8)
        Text("%\(viewModel.percent)")
          .font(AppFont.caption).foregroundStyle(Palette.muted)
          .contentTransition(.numericText())
      }
      .lineLimit(1)
      .padding(.top, 6)
      FillingProgressBar(value: viewModel.progress, tint: PackStyle.tint(for: pack))
    }
    .appearAnimation(index: 0)
  }

  /// Bulmaca kareleri: genişliğe göre sütun sayısı değişir (iPhone'da 4, iPad'de daha fazla).
  ///
  /// Paket en fazla birkaç düzine kare içerdiği için ızgara tembel değildir: kareler bir kez
  /// kurulur, kaydırırken yeniden oluşturulup giriş animasyonunu tekrar oynatmaz. Giriş
  /// animasyonu tek tek karelerde değil, ızgaranın tamamında bir kez oynar.
  private var grid: some View {
    let columns = PuzzleTileView.columnCount(for: gridWidth, spacing: Self.tileSpacing)
    return VStack(spacing: 14) {
      ForEach(Self.rows(of: viewModel.tiles, columns: columns), id: \.first?.id) { row in
        HStack(spacing: Self.tileSpacing) {
          ForEach(row) { tile in
            Button {
              viewModel.open(tile)
            } label: {
              PuzzleTileView(tile: tile, shakes: viewModel.shakes[tile.id] ?? 0)
            }
            .buttonStyle(PressScaleButtonStyle())
          }
          // Son satır eksikse boşluk kareleri sütunları hizalı tutar.
          ForEach(row.count..<columns, id: \.self) { _ in
            Color.clear.frame(maxWidth: .infinity)
          }
        }
      }
    }
    .onGeometryChange(for: CGFloat.self, of: \.size.width) { gridWidth = $0 }
    .padding(.top, 8)
    .appearAnimation(index: 2)
  }

  /// Kareleri verilen sütun sayısında satırlara böler.
  private static func rows(of tiles: [PuzzleTile], columns: Int) -> [[PuzzleTile]] {
    stride(from: 0, to: tiles.count, by: columns).map {
      Array(tiles[$0..<min($0 + columns, tiles.count)])
    }
  }

  /// Kareler arası yatay boşluk.
  private static let tileSpacing: CGFloat = 12

  // MARK: - Footer

  /// Sıra uyarısı baloncuğu.
  @ViewBuilder private var nudge: some View {
    if let nudge = viewModel.nudge {
      NudgeToast(text: nudge.message)
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .id(nudge.serial)
    }
  }

  /// Sıradaki bulmacayı açan ya da paywall'a götüren ana buton.
  @ViewBuilder private var footer: some View {
    if let title = viewModel.primaryTitle {
      Group {
        if viewModel.primaryNeedsPlus {
          Button(action: viewModel.openNext) {
            Label(title, systemImage: "crown.fill").lineLimit(1).minimumScaleFactor(0.8)
          }
          .buttonStyle(.plus)
        } else {
          Button(action: viewModel.openNext) {
            Text(title).lineLimit(1).minimumScaleFactor(0.8)
          }
          .buttonStyle(.chunky)
        }
      }
      .padding(.horizontal, Metrics.gutter)
      .padding(.top, 6)
      .padding(.bottom, 10)
      .frame(maxWidth: 640)
    }
  }
}

/// Bulmaca karesi: bitti (✓ ve yıldızlar), sıradaki (vurgulu, nabız atan), sıra kilitli (soluk,
/// kilit) ya da Plus kilitli (köşeye yaslı Plus sekmesi).
private struct PuzzleTileView: View {
  let tile: PuzzleTile
  let shakes: Int
  @State private var isPulsing = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// En dar kare genişliği: iPhone SE (339 pt içerik) dahil her iPhone'da satıra 4 kare sığar.
  static let minWidth: CGFloat = 72
  /// En geniş kare genişliği (iPad'de sütun sayısı artar).
  static let maxWidth: CGFloat = 104

  /// Verilen genişliğe sığan sütun sayısı (en az 1; genişlik bilinmiyorsa iPhone'daki 4).
  static func columnCount(for width: CGFloat, spacing: CGFloat) -> Int {
    guard width > 0 else { return 4 }
    return max(1, Int((width + spacing) / (minWidth + spacing)))
  }
  /// Kare köşe yarıçapı; Plus sekmesi de bu yarıçapla kırpılır.
  private static let radius: CGFloat = 18

  var body: some View {
    // Kare genişliği ızgara hücresinden gelir; şekil en-boy oranıyla boyu belirler, içerik
    // üstüne yerleşir (içeriğin kendi boyu kareyi daraltmasın diye).
    RoundedRectangle(cornerRadius: Self.radius, style: .continuous)
      .fill(background)
      .shadow(color: shadow, radius: 0, y: tile.access == .next ? 4 : 3)
      // Biraz uzun kare: üstte köşe sekmesine, altta durum satırına yer kalır.
      .aspectRatio(0.88, contentMode: .fit)
      .frame(maxWidth: .infinity)
      .overlay {
        VStack(spacing: 4) {
          Text("\(tile.number)")
            .font(AppFont.rounded(28, weight: .black))
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
          detail.frame(height: 16)
        }
        .foregroundStyle(foreground)
        .padding(.top, 6)
      }
      .overlay(
        RoundedRectangle(cornerRadius: Self.radius, style: .continuous)
          .strokeBorder(border, lineWidth: tile.access == .next ? 0 : 1)
      )
      .overlay { pulseRing }
      .overlay(alignment: .topTrailing) {
        if tile.access.isFinished {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white, Palette.good)
            .padding(6)
        }
      }
      .plusCornerTab(tile.access.showsPlusBadge, cornerRadius: Self.radius)
      .modifier(ShakeEffect(shakes: reduceMotion ? 0 : CGFloat(shakes)))
      .animation(.linear(duration: 0.45), value: shakes)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(label)
      .accessibilityAddTraits(.isButton)
  }

  // MARK: - Pieces

  /// Numaranın altındaki küçük içerik.
  @ViewBuilder private var detail: some View {
    switch tile.access {
    case .finished(let stars):
      HStack(spacing: 2) {
        ForEach(0..<3, id: \.self) { index in
          Image(systemName: "star.fill").font(.system(size: 11, weight: .bold))
            .foregroundStyle(Palette.streak.opacity(index < stars ? 1 : 0.25))
        }
      }
    case .next:
      Text("Sıradaki").font(AppFont.rounded(12, weight: .black))
        .lineLimit(1)
        .fixedSize()
    case .needsPrevious:
      Image(systemName: "lock.fill").font(.system(size: 12, weight: .bold))
        .foregroundStyle(Palette.muted)
    case .needsPlus:
      Text(PlusBrand.short).font(AppFont.rounded(12, weight: .black))
        .foregroundStyle(Palette.muted)
        .lineLimit(1)
        .fixedSize()
    }
  }

  /// Sıradaki karenin etrafında genişleyip sönen halka.
  @ViewBuilder private var pulseRing: some View {
    if tile.access == .next && !reduceMotion {
      RoundedRectangle(cornerRadius: Self.radius, style: .continuous)
        .strokeBorder(Palette.accent, lineWidth: 2)
        .scaleEffect(isPulsing ? 1.18 : 1)
        .opacity(isPulsing ? 0 : 0.7)
        .allowsHitTesting(false)
        .onAppear {
          withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
            isPulsing = true
          }
        }
    }
  }

  // MARK: - Colors

  private var foreground: Color {
    switch tile.access {
    case .next: .white
    case .needsPrevious: Palette.muted
    case .finished, .needsPlus: Palette.ink
    }
  }

  private var background: Color {
    switch tile.access {
    case .finished: Palette.goodBackground
    case .next: Palette.buttonFill
    case .needsPrevious: Palette.surface.opacity(0.6)
    case .needsPlus: Palette.surface
    }
  }

  private var border: Color {
    switch tile.access {
    case .finished: Palette.good.opacity(0.35)
    case .next: .clear
    case .needsPrevious, .needsPlus: Palette.cardBorder
    }
  }

  private var shadow: Color {
    switch tile.access {
    case .next: Palette.buttonShadow
    case .needsPrevious: .clear
    case .finished, .needsPlus: Palette.cardShadow
    }
  }

  private var label: String {
    let name = "Bulmaca \(tile.number)"
    switch tile.access {
    case .finished(let stars): return "\(name), bitti, \(stars) yıldız"
    case .next: return "\(name), sıradaki"
    case .needsPrevious(let blocker, let needsPlus):
      let plus = needsPlus ? ", \(PlusBrand.name) gerekli" : ""
      return "\(name), kilitli. \(PackRules.sequenceMessage(blocker: blocker))\(plus)"
    case .needsPlus: return "\(name), \(PlusBrand.name) gerekli"
    }
  }
}
