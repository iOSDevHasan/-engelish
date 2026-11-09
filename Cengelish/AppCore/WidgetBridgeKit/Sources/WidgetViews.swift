import DesignKit
import SwiftUI
import WidgetKit

// MARK: - Word of the day (small)

/// Küçük widget: günün kelimesi, anlamı ve telaffuzu.
public struct WordOfDayWidgetView: View {
  /// Gösterilen girdi.
  let entry: CengelishEntry

  /// Görünümü oluşturur.
  public init(entry: CengelishEntry) {
    self.entry = entry
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      WidgetEyebrow(text: "Günün kelimesi")
      Spacer(minLength: 0)
      if let word = entry.word {
        Text(word.en)
          .font(.system(size: 24, weight: .black, design: .rounded))
          .foregroundStyle(Palette.ink)
          .minimumScaleFactor(0.6)
          .lineLimit(1)
          .widgetAccentable()
        Text(word.meaning)
          .font(AppFont.caption)
          .foregroundStyle(Palette.muted)
          .lineLimit(2)
        Spacer(minLength: 0)
        Label(word.ipa, systemImage: "speaker.wave.2.fill")
          .font(AppFont.tiny)
          .foregroundStyle(Palette.accent)
          .lineLimit(1)
      } else {
        Text("Bugünün kelimesi uygulamayı açınca gelir.")
          .font(AppFont.caption)
          .foregroundStyle(Palette.muted)
        Spacer(minLength: 0)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .containerBackground(for: .widget) { Palette.surface }
    .widgetURL(WidgetShared.homeURL)
  }
}

// MARK: - Streak (small)

/// Küçük widget: seri, bugünkü hedef ve haftalık şerit.
public struct StreakWidgetView: View {
  /// Gösterilen girdi.
  let entry: CengelishEntry

  /// Görünümü oluşturur.
  public init(entry: CengelishEntry) {
    self.entry = entry
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack {
        Image(systemName: "flame.fill")
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(Palette.streak)
          .widgetAccentable()
        Spacer()
        AvatarView(entry.snapshot.avatar, size: 28)
      }
      Spacer(minLength: 0)
      Text("\(entry.streak)")
        .font(.system(size: 46, weight: .black, design: .rounded))
        .foregroundStyle(Palette.ink)
        .contentTransition(.numericText())
        .widgetAccentable()
      Text("gün seri · bugün \(entry.solvedToday)/\(entry.snapshot.dailyGoal)")
        .font(AppFont.tiny)
        .foregroundStyle(Palette.muted)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
      WeekStrip(slots: entry.snapshot.week(containing: entry.day))
        .padding(.top, 6)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .containerBackground(for: .widget) { Palette.surface }
    .widgetURL(WidgetShared.homeURL)
  }
}

/// Haftanın yedi gününü gösteren ince şerit.
struct WeekStrip: View {
  /// Günler (Pazartesi–Pazar).
  let slots: [WidgetSnapshot.WeekSlot]

  var body: some View {
    HStack(spacing: 3) {
      ForEach(slots, id: \.day) { slot in
        Capsule()
          .fill(slot.isSolved ? Palette.streak : Palette.line)
          .frame(height: 6)
          .overlay {
            if slot.isToday && !slot.isSolved {
              Capsule().strokeBorder(Palette.streak, lineWidth: 1)
            }
          }
          .widgetAccentable(slot.isSolved)
      }
    }
  }
}

// MARK: - Daily puzzle (medium)

/// Orta widget: günün bulmacası, ilerleme ve küçük ızgara.
public struct DailyPuzzleWidgetView: View {
  /// Gösterilen girdi.
  let entry: CengelishEntry

  /// Görünümü oluşturur.
  public init(entry: CengelishEntry) {
    self.entry = entry
  }

  public var body: some View {
    HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 4) {
        WidgetEyebrow(text: "Günün Bulmacası")
        Text(title)
          .font(.system(size: 20, weight: .black, design: .rounded))
          .foregroundStyle(Palette.ink)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
          .widgetAccentable()
        if let puzzle = entry.puzzle {
          Text("\(puzzle.wordCount) kelime · ~\(puzzle.minutes) dk")
            .font(AppFont.caption)
            .foregroundStyle(Palette.muted)
          Spacer(minLength: 0)
          WidgetProgressBar(value: puzzle.isFinished ? 1 : puzzle.progress)
          Text(statusText(puzzle))
            .font(AppFont.tiny)
            .foregroundStyle(puzzle.isFinished ? Palette.good : Palette.muted)
        } else {
          Text("Yeni bulmaca için uygulamayı aç.")
            .font(AppFont.caption)
            .foregroundStyle(Palette.muted)
          Spacer(minLength: 0)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      if let puzzle = entry.puzzle {
        WidgetMiniGrid(rows: puzzle.grid, cell: 19)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .containerBackground(for: .widget) { Palette.surface }
    .widgetURL(WidgetShared.dailyURL)
  }

  /// "8 Kasım · B1".
  private var title: String {
    let date = WidgetDay.date(from: entry.day) ?? entry.date
    guard let puzzle = entry.puzzle else { return DateText.dayMonth(date) }
    return "\(DateText.dayMonth(date)) · \(puzzle.level)"
  }

  /// İlerleme açıklaması.
  private func statusText(_ puzzle: WidgetSnapshot.PuzzleInfo) -> String {
    if puzzle.isFinished { return "Tamamlandı ✓" }
    if puzzle.progress <= 0 { return "Henüz başlanmadı" }
    return "%\(Int((puzzle.progress * 100).rounded())) tamamlandı"
  }
}

/// İnce ilerleme çubuğu.
struct WidgetProgressBar: View {
  /// 0...1 arası değer.
  let value: Double

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .leading) {
        Capsule().fill(Palette.line)
        Capsule()
          .fill(Palette.accent)
          .frame(width: proxy.size.width * min(max(value, 0), 1))
          .widgetAccentable()
      }
    }
    .frame(height: 8)
  }
}

/// Anlık görüntüdeki satırlardan çizilen küçük ızgara.
struct WidgetMiniGrid: View {
  /// Satırlar (`#` ipucu, `.` boş, `x` dolu, ` ` boşluk).
  let rows: [String]
  /// Kutu boyu.
  let cell: CGFloat

  var body: some View {
    VStack(spacing: 2) {
      ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
        HStack(spacing: 2) {
          ForEach(Array(row.enumerated()), id: \.offset) { _, kind in
            RoundedRectangle(cornerRadius: 4, style: .continuous)
              .fill(color(for: kind))
              .frame(width: cell, height: cell)
          }
        }
      }
    }
    .widgetAccentable()
  }

  /// Kutu türünün rengi.
  private func color(for kind: Character) -> Color {
    switch kind {
    case "#": Palette.accent
    case "x": Palette.good
    case ".": Palette.surface2
    default: .clear
    }
  }
}

/// Widget başlık etiketi.
struct WidgetEyebrow: View {
  /// Metin.
  let text: String

  var body: some View {
    Text(text.uppercased(with: Locale(identifier: "tr_TR")))
      .font(AppFont.eyebrow)
      .tracking(0.6)
      .foregroundStyle(Palette.accent)
      .widgetAccentable()
  }
}

// MARK: - Lock Screen

/// Kilit ekranı yuvarlak widget: alev ve seri.
public struct LockStreakWidgetView: View {
  /// Gösterilen girdi.
  let entry: CengelishEntry

  /// Görünümü oluşturur.
  public init(entry: CengelishEntry) {
    self.entry = entry
  }

  public var body: some View {
    ZStack {
      AccessoryWidgetBackground()
      VStack(spacing: 0) {
        Image(systemName: "flame.fill")
          .font(.system(size: 16, weight: .bold))
          .widgetAccentable()
        Text("\(entry.streak)")
          .font(.system(size: 20, weight: .black, design: .rounded))
          .minimumScaleFactor(0.6)
      }
    }
    .containerBackground(for: .widget) {}
    .widgetURL(WidgetShared.homeURL)
  }
}

/// Kilit ekranı dikdörtgen widget: günün kelimesi.
public struct LockWordWidgetView: View {
  /// Gösterilen girdi.
  let entry: CengelishEntry

  /// Görünümü oluşturur.
  public init(entry: CengelishEntry) {
    self.entry = entry
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(entry.word?.en ?? "Çengelish")
        .font(.system(size: 19, weight: .bold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .widgetAccentable()
      Text(caption)
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .lineLimit(2)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .containerBackground(for: .widget) {}
    .widgetURL(WidgetShared.homeURL)
  }

  /// "titiz, eksiksiz · Günün kelimesi".
  private var caption: String {
    guard let word = entry.word else { return "Günün kelimesi" }
    return "\(word.meaning) · Günün kelimesi"
  }
}
