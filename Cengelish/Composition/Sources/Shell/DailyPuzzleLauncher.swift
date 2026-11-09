import ContentKit
import DesignKit
import InjectionKit
import PuzzleModuleInterface
import SwiftUI

/// `cengelish://daily` bağlantısının açtığı ekran: bugünün bulmacasını bulup gösterir.
public struct DailyPuzzleLauncher: View {
  @Inject private var content: any ContentProviding
  @Inject private var puzzles: PuzzleModuleInterface
  @State private var puzzleId: String?
  @State private var isMissing = false

  /// Ekranı oluşturur.
  public init() {}

  public var body: some View {
    Group {
      if let puzzleId {
        puzzles.createPuzzleView(puzzleId: puzzleId)
      } else if isMissing {
        ContentUnavailableView(
          "Bugünün bulmacası bulunamadı", systemImage: "square.grid.3x3",
          description: Text("İnternete bağlanıp uygulamayı yeniden aç."))
      } else {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .screenBackground()
      }
    }
    .task {
      puzzleId = await content.dailyPuzzle(for: .now)?.id
      isMissing = puzzleId == nil
    }
  }
}
