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
      SpeakerButton(word: word.en, size: 36, isRound: true, action: onSpeak)
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
      // Metin sütunu kalan genişliğin tamamını alır; örnek cümle gereksiz yere kırılmaz.
      .frame(maxWidth: .infinity, alignment: .leading)
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

/// Alttan açılan kelime detay paneli: aksan seçimi, anlam, örnek cümle ve isteğe bağlı defter
/// bölümü.
///
/// Düz panel içeriğidir: kendi `ScrollView`'unu ya da panel ayarını içermez. Sunan taraf
/// DesignKit'in `.appBottomSheet(item:)` / `.appBottomSheet(isPresented:)` paneliyle açar; panel
/// içeriğe göre boylanır ve gerekirse kendisi kaydırır.
public struct WordDetailSheet: View {

  // MARK: - Properties

  private let word: Word
  private let boxLabel: String?
  private let onSpeak: () -> Void
  private let primaryTitle: String?
  private let onPrimary: (() -> Void)?
  private let onSpeakAccent: ((WordAccent) -> Void)?
  private let notebook: WordNotebookStatus?
  @State private var accent: WordAccent

  // MARK: - Init

  /// Kelime, kutu etiketi, telaffuz, isteğe bağlı ana eylem, aksan ve defter bölümüyle panel
  /// oluşturur.
  ///
  /// - Parameters:
  ///   - accent: Açılıştaki aksan (IPA ve telaffuz dili buna göre seçilir).
  ///   - onSpeakAccent: Verilirse telaffuz seçili aksanla bunun üzerinden yapılır; yoksa
  ///     `onSpeak` çağrılır.
  ///   - notebook: Verilirse "İlk görüldüğü", "Kutu x/5" ve Tekrarda kalsın / Öğrendim gösterilir.
  public init(
    word: Word, boxLabel: String? = nil, onSpeak: @escaping () -> Void,
    primaryTitle: String? = nil, onPrimary: (() -> Void)? = nil,
    accent: WordAccent = .american, onSpeakAccent: ((WordAccent) -> Void)? = nil,
    notebook: WordNotebookStatus? = nil
  ) {
    self.word = word
    self.boxLabel = boxLabel
    self.onSpeak = onSpeak
    self.primaryTitle = primaryTitle
    self.onPrimary = onPrimary
    self.onSpeakAccent = onSpeakAccent
    self.notebook = notebook
    self._accent = State(initialValue: accent)
  }

  // MARK: - Body

  public var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      header
      accentRow
      meaningSection
      exampleCard
      if let notebook { notebookSection(notebook) }
      if let primaryTitle, let onPrimary {
        Button(primaryTitle, action: onPrimary).buttonStyle(.chunky)
      }
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.top, 20)
    .padding(.bottom, 16)
    .frame(maxWidth: 560)
    .frame(maxWidth: .infinity)
  }

  // MARK: - Sections

  /// Kelime, IPA ve telaffuz butonu.
  private var header: some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(word.en).font(AppFont.rounded(34, weight: .black)).foregroundStyle(Palette.ink)
          .lineLimit(1).minimumScaleFactor(0.6)
        Text("\(word.ipa(british: accent.isBritish)) · \(word.posTitle)")
          .font(AppFont.caption).foregroundStyle(Palette.muted)
          .fixedSize(horizontal: false, vertical: true)
          .contentTransition(.opacity)
          .animation(Motion.snappy, value: accent)
      }
      Spacer(minLength: 8)
      SpeakerButton(
        word: word.en, size: 48, isRound: true, accent: true,
        label: "Telaffuzu dinle (\(accent.title))", action: speak)
    }
  }

  /// Aksan seçici ve seviye / kutu etiketleri aynı satırda.
  private var accentRow: some View {
    HStack(spacing: 8) {
      SegmentBar(
        WordAccent.allCases.map { ($0, $0.title) }, selection: $accent, compact: true)
      Spacer(minLength: 4)
      Pill(word.level.rawValue, tone: .accent)
      if notebook == nil, let boxLabel { Pill(boxLabel) }
    }
  }

  /// Türkçe anlam.
  private var meaningSection: some View {
    VStack(alignment: .leading, spacing: 4) {
      Eyebrow("Anlamı")
      Text(word.meaning).font(AppFont.headline).foregroundStyle(Palette.ink)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  /// Vurgulu örnek cümle ve Türkçesi.
  private var exampleCard: some View {
    VStack(alignment: .leading, spacing: 6) {
      Eyebrow("Örnek", color: Palette.muted)
      Text(Self.highlighted(word.example, word: word.en))
        .font(AppFont.body).foregroundStyle(Palette.ink)
        .fixedSize(horizontal: false, vertical: true)
      if let translation = word.exampleTr, !translation.isEmpty {
        Text(translation).font(AppFont.caption).foregroundStyle(Palette.muted)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 14)
    .padding(.leading, 18)
    .padding(.trailing, 14)
    .background(Palette.surface)
    .overlay(alignment: .leading) { Rectangle().fill(Palette.accent).frame(width: 4) }
    .clipShape(RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
        .strokeBorder(Palette.cardBorder, lineWidth: 1)
    )
  }

  /// İlk görüldüğü yer, kutu ve defter eylemleri.
  private func notebookSection(_ notebook: WordNotebookStatus) -> some View {
    VStack(spacing: 12) {
      HStack(alignment: .center, spacing: 10) {
        VStack(alignment: .leading, spacing: 2) {
          Text("İlk görüldüğü").font(AppFont.tiny).foregroundStyle(Palette.muted)
          Text(notebook.firstSeen).font(AppFont.caption).foregroundStyle(Palette.ink)
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 4)
        VStack(alignment: .trailing, spacing: 4) {
          Text(notebook.learned ? "Öğrenildi" : "Kutu \(notebook.box)/\(notebook.maxBox)")
            .font(AppFont.caption)
            .foregroundStyle(notebook.learned ? Palette.good : Palette.muted)
            .fixedSize()
          BoxDots(box: notebook.learned ? notebook.maxBox : notebook.box, maxBox: notebook.maxBox)
        }
      }
      .card(padding: 14)
      HStack(spacing: 10) {
        Button(action: notebook.onKeepReviewing) {
          Text("Tekrarda kalsın").lineLimit(1).minimumScaleFactor(0.8)
        }
        .buttonStyle(.chunkySecondary)
        Button(action: notebook.onLearned) {
          Label("Öğrendim", systemImage: "checkmark").lineLimit(1).minimumScaleFactor(0.8)
        }
        .buttonStyle(.chunky)
      }
      if let onRemove = notebook.onRemove {
        Button(role: .destructive, action: onRemove) {
          Label("Defterden çıkar", systemImage: "trash")
            .font(AppFont.caption)
            .foregroundStyle(Palette.bad)
            .frame(maxWidth: .infinity, minHeight: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
  }

  // MARK: - Actions

  /// Seçili aksanla okur.
  private func speak() {
    if let onSpeakAccent {
      onSpeakAccent(accent)
    } else {
      onSpeak()
    }
  }

  // MARK: - Helpers

  /// Örnek cümleyi tırnak içine alır ve kelimeyi kalın yapar.
  nonisolated static func highlighted(_ sentence: String, word: String) -> AttributedString {
    var text = AttributedString("“\(sentence)”")
    if let range = text.range(of: word, options: .caseInsensitive) {
      text[range].inlinePresentationIntent = .stronglyEmphasized
    }
    return text
  }
}
