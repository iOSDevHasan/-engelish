import ContentKit
import DesignKit
import SwiftUI

/// Kelime listesindeki satır: telaffuz butonu, kelime, IPA, anlam ve örnek cümle.
public struct WordRow<Trailing: View>: View {
  private let word: Word
  private let onSpeak: () -> Void
  private let trailing: Trailing

  /// Kelime, telaffuz eylemi ve sağdaki içerikle satır oluşturur.
  public init(word: Word, onSpeak: @escaping () -> Void, @ViewBuilder trailing: () -> Trailing) {
    self.word = word
    self.onSpeak = onSpeak
    self.trailing = trailing()
  }

  public var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Button(action: onSpeak) { IconCircle("speaker.wave.2.fill", size: 36) }
        .buttonStyle(.plain)
        .accessibilityLabel("\(word.en) telaffuzunu dinle")
      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 6) {
          Text(word.en).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
          Text(word.ipa).font(AppFont.caption).foregroundStyle(Palette.muted)
        }
        Text(word.meaning).font(AppFont.caption).foregroundStyle(Palette.ink)
        Text(word.example)
          .font(AppFont.caption.italic())
          .foregroundStyle(Palette.muted)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer(minLength: 4)
      trailing
    }
    .padding(.vertical, 10)
  }
}

extension WordRow where Trailing == EmptyView {
  /// Sağ içeriği olmayan satır oluşturur.
  public init(word: Word, onSpeak: @escaping () -> Void) {
    self.init(word: word, onSpeak: onSpeak) { EmptyView() }
  }
}

/// Alttan açılan kelime detay paneli.
public struct WordDetailSheet: View {
  private let word: Word
  private let boxLabel: String?
  private let onSpeak: () -> Void
  private let primaryTitle: String?
  private let onPrimary: (() -> Void)?

  /// Kelime, kutu etiketi, telaffuz ve isteğe bağlı ana eylemle panel oluşturur.
  public init(
    word: Word, boxLabel: String? = nil, onSpeak: @escaping () -> Void,
    primaryTitle: String? = nil, onPrimary: (() -> Void)? = nil
  ) {
    self.word = word
    self.boxLabel = boxLabel
    self.onSpeak = onSpeak
    self.primaryTitle = primaryTitle
    self.onPrimary = onPrimary
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 4) {
          Text(word.en).font(AppFont.title).foregroundStyle(Palette.ink)
          Text("\(word.ipa) · \(word.posTitle)").font(AppFont.caption)
            .foregroundStyle(Palette.muted)
        }
        Spacer()
        Button(action: onSpeak) { IconCircle("speaker.wave.2.fill", size: 48, accent: true) }
          .buttonStyle(.plain)
          .accessibilityLabel("Telaffuzu dinle")
      }
      HStack(spacing: 6) {
        Pill(word.level.rawValue, tone: .accent)
        if let boxLabel { Pill(boxLabel) }
      }
      VStack(alignment: .leading, spacing: 6) {
        Eyebrow("Anlamı")
        Text(word.meaning).font(AppFont.headline).foregroundStyle(Palette.ink)
      }
      VStack(alignment: .leading, spacing: 6) {
        Eyebrow("Örnek cümle")
        Text(word.example).font(AppFont.body.italic()).foregroundStyle(Palette.ink)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .card(padding: 14, fill: Palette.surface2)
      if let primaryTitle, let onPrimary {
        Button(primaryTitle, action: onPrimary).buttonStyle(.chunky)
      }
    }
    .padding(20)
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
    .presentationBackground(Palette.surface)
  }
}
