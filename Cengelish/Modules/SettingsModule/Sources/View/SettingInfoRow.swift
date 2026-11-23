import DesignKit
import SwiftUI

/// Başlığına dokununca ayarın ne yaptığını balonla (popover) anlatan ayar satırı.
///
/// Başlık bölümü balonu açar; sağdaki kontrol (anahtar, seçici) eskisi gibi çalışır. `action`
/// verilirse başlığın sağındaki alan (değer ve ok) o eylemi tetikler.
struct SettingInfoRow<Accessory: View>: View {
  private let systemImage: String
  private let title: String
  private let info: String
  private let tint: Color
  private let action: (() -> Void)?
  private let accessory: Accessory
  @State private var isInfoShown = false

  /// İkon, başlık, açıklama, renk, isteğe bağlı eylem ve sağ içerikle satır oluşturur.
  init(
    _ systemImage: String, _ title: String, info: String, tint: Color = Palette.ink,
    action: (() -> Void)? = nil, @ViewBuilder accessory: () -> Accessory
  ) {
    self.systemImage = systemImage
    self.title = title
    self.info = info
    self.tint = tint
    self.action = action
    self.accessory = accessory()
  }

  var body: some View {
    HStack(spacing: 12) {
      // Başlık önce yer alır; sağdaki değer/ok kalan alana sığar.
      titleButton.layoutPriority(1)
      if let action {
        Button(action: action) {
          HStack(spacing: 0) {
            Spacer(minLength: 8)
            accessory
          }
          .frame(maxHeight: .infinity)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
      } else {
        Spacer(minLength: 8)
        accessory
      }
    }
    .foregroundStyle(tint)
    .frame(minHeight: 48)
    .overlay(alignment: .bottom) { Rectangle().fill(Palette.line).frame(height: 1) }
  }

  /// İkon + başlık + küçük bilgi işareti; dokununca açıklama balonu.
  private var titleButton: some View {
    Button {
      isInfoShown.toggle()
    } label: {
      HStack(spacing: 12) {
        Image(systemName: systemImage)
          .font(.system(size: 17, weight: .semibold))
          .frame(width: 24)
        HStack(spacing: 5) {
          Text(title)
            .font(AppFont.body)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
          Image(systemName: "info.circle")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Palette.muted.opacity(isInfoShown ? 1 : 0.6))
            .symbolEffect(.bounce, value: isInfoShown)
        }
      }
      .frame(minHeight: 48)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
    .accessibilityHint("Ayarın ne yaptığını anlatır")
    .popover(isPresented: $isInfoShown, arrowEdge: .bottom) {
      SettingInfoBubble(systemImage: systemImage, title: title, info: info)
        .presentationCompactAdaptation(.popover)
    }
  }
}

/// Açıklama balonunun içeriği.
struct SettingInfoBubble: View {
  let systemImage: String
  let title: String
  let info: String

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Label(title, systemImage: systemImage)
        .font(AppFont.bodyBold)
        .foregroundStyle(Palette.accent)
      Text(info)
        .font(AppFont.rounded(14, weight: .semibold))
        .foregroundStyle(Palette.ink)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(16)
    .frame(width: 280, alignment: .leading)
    .presentationBackground(Palette.surface)
    .accessibilityElement(children: .combine)
  }
}

/// Ayar satırlarının açıklamaları (Türkçe, 1–2 cümle).
enum SettingInfo {
  /// iCloud yedekleme.
  static let iCloud =
    """
    Profilin, ilerlemen ve defterin iCloud'a yedeklenir; aynı Apple Kimliği'yle açtığın iPhone ve \
    iPad'in arasında senkron kalır. Değişiklik uygulamayı yeniden açınca geçerli olur.
    """
  /// Veri ve yedekleme ekranı.
  static let data =
    """
    Verilerinin cihazda ne kadar yer kapladığını gösterir. Tüm verileri silip uygulamayı baştan \
    başlatmak da buradadır.
    """
  /// Uygulama görünümü.
  static let appearance =
    """
    Menülerin ve kartların açık, koyu ya da cihaz ayarına uyan görünümde olmasını seçer. Bulmaca \
    ızgarası kendi temasını kullanır.
    """
  /// Bulmaca teması.
  static let puzzleTheme =
    """
    Bulmaca ızgarasının renklerini, kalem rengini ve kalınlığını belirler. Bazı temalar \
    \(PlusBrand.name) ile açılır.
    """
  /// Sol el modu.
  static let leftHanded =
    """
    Bulmaca ekranındaki kalem araç çubuğunu ters sıraya dizer; sık kullanılan araçlar sol eline \
    yakın durur.
    """
  /// Otomatik sonraki kutu.
  static let autoAdvance =
    """
    Bir kutuya yazdıktan kısa süre sonra seçim, kelimenin bir sonraki kutusuna kendiliğinden \
    geçer.
    """
  /// Sadece Apple Pencil.
  static let pencilOnly =
    """
    Kutulara yalnızca Apple Pencil ile yazılır; parmağın kaydırma ve yakınlaştırma için serbest \
    kalır. Elini ekrana dayayınca istemeden çizgi oluşmaz.
    """
  /// Telaffuz aksanı.
  static let accent =
    """
    Kelimelerin sesli okunuşunda Amerikan ya da İngiliz aksanını seçer. Kelime kartlarındaki \
    okunuş (IPA) da bu seçime uyar.
    """
  /// Günün bulmacası hatırlatıcısı.
  static let reminder =
    """
    Her gün seçtiğin saatte Günün Bulmacası için bildirim gönderir. Serin tehlikedeyse akşam bir \
    hatırlatma daha gelir.
    """
  /// Hatırlatıcı saati.
  static let reminderTime = "Günün Bulmacası bildiriminin her gün geleceği saat."
  /// Çengelish Plus (Plus kullanıcısı).
  static let plus =
    """
    \(PlusBrand.name)'ı ömür boyu aldın; yenileme ya da iptal yok; tarih satın alma \
    günüdür. Dokununca Plus ile açık olanları görürsün.
    """
  /// Koyu modda Gece teması.
  static let autoNight =
    """
    Cihaz koyu moddayken kendi koyu görünümü olmayan temaların yerine gözü yormayan Gece teması \
    kullanılır.
    """
  /// Yüksek kontrast ızgara.
  static let highContrast =
    """
    Izgarayı siyah-beyaz yapıp çizgileri ve harfleri belirginleştirir; az ışıkta ya da görme \
    güçlüğünde okumayı kolaylaştırır. Açıkken tema görünmez; bir tema seçince kapanır.
    """

  /// Tüm açıklamalar (test için).
  static let all = [
    iCloud, data, appearance, puzzleTheme, leftHanded, autoAdvance, pencilOnly, accent, reminder,
    reminderTime, plus, autoNight, highContrast,
  ]
}
