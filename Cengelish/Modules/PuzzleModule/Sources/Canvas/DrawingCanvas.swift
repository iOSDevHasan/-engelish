import PencilKit
import SwiftUI

/// Çizim katmanına araç ve geri al / yinele komutlarını ileten köprü.
@MainActor
final class CanvasBridge: ObservableObject {
  fileprivate weak var canvas: PKCanvasView?

  /// Son çizgiyi geri alır.
  func undo() { canvas?.undoManager?.undo() }
  /// Geri alınanı yineler.
  func redo() { canvas?.undoManager?.redo() }
  /// Yakınlaştırmayı sığdırma ölçeğine döndürür.
  func resetZoom() {
    guard let canvas else { return }
    canvas.setZoomScale(canvas.minimumZoomScale, animated: true)
  }
}

/// Kalem aracı.
enum DrawingTool: Equatable {
  case pen
  case pencil
  case eraser
}

/// PencilKit çizim alanı. Alttaki SwiftUI içeriği (ızgara ya da odak kutuları) çizimle birlikte
/// kayar ve yakınlaşır; yakınlaşma bitince içerik net görünmesi için yeni ölçekte yeniden çizilir.
struct DrawingCanvas: UIViewRepresentable {

  // MARK: - Inputs

  /// Çizim (kaynak doğruluk view model'de).
  let drawing: PKDrawing
  /// Çizim dışarıdan değiştiğinde artan sayaç.
  let drawingRevision: Int
  /// Ölçek 1'deki içerik boyutu.
  let contentSize: CGSize
  /// İçeriği verilen ölçekte çizen görünüm.
  let underlay: (CGFloat) -> AnyView
  /// Seçili araç.
  let tool: DrawingTool
  /// Tükenmez kalem rengi.
  let penColor: UIColor
  /// Kurşun kalem rengi.
  let pencilColor: UIColor
  /// Kalınlık çarpanı.
  let widthScale: CGFloat
  /// Ekranın açık / koyu modu; mürekkep rengi buna göre sabitlenir.
  let colorScheme: ColorScheme
  /// Sadece Apple Pencil ile çizilsin mi.
  let pencilOnly: Bool
  /// Yakınlaştırma açık mı.
  let allowsZoom: Bool
  /// Köprü.
  let bridge: CanvasBridge
  /// Kullanıcı çizdiğinde (yeni çizim).
  let onChange: (PKDrawing) -> Void
  /// Dokunma (küçük nokta) algılandığında, içerik koordinatında.
  let onTap: (CGPoint) -> Void
  /// Bir çizgi bitince, çizginin merkezi.
  let onStroke: (CGPoint) -> Void

  // MARK: - UIViewRepresentable

  func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

  func makeUIView(context: Context) -> PKCanvasView {
    let canvas = ZoomingCanvasView()
    canvas.backgroundColor = .clear
    canvas.isOpaque = false
    // PencilKit koyu modda mürekkebi otomatik ters çevirir; renkler zaten temaya göre seçildiği
    // için bu davranış kapatılır.
    canvas.overrideUserInterfaceStyle = .light
    canvas.delegate = context.coordinator
    canvas.drawing = drawing
    canvas.contentSize = contentSize
    canvas.showsHorizontalScrollIndicator = false
    canvas.showsVerticalScrollIndicator = false
    canvas.bouncesZoom = true
    canvas.onLayout = { [weak coordinator = context.coordinator] view in
      coordinator?.fitIfNeeded(view)
    }
    let host = context.coordinator.host
    host.view.backgroundColor = .clear
    host.view.frame = CGRect(origin: .zero, size: contentSize)
    canvas.insertSubview(host.view, at: 0)
    let tap = UITapGestureRecognizer(
      target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
    tap.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
    canvas.addGestureRecognizer(tap)
    context.coordinator.tapRecognizer = tap
    context.coordinator.appliedRevision = drawingRevision
    context.coordinator.strokeCount = drawing.strokes.count
    bridge.canvas = canvas
    return canvas
  }

  func updateUIView(_ canvas: PKCanvasView, context: Context) {
    let coordinator = context.coordinator
    coordinator.parent = self
    bridge.canvas = canvas
    canvas.drawingPolicy = pencilOnly ? .pencilOnly : .anyInput
    // Çizim alanı açık moda sabit; alttaki ızgara ise ekranın gerçek modunu izler.
    coordinator.host.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
    coordinator.tapRecognizer?.isEnabled = pencilOnly
    canvas.tool = makeTool()
    if coordinator.appliedRevision != drawingRevision {
      coordinator.appliedRevision = drawingRevision
      coordinator.isApplying = true
      canvas.drawing = drawing
      coordinator.strokeCount = drawing.strokes.count
      coordinator.isApplying = false
    }
    if coordinator.baseSize != contentSize {
      coordinator.baseSize = contentSize
      coordinator.didFit = false
      canvas.setNeedsLayout()
    }
    coordinator.renderUnderlay(in: canvas)
  }

  private func makeTool() -> PKTool {
    let traits = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
    switch tool {
    case .pen:
      return PKInkingTool(.pen, color: penColor.resolvedColor(with: traits), width: 5 * widthScale)
    case .pencil:
      return PKInkingTool(
        .pencil, color: pencilColor.resolvedColor(with: traits), width: 6 * widthScale)
    case .eraser:
      return PKEraserTool(.vector)
    }
  }

  // MARK: - Coordinator

  @MainActor
  final class Coordinator: NSObject, PKCanvasViewDelegate {
    var parent: DrawingCanvas
    let host = UIHostingController(rootView: AnyView(EmptyView()))
    weak var tapRecognizer: UITapGestureRecognizer?
    var appliedRevision = 0
    var strokeCount = 0
    var isApplying = false
    var didFit = false
    var baseSize: CGSize
    private var renderedScale: CGFloat = 0

    init(parent: DrawingCanvas) {
      self.parent = parent
      self.baseSize = parent.contentSize
      super.init()
      host.sizingOptions = []
      host.safeAreaRegions = []
    }

    /// İlk yerleşimde içeriği ekrana sığdıracak ölçeği ayarlar.
    func fitIfNeeded(_ canvas: PKCanvasView) {
      guard !didFit, canvas.bounds.width > 0, baseSize.width > 0 else { return }
      didFit = true
      let fit = min(canvas.bounds.width / baseSize.width, canvas.bounds.height / baseSize.height)
      canvas.minimumZoomScale = fit
      canvas.maximumZoomScale = parent.allowsZoom ? max(fit * 3.2, 2.5) : fit
      canvas.zoomScale = fit
      canvas.contentSize = CGSize(width: baseSize.width * fit, height: baseSize.height * fit)
      renderedScale = 0
      renderUnderlay(in: canvas)
      center(canvas)
    }

    /// Alttaki içeriği güncel yakınlaştırma ölçeğinde yeniden çizer.
    func renderUnderlay(in canvas: PKCanvasView) {
      let scale = canvas.zoomScale
      host.rootView = parent.underlay(scale)
      host.view.transform = .identity
      host.view.frame = CGRect(
        x: 0, y: 0, width: baseSize.width * scale, height: baseSize.height * scale)
      renderedScale = scale
    }

    /// İçerik ekrandan küçükse ortalar.
    private func center(_ canvas: PKCanvasView) {
      let x = max(0, (canvas.bounds.width - canvas.contentSize.width) / 2)
      let y = max(0, (canvas.bounds.height - canvas.contentSize.height) / 2)
      canvas.contentInset = UIEdgeInsets(top: y, left: x, bottom: y, right: x)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
      guard let canvas = scrollView as? PKCanvasView, renderedScale > 0 else { return }
      let ratio = canvas.zoomScale / renderedScale
      host.view.transform = CGAffineTransform(scaleX: ratio, y: ratio)
      host.view.frame.origin = .zero
      center(canvas)
    }

    func scrollViewDidEndZooming(
      _ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat
    ) {
      guard let canvas = scrollView as? PKCanvasView else { return }
      renderUnderlay(in: canvas)
      center(canvas)
    }

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
      guard !isApplying else { return }
      let drawing = canvasView.drawing
      defer { strokeCount = canvasView.drawing.strokes.count }
      if drawing.strokes.count == strokeCount + 1, let last = drawing.strokes.last {
        let bounds = last.renderBounds
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        if bounds.width < 9, bounds.height < 9, !parent.pencilOnly {
          // Küçük bir nokta dokunma sayılır: çizimden çıkarılır ve kutu seçilir.
          isApplying = true
          var cleaned = drawing
          cleaned.strokes.removeLast()
          canvasView.drawing = cleaned
          isApplying = false
          parent.onTap(center)
          return
        }
        parent.onChange(drawing)
        parent.onStroke(center)
        return
      }
      parent.onChange(drawing)
    }

    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
      guard let canvas = recognizer.view as? PKCanvasView else { return }
      let location = recognizer.location(in: canvas)
      parent.onTap(CGPoint(x: location.x / canvas.zoomScale, y: location.y / canvas.zoomScale))
    }
  }
}

/// Yerleşim değiştiğinde haber veren çizim alanı.
private final class ZoomingCanvasView: PKCanvasView {
  var onLayout: ((PKCanvasView) -> Void)?

  override func layoutSubviews() {
    super.layoutSubviews()
    onLayout?(self)
  }
}
