import DesignKit
import PuzzleKit
import SwiftUI

/// İpucu paneli: harf aç, kelimeyi göster ve (Plus değilse) Çengelish Plus tanıtım kartı.
///
/// Hak yetmeyen seçenek pasif görünür; paywall'a sadece tanıtım kartından gidilir.
/// `appBottomSheet` içinde gösterilir; içerik boyuna göre boylanır.
struct HintSheet: View {
  @ObservedObject var viewModel: PuzzleViewModel
  @Environment(\.dismissAppSheet) private var dismiss

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      header
      if let entry = viewModel.selected {
        Text("“\(entry.clue)” kelimesi için:")
          .font(AppFont.caption).foregroundStyle(Palette.muted)
      }
      if !viewModel.canReveal {
        Label("Bu kelimenin tüm harfleri açık.", systemImage: "checkmark.seal.fill")
          .font(AppFont.caption).foregroundStyle(Palette.good)
      }
      option(
        .letter, icon: "eye", title: "Bir harf aç", detail: "Seçili kutunun harfini gösterir")
      option(
        .word, icon: "key.fill", title: "Kelimeyi göster",
        detail: "Kelimenin açılmamış tüm harflerini gösterir")
      if !viewModel.isPremium {
        PlusPromoCard(
          title: isOutOfHints ? "İpucu hakkın bitti" : "Sınırsız ipucu",
          subtitle: "\(PlusBrand.name) ile hak derdi yok, her gün sınırsız ipucu.",
          action: viewModel.openPaywall
        )
        .padding(.top, 4)
      }
      Button("Vazgeç") { dismiss() }
        .buttonStyle(ChunkyButtonStyle(.ghost))
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.top, 8)
    .padding(.bottom, 16)
  }

  private var header: some View {
    HStack {
      Text("İpucu kullan").font(AppFont.headline).foregroundStyle(Palette.ink)
      Spacer()
      Pill(
        viewModel.hintsLeft.map { "\($0) hakkın var" } ?? "Sınırsız",
        systemImage: "lightbulb.fill",
        tone: .gold)
    }
  }

  /// Ücretsiz hak bitti mi (en ucuz ipucuna bile yetmiyor).
  private var isOutOfHints: Bool {
    !viewModel.canAfford(.letter)
  }

  private func option(
    _ kind: HintKind, icon: String, title: String, detail: String
  ) -> some View {
    let affordable = viewModel.canAfford(kind)
    let enabled = affordable && viewModel.canReveal
    return Button {
      viewModel.useHint(kind)
    } label: {
      OptionRow(isSelected: false) {
        Image(systemName: icon).font(.system(size: 20)).foregroundStyle(Palette.accent)
          .frame(width: 28)
        VStack(alignment: .leading, spacing: 2) {
          Text(title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
          Text(affordable ? detail : "Hakkın yetmiyor")
            .font(AppFont.caption).foregroundStyle(affordable ? Palette.muted : Palette.bad)
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 8)
        Pill("\(kind.cost) hak")
      }
    }
    .buttonStyle(PressScaleButtonStyle())
    .disabled(!enabled)
    .opacity(enabled ? 1 : 0.5)
    .accessibilityHint(affordable ? detail : "Hakkın yetmiyor")
  }
}

/// Bulmacadan çıkmadan tema ve kalem rengi seçimi; `appBottomSheet` içinde gösterilir.
struct ThemeSheet: View {
  @ObservedObject var viewModel: PuzzleViewModel
  let theme: PuzzleTheme
  @Environment(\.dismissAppSheet) private var dismiss

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Bulmaca teması").font(AppFont.headline).foregroundStyle(Palette.ink)
        Spacer()
        Button(action: viewModel.openAllThemes) {
          Label("Tüm temalar", systemImage: "chevron.right").labelStyle(TrailingIconLabelStyle())
        }
        .font(AppFont.caption)
        .foregroundStyle(Palette.accent)
      }
      themes
      HStack {
        Text("Kalem rengi").font(AppFont.bodyBold).foregroundStyle(Palette.ink)
        Spacer()
        PenColorRow(
          selection: viewModel.settings.penColor, theme: theme,
          onSelect: viewModel.selectPenColor)
      }
      Text("Yazdıkların silinmez, sadece görünüm değişir.").font(AppFont.tiny)
        .foregroundStyle(Palette.muted)
      Button("Tamam") { dismiss() }.buttonStyle(.chunky)
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.top, 8)
    .padding(.bottom, 16)
  }

  /// Yatay kaydırılan tema kartları; Plus temalarında sağ üstte Plus rozeti.
  ///
  /// Kilitli Plus temasına dokunmak paneli kapatıp paywall'u açar (`selectTheme`).
  private var themes: some View {
    ScrollViewReader { proxy in
      ScrollView(.horizontal) {
        HStack(spacing: 12) {
          ForEach(Array(PuzzleTheme.all.enumerated()), id: \.element.id) { index, option in
            Button {
              viewModel.selectTheme(option)
            } label: {
              ThemeOptionCard(
                theme: option, isSelected: option.id == viewModel.settings.puzzleTheme,
                isLocked: option.isPremium && !viewModel.isPremium, cellSize: 9
              )
              .frame(width: 88)
            }
            .buttonStyle(PressScaleButtonStyle())
            .appearAnimation(index: index)
            .id(option.id)
          }
        }
        // Seçim işareti ve Plus rozeti kartın köşesinden taşar; kırpılmasın diye boşluk bırakılır.
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
      }
      .scrollIndicators(.hidden)
      .padding(.horizontal, -8)
      .onAppear {
        // Tema sayısı arttı; seçili tema görünür olsun diye ona kaydırılır.
        proxy.scrollTo(viewModel.settings.puzzleTheme, anchor: .center)
      }
    }
  }
}
