import DesignKit
import SwiftUI

/// Aylık seri takvimi kartı: çözülen günler, bugün, ay gezinmesi ve seri dondurma bilgisi.
struct StreakCalendarCard: View {
  @ObservedObject var viewModel: ProfileViewModel

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

  var body: some View {
    let month = viewModel.month
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 6) {
        Text("Seri takvimi").font(AppFont.bodyBold).foregroundStyle(Palette.ink)
        Spacer()
        monthButton("chevron.left", label: "Önceki ay", enabled: viewModel.canShowPreviousMonth) {
          viewModel.shiftMonth(by: -1)
        }
        Text(month.title).font(AppFont.caption).foregroundStyle(Palette.ink)
          .frame(minWidth: 86)
        monthButton("chevron.right", label: "Sonraki ay", enabled: viewModel.canShowNextMonth) {
          viewModel.shiftMonth(by: 1)
        }
      }
      LazyVGrid(columns: columns, spacing: 4) {
        ForEach(StreakMonth.weekdays, id: \.self) { name in
          Text(name).font(AppFont.rounded(10, weight: .heavy)).foregroundStyle(Palette.muted)
        }
        ForEach(0..<month.leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 32) }
        ForEach(month.days) { day in cell(day) }
      }
      HStack(spacing: 6) {
        Image(systemName: "flame.fill").foregroundStyle(Palette.streak)
        Text(
          "Bu ay \(month.solvedCount) gün çözdün · En uzun seri \(viewModel.stats.longestStreak)"
        )
        .foregroundStyle(Palette.muted)
      }
      .font(AppFont.caption)
      freezeRow
    }
    .padding(.vertical, 14)
    .padding(.horizontal, 16)
    .card(padding: 0)
  }

  // MARK: - Subviews

  private func monthButton(
    _ symbol: String, label: String, enabled: Bool, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(systemName: symbol).font(.system(size: 12, weight: .heavy))
        .frame(width: 28, height: 28)
        .background(Circle().fill(Palette.surface2))
    }
    .buttonStyle(.plain)
    .foregroundStyle(enabled ? Palette.ink : Palette.lineStrong)
    .disabled(!enabled)
    .accessibilityLabel(label)
  }

  private func cell(_ day: StreakDay) -> some View {
    ZStack {
      switch day.state {
      case .solved:
        Circle().fill(Palette.streak)
      case .frozen:
        Circle().fill(Palette.pastels[1])
      case .missed, .future:
        Circle().fill(Color.clear)
      }
      if day.state == .frozen {
        Image(systemName: "snowflake").font(.system(size: 12, weight: .bold))
          .foregroundStyle(Color(hex: 0x3C9BE0))
      } else {
        Text("\(day.day)")
          .font(AppFont.rounded(12, weight: .heavy))
          .foregroundStyle(foreground(day))
      }
    }
    .frame(height: 32)
    .overlay(Circle().strokeBorder(day.isToday ? Palette.accent : .clear, lineWidth: 2))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibility(day))
  }

  @ViewBuilder
  private var freezeRow: some View {
    if viewModel.isPremium {
      HStack(spacing: 6) {
        Image(systemName: "snowflake").foregroundStyle(Color(hex: 0x3C9BE0))
        Text(viewModel.freezeText).foregroundStyle(Palette.muted)
      }
      .font(AppFont.caption)
    } else {
      Button(action: viewModel.openPaywall) {
        HStack(spacing: 6) {
          Image(systemName: "snowflake")
          Text("Seri dondurma Çengelish+ ile")
          Image(systemName: "chevron.right").imageScale(.small)
        }
        .font(AppFont.caption)
        .foregroundStyle(Palette.accent)
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - Helpers

  private func foreground(_ day: StreakDay) -> Color {
    switch day.state {
    case .solved: .white
    case .future: Palette.lineStrong
    case .missed, .frozen: Palette.muted
    }
  }

  private func accessibility(_ day: StreakDay) -> String {
    let state =
      switch day.state {
      case .solved: "çözüldü"
      case .frozen: "seri donduruldu"
      case .missed: "çözülmedi"
      case .future: ""
      }
    return "\(day.day). gün\(day.isToday ? ", bugün" : "")\(state.isEmpty ? "" : ", \(state)")"
  }
}
