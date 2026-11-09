import ContentKit
import DesignKit
import SwiftUI

// MARK: - Section header

/// Bölüm başlığı: solda başlık, sağda not / rozet / bağlantı.
struct SectionHeader<Trailing: View>: View {
  private let title: String
  private let trailing: Trailing

  /// Başlık ve sağ içerikle bölüm başlığı oluşturur.
  init(_ title: String, @ViewBuilder trailing: () -> Trailing) {
    self.title = title
    self.trailing = trailing()
  }

  var body: some View {
    HStack {
      Text(title).font(AppFont.section).foregroundStyle(Palette.ink)
        .accessibilityAddTraits(.isHeader)
      Spacer()
      trailing
    }
  }
}

// MARK: - Level tile

/// Seviye karesi: kod, yüzde ya da kilit, ince ilerleme çubuğu.
struct LevelTileView: View {
  let card: PackCard
  let isCurrent: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(card.pack.level.rawValue)
        .font(AppFont.rounded(19, weight: .black))
        .foregroundStyle(Palette.ink)
      Group {
        if card.isLocked {
          Image(systemName: "lock.fill").font(.system(size: 11, weight: .bold))
        } else {
          Text("%\(card.percent)").font(AppFont.tiny)
        }
      }
      .foregroundStyle(Palette.muted)
      .frame(height: 13)
      ProgressBar(value: card.isLocked ? 0 : card.progress, height: 4)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 10)
    .padding(.horizontal, 9)
    .background(
      RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
        .fill(Palette.surface)
        .shadow(color: Palette.cardShadow, radius: 0, y: 2)
    )
    .overlay(
      RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
        .strokeBorder(isCurrent ? Palette.accent : .clear, lineWidth: 2)
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityText)
  }

  private var accessibilityText: String {
    let status = card.isLocked ? "kilitli" : "yüzde \(card.percent) tamamlandı"
    return "\(card.pack.level.rawValue) seviyesi, \(status)\(isCurrent ? ", senin seviyen" : "")"
  }
}

// MARK: - Exam card

/// Sınav paketi kartı: düz renk, kelime/bulmaca sayısı, seviye aralığı, kilit.
struct ExamCardView: View {
  let card: PackCard

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .firstTextBaseline) {
        Text(card.shortTitle).font(AppFont.rounded(22, weight: .black))
          .lineLimit(1).minimumScaleFactor(0.7)
        Spacer(minLength: 4)
        if card.isLocked {
          Image(systemName: "lock.fill").font(.system(size: 14, weight: .bold))
        }
      }
      Text(
        "\(TurkishText.number(card.pack.wordCount)) kelime · \(card.puzzleCount) bulmaca"
      )
      .font(AppFont.caption).opacity(0.92).lineLimit(2)
      Spacer(minLength: 0)
      Text(card.levelRange).font(AppFont.tiny.weight(.black))
        .padding(.horizontal, 8).frame(height: 22)
        .background(Capsule().fill(.white.opacity(0.25)))
    }
    .foregroundStyle(.white)
    .padding(.vertical, 12)
    .padding(.horizontal, 13)
    .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
    .background(
      RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
        .fill(ExamStyle.color(for: card.pack.id))
        .shadow(color: .black.opacity(0.14), radius: 0, y: 4)
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "\(card.shortTitle), \(card.pack.wordCount) kelime, \(card.puzzleCount) bulmaca, "
        + "\(card.levelRange)\(card.isLocked ? ", kilitli" : "")")
  }
}

/// Sınav paketlerinin tasarımdaki düz renkleri.
enum ExamStyle {
  /// Paket kimliğine göre kart rengi; bilinmeyenlerde vurgu rengi.
  static func color(for packId: String) -> Color {
    switch packId {
    case "yds": Color(hex: 0x6C5CE7)
    case "yokdil": Color(hex: 0xFF8A3D)
    case "lgs": Color(hex: 0x1FB57A)
    case "ielts": Color(hex: 0xFF5A8A)
    case "toefl": Color(hex: 0x3C9BE0)
    default: Palette.accent
    }
  }
}

// MARK: - Theme tile

/// Tema paketi karesi: simge, başlık, bulmaca sayısı ve ücretsiz / premium durumu.
struct ThemeTileView: View {
  let card: PackCard
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Image(systemName: card.symbol)
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(Palette.ink.opacity(0.8))
      Spacer(minLength: 6)
      Text(card.pack.title).font(AppFont.rounded(14, weight: .black))
        .lineLimit(1).minimumScaleFactor(0.8)
      HStack(spacing: 3) {
        if card.isLocked {
          Image(systemName: "lock.fill").font(.system(size: 8, weight: .bold))
        }
        Text(ThemeText.detail(card)).lineLimit(1).minimumScaleFactor(0.8)
      }
      .font(.system(size: 10, weight: .bold, design: .rounded))
      .opacity(0.72)
    }
    .foregroundStyle(Palette.ink)
    .padding(.vertical, 10)
    .padding(.horizontal, 11)
    .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
    .background(RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous).fill(tint))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(card.pack.title), \(ThemeText.spokenDetail(card))")
  }
}

/// Tema paketi durum metinleri.
enum ThemeText {
  /// Kutudaki kısa metin: "24 bulmaca · Ücretsiz" ya da "20 bulmaca" (kilit simgesi yanında).
  static func detail(_ card: PackCard) -> String {
    let count = "\(card.puzzleCount) bulmaca"
    return card.pack.isFullyFree ? "\(count) · Ücretsiz" : count
  }

  /// Erişilebilirlik metni: kilitliyse "Premium" da okunur.
  static func spokenDetail(_ card: PackCard) -> String {
    card.isLocked ? "\(card.puzzleCount) bulmaca · Premium" : detail(card)
  }
}
