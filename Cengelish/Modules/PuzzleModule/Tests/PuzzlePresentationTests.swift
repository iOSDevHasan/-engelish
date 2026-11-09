import ContentKit
import CoreGraphics
import DesignKit
import Foundation
import PencilKit
import PuzzleKit
import Testing
import UIKit

@testable import PuzzleModule

@Suite("Puzzle presentation logic")
@MainActor
struct PuzzlePresentationTests {

  private let layout = CrosswordLayout(puzzle: SamplePuzzles.demo)

  private func entry(_ wordId: String) throws -> PuzzleEntry {
    try #require(SamplePuzzles.demo.entries.first { $0.wordId == wordId })
  }

  // MARK: - Focus

  @Test("Odak butonları komşu kelimelerin ipuçlarını gösterir (‹ Ev / Kuzey ›)")
  func neighbourLabels() throws {
    let labels = EntryNavigation.neighbourLabels(in: layout, around: try entry("w_racer"))
    #expect(labels.previous == "Ev")
    #expect(labels.next == "Kuzey")
  }

  @Test("İlk kelimenin önceki komşusu listenin sonuna sarar")
  func neighbourWraps() throws {
    let labels = EntryNavigation.neighbourLabels(in: layout, around: try entry("w_house"))
    #expect(labels.previous == "Dünya gezegeni")
    #expect(labels.next == "Yarışçı")
  }

  @Test("Kesişen kelimeler ters yönün okuyla listelenir")
  func crossing() throws {
    let text = EntryNavigation.crossingText(try entry("w_racer"), in: layout)
    #expect(text == "Kesişen: Balıkçıl (kuş) ↓ · Mide yarası ↓ · Dünya gezegeni ↓")
  }

  @Test("Odak kutularına taşınan çizgiler ızgaraya geri aynı kutuya döner")
  func focusRoundTrip() throws {
    let racer = try entry("w_racer")
    let cell = racer.cells[2]
    let rect = CanvasMetrics.grid.rect(for: cell)
    let stroke = Self.stroke(at: CGPoint(x: rect.midX, y: rect.midY))
    let extracted = PuzzleViewModel.extractFocus(racer, from: [stroke])
    #expect(extracted.rest.isEmpty)
    #expect(extracted.focus.count == 1)
    let focusBounds = try #require(extracted.focus.first).renderBounds
    #expect(
      CanvasMetrics.focusRect(index: 2, count: racer.cells.count)
        .contains(CGPoint(x: focusBounds.midX, y: focusBounds.midY)))
    let merged = PuzzleViewModel.mergeFocus(racer, extracted.focus, into: [])
    let back = try #require(merged.first).renderBounds
    #expect(rect.contains(CGPoint(x: back.midX, y: back.midY)))
  }

  // MARK: - Done state

  @Test("Tüm kutuları yazılan ya da açılan kelime tamam sayılır")
  func doneByCells() throws {
    let house = try entry("w_house")
    let last = try #require(house.cells.last)
    #expect(EntryNavigation.isDone(house, filled: Set(house.cells), revealed: [], marks: [:]))
    #expect(
      EntryNavigation.isDone(
        house, filled: Set(house.cells.dropLast()), revealed: [last], marks: [:]))
    #expect(
      !EntryNavigation.isDone(house, filled: Set(house.cells.dropLast()), revealed: [], marks: [:]))
  }

  @Test("Doğru işaretlenen kelime boş olsa da tamam sayılır")
  func doneByMark() throws {
    let house = try entry("w_house")
    #expect(EntryNavigation.isDone(house, filled: [], revealed: [], marks: [house.id: true]))
    #expect(!EntryNavigation.isDone(house, filled: [], revealed: [], marks: [house.id: false]))
  }

  @Test("Kelime deseni sadece açılan harfleri gösterir")
  func pattern() throws {
    let house = try entry("w_house")
    #expect(EntryNavigation.pattern(house, revealed: [house.cells[0]]) == "H _ _ _ _")
  }

  // MARK: - Answer key

  @Test("İşaret özeti doğru ve yanlışları sayar")
  func markSummary() {
    #expect(MarkSummary.text([:]) == "0 doğru · 0 yanlış")
    #expect(MarkSummary.text(["a": true, "b": true, "c": false]) == "2 doğru · 1 yanlış")
  }

  // MARK: - Zoom

  @Test("Yakınlaştırma yüzdesi tam sayıya yuvarlanır")
  func zoomPercent() {
    #expect(ZoomText.percent(1) == "%100")
    #expect(ZoomText.percent(1.849) == "%185")
  }

  @Test("Yakınlaştırma ipucu bir kez gösterilir")
  func zoomTipOnce() throws {
    let suite = "zoom-tip-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let zoomed = CanvasViewport(
      zoom: 1.85, visible: CGRect(x: 0.2, y: 0.3, width: 0.5, height: 0.5))

    let first = ZoomState(defaults: defaults)
    first.update(.fit)
    #expect(!first.isZoomed && !first.showsTip)
    first.update(zoomed)
    #expect(first.isZoomed)
    #expect(first.showsTip)
    #expect(first.percentText == "%185")
    #expect(first.visible == zoomed.visible)
    first.update(.fit)
    #expect(!first.isZoomed && !first.showsTip)

    let second = ZoomState(defaults: defaults)
    second.update(zoomed)
    #expect(second.isZoomed)
    #expect(!second.showsTip)
  }

  // MARK: - Layout mode

  @Test("Kareye yakın ve geniş kapsayıcı katlanabilir yerleşimi seçer")
  func layoutMode() {
    #expect(
      PuzzleLayoutMode.resolve(size: CGSize(width: 393, height: 852), isRegularWidth: false)
        == .phone)
    #expect(
      PuzzleLayoutMode.resolve(size: CGSize(width: 1194, height: 834), isRegularWidth: true)
        == .tablet)
    #expect(
      PuzzleLayoutMode.resolve(size: CGSize(width: 834, height: 1194), isRegularWidth: true)
        == .tablet)
    #expect(
      PuzzleLayoutMode.resolve(size: CGSize(width: 760, height: 700), isRegularWidth: true) == .fold
    )
    #expect(
      PuzzleLayoutMode.resolve(size: CGSize(width: 700, height: 690), isRegularWidth: false)
        == .fold)
    #expect(
      PuzzleLayoutMode.resolve(size: CGSize(width: 590, height: 600), isRegularWidth: false)
        == .phone)
  }

  // MARK: - Share

  @Test("Paylaşım metni ve bağlantısı tasarımdaki gibi")
  func shareText() {
    #expect(
      ShareText.message
        == "Ben bugünün Çengelish bulmacasını çözdüm! Sen de çöz: https://cengelish.app")
    #expect(ShareText.footer == "Cevaplar gizli · Sen de çöz → Çengelish")
    #expect(ShareText.owner(name: "Deniz", level: "B1") == "Deniz · B1")
  }

  @Test("Sonuç kareleri kelime sırasını izler; işaretsiz kelime doğru sayılır")
  func shareResults() throws {
    let entries = SamplePuzzles.demo.entries
    let marks = [entries[1].id: false, entries[2].id: true]
    #expect(
      ShareText.results(entries: entries, marks: marks) == [true, false, true, true, true, true])
  }

  @Test("Bağlantı panoya kopyalanır ve onay gösterilir")
  func copyLink() throws {
    let viewModel = ShareViewModel(card: card(), coordinator: nil, photoSaver: FakeSaver(.saved))
    let pasteboard = try #require(
      UIPasteboard(name: .init("test-\(UUID().uuidString)"), create: true))
    viewModel.copyLink(to: pasteboard)
    #expect(pasteboard.string == "https://cengelish.app")
    #expect(viewModel.notice == "Bağlantı kopyalandı")
  }

  @Test("Fotoğraflara kaydetme hatası kullanıcıya bildirilir")
  func saveFailure() async {
    let viewModel = ShareViewModel(card: card(), coordinator: nil, photoSaver: FakeSaver(.failed))
    viewModel.prepare()
    #expect(viewModel.storyImage != nil)
    await viewModel.saveToPhotos()
    #expect(viewModel.notice == "Kaydedilemedi, tekrar dene")
    #expect(!viewModel.isSaving)
  }

  // MARK: - Helpers

  private func card() -> ShareCard {
    ShareCard(
      layout: layout, title: "Günün Bulmacası", owner: "Deniz · B1", avatar: AvatarConfig(),
      date: .now, results: [true, false, true], duration: "6:12", correct: 2, total: 3,
      streak: 13)
  }

  private static func stroke(at point: CGPoint) -> PKStroke {
    let points = (0..<4).map { index in
      PKStrokePoint(
        location: CGPoint(x: point.x - 6 + CGFloat(index) * 4, y: point.y), timeOffset: 0,
        size: CGSize(width: 4, height: 4), opacity: 1, force: 1, azimuth: 0, altitude: 0)
    }
    return PKStroke(
      ink: PKInk(.pen, color: .black), path: PKStrokePath(controlPoints: points, creationDate: .now)
    )
  }
}

/// Sabit sonuç dönen sahte fotoğraf kaydedici.
private struct FakeSaver: PhotoSaving {
  let outcome: PhotoSaveOutcome

  init(_ outcome: PhotoSaveOutcome) { self.outcome = outcome }

  func save(_ data: Data) async -> PhotoSaveOutcome { outcome }
}
