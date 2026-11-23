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
///
/// Seçili bölmenin beyaz zemini seçim değişince yaylanarak kayar ve hafif dokunsal geri bildirim
/// verilir.
public struct SegmentBar<Value: Hashable>: View {
  private let options: [(value: Value, title: String)]
  @Binding private var selection: Value
  private let compact: Bool
  @Namespace private var namespace

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
        segment(options[index])
      }
    }
    .padding(3)
    .background(
      RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.surface2)
    )
    .fixedSize(horizontal: compact, vertical: false)
    .sensoryFeedback(.selection, trigger: selection)
  }

  /// Tek bir bölme butonu.
  private func segment(_ option: (value: Value, title: String)) -> some View {
    let isOn = option.value == selection
    return Button {
      withAnimation(Motion.snappy) { selection = option.value }
    } label: {
      Text(option.title)
        .font(compact ? AppFont.tiny.weight(.black) : AppFont.caption.weight(.black))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .foregroundStyle(isOn ? Palette.ink : Palette.muted)
        .padding(.horizontal, compact ? 10 : 6)
        .padding(.vertical, compact ? 6 : 8)
        .frame(maxWidth: compact ? nil : .infinity)
        .background {
          if isOn {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
              .fill(Palette.surface)
              .shadow(color: .black.opacity(0.14), radius: 1.5, y: 1)
              .matchedGeometryEffect(id: "selection", in: namespace)
          }
        }
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isOn ? .isSelected : [])
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

/// Telaffuz butonu: köşeli (liste satırları) ya da yuvarlak (panel, kart) görünümde.
///
/// Dokununca simge zıplar, buton hafifçe küçülür ve hafif dokunsal geri bildirim verilir.
public struct SpeakerButton: View {
  private let word: String
  private let size: CGFloat
  private let isRound: Bool
  private let accent: Bool
  private let label: String?
  private let action: () -> Void
  @State private var taps = 0

  /// Kelime, boyut, şekil ve eylemle buton oluşturur.
  ///
  /// - Parameters:
  ///   - isRound: `true` ise `IconCircle` görünümünde yuvarlak buton.
  ///   - accent: Yuvarlak butonda mor dolgu.
  ///   - label: Erişilebilirlik etiketi; verilmezse "<kelime> telaffuzunu dinle".
  public init(
    word: String, size: CGFloat = 34, isRound: Bool = false, accent: Bool = false,
    label: String? = nil, action: @escaping () -> Void
  ) {
    self.word = word
    self.size = size
    self.isRound = isRound
    self.accent = accent
    self.label = label
    self.action = action
  }

  public var body: some View {
    Button {
      taps += 1
      action()
    } label: {
      icon
        .symbolEffect(.bounce, value: taps)
        .contentShape(Rectangle())
    }
    .buttonStyle(PressScaleButtonStyle())
    .sensoryFeedback(.impact(flexibility: .soft), trigger: taps)
    .accessibilityLabel(label ?? "\(word) telaffuzunu dinle")
  }

  /// Butonun şekline göre simge.
  @ViewBuilder
  private var icon: some View {
    if isRound {
      IconCircle("speaker.wave.2.fill", size: size, accent: accent)
    } else {
      Image(systemName: "speaker.wave.2.fill")
        .font(.system(size: size * 0.44, weight: .bold))
        .foregroundStyle(Palette.ink)
        .frame(width: size, height: size)
        .background(
          RoundedRectangle(cornerRadius: size * 0.35, style: .continuous).fill(Palette.surface2))
    }
  }
}
