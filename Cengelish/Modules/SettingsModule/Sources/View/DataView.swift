import DesignKit
import SwiftUI

/// Veri ve yedekleme ekranı: iCloud tercihi, cihazdaki alan ve en altta tüm verileri silme.
struct DataView: View {
  @StateObject var viewModel: SettingsViewModel
  @State private var confirmDelete = false
  /// Panel onaylandı; silme, panelin kapanış animasyonu bitince yapılır.
  @State private var eraseConfirmed = false

  var body: some View {
    VStack(spacing: 0) {
      NavHeader("Veri ve yedekleme", onLeading: viewModel.back)
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          HStack(spacing: 14) {
            Image(systemName: "checkmark.shield.fill").font(.system(size: 26))
              .foregroundStyle(Palette.good)
              .frame(width: 52, height: 52)
              .background(RoundedRectangle(cornerRadius: 16).fill(Palette.goodBackground))
            VStack(alignment: .leading, spacing: 3) {
              Text("Verilerin sende").font(AppFont.headline).foregroundStyle(Palette.ink)
              Text("Hesap yok. Profilin ve ilerlemen bu cihazda saklanır.")
                .font(AppFont.caption).foregroundStyle(Palette.muted)
            }
          }
          VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: Binding(get: { viewModel.iCloudOn }, set: viewModel.setICloud)) {
              Label {
                VStack(alignment: .leading, spacing: 2) {
                  Text("iCloud yedekleme").font(AppFont.bodyBold)
                  Text("iPhone ve iPad'in arasında senkron")
                    .font(AppFont.caption).foregroundStyle(Palette.muted)
                }
              } icon: {
                Image(systemName: "icloud.fill").foregroundStyle(Palette.accent)
              }
            }
            .tint(Palette.good)
            if viewModel.iCloudOn && !viewModel.iCloudAvailable {
              Label(
                "Bu cihazda iCloud'a giriş yapılmamış. Veriler şimdilik sadece cihazda.",
                systemImage: "exclamationmark.icloud"
              )
              .font(AppFont.caption)
              .foregroundStyle(Palette.streak)
            }
          }
          .foregroundStyle(Palette.ink)
          .card(padding: 14)
          storage
          SettingsGroup {
            Button {
              confirmDelete = true
            } label: {
              SettingsRow("trash", "Tüm verileri sil", tint: Palette.bad) { EmptyView() }
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 30)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
      }
      .scrollIndicators(.hidden)
    }
    .screenBackground()
    .appBottomSheet(isPresented: $confirmDelete) {
      DeleteDataSheet { eraseConfirmed = true }
    }
    .onChange(of: confirmDelete) { _, isOn in
      guard !isOn, eraseConfirmed else { return }
      eraseConfirmed = false
      viewModel.eraseAllData()
    }
    .noticeAlert($viewModel.notice)
  }

  private var storage: some View {
    let usage = viewModel.usage
    let total = max(1, usage.total + viewModel.contentBytes)
    let parts: [(String, Int, Color)] = [
      ("El yazısı", usage.drawings, Color(hex: 0x6C5CE7)),
      ("Paketler", viewModel.contentBytes, Color(hex: 0xFF8A3D)),
      ("İlerleme", usage.progress, Color(hex: 0x1FB57A)),
      ("Profil", usage.profile, Color(hex: 0x3C9BE0)),
    ]
    return VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("Bu cihazda").font(AppFont.bodyBold)
        Spacer()
        Text(viewModel.format(bytes: usage.total + viewModel.contentBytes)).font(AppFont.caption)
          .foregroundStyle(Palette.muted)
      }
      GeometryReader { proxy in
        HStack(spacing: 2) {
          ForEach(parts, id: \.0) { part in
            Rectangle().fill(part.2)
              .frame(width: max(3, proxy.size.width * CGFloat(part.1) / CGFloat(total)))
          }
        }
        .clipShape(Capsule())
      }
      .frame(height: 10)
      FlowLayout(spacing: 10) {
        ForEach(parts, id: \.0) { part in
          HStack(spacing: 5) {
            Circle().fill(part.2).frame(width: 8, height: 8)
            Text("\(part.0) \(viewModel.format(bytes: part.1))").font(AppFont.tiny)
              .foregroundStyle(Palette.muted)
          }
        }
      }
    }
    .foregroundStyle(Palette.ink)
    .card(padding: 14)
  }
}
