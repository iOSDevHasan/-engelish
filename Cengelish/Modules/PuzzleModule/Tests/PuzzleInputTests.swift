import Combine
import ContentKit
import CoreGraphics
import Foundation
import PencilKit
import PurchaseKit
import PuzzleKit
import Testing
import UserDataKit

@testable import PuzzleModule

@Suite("Bulmaca girişi: ipucu, klavye, mürekkep kırpma")
@MainActor
struct PuzzleInputTests {

  private let demo = SamplePuzzles.demo

  // MARK: - Hints (#13)

  @Test("Bir harf açtıktan sonra iki harf daha açmak iki yeni harf gösterir")
  func revealThreeLetters() async throws {
    let (viewModel, store) = await makeViewModel()
    let house = try entry("w_house")
    viewModel.select(house)
    viewModel.useHint(.letter)
    #expect(viewModel.revealed == [house.cells[0]])
    viewModel.useHint(.letter)
    viewModel.useHint(.letter)
    #expect(viewModel.revealed == Set(house.cells.prefix(3)))
    #expect(viewModel.revealedLetters.count == 3)
    #expect(viewModel.hintsLeft == 0)
    #expect(store.progress(for: demo.id).revealedCells.count == 3)
    #expect(store.progress(for: demo.id).hintsUsed == 3)
  }

  @Test("Seçili kutu zaten açıksa harf ipucu kelimedeki sonraki kapalı kutuyu açar")
  func revealSkipsRevealedActiveCell() throws {
    let house = try entry("w_house")
    let first = house.cells[0]
    #expect(
      HintPicker.letterTarget(in: house, active: first, revealed: [first], filled: [])
        == house.cells[1])
    #expect(
      HintPicker.letterTarget(
        in: house, active: nil, revealed: [first], filled: [house.cells[1]])
        == house.cells[2])
    #expect(
      HintPicker.letterTarget(in: house, active: nil, revealed: Set(house.cells), filled: [])
        == nil)
  }

  @Test("Tamamen açık kelimede ipucu hak harcamaz")
  func noHintOnRevealedWord() async throws {
    let (viewModel, store) = await makeViewModel(premium: true)
    viewModel.select(try entry("w_house"))
    viewModel.useHint(.word)
    #expect(viewModel.revealed.count == 5)
    #expect(!viewModel.canReveal)
    viewModel.useHint(.letter)
    #expect(store.progress(for: demo.id).hintsUsed == HintKind.word.cost)
  }

  @Test("Hak yetmeyen ipucu türü pasif sayılır")
  func affordability() async throws {
    let (viewModel, _) = await makeViewModel()
    viewModel.select(try entry("w_house"))
    #expect(viewModel.canAfford(.word))
    viewModel.useHint(.letter)
    #expect(viewModel.canAfford(.letter))
    #expect(!viewModel.canAfford(.word))
  }

  // MARK: - Keyboard (#12)

  @Test("Klavyeyle yazılan harf kutuya yazılır, sonraki kutuya geçer ve kaydedilir")
  func typeAdvancesAndPersists() async throws {
    let (viewModel, store) = await makeViewModel()
    let house = try entry("w_house")
    viewModel.tool = .keyboard
    viewModel.select(house)
    viewModel.typeText("h")
    viewModel.typeText("o")
    #expect(viewModel.typed[house.cells[0]] == "H")
    #expect(viewModel.typed[house.cells[1]] == "O")
    #expect(viewModel.activeCell == house.cells[2])
    #expect(viewModel.filledCells.isSuperset(of: house.cells.prefix(2)))
    viewModel.pause()
    #expect(store.progress(for: demo.id).typedLetters == ["1,1": "H", "1,2": "O"])
  }

  @Test("Silme tuşu boş kutuda geri gidip önceki harfi siler")
  func backspace() async throws {
    let (viewModel, _) = await makeViewModel()
    let house = try entry("w_house")
    viewModel.select(house)
    viewModel.typeText("H")
    viewModel.typeText("O")
    viewModel.deleteBackward()
    #expect(viewModel.typed[house.cells[1]] == nil)
    #expect(viewModel.activeCell == house.cells[1])
    viewModel.deleteBackward()
    #expect(viewModel.typed.isEmpty)
    #expect(viewModel.activeCell == house.cells[0])
  }

  @Test("Klavye açılan kutuları atlar; ipucu kutudaki klavye harfini siler")
  func typingSkipsRevealed() async throws {
    let (viewModel, _) = await makeViewModel()
    let house = try entry("w_house")
    viewModel.select(house)
    viewModel.typeText("X")
    viewModel.tap(at: center(of: house.cells[0]))
    viewModel.useHint(.letter)
    #expect(viewModel.typed[house.cells[0]] == nil)
    #expect(viewModel.activeCell == house.cells[1])
    viewModel.tap(at: center(of: house.cells[0]))
    viewModel.typeText("O")
    #expect(viewModel.typed[house.cells[1]] == "O")
  }

  @Test("Klavye harfi kutudaki mürekkebi siler; yeni mürekkep klavye harfini siler")
  func lastInputWins() async throws {
    let (viewModel, _) = await makeViewModel()
    let house = try entry("w_house")
    let cell = house.cells[0]
    viewModel.select(house)
    viewModel.drawingChanged(PKDrawing(strokes: [Self.stroke(at: center(of: cell))]))
    #expect(viewModel.drawing.strokes.count == 1)
    viewModel.typeText("H")
    #expect(viewModel.drawing.strokes.isEmpty)
    #expect(viewModel.typed[cell] == "H")
    viewModel.drawingChanged(PKDrawing(strokes: [Self.stroke(at: center(of: cell))]))
    #expect(viewModel.typed[cell] == nil)
    #expect(viewModel.filledCells.contains(cell))
  }

  @Test("Geri al / yinele çizgiyi ve klavye harfini sırayla geri getirir")
  func undoRedo() async throws {
    let (viewModel, _) = await makeViewModel()
    let house = try entry("w_house")
    viewModel.select(house)
    #expect(!viewModel.canUndo)
    viewModel.drawingChanged(PKDrawing(strokes: [Self.stroke(at: center(of: house.cells[0]))]))
    viewModel.tap(at: center(of: house.cells[1]))
    viewModel.typeText("O")
    #expect(viewModel.canUndo)
    viewModel.undo()
    #expect(viewModel.typed[house.cells[1]] == nil)
    #expect(viewModel.drawing.strokes.count == 1)
    #expect(viewModel.canRedo)
    viewModel.undo()
    #expect(viewModel.drawing.strokes.isEmpty)
    #expect(!viewModel.canUndo)
    viewModel.redo()
    viewModel.redo()
    #expect(viewModel.drawing.strokes.count == 1)
    #expect(viewModel.typed[house.cells[1]] == "O")
    #expect(!viewModel.canRedo)
  }

  @Test("Silgi klavyeyle yazılan harfi siler; silme geri alınabilir")
  func eraserRemovesTypedLetter() async throws {
    let (viewModel, _) = await makeViewModel()
    let house = try entry("w_house")
    viewModel.select(house)
    viewModel.typeText("H")
    viewModel.tool = .eraser
    viewModel.erase(at: center(of: house.cells[0]))
    #expect(viewModel.typed[house.cells[0]] == nil)
    #expect(!viewModel.filledCells.contains(house.cells[0]))
    viewModel.undo()
    #expect(viewModel.typed[house.cells[0]] == "H")
  }

  @Test("Türkçe klavye harfleri İngilizce büyük harfe çevrilir, harf olmayanlar atılır")
  func normalizeLetters() {
    #expect(TypedInput.letter(from: "a") == "A")
    #expect(TypedInput.letter(from: "ı") == "I")
    #expect(TypedInput.letter(from: "i") == "I")
    #expect(TypedInput.letter(from: "ş") == nil)
    #expect(TypedInput.letter(from: "7") == nil)
    #expect(TypedInput.letter(from: "") == nil)
  }

  // MARK: - Ink clipping (#11)

  @Test("Mürekkep sadece açılmamış harf kutularında kalır")
  func inkRectsAreLetterCells() async throws {
    let (viewModel, _) = await makeViewModel()
    let layout = CrosswordLayout(puzzle: demo)
    #expect(viewModel.inkRects.count == layout.letterCells.count)
    viewModel.select(try entry("w_house"))
    viewModel.useHint(.letter)
    #expect(viewModel.inkRects.count == layout.letterCells.count - 1)
  }

  @Test("Kutudan ipucu kutusuna taşan çizgi kırpılır, tamamen dışarıdaki çizgi atılır")
  func clipStrokes() {
    let grid = CanvasMetrics.grid
    let letter = grid.rect(for: GridPoint(row: 1, col: 1))
    let clue = grid.rect(for: GridPoint(row: 1, col: 0))
    let crossing = Self.line(
      from: CGPoint(x: clue.midX, y: clue.midY), to: CGPoint(x: letter.midX, y: letter.midY))
    let pieces = StrokeMath.clip(crossing, to: [letter])
    #expect(pieces.count == 1)
    let bounds = pieces[0].path.map(\.location)
    #expect(bounds.allSatisfy { letter.contains($0) })

    let outside = Self.line(
      from: CGPoint(x: clue.minX + 4, y: clue.midY), to: CGPoint(x: clue.maxX - 4, y: clue.midY))
    #expect(StrokeMath.clip(outside, to: [letter]).isEmpty)

    let inside = Self.stroke(at: CGPoint(x: letter.midX, y: letter.midY))
    let kept = StrokeMath.clip([inside], to: [letter])
    #expect(!kept.changed)
    #expect(kept.strokes.count == 1)
  }

  @Test("İki harf kutusuna yayılan çizgi kutu başına ayrı çizgilere bölünür")
  func clipSplitsAcrossCells() {
    let grid = CanvasMetrics.grid
    let a = grid.rect(for: GridPoint(row: 1, col: 1))
    let b = grid.rect(for: GridPoint(row: 1, col: 2))
    let line = Self.line(from: CGPoint(x: a.midX, y: a.midY), to: CGPoint(x: b.midX, y: b.midY))
    let result = StrokeMath.clip([line], to: [a, b])
    #expect(result.changed)
    #expect(result.strokes.count == 2)
  }

  // MARK: - Helpers

  @Test("Kelimenin son harfi yazılınca sıradaki eksik kelimeye geçilir")
  func typingLastLetterMovesToNextWord() async throws {
    let (viewModel, _) = await makeViewModel()
    viewModel.tool = .keyboard
    let first = try #require(demo.entries.first)
    viewModel.select(first)
    for letter in first.answer { viewModel.typeText(String(letter)) }
    let selected = try #require(viewModel.selected)
    #expect(selected != first)
    #expect(selected.cells.contains { !viewModel.filledCells.contains($0) })
    #expect(viewModel.typed[try #require(first.cells.last)] == first.answer.last)
  }

  // MARK: - Finish gate

  @Test("Boş kutu varken Bitirdim uyarı verir ve ilk boş kutunun kelimesini seçer")
  func finishBlockedWhileEmpty() async throws {
    let (viewModel, _) = await makeViewModel()
    let total = Set(demo.entries.flatMap(\.cells)).count
    #expect(!viewModel.canFinish)
    #expect(viewModel.emptyCells.count == total)
    viewModel.select(demo.entries.last)
    viewModel.finishTapped()
    let nudge = try #require(viewModel.finishNudge)
    #expect(nudge.emptyCount == total)
    #expect(viewModel.activeCell == viewModel.emptyCells.first)
    viewModel.finishTapped()
    #expect(viewModel.finishNudge?.serial == nudge.serial + 1)
  }

  @Test("Bütün kutular klavyeyle ya da ipucuyla dolunca Bitirdim açılır")
  func finishAllowedWhenFilled() async throws {
    let (viewModel, _) = await makeViewModel(premium: true)
    viewModel.tool = .keyboard
    let entries = demo.entries
    viewModel.select(entries[0])
    viewModel.useHint(.word)
    for entry in entries.dropFirst() {
      viewModel.select(entry)
      for (cell, letter) in zip(entry.cells, entry.answer) where viewModel.emptyCells.contains(cell)
      {
        viewModel.tap(at: center(of: cell))
        viewModel.typeText(String(letter))
      }
    }
    #expect(viewModel.emptyCells.isEmpty)
    #expect(viewModel.canFinish)
    #expect(!viewModel.wantsKeyboard)
    viewModel.select(entries[1])
    #expect(viewModel.wantsKeyboard)
  }

  @Test("Her kelime işaretlenmeden sonuçlara geçilmez; göz atma ekranı bitiremez")
  func answerKeyRequiresAllMarks() throws {
    let store = UserDataStore(inMemory: true)
    let session = PuzzleSession(
      puzzle: demo, title: "Demo", words: [:], drawingData: Data(), revealed: [], marks: [:],
      durationSec: 30, nextPuzzleId: nil)
    let finishKey = AnswerKeyViewModel(
      session: session, purpose: .finish, coordinator: PuzzleCoordinator(), userData: store,
      entitlements: EntitlementStub())
    #expect(finishKey.unmarkedCount == demo.entries.count)
    finishKey.finish()
    #expect(finishKey.incompleteAttempt == 1)
    #expect(store.progress(for: demo.id).finishedAt == nil)
    for entry in demo.entries.dropLast() { finishKey.mark(entry, correct: true) }
    #expect(!finishKey.canFinish)
    #expect(finishKey.firstUnmarkedId == demo.entries.last?.id)
    finishKey.mark(try #require(demo.entries.last), correct: false)
    #expect(finishKey.canFinish)

    let peek = AnswerKeyViewModel(
      session: session, purpose: .peek, coordinator: PuzzleCoordinator(), userData: store,
      entitlements: EntitlementStub())
    #expect(!peek.canFinish)
  }

  @Test("Bitmiş bulmaca salt okunurdur: cevaplar görünür, yazma ve bitirme çalışmaz")
  func completedPuzzleIsReadOnly() async throws {
    let store = UserDataStore(inMemory: true)
    store.saveDraft(puzzleId: demo.id, drawing: nil, durationSec: 42)
    let first = try #require(demo.entries.first)
    _ = store.finish(
      puzzleId: demo.id, marks: [first.id: true], wordIdsByEntry: [first.id: first.wordId],
      isPremium: false, now: .now)
    let viewModel = PuzzleViewModel(
      puzzleId: demo.id, coordinator: PuzzleCoordinator(), content: DemoContent(puzzle: demo),
      userData: store, entitlements: EntitlementStub())
    await viewModel.load()

    #expect(viewModel.isCompleted)
    #expect(viewModel.correctCount == 1)
    #expect(viewModel.timerText == "00:42")
    let letters = viewModel.revealedLetters
    for entry in demo.entries {
      #expect(String(entry.cells.compactMap { letters[$0]?.0 }) == entry.answer)
    }
    viewModel.tool = .keyboard
    #expect(!viewModel.wantsKeyboard)
    viewModel.typeText("Q")
    #expect(viewModel.typed.isEmpty)
    viewModel.finishTapped()
    #expect(viewModel.finishNudge == nil)
  }

  private func entry(_ wordId: String) throws -> PuzzleEntry {
    try #require(demo.entries.first { $0.wordId == wordId })
  }

  private func center(of cell: GridPoint) -> CGPoint {
    let rect = CanvasMetrics.grid.rect(for: cell)
    return CGPoint(x: rect.midX, y: rect.midY)
  }

  private func makeViewModel(
    premium: Bool = false
  ) async -> (PuzzleViewModel, UserDataStore) {
    let store = UserDataStore(inMemory: true)
    let entitlements = EntitlementStub()
    entitlements.isPremium = premium
    let viewModel = PuzzleViewModel(
      puzzleId: demo.id, coordinator: PuzzleCoordinator(), content: DemoContent(puzzle: demo),
      userData: store, entitlements: entitlements)
    await viewModel.load()
    return (viewModel, store)
  }

  private static func stroke(at point: CGPoint) -> PKStroke {
    line(
      from: CGPoint(x: point.x - 12, y: point.y - 4), to: CGPoint(x: point.x + 12, y: point.y + 4))
  }

  private static func line(from start: CGPoint, to end: CGPoint) -> PKStroke {
    let points = (0...20).map { index in
      let t = CGFloat(index) / 20
      return PKStrokePoint(
        location: CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t),
        timeOffset: Double(index) * 0.01, size: CGSize(width: 4, height: 4), opacity: 1, force: 1,
        azimuth: 0, altitude: .pi / 2)
    }
    return PKStroke(
      ink: PKInk(.pen, color: .black), path: PKStrokePath(controlPoints: points, creationDate: .now)
    )
  }
}

/// Tek bulmaca dönen içerik sahtesi.
private struct DemoContent: ContentProviding {
  let puzzle: Puzzle

  func packs() async -> [Pack] { [] }
  func pack(id: String) async -> Pack? { nil }
  func puzzle(id: String) async -> Puzzle? { id == puzzle.id ? puzzle : nil }
  func puzzles(inPack packId: String) async -> [Puzzle] { [] }
  func words(ids: [String]) async -> [Word] { [] }
  func dailyPuzzle(for date: Date) async -> Puzzle? { nil }
}

/// Ayarlanabilir yetki servisi.
@MainActor
private final class EntitlementStub: EntitlementProviding {
  var changes: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
  var isPremium = false
  var ownedProductIds: Set<String> = []
  var products: [StoreProduct] = []
  func loadProducts() async {}
  func purchase(_ productId: String) async -> PurchaseOutcome { .cancelled }
  func restore() async {}
}
