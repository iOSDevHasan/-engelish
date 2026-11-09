import DesignKit
import SwiftUI

// MARK: - Accent

/// Telaffuz aksanı (kelime panelindeki Amerikan / İngiliz seçimi).
public enum WordAccent: String, CaseIterable, Identifiable, Sendable {
  case american
  case british

  public var id: String { rawValue }

  /// Ekranda görünen ad.
  public var title: String { self == .american ? "Amerikan" : "İngiliz" }

  /// AVSpeech dil kodu.
  public var languageCode: String { self == .american ? "en-US" : "en-GB" }

  /// İngiliz aksanı mı.
  public var isBritish: Bool { self == .british }

  /// Dil kodundan (`en-GB` → İngiliz) aksan oluşturur.
  public init(languageCode: String) {
    self = languageCode == "en-GB" ? .british : .american
  }
}

// MARK: - Notebook status

/// Kelime panelinin defter bölümü: ilk görüldüğü yer, kutu ve tekrar/öğrendim eylemleri.
public struct WordNotebookStatus {
  /// "Günün Bulmacası · 8 Kasım" gibi ilk görüldüğü yer ve tarih.
  public let firstSeen: String
  /// Leitner kutusu (1–`maxBox`).
  public let box: Int
  /// En yüksek kutu.
  public let maxBox: Int
  /// Öğrenildi mi.
  public let learned: Bool
  /// "Tekrarda kalsın" eylemi.
  public let onKeepReviewing: () -> Void
  /// "Öğrendim" eylemi.
  public let onLearned: () -> Void
  /// Defterden çıkarma eylemi (nil ise gösterilmez).
  public let onRemove: (() -> Void)?

  /// Defter bölümünü tüm alanlarıyla oluşturur.
  public init(
    firstSeen: String, box: Int, maxBox: Int = 5, learned: Bool,
    onKeepReviewing: @escaping () -> Void, onLearned: @escaping () -> Void,
    onRemove: (() -> Void)? = nil
  ) {
    self.firstSeen = firstSeen
    self.box = box
    self.maxBox = maxBox
    self.learned = learned
    self.onKeepReviewing = onKeepReviewing
    self.onLearned = onLearned
    self.onRemove = onRemove
  }
}

// MARK: - Segment bar

/// Tasarımdaki yuvarlak köşeli bölmeli seçici ("Tümü / Tekrar / Öğrendim").
public struct SegmentBar<Value: Hashable>: View {
  private let options: [(value: Value, title: String)]
  @Binding private var selection: Value
  private let compact: Bool

  /// Seçenekler, seçim ve boyutla seçici oluşturur.
  public init(
    _ options: [(value: Value, title: String)], selection: Binding<Value>, compact: Bool = false
  ) {
    self.options = options
    self._selection = selection
    self.compact = compact
  }

  public var body: some View {
    HStack(spacing: 0) {
      ForEach(options.indices, id: \.self) { index in
        let option = options[index]
        let isOn = option.value == selection
        Button {
          withAnimation(.snappy(duration: 0.2)) { selection = option.value }
        } label: {
          Text(option.title)
            .font(compact ? AppFont.tiny.weight(.black) : AppFont.caption.weight(.black))
            .lineLimit(1)
            .foregroundStyle(isOn ? Palette.ink : Palette.muted)
            .padding(.horizontal, compact ? 10 : 6)
            .padding(.vertical, compact ? 6 : 8)
            .frame(maxWidth: compact ? nil : .infinity)
            .background {
              if isOn {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                  .fill(Palette.surface)
                  .shadow(color: .black.opacity(0.14), radius: 1.5, y: 1)
              }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
      }
    }
    .padding(3)
    .background(
      RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.surface2)
    )
    .fixedSize(horizontal: compact, vertical: false)
  }
}

// MARK: - Box dots

/// Leitner kutusu ilerlemesi: dolu kutular yeşil, kalanlar gri beş küçük kare.
public struct BoxDots: View {
  private let box: Int
  private let maxBox: Int

  /// Kutu numarası ve en yüksek kutuyla gösterge oluşturur.
  public init(box: Int, maxBox: Int = 5) {
    self.box = box
    self.maxBox = maxBox
  }

  public var body: some View {
    HStack(spacing: 3) {
      ForEach(1...max(maxBox, 1), id: \.self) { index in
        RoundedRectangle(cornerRadius: 2)
          .fill(index <= box ? Palette.good : Palette.lineStrong)
          .frame(width: 8, height: 8)
      }
    }
    .accessibilityElement()
    .accessibilityLabel("Kutu \(box)/\(maxBox)")
  }
}

// MARK: - Speaker button

/// Köşeli telaffuz butonu (liste satırları için).
public struct SpeakerButton: View {
  private let word: String
  private let size: CGFloat
  private let action: () -> Void

  /// Kelime, boyut ve eylemle buton oluşturur.
  public init(word: String, size: CGFloat = 34, action: @escaping () -> Void) {
    self.word = word
    self.size = size
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      Image(systemName: "speaker.wave.2.fill")
        .font(.system(size: size * 0.44, weight: .bold))
        .foregroundStyle(Palette.ink)
        .frame(width: size, height: size)
        .background(
          RoundedRectangle(cornerRadius: size * 0.35, style: .continuous).fill(Palette.surface2))
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(word) telaffuzunu dinle")
  }
}
