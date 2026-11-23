import DesignKit
import SwiftUI

/// "Tüm verileri sil" onay paneli: neyin silineceğini anlatır, onay ya da vazgeç.
///
/// `appBottomSheet` içinde gösterilir. Onaylanınca `onConfirm` çağrılır ve panel kapanır;
/// silme işini panelin sahibi, kapanış bittikten sonra yapar.
struct DeleteDataSheet: View {
  /// Kullanıcı silmeyi onayladı.
  let onConfirm: @MainActor () -> Void
  @Environment(\.dismissAppSheet) private var dismissAppSheet

  /// Silinecek veriler (ikon, metin).
  private static let erased: [(icon: String, text: String)] = [
    ("person.crop.circle", "Profilin, fotoğrafın ve takma adın"),
    ("square.grid.3x3", "Bulmaca ilerlemen ve el yazısı çizimlerin"),
    ("book.closed", "Kelime Defterin"),
    ("medal", "Rozetlerin, serin ve sayaçların"),
    ("gearshape", "Ayarların"),
  ]

  var body: some View {
    VStack(spacing: 18) {
      warningIcon
      VStack(spacing: 6) {
        Text("Tüm veriler silinsin mi?")
          .font(AppFont.headline)
          .foregroundStyle(Palette.ink)
        Text("Bu işlem geri alınamaz. Uygulama baştan başlar ve tanışma adımları yeniden açılır.")
          .font(AppFont.caption)
          .foregroundStyle(Palette.muted)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
      erasedList
      purchasesNote
      VStack(spacing: 10) {
        Button {
          onConfirm()
          dismissAppSheet()
        } label: {
          Label("Tüm verileri sil", systemImage: "trash.fill")
        }
        .buttonStyle(DestructiveButtonStyle())
        Button("Vazgeç") { dismissAppSheet() }
          .buttonStyle(ChunkyButtonStyle(.ghost))
      }
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.top, 12)
    .padding(.bottom, 20)
  }

  // MARK: - Subviews

  private var warningIcon: some View {
    Image(systemName: "exclamationmark.triangle.fill")
      .font(.system(size: 30, weight: .bold))
      .foregroundStyle(Palette.bad)
      .frame(width: 64, height: 64)
      .background(Circle().fill(Palette.badBackground))
      .accessibilityHidden(true)
  }

  private var erasedList: some View {
    VStack(alignment: .leading, spacing: 10) {
      ForEach(Self.erased, id: \.text) { item in
        HStack(spacing: 12) {
          Image(systemName: item.icon)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Palette.bad)
            .frame(width: 22)
          Text(item.text)
            .font(AppFont.body)
            .foregroundStyle(Palette.ink)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .card(padding: 14)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Silinecekler: \(Self.erased.map(\.text).joined(separator: ", "))")
  }

  private var purchasesNote: some View {
    Label {
      Text(
        "Satın alımların silinmez; App Store'da Apple Kimliğine bağlıdır ve "
          + "\"Satın alımları geri yükle\" ile geri gelir."
      )
      .fixedSize(horizontal: false, vertical: true)
    } icon: {
      Image(systemName: "checkmark.seal.fill").foregroundStyle(Palette.good)
    }
    .font(AppFont.caption)
    .foregroundStyle(Palette.muted)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// Kırmızı dolgulu, alt gölgesi basınca kaybolan yıkıcı eylem butonu (`.chunky` ile aynı biçim).
private struct DestructiveButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    let pressed = configuration.isPressed
    return configuration.label
      .font(AppFont.bodyBold)
      .foregroundStyle(.white)
      .padding(.horizontal, 20)
      .frame(maxWidth: .infinity, minHeight: 52)
      .background(
        RoundedRectangle(cornerRadius: Metrics.buttonRadius, style: .continuous)
          .fill(Palette.bad)
          .shadow(color: Color(hex: 0xC23A3F), radius: 0, y: pressed ? 0 : 4)
      )
      .offset(y: pressed ? 4 : 0)
      .animation(.spring(duration: 0.18), value: pressed)
      .contentShape(Rectangle())
  }
}
