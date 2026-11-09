import SwiftUI
import WidgetBridgeKit
import WidgetKit

/// Çengelish widget eklentisi: Ana Ekran ve Kilit Ekranı widget'ları.
@main
struct CengelishWidgetsBundle: WidgetBundle {
  var body: some Widget {
    WordOfDayWidget()
    StreakWidget()
    DailyPuzzleWidget()
    LockStreakWidget()
    LockWordWidget()
  }
}
