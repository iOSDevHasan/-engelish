import Combine
import ContentKit
import DesignKit
import Foundation
import PencilKit
import PurchaseKit
import PuzzleKit
import UserDataKit
import WordKit

/// İpucu türü.
enum HintKind {
  case letter
  case word

  /// Hak bedeli.
  var cost: Int { self == .letter ? HintRules.letterCost : HintRules.wordCost }
}

/// Bulmaca ekranının durumu ve kullanıcı eylemleri.
@MainActor
final class PuzzleViewModel: ObservableObject {

  // MARK: - Published state

  @Published private(set) var layout: CrosswordLayout?
  @Published private(set) var title = ""
  @Published private(set) var subtitle = ""
  @Published private(set) var drawing = PKDrawing()
  @Published private(set) var drawingRevision = 0
  @Published private(set) var selected: PuzzleEntry? {
    didSet {
      if oldValue != selected { deriveInlineFocus() }
    }
  }
  @Published private(set) var activeCell: GridPoint?
  @Published private(set) var revealed: Set<GridPoint> = []
  @Published private(set) var elapsed = 0
  @Published private(set) var settings = AppSettings()
  @Published private(set) var isPremium = false
  @Published private(set) var hintsLeft: Int?
  @Published var tool: DrawingTool = .pen
  @Published var isHintSheetPresented = false
  @Published var isThemeSheetPresented = false
  @Published var isFocusPresented = false
  @Published private(set) var focusDrawing = PKDrawing()
  @Published private(set) var focusRevision = 0
  @Published private(set) var isMissing = false
  /// Kalemle yazılmış harf kutuları (iPad listesindeki ✓ için).
  @Published private(set) var filledCells: Set<GridPoint> = []
  /// Kayıtlı doğru / yanlış işaretleri.
  @Published private(set) var marks: [String: Bool] = [:]
  /// Katlanabilir yerleşimde ızgaranın yanında odak alanı açık mı.
  @Published private(set) var isInlineFocus = false
  /// Yakınlaştırma göstergeleri (ayrı nesne; kaydırırken ekranın tamamı yenilenmez).
  let zoom: ZoomState

  // MARK: - Dependencies

  private let puzzleId: String
  private let coordinator: PuzzleCoordinator
  private let content: any ContentProviding
  private let userData: any UserDataStoring
  private let entitlements: any EntitlementProviding
  private var words: [String: Word] = [:]
  private var nextPuzzleId: String?
  private var baseDuration = 0
  private var openedAt = Date.now
  private var hintsUsed = 0
  private var timerTask: Task<Void, Never>?
  private var saveTask: Task<Void, Never>?
  private var advanceTask: Task<Void, Never>?
  private var focusSourceRects: [CGRect] = []
  private var cancellables: Set<AnyCancellable> = []

  // MARK: - Init

  init(
    puzzleId: String, coordinator: PuzzleCoordinator, content: any ContentProviding,
    userData: any UserDataStoring, entitlements: any EntitlementProviding,
    zoom: ZoomState = ZoomState()
  ) {
    self.zoom = zoom
    self.puzzleId = puzzleId
    self.coordinator = coordinator
    self.content = content
    self.userData = userData
    self.entitlements = entitlements
    refreshSettings()
    userData.changes.merge(with: entitlements.changes)
      .sink { [weak self] in self?.refreshSettings() }
      .store(in: &cancellables)
  }

  // MARK: - Lifecycle

  /// Bulmacayı, kelimeleri ve kayıtlı ilerlemeyi yükler.
  func load() async {
    guard layout == nil else { return startTimer() }
    guard let puzzle = await content.puzzle(id: puzzleId) else {
      isMissing = true
      return
    }
    let loadedWords = await content.words(ids: puzzle.wordIds)
    words = Dictionary(uniqueKeysWithValues: loadedWords.map { ($0.id, $0) })
    if let packId = puzzle.packId, let pack = await content.pack(id: packId) {
      let index = pack.puzzleIds.firstIndex(of: puzzle.id) ?? 0
      title = pack.title
      subtitle = "\(puzzle.level.rawValue) · Bulmaca \(index + 1)"
      nextPuzzleId = pack.puzzleIds.dropFirst(index + 1).first
    } else if puzzle.isReview {
      title = "Tekrar bulmacası"
      subtitle = "Defterindeki kelimeler · \(puzzle.entries.count) kelime"
    } else {
      title = "Günün Bulmacası"
      subtitle = "\(puzzle.level.rawValue) · \(DateText.dayMonth(.now))"
    }
    let progress = userData.progress(for: puzzle.id)
    if let data = progress.drawing, let saved = try? PKDrawing(data: data) {
      replaceDrawing(saved)
    }
    revealed = Set(progress.revealedCells.compactMap(GridPoint.init(key:)))
    hintsUsed = progress.hintsUsed
    marks = progress.marks
    baseDuration = progress.durationSec
    elapsed = baseDuration
    layout = CrosswordLayout(puzzle: puzzle)
    updateFilledCells()
    select(puzzle.entries.first)
    startTimer()
  }

  /// Ekrandan çıkarken kaydeder ve sayacı durdurur.
  func pause() {
    timerTask?.cancel()
    saveNow()
  }

  // MARK: - Selection

  /// Kelimeyi seçer ve ilk boş kutuyu etkin yapar.
  func select(_ entry: PuzzleEntry?) {
    selected = entry
    activeCell = entry?.cells.first
  }

  /// İpucu çubuğundaki ok: sonraki ya da önceki kelime.
  func step(_ delta: Int) {
    guard let layout, let selected else { return }
    select(layout.entry(after: selected, step: delta))
  }

  /// Çizim koordinatındaki dokunmayı işler: harf kutusuysa seçer, ipucu kutusuysa kelimeyi seçer.
  func tap(at location: CGPoint) {
    guard let layout,
      let point = CanvasMetrics.grid.point(at: location, rows: layout.rows, columns: layout.columns)
    else { return }
    switch layout.kind(at: point) {
    case .clue(let entries):
      select(entries.first { $0.dir != selected?.dir } ?? entries.first)
    case .letter:
      let sameCellTapped = point == activeCell
      let direction = sameCellTapped ? (selected?.dir == .across ? .down : .across) : selected?.dir
      selected = layout.entry(at: point, preferring: direction)
      activeCell = point
    case .blank:
      break
    }
  }

  /// Bir çizgi bitince etkin kutuyu günceller ve otomatik ilerlemeyi planlar.
  func strokeEnded(at location: CGPoint) {
    guard let layout,
      let point = CanvasMetrics.grid.point(
        at: location, rows: layout.rows, columns: layout.columns),
      layout.kind(at: point) == .letter
    else { return }
    advanceTask?.cancel()
    if point != activeCell {
      activeCell = point
      if let selected, !selected.cells.contains(point) {
        self.selected = layout.entry(at: point, preferring: selected.dir)
      }
    }
    scheduleAdvance(from: point)
  }

  /// Ayar açıksa, kısa bir beklemeden sonra etkin kutuyu kelimenin sonraki kutusuna taşır.
  private func scheduleAdvance(from point: GridPoint) {
    guard settings.autoAdvance, let entry = selected, let index = entry.cells.firstIndex(of: point),
      index + 1 < entry.cells.count
    else { return }
    let next = entry.cells[index + 1]
    advanceTask = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(1100))
      guard !Task.isCancelled else { return }
      self?.activeCell = next
    }
  }

  // MARK: - Drawing

  /// Kullanıcı çizdiğinde çağrılır; kaydı biraz bekletir.
  func drawingChanged(_ newDrawing: PKDrawing) {
    drawing = newDrawing
    updateFilledCells()
    deriveInlineFocus()
    scheduleSave()
  }

  /// Seçili kelimenin kutularındaki yazıları siler.
  func clearSelectedWord() {
    guard let selected else { return }
    let rects = selected.cells.map(CanvasMetrics.grid.rect(for:))
    let result = StrokeMath.split(drawing.strokes, into: rects)
    replaceDrawing(PKDrawing(strokes: result.rest))
    updateFilledCells()
    deriveInlineFocus()
    scheduleSave()
  }

  // MARK: - Focus mode

  /// Seçili kelimeyi büyük kutularda yazmak için odak modunu açar.
  func openFocus() {
    guard let selected, !isInlineFocus else { return }
    if let activeCell, !selected.cells.contains(activeCell) {
      self.activeCell = selected.cells.first
    }
    focusSourceRects = selected.cells.map(CanvasMetrics.grid.rect(for:))
    let extracted = Self.extractFocus(selected, from: drawing.strokes)
    replaceDrawing(PKDrawing(strokes: extracted.rest))
    focusDrawing = PKDrawing(strokes: extracted.focus)
    focusRevision += 1
    isFocusPresented = true
  }

  /// Odak modundaki çizimi günceller; yan odak alanında ızgaraya da hemen yansıtır.
  func focusChanged(_ newDrawing: PKDrawing) {
    focusDrawing = newDrawing
    guard isInlineFocus, !isFocusPresented, let selected else { return }
    let rest = StrokeMath.split(drawing.strokes, into: Self.gridRects(selected)).rest
    replaceDrawing(PKDrawing(strokes: Self.mergeFocus(selected, newDrawing.strokes, into: rest)))
    updateFilledCells()
    scheduleSave()
  }

  /// Odak kutusunda bir çizgi bitince o kutuyu etkin yapar ve otomatik ilerlemeyi planlar.
  func focusStrokeEnded(at location: CGPoint) {
    guard let point = focusCell(at: location) else { return }
    advanceTask?.cancel()
    activeCell = point
    scheduleAdvance(from: point)
  }

  /// Odak kutusuna dokunulunca o kutuyu etkin yapar.
  func focusTap(at location: CGPoint) {
    guard let point = focusCell(at: location) else { return }
    advanceTask?.cancel()
    activeCell = point
  }

  /// Odak modundaki yazıları siler.
  func clearFocus() {
    focusChanged(PKDrawing())
    focusRevision += 1
  }

  /// Katlanabilir yerleşimde yan odak alanını açar ya da kapatır.
  func setInlineFocus(_ isOn: Bool) {
    guard isOn != isInlineFocus else { return }
    if isOn, isFocusPresented { closeFocus() }
    isInlineFocus = isOn
    if isOn {
      deriveInlineFocus()
    } else {
      focusDrawing = PKDrawing()
      focusRevision += 1
    }
  }

  /// Odak modunu kapatır ve yazılanları ızgaraya taşır.
  func closeFocus(moveTo step: Int = 0) {
    guard let selected, isFocusPresented else { return }
    let count = selected.cells.count
    let boxes = (0..<count).map { CanvasMetrics.focusRect(index: $0, count: count) }
    let result = StrokeMath.split(focusDrawing.strokes, into: boxes)
    var strokes = drawing.strokes
    for (index, matched) in result.matched.enumerated() where index < focusSourceRects.count {
      let transform = StrokeMath.transform(from: boxes[index], to: focusSourceRects[index])
      strokes += matched.map { StrokeMath.move($0, by: transform) }
    }
    replaceDrawing(PKDrawing(strokes: strokes))
    focusDrawing = PKDrawing()
    updateFilledCells()
    scheduleSave()
    if step != 0 {
      self.step(step)
      openFocus()
    } else {
      isFocusPresented = false
    }
  }

  // MARK: - Hints

  /// İpucu kullanır; hak yetmezse paywall açar.
  func useHint(_ kind: HintKind) {
    guard let selected else { return }
    let cells: [GridPoint]
    switch kind {
    case .letter:
      let target = activeCell.flatMap { selected.cells.contains($0) ? $0 : nil }
      cells = [target ?? selected.cells.first { !revealed.contains($0) } ?? selected.cells[0]]
    case .word:
      cells = selected.cells
    }
    guard userData.consumeHints(kind.cost, isPremium: isPremium) else {
      return openPaywall()
    }
    revealed.formUnion(cells)
    hintsUsed += kind.cost
    userData.saveRevealed(puzzleId: puzzleId, cells: Set(revealed.map(\.key)), hintsUsed: hintsUsed)
    hintsLeft = userData.hintsLeft(isPremium: isPremium)
    isHintSheetPresented = false
  }

  /// Paywall'u açar.
  func openPaywall() {
    isHintSheetPresented = false
    // Paywall gezinme yığınına eklenir; tam ekran odak modu açıksa önce kapatılır.
    if isFocusPresented { closeFocus() }
    coordinator.showPaywall()
  }

  // MARK: - Theme

  /// Bulmaca temasını değiştirir; premium tema kilitliyse paywall açar.
  func selectTheme(_ theme: PuzzleTheme) {
    guard !theme.isPremium || isPremium else {
      isThemeSheetPresented = false
      return coordinator.showPaywall()
    }
    userData.updateSettings { $0.puzzleTheme = theme.id }
  }

  /// Kalem rengini değiştirir.
  func selectPenColor(_ id: String) {
    userData.updateSettings { $0.penColor = id }
  }

  /// Tüm temalar ekranını açar.
  func openAllThemes() {
    isThemeSheetPresented = false
    coordinator.showThemes()
  }

  // MARK: - Navigation

  /// Geri gider.
  func back() {
    pause()
    coordinator.back()
  }

  /// Cevap anahtarını açar.
  func openAnswerKey() {
    guard let session = makeSession() else { return }
    pause()
    coordinator.showAnswerKey(session)
  }

  // MARK: - Derived

  /// Izgarada vurgulanan kutular.
  var highlighted: Set<GridPoint> { Set(selected?.cells ?? []) }

  /// Seçili kelimenin ipucu kutusu.
  var activeClue: GridPoint? { selected?.clueCell }

  /// Etkin kutuların ipucu harfleri.
  var revealedLetters: [GridPoint: (Character, GridLetterStyle)] {
    guard let layout else { return [:] }
    var letters: [GridPoint: (Character, GridLetterStyle)] = [:]
    for point in revealed {
      if let char = layout.answer(at: point) { letters[point] = (char, .revealed) }
    }
    return letters
  }

  /// Odak modunda etkin kutunun sırası.
  var focusActiveIndex: Int? {
    guard let activeCell else { return nil }
    return selected?.cells.firstIndex(of: activeCell)
  }

  /// Odak modundaki önceki / sonraki butonlarında gösterilen komşu kelime ipuçları.
  var neighbourLabels: (previous: String, next: String) {
    guard let layout, let selected else { return ("Önceki", "Sonraki") }
    return EntryNavigation.neighbourLabels(in: layout, around: selected)
  }

  /// Kelime yazılmış ya da doğru işaretlenmiş mi (iPad ipucu listesi).
  func isDone(_ entry: PuzzleEntry) -> Bool {
    EntryNavigation.isDone(entry, filled: filledCells, revealed: revealed, marks: marks)
  }

  /// Sayaç metni (dd:ss).
  var timerText: String {
    String(format: "%02d:%02d", elapsed / 60, elapsed % 60)
  }

  // MARK: - Private

  private func refreshSettings() {
    settings = userData.settings
    isPremium = entitlements.isPremium
    hintsLeft = userData.hintsLeft(isPremium: isPremium)
  }

  /// Yazılmış harf kutularını çizimden yeniden hesaplar.
  private func updateFilledCells() {
    guard let layout else { return }
    var cells = Set<GridPoint>()
    for stroke in drawing.strokes {
      let bounds = stroke.renderBounds
      let center = CGPoint(x: bounds.midX, y: bounds.midY)
      if let point = CanvasMetrics.grid.point(
        at: center, rows: layout.rows, columns: layout.columns),
        layout.kind(at: point) == .letter
      {
        cells.insert(point)
      }
    }
    if cells != filledCells { filledCells = cells }
  }

  /// Yan odak alanının çizimini ızgaradaki seçili kelimenin yazılarından üretir.
  private func deriveInlineFocus() {
    guard isInlineFocus, !isFocusPresented, let selected else { return }
    focusDrawing = PKDrawing(strokes: Self.extractFocus(selected, from: drawing.strokes).focus)
    focusRevision += 1
  }

  /// Odak koordinatındaki noktanın düştüğü kelime kutusu.
  private func focusCell(at location: CGPoint) -> GridPoint? {
    guard let selected else { return nil }
    let count = selected.cells.count
    let index = (0..<count).first {
      CanvasMetrics.focusRect(index: $0, count: count).contains(location)
    }
    return index.map { selected.cells[$0] }
  }

  /// Seçili kelimenin ızgaradaki kutu çerçeveleri.
  private static func gridRects(_ entry: PuzzleEntry) -> [CGRect] {
    entry.cells.map(CanvasMetrics.grid.rect(for:))
  }

  /// Izgara çizgilerinden kelimenin kutularına düşenleri odak kutularına taşır.
  static func extractFocus(
    _ entry: PuzzleEntry, from strokes: [PKStroke]
  ) -> (focus: [PKStroke], rest: [PKStroke]) {
    let sources = gridRects(entry)
    let result = StrokeMath.split(strokes, into: sources)
    var focus: [PKStroke] = []
    for (index, matched) in result.matched.enumerated() {
      let target = CanvasMetrics.focusRect(index: index, count: entry.cells.count)
      let transform = StrokeMath.transform(from: sources[index], to: target)
      focus += matched.map { StrokeMath.move($0, by: transform) }
    }
    return (focus, result.rest)
  }

  /// Odak kutularındaki çizgileri ızgara kutularına taşıyıp kalan çizgilere ekler.
  static func mergeFocus(
    _ entry: PuzzleEntry, _ focusStrokes: [PKStroke], into rest: [PKStroke]
  ) -> [PKStroke] {
    let count = entry.cells.count
    let boxes = (0..<count).map { CanvasMetrics.focusRect(index: $0, count: count) }
    let targets = gridRects(entry)
    let result = StrokeMath.split(focusStrokes, into: boxes)
    var strokes = rest
    for (index, matched) in result.matched.enumerated() {
      let transform = StrokeMath.transform(from: boxes[index], to: targets[index])
      strokes += matched.map { StrokeMath.move($0, by: transform) }
    }
    return strokes
  }

  /// Çizimi dışarıdan değiştirir ve çizim alanına yansıtır.
  private func replaceDrawing(_ newDrawing: PKDrawing) {
    drawing = newDrawing
    drawingRevision += 1
  }

  private func startTimer() {
    timerTask?.cancel()
    openedAt = .now
    baseDuration = elapsed
    timerTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))
        guard let self, !Task.isCancelled else { return }
        self.elapsed = self.baseDuration + Int(Date.now.timeIntervalSince(self.openedAt))
      }
    }
  }

  private func scheduleSave() {
    saveTask?.cancel()
    saveTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(1.5))
      guard !Task.isCancelled else { return }
      self?.saveNow()
    }
  }

  private func saveNow() {
    guard layout != nil else { return }
    saveTask?.cancel()
    userData.saveDraft(
      puzzleId: puzzleId, drawing: drawing.dataRepresentation(), durationSec: elapsed)
  }

  private func makeSession() -> PuzzleSession? {
    guard let layout else { return nil }
    if isFocusPresented { closeFocus() }
    return PuzzleSession(
      puzzle: layout.puzzle, title: title, words: words,
      drawingData: drawing.dataRepresentation(), revealed: revealed,
      marks: userData.progress(for: puzzleId).marks, durationSec: elapsed,
      nextPuzzleId: nextPuzzleId)
  }
}
