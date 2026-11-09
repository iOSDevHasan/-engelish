import CoreGraphics
import Foundation

/// Çizim alanının görünen bölgesi: sığdırma ölçeğine göre yakınlaştırma ve içerikte görünen alan.
struct CanvasViewport: Equatable {
  /// Sığdırma ölçeğine oranla yakınlaştırma (1 = tamamı görünüyor).
  var zoom: CGFloat
  /// Görünen alan, içeriğin 0…1 aralığına normalize edilmiş hali.
  var visible: CGRect

  /// Tamamı görünen başlangıç durumu.
  static let fit = CanvasViewport(zoom: 1, visible: CGRect(x: 0, y: 0, width: 1, height: 1))
}

/// Yakınlaştırma göstergeleri (yüzde, mini harita, tek seferlik ipucu).
///
/// Kaydırma sırasında sık güncellenir; bulmaca ekranının tamamı yeniden çizilmesin diye view
/// model'den ayrı tutulur ve sadece göstergeler bunu izler.
@MainActor
final class ZoomState: ObservableObject {

  // MARK: - Published state

  /// Yakınlaştırılmış mı.
  @Published private(set) var isZoomed = false
  /// Yakınlaştırma yüzdesi metni.
  @Published private(set) var percentText = "%100"
  /// Tek seferlik "iki parmakla gezin" ipucu görünüyor mu.
  @Published private(set) var showsTip = false
  /// Mini haritadaki görünen alan (0…1).
  @Published private(set) var visible = CanvasViewport.fit.visible

  // MARK: - Properties

  /// İpucunun gösterildiğini saklayan anahtar.
  static let tipKey = "puzzle.zoomTipShown"
  /// Bu orandan büyükse yakınlaştırılmış sayılır.
  static let zoomThreshold: CGFloat = 1.02
  private let defaults: UserDefaults
  private let tipDuration: Duration
  private var tipTask: Task<Void, Never>?

  // MARK: - Init

  /// Ayar deposu ve ipucu süresiyle oluşturur.
  init(defaults: UserDefaults = .standard, tipDuration: Duration = .seconds(3.5)) {
    self.defaults = defaults
    self.tipDuration = tipDuration
  }

  // MARK: - Updates

  /// Çizim alanından gelen görünen bölgeyi uygular.
  func update(_ viewport: CanvasViewport) {
    let zoomed = viewport.zoom > Self.zoomThreshold
    if zoomed != isZoomed { isZoomed = zoomed }
    let text = ZoomText.percent(viewport.zoom)
    if text != percentText { percentText = text }
    if viewport.visible != visible { visible = viewport.visible }
    if zoomed {
      showTipIfNeeded()
    } else if showsTip {
      hideTip()
    }
  }

  /// İpucunu hemen gizler.
  func hideTip() {
    tipTask?.cancel()
    showsTip = false
  }

  // MARK: - Private

  private func showTipIfNeeded() {
    guard !defaults.bool(forKey: Self.tipKey) else { return }
    defaults.set(true, forKey: Self.tipKey)
    showsTip = true
    let duration = tipDuration
    tipTask = Task { [weak self] in
      try? await Task.sleep(for: duration)
      guard !Task.isCancelled else { return }
      self?.showsTip = false
    }
  }
}
