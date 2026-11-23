import CrashReportingKit
import UIKit
// jarvis:bootstrap-imports

/// Process-wide setup that must run before the first view renders
/// (fonts, theme, analytics — only for the shared kits this app actually links).
@MainActor
public enum AppBootstrap {

  public static func configure() {
    // Firebase'den yalnızca Crashlytics kullanılır (çökme raporları).
    CrashReporting.start()
    // Uygulamanın hiçbir yerinde kaydırma çubuğu gösterilmez.
    UIScrollView.appearance().showsVerticalScrollIndicator = false
    UIScrollView.appearance().showsHorizontalScrollIndicator = false
    // jarvis:bootstrap
  }
}
