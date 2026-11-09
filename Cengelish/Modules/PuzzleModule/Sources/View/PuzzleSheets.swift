import DesignKit
import PuzzleKit
import SwiftUI

/// İpucu paneli: harf aç, kelimeyi göster, Çengelish+.
struct HintSheet: View {
  @ObservedObject var viewModel: PuzzleViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("İpucu kullan").font(AppFont.headline).foregroundStyle(Palette.ink)
        Spacer()
        Pill(
          viewModel.hintsLeft.map { "\($0) hakkın var" } ?? "Sınırsız",
          systemImage: "lightbulb.fill",
          tone: .gold)
      }
      if let entry = viewModel.selected {
        Text("“\(entry.clue)” kelimesi için:").font(AppFont.caption).foregroundStyle(Palette.muted)
      }
      option("eye", "Bir harf aç", "Seçili kutunun harfini gösterir", cost: HintKind.letter.cost) {
        viewModel.useHint(.letter)
      }
      option(
        "key.fill", "Kelimeyi göster", "Kelimenin tüm harflerini gösterir", cost: HintKind.word.cost
      ) {
        viewModel.useHint(.word)
      }
      if !viewModel.isPremium {
        Button(action: viewModel.openPaywall) {
          OptionRow(isSelected: true) {
            Image(systemName: "crown.fill").font(.system(size: 20)).foregroundStyle(Palette.accent)
            VStack(alignment: .leading, spacing: 2) {
              Text("Sınırsız ipucu").font(AppFont.bodyBold).foregroundStyle(Palette.ink)
              Text("Çengelish+ ile hak derdi yok").font(AppFont.caption).foregroundStyle(
                Palette.muted)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Palette.muted)
          }
        }
        .buttonStyle(.plain)
      }
      Button("Vazgeç") { viewModel.isHintSheetPresented = false }
        .buttonStyle(ChunkyButtonStyle(.ghost))
    }
    .padding(20)
    .presentationDetents([.height(420)])
    .presentationDragIndicator(.visible)
    .presentationBackground(Palette.surface)
  }

  private func option(
    _ icon: String, _ title: String, _ detail: String, cost: Int, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      OptionRow(isSelected: false) {
        Image(systemName: icon).font(.system(size: 20)).foregroundStyle(Palette.accent).frame(
          width: 28)
        VStack(alignment: .leading, spacing: 2) {
          Text(title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
          Text(detail).font(AppFont.caption).foregroundStyle(Palette.muted)
        }
        Spacer()
        Pill("\(cost) hak")
      }
    }
    .buttonStyle(.plain)
  }
}

/// Bulmacadan çıkmadan tema ve kalem rengi seçimi.
struct ThemeSheet: View {
  @ObservedObject var viewModel: PuzzleViewModel
  let theme: PuzzleTheme

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text("Bulmaca teması").font(AppFont.headline).foregroundStyle(Palette.ink)
        Spacer()
        Button(action: viewModel.openAllThemes) {
          Label("Tüm temalar", systemImage: "chevron.right").labelStyle(TrailingIconLabelStyle())
        }
        .font(AppFont.caption)
        .foregroundStyle(Palette.accent)
      }
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 10) {
          ForEach(PuzzleTheme.all) { option in
            Button {
              viewModel.selectTheme(option)
            } label: {
              ThemeOptionCard(
                theme: option, isSelected: option.id == viewModel.settings.puzzleTheme,
                isLocked: option.isPremium && !viewModel.isPremium, cellSize: 9
              )
              .frame(width: 84)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
      }
      HStack {
        Text("Kalem rengi").font(AppFont.bodyBold).foregroundStyle(Palette.ink)
        Spacer()
        PenColorRow(
          selection: viewModel.settings.penColor, theme: theme, onSelect: viewModel.selectPenColor)
      }
      Text("Yazdıkların silinmez, sadece görünüm değişir.").font(AppFont.tiny)
        .foregroundStyle(Palette.muted)
      Button("Tamam") { viewModel.isThemeSheetPresented = false }.buttonStyle(.chunky)
    }
    .padding(20)
    .presentationDetents([.height(360)])
    .presentationDragIndicator(.visible)
    .presentationBackground(Palette.surface)
  }
}
