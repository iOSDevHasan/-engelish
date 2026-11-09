import DesignKit
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
          SettingsGroup("Profil ve veriler") {
            SettingsRow("icloud", "iCloud yedekleme") {
              Toggle("", isOn: Binding(get: { viewModel.iCloudOn }, set: viewModel.setICloud))
                .labelsHidden().tint(Palette.good)
            }
            Button(action: viewModel.openData) {
              SettingsRow("externaldrive", "Veri ve yedekleme") {
                DisclosureValue(viewModel.format(bytes: viewModel.usage.total))
              }
            }
            .buttonStyle(.plain)
          }
          SettingsGroup("Görünüm") {
            Button(action: viewModel.openAppearance) {
              SettingsRow("circle.lefthalf.filled", "Uygulama görünümü") {
                DisclosureValue(viewModel.settings.appearance.title)
              }
            }
            .buttonStyle(.plain)
            Button(action: viewModel.openPuzzleTheme) {
              SettingsRow("paintpalette", "Bulmaca teması") {
                DisclosureValue(ThemeName.of(viewModel.settings.puzzleTheme))
              }
            }
            .buttonStyle(.plain)
          }
          SettingsGroup("Oyun") {
            toggleRow("hand.raised", "Sol el modu", \.leftHanded)
            toggleRow("arrow.right.square", "Otomatik sonraki kutu", \.autoAdvance)
            toggleRow("applepencil", "Sadece Apple Pencil ile yaz", \.pencilOnly)
            SettingsRow("speaker.wave.2", "Telaffuz aksanı") {
              Picker("", selection: binding(\.accent)) {
                ForEach(SpeechAccent.allCases, id: \.self) { Text($0.title).tag($0) }
              }
              .labelsHidden()
              .tint(Palette.muted)
            }
          }
          SettingsGroup("Bildirimler") {
            SettingsRow("bell", "Günün Bulmacası hatırlatıcısı") {
              Toggle(
                "",
                isOn: Binding(
                  get: { viewModel.settings.reminderEnabled },
                  set: { on in Task { await viewModel.setReminder(on) } })
              )
              .labelsHidden().tint(Palette.good)
            }
            if viewModel.settings.reminderEnabled {
              SettingsRow("clock", "Saat") {
                DatePicker("", selection: reminderTime, displayedComponents: .hourAndMinute)
                  .labelsHidden()
              }
            }
          }
          SettingsGroup("Abonelik") {
            Button(action: viewModel.openPaywall) {
              SettingsRow("crown", viewModel.isPremium ? "Çengelish+ aktif" : "Çengelish+'a geç") {
                DisclosureValue(viewModel.isPremium ? "Yönet" : "")
              }
            }
            .buttonStyle(.plain)
          }
          Text("Çengelish \(Bundle.main.versionText) · Hesap yok, veriler cihazında.")
            .font(AppFont.tiny)
            .foregroundStyle(Palette.muted)
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 30)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
      }
    }
    .screenBackground()
    .noticeAlert($viewModel.notice)
  }

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

  private func binding<T>(_ key: WritableKeyPath<AppSettings, T>) -> Binding<T> {
    Binding(
      get: { viewModel.settings[keyPath: key] },
      set: { value in viewModel.update { $0[keyPath: key] = value } })
  }

  private func toggleRow(
    _ icon: String, _ title: String, _ key: WritableKeyPath<AppSettings, Bool>
  )
    -> some View
  {
    SettingsRow(icon, title) {
      Toggle("", isOn: binding(key)).labelsHidden().tint(Palette.good)
    }
  }
}

/// Tema kimliğini ada çevirir.
enum ThemeName {
  /// Kimliğe göre tema adı.
  static func of(_ id: String) -> String {
    switch id {
    case "kagit": "Kağıt"
    case "gece": "Gece"
    case "okyanus": "Okyanus"
    case "pastel": "Pastel"
    case "kareli": "Kareli Defter"
    default: "Canlı"
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
