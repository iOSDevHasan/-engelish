import DesignKit
import PuzzleKit
import StoreKit
import SwiftUI
import UserDataKit

/// Ayarlar listesi.
struct SettingsView: View {
  @StateObject var viewModel: SettingsViewModel

  var body: some View {
    VStack(spacing: 0) {
      NavHeader("Ayarlar", onLeading: viewModel.back)
      ScrollView {
        VStack(spacing: 16) {
          plusSection.appearAnimation(index: 0)
          SettingsGroup("Veriler") {
            SettingInfoRow("icloud", "iCloud yedekleme", info: SettingInfo.iCloud) {
              Toggle(
                "iCloud yedekleme",
                isOn: Binding(get: { viewModel.iCloudOn }, set: viewModel.setICloud)
              )
              .labelsHidden().tint(Palette.good)
            }
            SettingInfoRow(
              "externaldrive", "Veri ve yedekleme", info: SettingInfo.data,
              action: viewModel.openData
            ) {
              DisclosureValue(viewModel.format(bytes: viewModel.usage.total))
            }
          }
          .appearAnimation(index: 1)
          SettingsGroup("Görünüm") {
            SettingInfoRow(
              "circle.lefthalf.filled", "Uygulama görünümü", info: SettingInfo.appearance,
              action: viewModel.openAppearance
            ) {
              DisclosureValue(viewModel.settings.appearance.title)
            }
            SettingInfoRow(
              "paintpalette", "Bulmaca teması", info: SettingInfo.puzzleTheme,
              action: viewModel.openPuzzleTheme
            ) {
              DisclosureValue(PuzzleTheme.theme(id: viewModel.settings.puzzleTheme).name)
            }
          }
          .appearAnimation(index: 2)
          SettingsGroup("Oyun") {
            toggleRow("hand.raised", "Sol el modu", SettingInfo.leftHanded, \.leftHanded)
            toggleRow(
              "arrow.right.square", "Otomatik sonraki kutu", SettingInfo.autoAdvance,
              \.autoAdvance)
            toggleRow(
              "applepencil", "Sadece Apple Pencil ile yaz", SettingInfo.pencilOnly, \.pencilOnly)
            SettingInfoRow("speaker.wave.2", "Telaffuz aksanı", info: SettingInfo.accent) {
              // Diğer satırların değer yazısıyla aynı görünen açılır menü.
              Menu {
                Picker("Telaffuz aksanı", selection: binding(\.accent)) {
                  ForEach(SpeechAccent.allCases, id: \.self) { Text($0.title).tag($0) }
                }
              } label: {
                HStack(spacing: 6) {
                  Text(viewModel.settings.accent.title)
                    .font(AppFont.caption).foregroundStyle(Palette.muted)
                  Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Palette.lineStrong)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
              }
              .accessibilityLabel("Telaffuz aksanı, \(viewModel.settings.accent.title)")
            }
          }
          .appearAnimation(index: 3)
          SettingsGroup("Bildirimler") {
            SettingInfoRow("bell", "Günün bulmacası", info: SettingInfo.reminder) {
              Toggle(
                "Günün bulmacası",
                isOn: Binding(
                  get: { viewModel.settings.reminderEnabled },
                  set: { on in Task { await viewModel.setReminder(on) } })
              )
              .labelsHidden().tint(Palette.good)
            }
            if viewModel.settings.reminderEnabled {
              SettingInfoRow("clock", "Saat", info: SettingInfo.reminderTime) {
                DatePicker("Saat", selection: reminderTime, displayedComponents: .hourAndMinute)
                  .labelsHidden()
              }
              .transition(.move(edge: .top).combined(with: .opacity))
            }
          }
          .animation(Motion.snappy, value: viewModel.settings.reminderEnabled)
          .appearAnimation(index: 4)
          Text("Çengelish \(Bundle.main.versionText) · Hesap yok, veriler cihazında.")
            .font(AppFont.tiny)
            .foregroundStyle(Palette.muted)
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 4)
        .padding(.bottom, 30)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
      }
      .scrollIndicators(.hidden)
    }
    .screenBackground()
    .noticeAlert($viewModel.notice)
  }

  /// Plus değilse dikkat çekici Plus kartı; Plus ise ömür boyu plan ve satın alma tarihi.
  @ViewBuilder
  private var plusSection: some View {
    if viewModel.isPremium {
      SettingsGroup(PlusBrand.name) {
        SettingInfoRow(
          "crown.fill", viewModel.plusTitle, info: SettingInfo.plus,
          tint: Palette.ink, action: viewModel.openPaywall
        ) {
          HStack(spacing: 8) {
            PlusBadge(compact: true)
            DisclosureValue(viewModel.plusDetail)
          }
        }
      }
    } else {
      PlusPromoCard(
        title: viewModel.plusTitle, subtitle: SettingsViewModel.plusPitch,
        action: viewModel.openPaywall)
    }
  }

  /// Hatırlatıcı saatini tarih seçiciye bağlar.
  private var reminderTime: Binding<Date> {
    Binding(
      get: {
        Calendar.current.date(
          from: DateComponents(
            hour: viewModel.settings.reminderHour, minute: viewModel.settings.reminderMinute))
          ?? .now
      },
      set: { date in
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        viewModel.update {
          $0.reminderHour = parts.hour ?? 20
          $0.reminderMinute = parts.minute ?? 0
        }
      })
  }

  /// Ayar alanını bağlar; değişiklik kaydedilir.
  private func binding<T>(_ key: WritableKeyPath<AppSettings, T>) -> Binding<T> {
    Binding(
      get: { viewModel.settings[keyPath: key] },
      set: { value in viewModel.update { $0[keyPath: key] = value } })
  }

  /// Anahtarlı ayar satırı.
  private func toggleRow(
    _ icon: String, _ title: String, _ info: String, _ key: WritableKeyPath<AppSettings, Bool>
  ) -> some View {
    SettingInfoRow(icon, title, info: info) {
      Toggle(title, isOn: binding(key)).labelsHidden().tint(Palette.good)
    }
  }
}

extension Bundle {
  /// "1.0.0 (1)" biçiminde sürüm metni.
  var versionText: String {
    let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
    return "\(version) (\(build))"
  }
}

extension View {
  /// Kısa bilgi mesajını uyarı olarak gösterir.
  func noticeAlert(_ message: Binding<String?>) -> some View {
    alert(
      "Bilgi",
      isPresented: Binding(
        get: { message.wrappedValue != nil }, set: { _ in message.wrappedValue = nil })
    ) {
      Button("Tamam", role: .cancel) {}
    } message: {
      Text(message.wrappedValue ?? "")
    }
  }
}
