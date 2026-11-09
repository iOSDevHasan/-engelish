import DesignKit
import SwiftUI

/// Çengelish+ satın alma ekranı.
struct PaywallView: View {
  @StateObject var viewModel: PaywallViewModel

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Button(action: viewModel.close) { IconCircle("xmark") }
          .buttonStyle(.plain)
          .accessibilityLabel("Kapat")
        Spacer()
        Button("Satın alımları geri yükle") { Task { await viewModel.restore() } }
          .font(AppFont.caption)
          .foregroundStyle(Palette.muted)
      }
      .padding(.horizontal, Metrics.gutter)
      .padding(.vertical, 6)
      ScrollView {
        VStack(spacing: 18) {
          hero
          benefits
          plans
        }
        .padding(.horizontal, Metrics.gutter)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
      }
      VStack(spacing: 8) {
        Button {
          Task { await viewModel.purchase() }
        } label: {
          if viewModel.isWorking { ProgressView().tint(.white) } else { Text(viewModel.ctaTitle) }
        }
        .buttonStyle(.chunky)
        .disabled(viewModel.isWorking)
        Text(
          "Deneme bitmeden 24 saat önce iptal edilmezse abonelik başlar. Aboneliği App Store hesabından yönetebilirsin."
        )
        .font(AppFont.tiny)
        .foregroundStyle(Palette.muted)
        .multilineTextAlignment(.center)
        HStack(spacing: 14) {
          Link("Gizlilik", destination: LegalLinks.privacy)
          Link("Kullanım Koşulları", destination: LegalLinks.terms)
        }
        .font(AppFont.tiny)
      }
      .padding(.horizontal, Metrics.gutter)
      .padding(.bottom, 10)
      .frame(maxWidth: 560)
    }
    .screenBackground()
    .task { await viewModel.load() }
    .alert(
      "Çengelish+",
      isPresented: Binding(get: { viewModel.message != nil }, set: { _ in viewModel.message = nil })
    ) {
      Button("Tamam", role: .cancel) {}
    } message: {
      Text(viewModel.message ?? "")
    }
  }

  private var hero: some View {
    VStack(spacing: 8) {
      Image(systemName: "crown.fill")
        .font(.system(size: 30, weight: .bold))
        .foregroundStyle(Palette.goldInk)
        .frame(width: 68, height: 68)
        .background(RoundedRectangle(cornerRadius: 22).fill(Palette.gold))
      Text("Çengelish+").font(AppFont.title).foregroundStyle(Palette.ink)
      Text("Tüm bulmacalar, tüm sınav paketleri.").font(AppFont.body).foregroundStyle(Palette.muted)
    }
    .padding(.top, 8)
  }

  private var benefits: some View {
    VStack(alignment: .leading, spacing: 10) {
      ForEach(viewModel.benefits, id: \.self) { benefit in
        Label {
          Text(benefit).font(AppFont.body).foregroundStyle(Palette.ink)
        } icon: {
          Image(systemName: "checkmark").font(.system(size: 14, weight: .black))
            .foregroundStyle(Palette.good)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var plans: some View {
    VStack(spacing: 12) {
      ForEach(viewModel.plans) { plan in
        Button {
          viewModel.selected = plan.id
        } label: {
          OptionRow(isSelected: viewModel.selected == plan.id) {
            RadioMark(isOn: viewModel.selected == plan.id)
            VStack(alignment: .leading, spacing: 2) {
              Text(plan.title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
              Text(plan.detail).font(AppFont.caption).foregroundStyle(Palette.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
              Text(plan.price).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
              if let unit = plan.unit {
                Text(unit).font(AppFont.tiny).foregroundStyle(Palette.muted)
              }
            }
          }
          .overlay(alignment: .topTrailing) {
            if let badge = plan.badge {
              Pill(badge, tone: .gold).offset(x: -12, y: -11)
            }
          }
        }
        .buttonStyle(.plain)
      }
    }
  }
}

/// Yasal bağlantılar.
enum LegalLinks {
  // Sabit, geçerli URL metinleri; çözümleme başarısız olamaz.
  // swiftlint:disable force_unwrapping
  /// Gizlilik politikası.
  static let privacy = URL(string: "https://cengelish.app/gizlilik")!
  /// Apple standart kullanım koşulları (EULA).
  static let terms = URL(
    string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
  // swiftlint:enable force_unwrapping
}
