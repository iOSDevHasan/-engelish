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
  /// Klavyeyle yazılan harfler.
  @Published private(set) var typed: [GridPoint: Character] = [:]
  /// Mürekkebin görünebildiği ızgara kutuları: açılmamış harf kutuları (ölçek 1).
  @Published private(set) var inkRects: [CGRect] = []
  @Published private(set) var elapsed = 0
  @Published private(set) var settings = AppSettings()
  @Published private(set) var isPremium = false
  @Published private(set) var hintsLeft: Int?
  @Published var tool: DrawingTool = .pen {
    didSet {
      if tool == .keyboard, oldValue != .keyboard { prepareKeyboard() }
    }
  }
  @Published var isHintSheetPresented = false
  @Published var isThemeSheetPresented = false
  @Published var isFocusPresented = false
  /// Klavye modunda kutuya her dokunuşta artar; klavye yeniden açılır.
  @Published private(set) var keyboardRequest = 0
  /// Bulmaca dolunca klavye geçici olarak kapatılır ("Bitirdim" görünsün); kutu seçilince açılır.
  @Published private(set) var isKeyboardParked = false
  /// Sistem klavyesi şu an açık mı (telefonda ızgaraya yer açmak için).
  @Published private(set) var isKeyboardShown = false
  @Published private(set) var focusDrawing = PKDrawing()
  @Published private(set) var focusRevision = 0
  @Published private(set) var isMissing = false
  /// Kalemle ya da klavyeyle yazılmış harf kutuları (iPad listesindeki ✓ için).
  @Published private(set) var filledCells: Set<GridPoint> = []
  /// Kayıtlı doğru / yanlış işaretleri.
  @Published private(set) var marks: [String: Bool] = [:]
  /// "Bitirdim"e boş kutu varken basılınca gösterilen uyarı (her basışta yenilenir).
  @Published private(set) var finishNudge: FinishNudge?
  /// Katlanabilir yerleşimde ızgaranın yanında odak alanı açık mı.
  @Published private(set) var isInlineFocus = false
  /// Bulmaca daha önce bitirildi mi. Bitmiş bulmaca salt okunurdur: ızgarada doğru cevaplar
  /// görünür; yazma, ipucu, cevap anahtarı ve "Bitirdim" yoktur, ilerleme değişmez.
  @Published private(set) var isCompleted = false
  /// Bitmiş bulmacada doğru işaretlenen kelime sayısı.
  @Published private(set) var correctCount = 0
  /// Geri alınacak yazı var mı.
  @Published private(set) var canUndo = false
  /// Yinelenecek (geri alınmış) yazı var mı.
  @Published private(set) var canRedo = false
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
  private var savedTyped: [String: String] = [:]
  private var timerTask: Task<Void, Never>?
  private var saveTask: Task<Void, Never>?
  private var advanceTask: Task<Void, Never>?
  private var focusSourceRects: [CGRect] = []
  private var undoStack: [InkSnapshot] = []
  private var redoStack: [InkSnapshot] = []
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
    revealed = Set(progress.revealedCells.compactMap(GridPoint.init(key:)))
    typed = Self.decodeTyped(progress.typedLetters)
    savedTyped = progress.typedLetters
    hintsUsed = progress.hintsUsed
    marks = progress.marks
    baseDuration = progress.durationSec
    elapsed = baseDuration
    let loadedLayout = CrosswordLayout(puzzle: puzzle)
    if progress.finishedAt != nil {
      return showCompleted(loadedLayout)
    }
    layout = loadedLayout
    refreshInkRects()
    if let data = progress.drawing, let saved = try? PKDrawing(data: data) {
      // Eski sürümlerde kutu dışına taşan mürekkep yüklerken temizlenir.
      replaceDrawing(PKDrawing(strokes: StrokeMath.clip(saved.strokes, to: inkRects).strokes))
    }
    updateFilledCells()
    select(puzzle.entries.first)
    startTimer()
  }

  /// Bitmiş bulmacayı salt okunur açar: tüm kutularda doğru cevap görünür, mürekkep ve klavye
  /// harfleri gösterilmez, sayaç çalışmaz. Kayıtlı ilerleme değiştirilmez.
  private func showCompleted(_ loadedLayout: CrosswordLayout) {
    isCompleted = true
    tool = .pen
    typed = [:]
    revealed = Set(loadedLayout.letterCells)
    correctCount = loadedLayout.puzzle.entries.filter { marks[$0.id] == true }.count
    layout = loadedLayout
    refreshInkRects()
    updateFilledCells()
    selected = loadedLayout.puzzle.entries.first
    activeCell = nil
  }

  /// Ekrandan çıkarken kaydeder ve sayacı durdurur.
  func pause() {
    timerTask?.cancel()
    saveNow()
  }

  // MARK: - Selection

  /// Kelimeyi seçer ve ilk boş kutuyu (yoksa ilk kutuyu) etkin yapar.
  func select(_ entry: PuzzleEntry?) {
    selected = entry
    activeCell =
      entry?.cells.first { !filledCells.contains($0) && !revealed.contains($0) }
      ?? entry?.cells.first
    requestKeyboard()
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
      advanceTask?.cancel()
      let sameCellTapped = point == activeCell
      let direction = sameCellTapped ? (selected?.dir == .across ? .down : .across) : selected?.dir
      selected = layout.entry(at: point, preferring: direction)
      activeCell = point
      requestKeyboard()
    case .blank:
      break
    }
  }

  /// Bir çizgi bitince etkin kutuyu günceller ve otomatik ilerlemeyi planlar.
  func strokeEnded(at location: CGPoint) {
    guard !isCompleted, let layout,
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

  /// Kullanıcı çizdiğinde çağrılır; kaydı biraz bekletir. Mürekkep yazılan kutudaki klavye harfi
  /// silinir (son yazılan geçerlidir).
  func drawingChanged(_ newDrawing: PKDrawing) {
    guard !isCompleted, newDrawing != drawing else { return }
    recordUndo()
    drawing = newDrawing
    updateFilledCells()
    deriveInlineFocus()
    scheduleSave()
  }

  /// Seçili kelimenin kutularındaki yazıları (mürekkep ve klavye harfleri) siler.
  func clearSelectedWord() {
    guard !isCompleted, let selected else { return }
    recordUndo()
    clear(Set(selected.cells))
    scheduleSave()
  }

  // MARK: - Undo

  /// Son yazma işlemini (çizgi, silgi, klavye harfi, temizleme) geri alır.
  func undo() {
    guard !isCompleted, let previous = undoStack.popLast() else { return }
    redoStack.append(snapshot)
    restore(previous)
  }

  /// Geri alınan işlemi yineler.
  func redo() {
    guard !isCompleted, let next = redoStack.popLast() else { return }
    undoStack.append(snapshot)
    restore(next)
  }

  /// Silgi klavye harfinin üstünden geçince harfi siler (ızgara koordinatında).
  func erase(at location: CGPoint) {
    guard !isCompleted, let layout,
      let point = CanvasMetrics.grid.point(at: location, rows: layout.rows, columns: layout.columns)
    else { return }
    eraseTyped(point)
  }

  /// Odak kutularında silgi klavye harfinin üstünden geçince harfi siler.
  func focusErase(at location: CGPoint) {
    guard !isCompleted, let point = focusCell(at: location) else { return }
    eraseTyped(point)
  }

  /// Kutudaki klavye harfini geri alınabilir biçimde siler.
  private func eraseTyped(_ cell: GridPoint) {
    guard typed[cell] != nil, !revealed.contains(cell) else { return }
    recordUndo()
    typed[cell] = nil
    updateFilledCells()
    scheduleSave()
  }

  /// Şu anki yazı durumu.
  private var snapshot: InkSnapshot {
    InkSnapshot(drawing: drawing, focusDrawing: focusDrawing, typed: typed)
  }

  /// Değişiklikten önce durumu geri alma yığınına ekler; yineleme yığını boşalır.
  private func recordUndo() {
    undoStack.append(snapshot)
    if undoStack.count > Self.historyLimit { undoStack.removeFirst() }
    redoStack.removeAll()
    refreshHistoryFlags()
  }

  /// Geri al / yinele geçmişini siler (odak modu açılıp kapanınca, ipucundan sonra).
  private func resetHistory() {
    undoStack.removeAll()
    redoStack.removeAll()
    refreshHistoryFlags()
  }

  /// Kayıtlı durumu ızgaraya ve (açıksa) odak alanına geri yazar.
  private func restore(_ state: InkSnapshot) {
    advanceTask?.cancel()
    replaceDrawing(state.drawing)
    typed = state.typed
    if isFocusPresented {
      focusDrawing = state.focusDrawing
      focusRevision += 1
    } else {
      deriveInlineFocus()
    }
    updateFilledCells()
    refreshHistoryFlags()
    scheduleSave()
  }

  private func refreshHistoryFlags() {
    if canUndo == undoStack.isEmpty { canUndo = !undoStack.isEmpty }
    if canRedo == redoStack.isEmpty { canRedo = !redoStack.isEmpty }
  }

  /// Geri alınabilecek en fazla adım.
  private static let historyLimit = 100

  // MARK: - Keyboard

  /// Klavye modunda yazılan metni işler: harf seçili kutuya yazılır ve sonraki kutuya geçilir,
  /// boşluk bir kutu ilerler. Kutudaki mürekkep silinir (son yazılan geçerlidir).
  func typeText(_ text: String) {
    guard !isCompleted, let selected else { return }
    advanceTask?.cancel()
    if text == " " {
      if let cell = activeCell,
        let next = TypedInput.nextCell(in: selected, after: cell, revealed: revealed)
      {
        activeCell = next
      }
      return
    }
    guard let letter = TypedInput.letter(from: text),
      let cell = TypedInput.writableCell(in: selected, from: activeCell, revealed: revealed)
    else { return }
    recordUndo()
    removeInk(in: [cell])
    typed[cell] = letter
    let next = TypedInput.nextCell(in: selected, after: cell, revealed: revealed)
    activeCell = next ?? cell
    updateFilledCells()
    scheduleSave()
    if emptyCells.isEmpty {
      // Bulmaca doldu: klavye kapanır, alttaki "Bitirdim" görünür. Kutuya dokununca yeniden açılır.
      isKeyboardParked = true
    } else if next == nil, settings.autoAdvance {
      // Kelimenin son kutusu yazıldıysa sıradaki eksik kelimeye geçilir; harfler son kutunun
      // üstüne yazılıp durmaz.
      selectNextIncompleteEntry(after: selected)
    }
  }

  /// Verilen kelimeden sonra (sırayla, başa dönerek) boş kutusu olan ilk kelimeyi seçer; kelime
  /// kendisi de dahil hepsi doluysa seçim değişmez.
  private func selectNextIncompleteEntry(after entry: PuzzleEntry) {
    guard let layout else { return }
    let entries = layout.puzzle.entries
    guard let index = entries.firstIndex(of: entry) else { return }
    for offset in 1..<max(entries.count, 1) {
      let candidate = entries[(index + offset) % entries.count]
      if candidate.cells.contains(where: { !filledCells.contains($0) && !revealed.contains($0) }) {
        return select(candidate)
      }
    }
  }

  /// Silme tuşu: etkin kutu doluysa temizler, boşsa önceki kutuya geçip onu temizler.
  func deleteBackward() {
    guard !isCompleted, let selected, let cell = activeCell, selected.cells.contains(cell) else {
      return
    }
    advanceTask?.cancel()
    if !revealed.contains(cell), filledCells.contains(cell) {
      recordUndo()
      clear([cell])
    } else if let previous = TypedInput.previousCell(in: selected, before: cell, revealed: revealed)
    {
      activeCell = previous
      recordUndo()
      clear([previous])
    } else {
      return
    }
    scheduleSave()
  }

  /// Klavyedeki "Sonraki" tuşu: sonraki kelimeye geçer.
  func keyboardReturn() {
    step(1)
  }

  /// Sistem klavyesinin açılıp kapandığını bildirir.
  func keyboardFocusChanged(_ isShown: Bool) {
    if isKeyboardShown != isShown { isKeyboardShown = isShown }
  }

  /// Klavye modunda klavyenin açık olması gerekiyor mu (panel açıkken kapalı kalır).
  var wantsKeyboard: Bool {
    !isCompleted && tool == .keyboard && !isHintSheetPresented && !isThemeSheetPresented
      && !isKeyboardParked
  }

  /// Klavye moduna geçince etkin kutu yoksa seçili kelimenin ilk boş kutusunu seçer.
  private func prepareKeyboard() {
    advanceTask?.cancel()
    guard let selected, let activeCell, selected.cells.contains(activeCell) else {
      return select(selected ?? layout?.puzzle.entries.first)
    }
    requestKeyboard()
  }

  /// Klavye modundaysa klavyeyi yeniden açtırır.
  private func requestKeyboard() {
    guard tool == .keyboard else { return }
    isKeyboardParked = false
    keyboardRequest += 1
  }

  // MARK: - Focus mode

  /// Seçili kelimeyi büyük kutularda yazmak için odak modunu açar.
  func openFocus() {
    guard !isCompleted, let selected, !isInlineFocus else { return }
    if let activeCell, !selected.cells.contains(activeCell) {
      self.activeCell = selected.cells.first
    }
    focusSourceRects = selected.cells.map(CanvasMetrics.grid.rect(for:))
    let extracted = Self.extractFocus(selected, from: drawing.strokes)
    replaceDrawing(PKDrawing(strokes: extracted.rest))
    focusDrawing = PKDrawing(strokes: extracted.focus)
    focusRevision += 1
    resetHistory()
    isFocusPresented = true
  }

  /// Odak modundaki çizimi günceller; yan odak alanında ızgaraya da hemen yansıtır.
  func focusChanged(_ newDrawing: PKDrawing) {
    guard !isCompleted, newDrawing != focusDrawing else { return }
    recordUndo()
    applyFocusDrawing(newDrawing)
  }

  /// Odak çizimini yazar; yan odak alanında ızgaraya da yansıtır.
  private func applyFocusDrawing(_ newDrawing: PKDrawing) {
    focusDrawing = newDrawing
    guard isInlineFocus, !isFocusPresented, let selected else { return updateFilledCells() }
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
    requestKeyboard()
  }

  /// Odak modundaki yazıları (mürekkep ve klavye harfleri) siler.
  func clearFocus() {
    recordUndo()
    if let selected {
      for cell in selected.cells { typed[cell] = nil }
    }
    applyFocusDrawing(PKDrawing())
    focusRevision += 1
    scheduleSave()
  }

  /// Odak kutularından mürekkebin görünebildiği (açılmamış) kutular.
  func focusInkRects(for entry: PuzzleEntry) -> [CGRect] {
    let count = entry.cells.count
    return entry.cells.indices
      .filter { !revealed.contains(entry.cells[$0]) }
      .map { CanvasMetrics.focusRect(index: $0, count: count) }
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
    resetHistory()
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
  ///
  /// Harf ipucu seçili kutuyu (açıksa kelimedeki sonraki açılmamış kutuyu) açar ve etkin kutuyu
  /// bir sonraki açılmamış kutuya taşır; böylece art arda kullanılan ipuçları hep yeni harf açar.
  /// Açılan kutulardaki mürekkep ve klavye harfleri silinir ki ipucu harfi görünsün. Kelimenin
  /// tamamı zaten açıksa hak harcanmaz.
  func useHint(_ kind: HintKind) {
    guard !isCompleted, let selected else { return }
    let cells: [GridPoint]
    switch kind {
    case .letter:
      cells =
        HintPicker.letterTarget(
          in: selected, active: activeCell, revealed: revealed, filled: filledCells
        ).map { [$0] } ?? []
    case .word:
      cells = HintPicker.wordTargets(in: selected, revealed: revealed)
    }
    guard !cells.isEmpty else {
      isHintSheetPresented = false
      return
    }
    guard userData.consumeHints(kind.cost, isPremium: isPremium) else {
      return openPaywall()
    }
    clear(Set(cells))
    revealed.formUnion(cells)
    // Açılan kutulara eski yazı geri gelmesin diye geçmiş sıfırlanır.
    resetHistory()
    refreshInkRects()
    if let last = cells.last {
      activeCell = TypedInput.nextCell(in: selected, after: last, revealed: revealed) ?? last
    }
    hintsUsed += kind.cost
    userData.saveRevealed(puzzleId: puzzleId, cells: Set(revealed.map(\.key)), hintsUsed: hintsUsed)
    hintsLeft = userData.hintsLeft(isPremium: isPremium)
    updateFilledCells()
    scheduleSave()
    isHintSheetPresented = false
  }

  /// Seçili kelimede ipucuyla açılmamış kutu var mı.
  var canReveal: Bool {
    selected.map { !HintPicker.wordTargets(in: $0, revealed: revealed).isEmpty } ?? false
  }

  /// İpucu hakkı bu türe yetiyor mu (Plus'ta sınırsız).
  func canAfford(_ kind: HintKind) -> Bool {
    hintsLeft.map { $0 >= kind.cost } ?? true
  }

  /// Paywall'u açar.
  func openPaywall() {
    isHintSheetPresented = false
    // Paywall gezinme yığınına eklenir; tam ekran odak modu açıksa önce kapatılır.
    if isFocusPresented { closeFocus() }
    coordinator.showPaywall()
  }

  // MARK: - Theme

  /// Bulmaca temasını değiştirir; tema Çengelish Plus gerektiriyorsa ve kilitliyse paywall açar.
  ///
  /// Elle seçilen tema her zaman uygulanır: yüksek kontrast (tüm temaları siyah-beyaz yapar)
  /// kapanır; kendi koyu görünümü olmayan bir tema seçilince "Koyu modda Gece teması" da kapanır.
  func selectTheme(_ theme: PuzzleTheme) {
    guard !theme.isPremium || isPremium else {
      isThemeSheetPresented = false
      return coordinator.showPaywall()
    }
    userData.updateSettings {
      $0.puzzleTheme = theme.id
      $0.highContrast = false
      if !theme.keepsInDarkMode { $0.autoNightTheme = false }
    }
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

  /// Cevap anahtarına göz atar (işaretleme ve bitirme yok; bulmacaya geri dönülür).
  func openAnswerKey() {
    guard !isCompleted, let session = makeSession() else { return }
    pause()
    coordinator.showAnswerKey(session, purpose: .peek)
  }

  /// "Bitirdim": tüm kutular doluysa kelimeleri işaretleme ekranına geçer; boş kutu varsa ilk
  /// boş kutunun kelimesini seçer ve uyarı gösterir.
  func finishTapped() {
    guard !isCompleted, layout != nil else { return }
    let empty = emptyCells
    guard empty.isEmpty else {
      if let cell = empty.first, let layout {
        selected = layout.entry(at: cell, preferring: selected?.dir)
        activeCell = cell
        requestKeyboard()
      }
      finishNudge = FinishNudge(
        serial: (finishNudge?.serial ?? 0) + 1, emptyCount: empty.count)
      return
    }
    guard let session = makeSession() else { return }
    pause()
    coordinator.showAnswerKey(session, purpose: .finish)
  }

  /// Bitirme uyarısını kapatır (aynı uyarı hâlâ gösteriliyorsa).
  func dismissFinishNudge(serial: Int) {
    if finishNudge?.serial == serial { finishNudge = nil }
  }

  // MARK: - Derived

  /// Izgarada vurgulanan kutular.
  var highlighted: Set<GridPoint> { Set(selected?.cells ?? []) }

  /// Seçili kelimenin ipucu kutusu.
  var activeClue: GridPoint? { selected?.clueCell }

  /// İpucuyla açılan kutuların harfleri.
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

  /// Henüz yazılmamış ve ipucuyla açılmamış harf kutuları (kelime sırasıyla, tekrarsız).
  var emptyCells: [GridPoint] {
    guard let layout else { return [] }
    var seen = Set<GridPoint>()
    var result: [GridPoint] = []
    for entry in layout.puzzle.entries {
      for cell in entry.cells
      where !filledCells.contains(cell) && !revealed.contains(cell) && seen.insert(cell).inserted {
        result.append(cell)
      }
    }
    return result
  }

  /// Bütün kutular dolu mu ("Bitirdim" etkin mi).
  var canFinish: Bool { layout != nil && emptyCells.isEmpty }

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

  /// Mürekkepli kutuları çizimden yeniden hesaplar, mürekkep yazılan kutudaki klavye harfini
  /// siler ve dolu kutuları (mürekkep + klavye) günceller.
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
    if isFocusPresented, let selected {
      let count = selected.cells.count
      let boxes = (0..<count).map { CanvasMetrics.focusRect(index: $0, count: count) }
      let matched = StrokeMath.split(focusDrawing.strokes, into: boxes).matched
      for (index, strokes) in matched.enumerated() where !strokes.isEmpty {
        cells.insert(selected.cells[index])
      }
    }
    if typed.keys.contains(where: cells.contains) {
      typed = typed.filter { !cells.contains($0.key) }
    }
    cells.formUnion(typed.keys)
    if cells != filledCells { filledCells = cells }
  }

  /// Kutulardaki mürekkebi ve klavye harflerini siler.
  private func clear(_ cells: Set<GridPoint>) {
    removeInk(in: cells)
    if cells.contains(where: { typed[$0] != nil }) {
      typed = typed.filter { !cells.contains($0.key) }
    }
    updateFilledCells()
  }

  /// Kutulardaki mürekkebi ızgaradan ve (açıksa) odak alanından siler.
  private func removeInk(in cells: Set<GridPoint>) {
    if isFocusPresented, let selected {
      let count = selected.cells.count
      let boxes = selected.cells.indices.filter { cells.contains(selected.cells[$0]) }
        .map { CanvasMetrics.focusRect(index: $0, count: count) }
      let rest = StrokeMath.split(focusDrawing.strokes, into: boxes).rest
      if rest.count != focusDrawing.strokes.count {
        focusDrawing = PKDrawing(strokes: rest)
        focusRevision += 1
      }
    }
    let rest = StrokeMath.split(drawing.strokes, into: cells.map(CanvasMetrics.grid.rect(for:)))
      .rest
    guard rest.count != drawing.strokes.count else { return }
    replaceDrawing(PKDrawing(strokes: rest))
    deriveInlineFocus()
  }

  /// Mürekkep maskesini açılmamış harf kutularından yeniden kurar.
  private func refreshInkRects() {
    guard let layout else { return }
    inkRects = layout.letterCells
      .filter { !revealed.contains($0) }
      .sorted { ($0.row, $0.col) < ($1.row, $1.col) }
      .map(CanvasMetrics.grid.rect(for:))
  }

  /// Kayıtlı klavye harflerini (`satır,sütun` → harf) çözer.
  static func decodeTyped(_ stored: [String: String]) -> [GridPoint: Character] {
    var result: [GridPoint: Character] = [:]
    for (key, value) in stored {
      guard let point = GridPoint(key: key), let letter = value.first else { continue }
      result[point] = letter
    }
    return result
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
    guard !isCompleted else { return }
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
    guard layout != nil, !isCompleted else { return }
    saveTask?.cancel()
    userData.saveDraft(
      puzzleId: puzzleId, drawing: persistedDrawing.dataRepresentation(), durationSec: elapsed)
    let letters = Dictionary(uniqueKeysWithValues: typed.map { ($0.key.key, String($0.value)) })
    if letters != savedTyped {
      userData.saveTyped(puzzleId: puzzleId, letters: letters)
      savedTyped = letters
    }
  }

  /// Kaydedilecek çizim: tam ekran odak modu açıksa odaktaki yazılar ızgaraya taşınmış haliyle.
  private var persistedDrawing: PKDrawing {
    guard isFocusPresented, let selected else { return drawing }
    return PKDrawing(
      strokes: Self.mergeFocus(selected, focusDrawing.strokes, into: drawing.strokes))
  }

  private func makeSession() -> PuzzleSession? {
    guard let layout else { return nil }
    if isFocusPresented { closeFocus() }
    return PuzzleSession(
      puzzle: layout.puzzle, title: title, words: words,
      drawingData: drawing.dataRepresentation(), revealed: revealed, typed: typed,
      marks: userData.progress(for: puzzleId).marks, durationSec: elapsed,
      nextPuzzleId: nextPuzzleId)
  }
}

/// "Bitirdim"e erken basılınca gösterilen uyarı.
struct FinishNudge: Equatable {
  /// Her basışta artar; uyarı yeniden canlanır.
  let serial: Int
  /// Boş kutu sayısı.
  let emptyCount: Int

  /// Uyarı metni.
  var message: String {
    emptyCount == 1
      ? "1 kutu boş kaldı. Bitirmek için onu da doldur."
      : "\(emptyCount) kutu boş. Bitirmek için tüm kutuları doldur."
  }
}

/// Geri al / yinele için yazı durumu: ızgara ve odak çizimi ile klavye harfleri.
struct InkSnapshot {
  let drawing: PKDrawing
  let focusDrawing: PKDrawing
  let typed: [GridPoint: Character]
}
