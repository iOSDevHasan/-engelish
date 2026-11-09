import DesignKit
import PuzzleKit
import SwiftUI
import UserDataKit

/// Uygulama görünümü: Sistem / Açık / Koyu ve bulmaca temasına geçiş.
struct AppearanceView: View {
  @StateObject var viewModel: SettingsViewModel
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    VStack(spacing: 0) {
      NavHeader("Görünüm", onLeading: viewModel.back)
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          Text("Uygulama görünümü").font(AppFont.section).foregroundStyle(Palette.ink)
          HStack(spacing: 10) {
            ForEach(Appearance.allCases, id: \.self) { option in
              Button {
                viewModel.update { $0.appearance = option }
              } label: {
                AppearanceTile(option: option, isOn: viewModel.settings.appearance == option)
              }
              .buttonStyle(.plain)
            }
          }
          Text(
            "Menüler, kartlar ve tab bar bu ayarı izler. Bulmaca ızgarası kendi temasını kullanır."
          )
          .font(AppFont.tiny).foregroundStyle(Palette.muted)
          Text("Bulmaca").font(AppFont.section).foregroundStyle(Palette.ink).padding(.top, 4)
          Button(action: viewModel.openPuzzleTheme) {
            HStack(spacing: 14) {
              MiniGridView(puzzle: SamplePuzzles.demo, theme: currentTheme, cellSize: 13)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 12).fill(Palette.surface2))
              VStack(alignment: .leading, spacing: 3) {
                Eyebrow("Bulmaca teması")
                Text(currentTheme.name).font(AppFont.headline).foregroundStyle(Palette.ink)
                Text("6 tema · kalem rengi ve kalınlığı").font(AppFont.caption)
                  .foregroundStyle(Palette.muted)
              }
              Spacer()
              Image(systemName: "chevron.right").foregroundStyle(Palette.lineStrong)
            }
            .card(padding: 12)
          }
          .buttonStyle(.plain)
          SettingsGroup {
            SettingsRow("moon", "Koyu modda Gece teması") {
              Toggle(
                "",
                isOn: Binding(
                  get: { viewModel.settings.autoNightTheme },
                  set: { on in viewModel.update { $0.autoNightTheme = on } })
              )
              .labelsHidden().tint(Palette.good)
            }
            SettingsRow("eye", "Yüksek kontrast ızgara") {
              Toggle(
                "",
                isOn: Binding(
                  get: { viewModel.settings.highContrast },
                  set: { on in viewModel.update { $0.highContrast = on } })
              )
              .labelsHidden().tint(Palette.good)
            }
          }
        }
        .padding(.horizontal, Metrics.gutter)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
      }
    }
    .screenBackground()
  }

  private var currentTheme: PuzzleTheme {
    PuzzleTheme.resolve(
      id: viewModel.settings.puzzleTheme, isDark: scheme == .dark,
      autoNight: viewModel.settings.autoNightTheme, highContrast: viewModel.settings.highContrast)
  }
}

/// Görünüm seçeneği kutucuğu.
private struct AppearanceTile: View {
  let option: Appearance
  let isOn: Bool

  var body: some View {
    VStack(spacing: 6) {
      RoundedRectangle(cornerRadius: 16)
        .fill(fill)
        .frame(height: 62)
        .overlay(alignment: .topLeading) {
          VStack(alignment: .leading, spacing: 7) {
            ForEach(0..<3, id: \.self) { _ in
              Capsule().fill(lineColor.opacity(0.35)).frame(width: 46, height: 7)
            }
          }
          .padding(10)
        }
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .strokeBorder(isOn ? Palette.accent : Palette.lineStrong, lineWidth: isOn ? 3 : 2))
      Text(option.title).font(AppFont.caption.weight(.black)).foregroundStyle(Palette.ink)
    }
    .frame(maxWidth: .infinity)
    .accessibilityAddTraits(isOn ? .isSelected : [])
  }

  private var fill: AnyShapeStyle {
    switch option {
    case .light: AnyShapeStyle(Color(hex: 0xFFF8EE))
    case .dark: AnyShapeStyle(Color(hex: 0x121027))
    case .system:
      AnyShapeStyle(
        LinearGradient(
          stops: [
            .init(color: Color(hex: 0xFFF8EE), location: 0.5),
            .init(color: Color(hex: 0x121027), location: 0.5),
          ],
          startPoint: .leading, endPoint: .trailing))
    }
  }

  private var lineColor: Color {
    option == .dark ? .white : Color(hex: 0x24204D)
  }
}
