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

/// Alttan açılan kelime detay paneli: aksan seçimi, anlam, örnek cümle ve isteğe bağlı defter
/// bölümü.
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
  @State private var contentHeight: CGFloat = 460

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
    VStack(alignment: .leading, spacing: 14) {
      header
      SegmentBar(
        WordAccent.allCases.map { ($0, $0.title) }, selection: $accent, compact: true)
      if notebook == nil {
        HStack(spacing: 6) {
          Pill(word.level.rawValue, tone: .accent)
          if let boxLabel { Pill(boxLabel) }
        }
      }
      VStack(alignment: .leading, spacing: 4) {
        Eyebrow("Anlamı")
        Text(word.meaning).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
          .fixedSize(horizontal: false, vertical: true)
      }
      exampleCard
      if let notebook { notebookSection(notebook) }
      if let primaryTitle, let onPrimary {
        Button(primaryTitle, action: onPrimary).buttonStyle(.chunky)
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 24)
    .padding(.bottom, 16)
    .onGeometryChange(for: CGFloat.self, of: \.size.height) { contentHeight = $0 }
    .frame(maxHeight: .infinity, alignment: .top)
    .presentationDetents([.height(contentHeight)])
    .presentationDragIndicator(.visible)
    .presentationBackground(Palette.surface)
  }

  // MARK: - Sections

  /// Kelime, IPA ve telaffuz butonu.
  private var header: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 6) {
        Text(word.en).font(AppFont.rounded(36, weight: .black)).foregroundStyle(Palette.ink)
          .lineLimit(1).minimumScaleFactor(0.6)
        Text("\(word.ipa(british: accent.isBritish)) · \(word.posTitle)")
          .font(AppFont.caption).foregroundStyle(Palette.muted)
      }
      Spacer()
      Button(action: speak) { IconCircle("speaker.wave.2.fill", size: 44, accent: true) }
        .buttonStyle(.plain)
        .accessibilityLabel("Telaffuzu dinle (\(accent.title))")
    }
  }

  /// Vurgulu örnek cümle ve Türkçesi.
  private var exampleCard: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(Self.highlighted(word.example, word: word.en))
        .font(AppFont.body).foregroundStyle(Palette.ink)
        .fixedSize(horizontal: false, vertical: true)
      if let translation = word.exampleTr, !translation.isEmpty {
        Text(translation).font(AppFont.caption).foregroundStyle(Palette.muted)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 12)
    .padding(.horizontal, 14)
    .background(
      RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous).fill(Palette.surface2)
    )
    .overlay(alignment: .leading) { Rectangle().fill(Palette.accent).frame(width: 4) }
    .clipShape(RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous))
  }

  /// İlk görüldüğü yer, kutu ve defter eylemleri.
  private func notebookSection(_ notebook: WordNotebookStatus) -> some View {
    VStack(spacing: 12) {
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        Text("İlk görüldüğü: \(notebook.firstSeen)").lineLimit(2)
        Spacer(minLength: 4)
        Text(notebook.learned ? "Öğrenildi" : "Kutu \(notebook.box)/\(notebook.maxBox)")
          .fixedSize()
      }
      .font(AppFont.caption)
      .foregroundStyle(Palette.muted)
      HStack(spacing: 10) {
        Button("Tekrarda kalsın", action: notebook.onKeepReviewing)
          .buttonStyle(.chunkySecondary)
        Button(action: notebook.onLearned) {
          Label("Öğrendim", systemImage: "checkmark")
        }
        .buttonStyle(.chunky)
      }
      if let onRemove = notebook.onRemove {
        Button(role: .destructive, action: onRemove) {
          Label("Defterden çıkar", systemImage: "trash")
            .font(AppFont.caption)
            .foregroundStyle(Palette.bad)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
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
  static func highlighted(_ sentence: String, word: String) -> AttributedString {
    var text = AttributedString("“\(sentence)”")
    if let range = text.range(of: word, options: .caseInsensitive) {
      text[range].inlinePresentationIntent = .stronglyEmphasized
    }
    return text
  }
}
