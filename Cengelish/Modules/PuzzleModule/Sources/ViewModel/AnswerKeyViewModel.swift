import ContentKit
import Foundation
import PencilKit
import PurchaseKit
import PuzzleKit
import UIKit
import UserDataKit

/// Cevap anahtarı görünüm modu.
enum KeyMode: String, CaseIterable, Identifiable {
  case mine = "Benim"
  case key = "Anahtar"
  case compare = "Karşılaştır"

  var id: String { rawValue }
}

/// Cevap anahtarı: kullanıcı kendi yazdığını anahtarla karşılaştırıp her kelimeyi işaretler.
@MainActor
final class AnswerKeyViewModel: ObservableObject {

  // MARK: - Properties

  @Published var mode: KeyMode = .compare
  @Published private(set) var marks: [String: Bool]
  /// Bulmaca durumu.
  let session: PuzzleSession
  /// Kullanıcının çizimi (ölçek 1).
  let drawing: PKDrawing
  private let coordinator: PuzzleCoordinator
  private let userData: any UserDataStoring
  private let entitlements: any EntitlementProviding

  // MARK: - Init

  init(
    session: PuzzleSession, coordinator: PuzzleCoordinator, userData: any UserDataStoring,
    entitlements: any EntitlementProviding
  ) {
    self.session = session
    self.coordinator = coordinator
    self.userData = userData
    self.entitlements = entitlements
    self.marks = session.marks
    self.drawing = (try? PKDrawing(data: session.drawingData)) ?? PKDrawing()
  }

  // MARK: - Intents

  /// Kelimeyi doğru ya da yanlış işaretler; aynı işarete tekrar dokunmak kaldırır.
  func mark(_ entry: PuzzleEntry, correct: Bool) {
    marks[entry.id] = marks[entry.id] == correct ? nil : correct
  }

  /// İşaretlenmemiş kelimeleri doğru sayar.
  func markRestCorrect() {
    for entry in session.puzzle.entries where marks[entry.id] == nil {
      marks[entry.id] = true
    }
  }

  /// Sonuçları kaydedip bitiş ekranına geçer.
  func finish() {
    markRestCorrect()
    let wordIds = Dictionary(
      uniqueKeysWithValues: session.puzzle.entries.map { ($0.id, $0.wordId) })
    let result = userData.finish(
      puzzleId: session.puzzle.id, marks: marks, wordIdsByEntry: wordIds,
      isPremium: entitlements.isPremium, now: .now)
    coordinator.showFinish(session: session, result: result, marks: marks)
  }

  /// Geri gider.
  func back() {
    coordinator.back()
  }

  // MARK: - Derived

  /// İşaretlenen kelime sayısı.
  var markedCount: Int { marks.count }

  /// "{x} doğru · {y} yanlış" özeti.
  var summaryText: String { MarkSummary.text(marks) }

  /// Izgarada gösterilecek harfler (moda göre).
  var letters: [GridPoint: (Character, GridLetterStyle)] {
    guard mode != .mine else { return revealedOnly }
    let layout = session.layout
    var result: [GridPoint: (Character, GridLetterStyle)] = [:]
    for point in layout.letterCells {
      guard let char = layout.answer(at: point) else { continue }
      result[point] = (char, mode == .key ? .revealed : .key)
    }
    return result
  }

  /// Kullanıcının çizimi gösterilsin mi.
  var showsDrawing: Bool { mode != .key }

  /// Çizimi verilen boyutta resme çevirir.
  func drawingImage(scale: CGFloat) -> UIImage {
    let layout = session.layout
    let size = CanvasMetrics.grid.size(rows: layout.rows, columns: layout.columns)
    // Mürekkep renkleri ekrandaki gibi kalsın diye açık modda çizilir (PencilKit koyu modda
    // renkleri ters çevirir; çizim alanı da açık moda sabit).
    var image = UIImage()
    UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
      image = drawing.image(from: CGRect(origin: .zero, size: size), scale: scale)
    }
    return image
  }

  private var revealedOnly: [GridPoint: (Character, GridLetterStyle)] {
    let layout = session.layout
    var result: [GridPoint: (Character, GridLetterStyle)] = [:]
    for point in session.revealed {
      if let char = layout.answer(at: point) { result[point] = (char, .revealed) }
    }
    return result
  }
}
