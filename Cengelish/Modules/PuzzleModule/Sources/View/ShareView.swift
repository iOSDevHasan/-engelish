import DesignKit
import PuzzleKit
import SwiftUI

/// Paylaş ekranı: sonuç kartı ve Hikâye / Mesaj / Kaydet / Bağlantı seçenekleri.
struct ShareView: View {
  @StateObject var viewModel: ShareViewModel

  var body: some View {
    VStack(spacing: 0) {
      NavHeader("Paylaş", leadingSymbol: "xmark", onLeading: viewModel.close)
      ScrollView {
        ShareCardView(card: viewModel.card)
          .shadow(color: .black.opacity(0.3), radius: 22, y: 16)
          .padding(.horizontal, Metrics.gutter)
          .padding(.vertical, 12)
          .frame(maxWidth: .infinity)
      }
      .scrollBounceBehavior(.basedOnSize)
      options
        .padding(.horizontal, Metrics.gutter)
        .padding(.vertical, 12)
        .frame(maxWidth: 520)
    }
    .overlay(alignment: .bottom) {
      if let notice = viewModel.notice {
        Text(notice)
          .font(.system(size: 12.5, weight: .heavy, design: .rounded))
          .foregroundStyle(Palette.background)
          .padding(.horizontal, 14)
          .padding(.vertical, 9)
          .background(Capsule().fill(Palette.ink))
          .padding(.bottom, 110)
          .transition(.opacity.combined(with: .move(edge: .bottom)))
      }
    }
    .animation(.easeOut(duration: 0.2), value: viewModel.notice)
    .screenBackground()
    .task { viewModel.prepare() }
  }

  private var options: some View {
    HStack {
      if let story = viewModel.storyImage {
        let image = Image(uiImage: story)
        ShareLink(item: image, preview: SharePreview("Çengelish sonucum", image: image)) {
          ShareOption(icon: "photo", title: "Hikâye")
        }
      } else {
        ShareOption(icon: "photo", title: "Hikâye").opacity(0.4)
      }
      Spacer()
      if let card = viewModel.cardImage {
        let image = Image(uiImage: card)
        ShareLink(
          item: image, subject: Text("Çengelish"), message: Text(viewModel.messageText),
          preview: SharePreview("Çengelish sonucum", image: image)
        ) {
          ShareOption(icon: "message", title: "Mesaj")
        }
      } else {
        ShareOption(icon: "message", title: "Mesaj").opacity(0.4)
      }
      Spacer()
      Button {
        Task { await viewModel.saveToPhotos() }
      } label: {
        ShareOption(icon: "square.and.arrow.down", title: "Kaydet")
      }
      .disabled(viewModel.storyImage == nil || viewModel.isSaving)
      Spacer()
      Button {
        viewModel.copyLink()
      } label: {
        ShareOption(icon: "link", title: "Bağlantı")
      }
    }
    .buttonStyle(.plain)
  }
}

/// Paylaşım seçeneği: yuvarlak köşeli ikon kutusu ve etiket.
private struct ShareOption: View {
  let icon: String
  let title: String

  var body: some View {
    VStack(spacing: 6) {
      Image(systemName: icon).font(.system(size: 22, weight: .semibold))
        .foregroundStyle(Palette.ink)
        .frame(width: 56, height: 56)
        .background(
          RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Palette.surface)
            .shadow(color: Palette.cardShadow, radius: 0, y: 2)
        )
      Text(title).font(.system(size: 12, weight: .heavy, design: .rounded))
        .foregroundStyle(Palette.ink)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
    .accessibilityAddTraits(.isButton)
  }
}

/// Paylaşım kartı: dolu kutular, ✓/✗ sonuç kareleri ve istatistikler; cevaplar gösterilmez.
struct ShareCardView: View {
  let card: ShareCard
  /// Kartın içerik genişliği.
  private let innerWidth: CGFloat = 280

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        HStack(spacing: 8) {
          AvatarView(card.avatar, size: 34)
          Text(card.owner).font(AppFont.bodyBold).lineLimit(1)
        }
        Spacer(minLength: 8)
        Text(DateText.dayMonth(card.date)).font(AppFont.caption)
      }
      Text(card.title).font(AppFont.rounded(28, weight: .black)).lineLimit(1)
        .minimumScaleFactor(0.6)
      PuzzleGridView(
        layout: card.layout, theme: Self.theme, cellSize: gridCell,
        letters: Dictionary(
          uniqueKeysWithValues: card.layout.letterCells.map { ($0, ("·", .filled)) }),
        showsClueText: false
      )
      .accessibilityHidden(true)
      results
      HStack(spacing: 16) {
        Label(card.duration, systemImage: "clock")
        Label("\(card.correct)/\(card.total)", systemImage: "checkmark")
        Label("\(card.streak) gün", systemImage: "flame.fill")
      }
      .font(.system(size: 14, weight: .black, design: .rounded))
      .labelStyle(CompactLabelStyle())
      Text(ShareText.footer).font(.system(size: 12, weight: .heavy, design: .rounded))
        .opacity(0.8)
    }
    .foregroundStyle(.white)
    .padding(20)
    .frame(width: innerWidth + 40)
    .background(
      LinearGradient(
        colors: [Color(hex: 0x6C5CE7), Color(hex: 0x9A8CFF)], startPoint: .topLeading,
        endPoint: .bottomTrailing),
      in: RoundedRectangle(cornerRadius: 30, style: .continuous)
    )
    .environment(\.colorScheme, .light)
    .accessibilityElement(children: .combine)
  }

  /// Sonuç kareleri (28 pt; çok kelimede sığacak kadar küçülür).
  private var results: some View {
    let count = max(card.results.count, 1)
    let side = min(28, (innerWidth - 6 * CGFloat(count - 1)) / CGFloat(count))
    return HStack(spacing: 6) {
      ForEach(Array(card.results.enumerated()), id: \.offset) { _, isCorrect in
        RoundedRectangle(cornerRadius: side * 0.32, style: .continuous)
          .fill(Color(hex: isCorrect ? 0x3DD69A : 0xFF6B70))
          .overlay {
            Image(systemName: isCorrect ? "checkmark" : "xmark")
              .font(.system(size: side * 0.45, weight: .black))
              .foregroundStyle(.white.opacity(0.9))
          }
          .frame(width: side, height: side)
      }
    }
    .accessibilityElement()
    .accessibilityLabel("\(card.correct) doğru, \(card.total - card.correct) yanlış")
  }

  private var gridCell: CGFloat {
    let columns = CGFloat(max(card.layout.columns, 1))
    return min(30, (innerWidth - columns * Self.theme.gap) / columns)
  }

  /// Kart üstündeki ızgara teması (dolu kutular sarı).
  static let theme = PuzzleTheme(
    id: "share", name: "", detail: "", isPremium: false, cell: .white.opacity(0.25),
    clue: .white.opacity(0.28), clueInk: .white, line: .clear, pen: Color(hex: 0xFFC93C),
    pencil: .white, blank: .clear, stripedBlanks: false, highlight: .white.opacity(0.25),
    active: .white, activeRing: nil, arrow: .white, gap: 3, border: 0, cornerRatio: 0.2,
    keyInk: .white)
}

/// 9:16 hikâye görseli: marka başlığı, ortada kart.
struct ShareStoryView: View {
  let card: ShareCard

  var body: some View {
    VStack(spacing: 24) {
      Spacer()
      Text("Çengelish").font(AppFont.rounded(30, weight: .black))
        .foregroundStyle(Color(hex: 0x6C5CE7))
      ShareCardView(card: card)
        .shadow(color: .black.opacity(0.25), radius: 20, y: 14)
      Text("cengelish.app").font(AppFont.caption).foregroundStyle(Color(hex: 0x7C78A3))
      Spacer()
    }
    .frame(width: 360, height: 640)
    .background(
      LinearGradient(
        colors: [Color(hex: 0xFFF8EE), Color(hex: 0xE9E4FF)], startPoint: .top,
        endPoint: .bottom)
    )
    .environment(\.colorScheme, .light)
  }
}

/// İkon ve metin arası dar boşluklu etiket.
private struct CompactLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 5) {
      configuration.icon
      configuration.title
    }
  }
}
