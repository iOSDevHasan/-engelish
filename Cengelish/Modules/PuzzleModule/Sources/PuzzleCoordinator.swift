import ContentKit
import DesignKit
import InjectionKit
import PaywallModuleInterface
import PurchaseKit
import PuzzleKit
import PuzzleModuleInterface
import RouterKitInterface
import SettingsModuleInterface
import SwiftUI
import UserDataKit
import WordKit

/// Bulmaca akışının ekranlarını kurar: bulmaca → cevap anahtarı → bitiş.
@MainActor
public final class PuzzleCoordinator: PuzzleModuleInterface {
  @Inject private var nav: Routing
  @Inject private var content: any ContentProviding
  @Inject private var userData: any UserDataStoring
  @Inject private var entitlements: any EntitlementProviding
  @Inject private var pronouncer: any Pronouncing
  @Inject private var paywall: PaywallModuleInterface
  @Inject private var settings: SettingsModuleInterface

  public init() {}

  public func createPuzzleView(puzzleId: String) -> AnyView {
    let viewModel = PuzzleViewModel(
      puzzleId: puzzleId, coordinator: self, content: content, userData: userData,
      entitlements: entitlements)
    return AnyView(PuzzleView(viewModel: viewModel).chromeless())
  }

  /// Cevap anahtarını açar: göz atma ya da bitirme (kelimeleri işaretleme) için.
  func showAnswerKey(_ session: PuzzleSession, purpose: AnswerKeyPurpose) {
    let viewModel = AnswerKeyViewModel(
      session: session, purpose: purpose, coordinator: self, userData: userData,
      entitlements: entitlements)
    nav.push(
      AnswerKeyView(viewModel: viewModel, theme: theme(for:), penColor: penColor(for:))
        .chromeless())
  }

  /// Bitiş ekranını açar.
  func showFinish(session: PuzzleSession, result: FinishResult, marks: [String: Bool]) {
    let viewModel = FinishViewModel(
      session: session, result: result, marks: marks, coordinator: self, userData: userData,
      pronouncer: pronouncer)
    nav.push(FinishView(viewModel: viewModel).chromeless())
  }

  /// Paylaş ekranını açar.
  func showShare(card: ShareCard) {
    let viewModel = ShareViewModel(card: card, coordinator: self, photoSaver: PhotoLibrarySaver())
    nav.push(ShareView(viewModel: viewModel).chromeless())
  }

  /// Paketteki sonraki bulmacayı açar: bitirilen bulmacanın akışını (bulmaca, cevap anahtarı,
  /// bitiş) yığından çıkarıp yerine yeni bulmacayı koyar; altındaki paket ekranı kalır.
  func openNext(puzzleId: String) {
    nav.pop(count: Self.finishFlowDepth)
    nav.push(createPuzzleView(puzzleId: puzzleId))
  }

  /// Bitiş ekranındayken bulmacadan itibaren yığındaki ekran sayısı: bulmaca, cevap anahtarı, bitiş.
  private static let finishFlowDepth = 3

  /// Ana sayfaya döner.
  func home() {
    nav.popToRoot()
  }

  /// Paywall'u açar.
  func showPaywall() {
    nav.present(paywall.createPaywallView(highlightProductId: nil))
  }

  /// Tüm temalar ekranını açar.
  func showThemes() {
    nav.push(settings.createPuzzleThemeView())
  }

  /// Geri gider.
  func back() {
    nav.pop()
  }

  /// Ayarlardaki kalem rengi (klavye harfleri için).
  private func penColor(for theme: PuzzleTheme) -> Color {
    PenStyle.color(id: userData.settings.penColor, theme: theme)
  }

  /// Ayarlara göre gösterilecek bulmaca teması.
  private func theme(for scheme: ColorScheme) -> PuzzleTheme {
    let settings = userData.settings
    return PuzzleTheme.resolve(
      id: settings.puzzleTheme, isDark: scheme == .dark, autoNight: settings.autoNightTheme,
      highContrast: settings.highContrast)
  }
}
