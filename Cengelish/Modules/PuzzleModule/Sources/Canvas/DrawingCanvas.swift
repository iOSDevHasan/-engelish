import PencilKit
import SwiftUI

/// Çizim katmanına yakınlaştırma komutlarını ileten köprü. Geri al / yinele view model'dedir
/// (çizgi, silgi ve klavye harfleri tek geçmişte tutulur).
@MainActor
final class CanvasBridge: ObservableObject {
  fileprivate weak var canvas: PKCanvasView?

  /// Yakınlaştırmayı sığdırma ölçeğine döndürür.
  func resetZoom() {
    guard let canvas else { return }
    canvas.setZoomScale(canvas.minimumZoomScale, animated: true)
  }
}

/// Yazma aracı: kalem, kurşun kalem, silgi ya da klavye.
enum DrawingTool: Equatable {
  case pen
  case pencil
  case eraser
  case keyboard

  /// Araç PencilKit ile çizim yapıyor mu (klavye modunda çizim kapalıdır).
  var draws: Bool { self != .keyboard }
}

/// PencilKit çizim alanı. Alttaki SwiftUI içeriği (ızgara ya da odak kutuları) çizimle birlikte
/// kayar ve yakınlaşır; yakınlaşma bitince içerik net görünmesi için yeni ölçekte yeniden çizilir.
///
/// Mürekkep sadece `inkRects` içinde görünür: çizim katmanı bu kutuların birleşimiyle maskelenir
/// ve biten her çizgi kutulara kırpılır (bkz. `StrokeMath.clip`), böylece ipucu / blok kutularına
/// ya da ızgara dışına taşan yazı ne görünür ne de kaydedilir. Alttaki içerik maskenin dışında,
/// çizim alanının arkasında durur ve kaydırma / yakınlaşmayla birlikte konumlanır.
struct DrawingCanvas: UIViewRepresentable {

  // MARK: - Inputs

  /// Çizim (kaynak doğruluk view model'de).
  let drawing: PKDrawing
  /// Çizim dışarıdan değiştiğinde artan sayaç.
  let drawingRevision: Int
  /// Ölçek 1'deki içerik boyutu.
  let contentSize: CGSize
  /// Mürekkebin görünebildiği kutular (ölçek 1 içerik koordinatında); boşsa sınır yoktur.
  let inkRects: [CGRect]
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
  /// Yakınlaştırma ya da kaydırma değişince görünen bölge (isteğe bağlı).
  var onViewport: ((CanvasViewport) -> Void)?
  /// Silgi bir noktanın üstünden geçtiğinde, içerik koordinatında (klavye harflerini silmek için).
  var onErase: ((CGPoint) -> Void)?

  // MARK: - UIViewRepresentable

  func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

  func makeUIView(context: Context) -> CanvasContainerView {
    let container = CanvasContainerView()
    let canvas = container.canvas
    let coordinator = context.coordinator
    coordinator.container = container
    // PencilKit koyu modda mürekkebi otomatik ters çevirir; renkler zaten temaya göre seçildiği
    // için bu davranış kapatılır.
    canvas.overrideUserInterfaceStyle = .light
    canvas.delegate = coordinator
    canvas.drawing = drawing
    canvas.contentSize = contentSize
    canvas.bouncesZoom = true
    canvas.onLayout = { [weak coordinator] view in
      coordinator?.fitIfNeeded(view)
    }
    let host = coordinator.host.view ?? UIView()
    host.backgroundColor = .clear
    host.isUserInteractionEnabled = false
    host.bounds = CGRect(origin: .zero, size: contentSize)
    container.insertSubview(host, at: 0)
    let tap = UITapGestureRecognizer(
      target: coordinator, action: #selector(Coordinator.handleTap(_:)))
    tap.allowedTouchTypes = [
      NSNumber(value: UITouch.TouchType.direct.rawValue),
      NSNumber(value: UITouch.TouchType.pencil.rawValue),
    ]
    canvas.addGestureRecognizer(tap)
    coordinator.tapRecognizer = tap
    // Silgi PencilKit çizgisi üretmez; klavye harflerinin üstünden geçtiği bu algılayıcıyla
    // izlenir. Basılır basılmaz başlar ve çizimle aynı anda çalışır.
    let erase = UILongPressGestureRecognizer(
      target: coordinator, action: #selector(Coordinator.handleErase(_:)))
    erase.minimumPressDuration = 0
    erase.allowableMovement = .greatestFiniteMagnitude
    erase.cancelsTouchesInView = false
    erase.delaysTouchesBegan = false
    erase.delegate = coordinator
    canvas.addGestureRecognizer(erase)
    coordinator.eraseRecognizer = erase
    coordinator.appliedRevision = drawingRevision
    coordinator.commit(drawing)
    coordinator.applyInkRects(inkRects)
    bridge.canvas = canvas
    return container
  }

  func updateUIView(_ container: CanvasContainerView, context: Context) {
    let canvas = container.canvas
    let coordinator = context.coordinator
    coordinator.parent = self
    bridge.canvas = canvas
    canvas.drawingPolicy = pencilOnly ? .pencilOnly : .anyInput
    // Araç atanınca PencilKit çizim algılayıcısını yeniden açabilir; kapatma araçtan sonra yapılır.
    canvas.tool = makeTool()
    canvas.isDrawingEnabled = tool.draws
    canvas.drawingGestureRecognizer.isEnabled = tool.draws
    // Çizim alanı açık moda sabit; alttaki ızgara ise ekranın gerçek modunu izler.
    coordinator.host.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
    // Parmakla çizerken dokunma küçük noktadan anlaşılır; sadece kalem modunda ya da klavye
    // modunda (çizim kapalı) ayrı dokunma algılayıcısı çalışır.
    coordinator.tapRecognizer?.isEnabled = pencilOnly || !tool.draws
    if let erase = coordinator.eraseRecognizer {
      erase.isEnabled = tool == .eraser && onErase != nil
      erase.allowedTouchTypes =
        pencilOnly
        ? [NSNumber(value: UITouch.TouchType.pencil.rawValue)]
        : [
          NSNumber(value: UITouch.TouchType.direct.rawValue),
          NSNumber(value: UITouch.TouchType.pencil.rawValue),
        ]
    }
    if coordinator.appliedRevision != drawingRevision {
      coordinator.appliedRevision = drawingRevision
      coordinator.isApplying = true
      canvas.drawing = drawing
      coordinator.commit(drawing)
      coordinator.isApplying = false
    }
    coordinator.applyInkRects(inkRects)
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
    case .pen, .keyboard:
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
  final class Coordinator: NSObject, PKCanvasViewDelegate, UIGestureRecognizerDelegate {
    var parent: DrawingCanvas
    let host = UIHostingController(rootView: AnyView(EmptyView()))
    weak var container: CanvasContainerView?
    weak var tapRecognizer: UITapGestureRecognizer?
    weak var eraseRecognizer: UILongPressGestureRecognizer?
    var appliedRevision = 0
    var isApplying = false
    var didFit = false
    var baseSize: CGSize
    private var renderedScale: CGFloat = 0
    private var fittedSize: CGSize = .zero
    private var inkRects: [CGRect]?
    /// Modelin bildiği çizim. Yeni çizim çizim alanından değil, bundan kurulur: PencilKit geri
    /// alınmış çizgileri çizim alanında tutup sonraki çizgiyle geri getirebiliyor.
    private var committed = PKDrawing()
    /// Görülen en yeni çizginin başlama anı; bundan sonra başlayan çizgiler yenidir.
    private var newestStroke = Date.distantPast

    init(parent: DrawingCanvas) {
      self.parent = parent
      self.baseSize = parent.contentSize
      super.init()
      host.sizingOptions = []
      host.safeAreaRegions = []
    }

    /// İlk yerleşimde ve çizim alanının boyutu değişince (döndürme, klavye) sığdırma ölçeğini
    /// ayarlar. Kullanıcı yakınlaştırmamışsa içerik yeni boyuta sığdırılır.
    func fitIfNeeded(_ canvas: PKCanvasView) {
      let size = canvas.bounds.size
      guard size.width > 0, size.height > 0, baseSize.width > 0, baseSize.height > 0 else {
        return
      }
      guard !didFit || size != fittedSize else { return }
      let wasFitted = !didFit || canvas.zoomScale <= canvas.minimumZoomScale + 0.001
      didFit = true
      fittedSize = size
      let fit = min(size.width / baseSize.width, size.height / baseSize.height)
      canvas.minimumZoomScale = fit
      canvas.maximumZoomScale = parent.allowsZoom ? max(fit * 3.2, 2.5) : fit
      if wasFitted || canvas.zoomScale < fit {
        canvas.zoomScale = fit
        canvas.contentSize = CGSize(width: baseSize.width * fit, height: baseSize.height * fit)
      }
      renderedScale = 0
      renderUnderlay(in: canvas)
      center(canvas)
      // Yerleşim SwiftUI güncellemesi sırasında olabilir; durum değişikliği bir sonraki tura
      // bırakılır.
      Task { @MainActor [weak self, weak canvas] in
        guard let self, let canvas else { return }
        self.reportViewport(canvas)
      }
    }

    /// Görünen bölgeyi üst görünüme bildirir.
    func reportViewport(_ canvas: PKCanvasView) {
      guard let onViewport = parent.onViewport, canvas.minimumZoomScale > 0,
        canvas.contentSize.width > 0, canvas.contentSize.height > 0
      else { return }
      let size = canvas.contentSize
      let visible = CGRect(
        x: canvas.contentOffset.x / size.width, y: canvas.contentOffset.y / size.height,
        width: canvas.bounds.width / size.width, height: canvas.bounds.height / size.height
      )
      .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
      onViewport(
        CanvasViewport(
          zoom: canvas.zoomScale / canvas.minimumZoomScale,
          visible: visible.isNull ? CanvasViewport.fit.visible : visible))
    }

    /// Alttaki içeriği güncel yakınlaştırma ölçeğinde yeniden çizer.
    func renderUnderlay(in canvas: PKCanvasView) {
      let scale = canvas.zoomScale
      host.rootView = parent.underlay(scale)
      host.view.transform = .identity
      host.view.bounds = CGRect(
        x: 0, y: 0, width: baseSize.width * scale, height: baseSize.height * scale)
      renderedScale = scale
      syncLayers(canvas)
    }

    /// Mürekkep kutuları değiştiyse maskeyi yeniden kurar.
    func applyInkRects(_ rects: [CGRect]) {
      guard rects != inkRects else { return }
      inkRects = rects
      container?.setInkRects(rects)
      if let canvas = container?.canvas { syncLayers(canvas) }
    }

    /// Alttaki içeriği ve mürekkep maskesini güncel kaydırma / yakınlaşmaya hizalar.
    private func syncLayers(_ canvas: PKCanvasView) {
      let zoom = canvas.zoomScale
      let offset = canvas.contentOffset
      if renderedScale > 0, let view = host.view {
        let ratio = zoom / renderedScale
        view.transform = CGAffineTransform(scaleX: ratio, y: ratio)
        view.center = CGPoint(
          x: baseSize.width * zoom / 2 - offset.x, y: baseSize.height * zoom / 2 - offset.y)
      }
      container?.alignMask(zoom: zoom, offset: offset)
    }

    /// İçerik ekrandan küçükse ortalar.
    private func center(_ canvas: PKCanvasView) {
      let x = max(0, (canvas.bounds.width - canvas.contentSize.width) / 2)
      let y = max(0, (canvas.bounds.height - canvas.contentSize.height) / 2)
      canvas.contentInset = UIEdgeInsets(top: y, left: x, bottom: y, right: x)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
      guard let canvas = scrollView as? PKCanvasView, renderedScale > 0 else { return }
      center(canvas)
      syncLayers(canvas)
      reportViewport(canvas)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
      guard let canvas = scrollView as? PKCanvasView, didFit else { return }
      syncLayers(canvas)
      reportViewport(canvas)
    }

    func scrollViewDidEndZooming(
      _ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat
    ) {
      guard let canvas = scrollView as? PKCanvasView else { return }
      renderUnderlay(in: canvas)
      center(canvas)
      reportViewport(canvas)
    }

    /// Modelden gelen çizimi bilinen çizim olarak kaydeder.
    func commit(_ drawing: PKDrawing) {
      committed = drawing
      // Başka cihazda (saati biraz ileride) çizilmiş çizgiler yenileri engellemesin.
      markSeen(drawing.strokes, until: .now)
    }

    /// Çizgilerin en yenisini (verilen andan ileri gitmeden) görülmüş sayar.
    private func markSeen(_ strokes: [PKStroke], until limit: Date = .distantFuture) {
      for stroke in strokes {
        newestStroke = max(newestStroke, min(stroke.path.creationDate, limit))
      }
    }

    /// Çizim alanındaki değişikliği modele çevirir: bilinen çizimde çizim alanında hâlâ duran
    /// çizgiler (silgi bunları kaldırır) ve son görülenden sonra başlamış yeni çizgiler. Geri
    /// alınmış eski çizgiler çizim alanında kalsa bile alınmaz ve çizim alanından da silinir.
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
      guard !isApplying else { return }
      let drawing = canvasView.drawing
      let fresh = drawing.strokes.filter { $0.path.creationDate > newestStroke }
      markSeen(fresh)
      let present = Set(drawing.strokes.map(StrokeKey.init))
      let kept = committed.strokes.filter { present.contains(StrokeKey($0)) }
      guard parent.tool.draws else {
        // Çizim kapalıyken (klavye modu, bitmiş bulmaca) gelen çizgi geri alınır.
        if drawing.strokes.count != committed.strokes.count { apply(committed, to: canvasView) }
        return
      }
      if fresh.count == 1, let dot = fresh.first?.renderBounds, dot.width < 9, dot.height < 9,
        !parent.pencilOnly
      {
        // Küçük bir nokta dokunma sayılır: çizimden çıkarılır ve kutu seçilir.
        update(canvasView, drawing, to: kept)
        notify { $0.onTap(CGPoint(x: dot.midX, y: dot.midY)) }
        return
      }
      // Kutu dışına taşan kısımlar atılır; çizim alanına kırpılmış hali yazılır.
      let pieces = fresh.flatMap {
        parent.inkRects.isEmpty ? [$0] : StrokeMath.clip($0, to: parent.inkRects)
      }
      let isClipped =
        pieces.count != fresh.count
        || zip(pieces, fresh).contains { $0.path.count != $1.path.count }
      update(canvasView, drawing, to: kept + pieces, force: isClipped)
      let stroke = pieces.max(by: { $0.path.count < $1.path.count }).map {
        CGPoint(x: $0.renderBounds.midX, y: $0.renderBounds.midY)
      }
      if let stroke { notify { $0.onStroke(stroke) } }
    }

    /// Sonucu bilinen çizim yapar, çizim alanı farklıysa düzeltir ve değiştiyse modele bildirir.
    private func update(
      _ canvas: PKCanvasView, _ drawing: PKDrawing, to strokes: [PKStroke], force: Bool = false
    ) {
      let result = PKDrawing(strokes: strokes)
      if force || strokes.count != drawing.strokes.count { apply(result, to: canvas) }
      let changed =
        strokes.count != committed.strokes.count
        || zip(strokes, committed.strokes).contains { StrokeKey($0) != StrokeKey($1) }
      guard changed else { return }
      committed = result
      notify { $0.onChange(result) }
    }

    /// Çizim bildirimini bir sonraki ana döngüde iletir.
    ///
    /// PencilKit bu bildirimi SwiftUI'nin görünüm güncellemesi ya da yerleşimi sırasında da
    /// gönderebilir (araç değişince yarım kalan çizginin bitmesi, çizim atandıktan sonra gelen
    /// gecikmeli bildirim). O anda view model'e yazmak SwiftUI'da tanımsız davranıştır
    /// ("Publishing changes from within view updates"); çizginin kırpılması ise hemen yapılır.
    private func notify(_ deliver: @escaping @MainActor (DrawingCanvas) -> Void) {
      Task { @MainActor [weak self] in
        guard let self else { return }
        deliver(self.parent)
      }
    }

    /// Çizimi, değişiklik bildirimi tetiklemeden çizim alanına yazar.
    private func apply(_ drawing: PKDrawing, to canvas: PKCanvasView) {
      isApplying = true
      canvas.drawing = drawing
      isApplying = false
    }

    /// Silginin geçtiği noktayı içerik koordinatında bildirir.
    @objc func handleErase(_ recognizer: UILongPressGestureRecognizer) {
      guard recognizer.state == .began || recognizer.state == .changed,
        let canvas = recognizer.view as? PKCanvasView
      else { return }
      let location = recognizer.location(in: canvas)
      let point = CGPoint(x: location.x / canvas.zoomScale, y: location.y / canvas.zoomScale)
      notify { $0.onErase?(point) }
    }

    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      true
    }

    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
      guard let canvas = recognizer.view as? PKCanvasView else { return }
      let location = recognizer.location(in: canvas)
      parent.onTap(CGPoint(x: location.x / canvas.zoomScale, y: location.y / canvas.zoomScale))
    }
  }
}

/// Çizim alanının kabı: arkada alttaki içerik, önde mürekkep maskeli PencilKit alanı.
final class CanvasContainerView: UIView {
  /// PencilKit çizim alanı.
  let canvas = ZoomingCanvasView()
  /// Çizim alanını taşıyan ve maskelenen katman.
  private let inkView = UIView()
  /// Mürekkep kutularının birleşimi (ölçek 1 içerik koordinatında).
  private let maskLayer = CAShapeLayer()

  override init(frame: CGRect) {
    super.init(frame: frame)
    clipsToBounds = true
    backgroundColor = .clear
    inkView.backgroundColor = .clear
    canvas.backgroundColor = .clear
    canvas.isOpaque = false
    canvas.showsHorizontalScrollIndicator = false
    canvas.showsVerticalScrollIndicator = false
    maskLayer.anchorPoint = .zero
    maskLayer.position = .zero
    maskLayer.fillColor = UIColor.black.cgColor
    addSubview(inkView)
    inkView.addSubview(canvas)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) kullanılmaz")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    inkView.frame = bounds
    canvas.frame = bounds
  }

  /// Maskeyi verilen kutularla kurar; kutu yoksa maske kaldırılır.
  func setInkRects(_ rects: [CGRect]) {
    guard !rects.isEmpty else {
      inkView.layer.mask = nil
      return
    }
    let path = CGMutablePath()
    path.addRects(rects)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    maskLayer.path = path
    let box = path.boundingBoxOfPath
    maskLayer.bounds = CGRect(x: 0, y: 0, width: max(1, box.maxX), height: max(1, box.maxY))
    CATransaction.commit()
    inkView.layer.mask = maskLayer
  }

  /// Maskeyi içerik koordinatından ekran koordinatına taşır (yakınlaşma ve kaydırma).
  func alignMask(zoom: CGFloat, offset: CGPoint) {
    guard inkView.layer.mask != nil else { return }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    maskLayer.setAffineTransform(
      CGAffineTransform(a: zoom, b: 0, c: 0, d: zoom, tx: -offset.x, ty: -offset.y))
    CATransaction.commit()
  }
}

/// Yerleşim değiştiğinde haber veren çizim alanı.
///
/// PencilKit'in dokununca açılan düzenleme menüsü ("Tümünü Seç", "Boşluk Ekle") kapalıdır:
/// uygulama araç seçiciyi kullanmadığı için alan ilk yanıtlayıcı olmaz. Böylece menü açılmaz ve
/// klavye modundaki görünmez girişin odağı (dolayısıyla klavye ve ekran yerleşimi) korunur.
final class ZoomingCanvasView: PKCanvasView {
  var onLayout: ((PKCanvasView) -> Void)?

  override var canBecomeFirstResponder: Bool { false }

  override func layoutSubviews() {
    super.layoutSubviews()
    onLayout?(self)
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    removeEditMenus()
  }

  override func addInteraction(_ interaction: any UIInteraction) {
    guard !(interaction is UIEditMenuInteraction) else { return }
    super.addInteraction(interaction)
  }

  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    false
  }

  /// PencilKit'in eklediği düzenleme menüsü etkileşimlerini kaldırır.
  private func removeEditMenus() {
    for interaction in interactions where interaction is UIEditMenuInteraction {
      removeInteraction(interaction)
    }
  }
}

/// Bir çizgiyi çizim alanı ile model arasında tanımaya yeten özet (`PKStroke` eşitlenemez).
/// Kalem basıncı gibi sonradan güncellenebilen özellikler dahil edilmez.
private struct StrokeKey: Hashable {
  let created: TimeInterval
  let points: Int
  let startX: Int
  let startY: Int

  init(_ stroke: PKStroke) {
    created = stroke.path.creationDate.timeIntervalSinceReferenceDate
    points = stroke.path.count
    let start = stroke.path.first?.location ?? .zero
    startX = Int((start.x * 10).rounded())
    startY = Int((start.y * 10).rounded())
  }
}
