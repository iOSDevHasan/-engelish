import DesignKit
import PuzzleKit
import SwiftUI

/// Bulmaca teması ekranı: canlı önizleme, temalar, kalem rengi ve kalınlığı.
struct PuzzleThemeView: View {
  @StateObject var viewModel: SettingsViewModel
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    VStack(spacing: 0) {
      NavHeader("Bulmaca teması", onLeading: viewModel.back)
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          preview
          HStack {
            Text("Temalar").font(AppFont.section).foregroundStyle(Palette.ink)
            Spacer()
            Text("Dokun, anında uygulanır").font(AppFont.caption).foregroundStyle(Palette.muted)
          }
          LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10
          ) {
            ForEach(PuzzleTheme.all) { theme in
              Button {
                viewModel.selectTheme(id: theme.id, isPremiumTheme: theme.isPremium)
              } label: {
                ThemeOptionCard(
                  theme: theme, isSelected: theme.id == selected.id,
                  isLocked: theme.isPremium && !viewModel.isPremium)
              }
              .buttonStyle(.plain)
            }
          }
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text("Kalem rengi").font(AppFont.bodyBold)
              Spacer()
              PenColorRow(selection: viewModel.settings.penColor, theme: shown) { id in
                viewModel.update { $0.penColor = id }
              }
            }
            HStack {
              Text("Kalınlık").font(AppFont.bodyBold)
              Spacer()
              Picker(
                "Kalınlık",
                selection: Binding(
                  get: { viewModel.settings.penWidth },
                  set: { value in viewModel.update { $0.penWidth = value } })
              ) {
                ForEach(PenStyle.widths, id: \.value) { Text($0.title).tag($0.value) }
              }
              .pickerStyle(.segmented)
              .frame(width: 190)
            }
          }
          .foregroundStyle(Palette.ink)
          .card(padding: 14)
          if !viewModel.isPremium {
            Button(action: viewModel.openPaywall) {
              OptionRow(isSelected: true) {
                Image(systemName: "crown.fill").foregroundStyle(Palette.accent)
                VStack(alignment: .leading, spacing: 2) {
                  Text("Pastel ve Kareli Defter").font(AppFont.bodyBold).foregroundStyle(
                    Palette.ink)
                  Text("Çengelish+ ile tüm temalar açılır").font(AppFont.caption)
                    .foregroundStyle(Palette.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Palette.muted)
              }
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 30)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
      }
    }
    .screenBackground()
  }

  /// Seçili tema (ayar).
  private var selected: PuzzleTheme { PuzzleTheme.theme(id: viewModel.settings.puzzleTheme) }

  /// Ekranda görünecek tema (koyu mod ve kontrast ayarları uygulanmış).
  private var shown: PuzzleTheme {
    PuzzleTheme.resolve(
      id: selected.id, isDark: scheme == .dark, autoNight: viewModel.settings.autoNightTheme,
      highContrast: viewModel.settings.highContrast)
  }

  private var preview: some View {
    HStack(spacing: 14) {
      PuzzleGridView(
        layout: CrosswordLayout(puzzle: SamplePuzzles.demo), theme: shown, cellSize: 25,
        highlighted: Set(SamplePuzzles.demo.entries[1].cells), active: .init(row: 3, col: 3),
        activeClue: .init(row: 3, col: 0))
      VStack(alignment: .leading, spacing: 6) {
        Eyebrow("Seçili tema")
        Text(shown.name).font(AppFont.headline).foregroundStyle(Palette.ink)
        Text(shown.detail).font(AppFont.caption).foregroundStyle(Palette.muted)
        if shown.id != selected.id {
          Text("Koyu modda Gece teması gösteriliyor").font(AppFont.tiny)
            .foregroundStyle(Palette.muted)
        }
        Pill(selected.isPremium ? "Çengelish+" : "Ücretsiz", systemImage: "checkmark", tone: .good)
      }
      Spacer(minLength: 0)
    }
    .card(padding: 14)
  }
}
