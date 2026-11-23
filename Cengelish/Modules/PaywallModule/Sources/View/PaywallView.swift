import DesignKit
import StoreKit
import SwiftUI

/// Çengelish Plus satın alma ekranı (GolBil sırası): kısa kahraman, Plus'ın sundukları, plan
/// seçimi ve altta sabit satın alma alanı (buton, geri yükleme, açıklama, yasal bağlantılar).
/// Plus üyesinde ve satın alma sonrasında planların yerine üyelik durumu gösterilir.
struct PaywallView: View {
  @StateObject var viewModel: PaywallViewModel
  /// Kahraman alanı kaydırılarak geçildi mi (durum çubuğu zemini için).
  @State private var isPastHero = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// İçeriğin iPad'deki en geniş hâli.
  private static let maxContentWidth: CGFloat = 560

  var body: some View {
    GeometryReader { proxy in
      content(topInset: proxy.safeAreaInsets.top)
    }
    .overlay {
      if viewModel.isCelebrating && !reduceMotion {
        PaywallConfetti().ignoresSafeArea()
      }
    }
    .screenBackground()
    .animation(reduceMotion ? nil : Motion.gentle, value: viewModel.stage)
    .sensoryFeedback(.selection, trigger: viewModel.selected)
    .sensoryFeedback(trigger: viewModel.stage) { _, stage in
      stage.isCelebration ? .success : nil
    }
    .task { await viewModel.load() }
    .alert(
      PlusBrand.name,
      isPresented: Binding(get: { viewModel.message != nil }, set: { _ in viewModel.message = nil })
    ) {
      Button("Tamam", role: .cancel) {}
    } message: {
      Text(viewModel.message ?? "")
    }
  }

  // MARK: - Sections

  /// Kaydırılan içerik; kahraman gradyanı durum çubuğunun arkasına uzanır.
  private func content(topInset: CGFloat) -> some View {
    ScrollView {
      VStack(spacing: 0) {
        PaywallHero(
          title: viewModel.heroTitle, subtitle: viewModel.heroSubtitle,
          isUnlocked: viewModel.isUnlocked, topInset: topInset)
        Group {
          if viewModel.isUnlocked {
            PaywallUnlockedView(
              facts: viewModel.membershipFacts, benefitsTitle: viewModel.unlockedBenefitsTitle,
              benefits: viewModel.unlockedBenefits
            )
            .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
          } else {
            VStack(spacing: 22) {
              PaywallPerkList(viewModel: viewModel).appearAnimation(index: 1)
              PaywallPlanPicker(viewModel: viewModel).appearAnimation(index: 2)
            }
            .transition(.opacity)
          }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .frame(maxWidth: Self.maxContentWidth)
      }
      .frame(maxWidth: .infinity)
    }
    .scrollIndicators(.hidden)
    .onScrollGeometryChange(for: Bool.self) { geometry in
      geometry.contentOffset.y > 160
    } action: { _, isPast in
      withAnimation(.easeOut(duration: 0.2)) { isPastHero = isPast }
    }
    .ignoresSafeArea(.container, edges: .top)
    .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
    .overlay(alignment: .top) { statusBarScrim(height: topInset) }
    .overlay(alignment: .topTrailing) { closeButton }
  }

  /// Kahraman alanı geçilince durum çubuğunun arkasında beliren zemin; içerik saatin altına
  /// karışmaz.
  private func statusBarScrim(height: CGFloat) -> some View {
    Palette.background
      .frame(height: height)
      .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
      .ignoresSafeArea(edges: .top)
      .opacity(isPastHero ? 1 : 0)
      .allowsHitTesting(false)
  }

  /// Sağ üstteki kapatma butonu (gradyan üzerinde de, kaydırınca da okunur).
  private var closeButton: some View {
    Button(action: viewModel.close) {
      Image(systemName: "xmark")
        .font(.system(size: 14, weight: .black))
        .foregroundStyle(.white)
        .frame(width: 34, height: 34)
        .background(Circle().fill(.black.opacity(0.28)))
        .frame(width: 44, height: 44)
        .contentShape(Circle())
    }
    .buttonStyle(PressScaleButtonStyle())
    .disabled(viewModel.isWorking)
    .padding(.trailing, Metrics.gutter - 6)
    .padding(.top, 2)
    .accessibilityLabel("Kapat")
  }

  /// Altta sabit alan: planlarda satın alma, açılmış durumda devam.
  private var bottomBar: some View {
    Group {
      if viewModel.isUnlocked {
        unlockedBar
      } else {
        purchaseBar
      }
    }
    .padding(.horizontal, Metrics.gutter)
    .padding(.top, 12)
    .padding(.bottom, 8)
    .frame(maxWidth: Self.maxContentWidth)
    .frame(maxWidth: .infinity)
    .background {
      Palette.background
        .ignoresSafeArea(edges: .bottom)
        .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
    }
  }

  /// Satın alma butonu, hemen altında geri yükleme, sonra yasal açıklama ve bağlantılar.
  private var purchaseBar: some View {
    VStack(spacing: 4) {
      Button {
        Task { await viewModel.purchase() }
      } label: {
        if viewModel.isWorking {
          ProgressView().tint(Palette.goldInk)
        } else {
          Text(viewModel.ctaTitle).contentTransition(.opacity)
        }
      }
      .buttonStyle(.plus)
      .disabled(!viewModel.canPurchase)
      .opacity(viewModel.canPurchase || viewModel.isWorking ? 1 : 0.6)
      .padding(.bottom, 2)
      Button("Satın alımları geri yükle") { Task { await viewModel.restore() } }
        .font(AppFont.caption.weight(.heavy))
        .foregroundStyle(Palette.accent)
        .frame(minHeight: 34)
        .disabled(viewModel.isWorking)
      Text(viewModel.disclosure)
        .font(AppFont.tiny)
        .foregroundStyle(Palette.muted)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .contentTransition(.opacity)
      legalLinks
    }
    .animation(Motion.snappy, value: viewModel.selected)
  }

  /// Açılmış durumda devam butonu.
  private var unlockedBar: some View {
    Button(viewModel.continueTitle, action: viewModel.close)
      .buttonStyle(.plus)
      .padding(.bottom, 2)
  }

  /// Gizlilik ve kullanım koşulları bağlantıları.
  private var legalLinks: some View {
    HStack(spacing: 8) {
      Link("Gizlilik", destination: LegalLinks.privacy)
      Text("·").accessibilityHidden(true)
      Link("Kullanım Koşulları", destination: LegalLinks.terms)
    }
    .font(AppFont.tiny.weight(.heavy))
    .foregroundStyle(Palette.muted)
    .frame(minHeight: 28)
  }
}

/// Yasal bağlantılar.
enum LegalLinks {
  // Sabit, geçerli URL metinleri; çözümleme başarısız olamaz.
  // swiftlint:disable force_unwrapping
  /// Gizlilik politikası.
  static let privacy = URL(string: "https://iosdevhasan.github.io/-engelish/gizlilik.html")!
  /// Apple standart kullanım koşulları (EULA).
  static let terms = URL(
    string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
  // swiftlint:enable force_unwrapping
}
