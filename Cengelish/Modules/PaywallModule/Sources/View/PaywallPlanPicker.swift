import DesignKit
import SwiftUI

/// Plan seçimi: "Planını seç" başlığı, "Çengelish Plus | Sınav paketleri" sekmeleri ve açık
/// sekmenin plan satırları.
struct PaywallPlanPicker: View {
  @ObservedObject var viewModel: PaywallViewModel
  @Namespace private var tabNamespace

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Eyebrow("Planını seç", color: Palette.muted)
        .padding(.leading, 4)
        .accessibilityAddTraits(.isHeader)
      PaywallTabPicker(selection: viewModel.tab, namespace: tabNamespace) { tab in
        withAnimation(Motion.snappy) { viewModel.selectTab(tab) }
      }
      VStack(spacing: 12) {
        ForEach(viewModel.visiblePlans) { plan in
          Button {
            withAnimation(Motion.snappy) { viewModel.select(plan.id) }
          } label: {
            PlanRow(plan: plan, isSelected: viewModel.selected == plan.id)
          }
          .buttonStyle(PressScaleButtonStyle())
          .accessibilityAddTraits(viewModel.selected == plan.id ? .isSelected : [])
          .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
        }
      }
      .padding(.top, 8)
    }
  }
}

// MARK: - Tab picker

/// "Çengelish Plus | Sınav paketleri" sekme seçici; seçili kapsül kayarak geçer.
struct PaywallTabPicker: View {
  let selection: PaywallTab
  let namespace: Namespace.ID
  let onSelect: (PaywallTab) -> Void

  var body: some View {
    HStack(spacing: 4) {
      ForEach(PaywallTab.allCases) { tab in
        let isOn = tab == selection
        Button {
          onSelect(tab)
        } label: {
          Label(tab.title, systemImage: tab.systemImage)
            .font(AppFont.caption.weight(.heavy))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(isOn ? onColor(tab) : Palette.muted)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background {
              if isOn {
                Capsule()
                  .fill(fill(tab))
                  .matchedGeometryEffect(id: "paywall.tab", in: namespace)
              }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
      }
    }
    .padding(4)
    .background(
      Capsule()
        .fill(Palette.surface)
        .overlay(Capsule().strokeBorder(Palette.cardBorder, lineWidth: 1))
    )
  }

  /// Seçili sekmenin dolgusu: Plus altın, paketler mor.
  private func fill(_ tab: PaywallTab) -> AnyShapeStyle {
    switch tab {
    case .plus:
      AnyShapeStyle(
        LinearGradient(
          colors: Palette.plusGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
    case .packs: AnyShapeStyle(Palette.accent)
    }
  }

  /// Seçili sekmenin yazı rengi.
  private func onColor(_ tab: PaywallTab) -> Color {
    tab == .plus ? Palette.goldInk : .white
  }
}

// MARK: - Plan row

/// Seçilebilir plan satırı; önerilen plan altın çerçeve ve tasarruf rozetiyle öne çıkar.
struct PlanRow: View {
  let plan: PlanOption
  let isSelected: Bool

  var body: some View {
    OptionRow(isSelected: isSelected) {
      RadioMark(isOn: isSelected)
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          Text(plan.title).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
          if plan.isRecommended { PlusBadge(compact: true) }
        }
        Text(plan.detail)
          .font(AppFont.caption)
          .foregroundStyle(Palette.muted)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer(minLength: 6)
      if plan.isOwned {
        Pill("Sende var", systemImage: "checkmark", tone: .good)
      } else {
        VStack(alignment: .trailing, spacing: 0) {
          Text(plan.price).font(AppFont.bodyBold).foregroundStyle(Palette.ink)
          if let unit = plan.unit {
            Text(unit).font(AppFont.tiny).foregroundStyle(Palette.muted)
          }
        }
        .fixedSize()
      }
    }
    .overlay {
      if plan.isRecommended {
        RoundedRectangle(cornerRadius: Metrics.radius, style: .continuous)
          .strokeBorder(
            LinearGradient(
              colors: Palette.plusGradient, startPoint: .topLeading, endPoint: .bottomTrailing),
            lineWidth: isSelected ? 2.5 : 1.5)
      }
    }
    .overlay(alignment: .topTrailing) {
      if let badge = plan.badge {
        Text(badge)
          .font(AppFont.tiny.weight(.black))
          .foregroundStyle(Palette.goldInk)
          .padding(.horizontal, 8)
          .frame(height: 22)
          .background(
            Capsule().fill(
              LinearGradient(
                colors: Palette.plusGradient, startPoint: .leading, endPoint: .trailing))
          )
          .fixedSize()
          .offset(x: -14, y: -11)
      }
    }
    .accessibilityElement(children: .combine)
  }
}
