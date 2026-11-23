import FirebaseCore
import FirebaseCrashlytics
import Foundation

/// Firebase Crashlytics ile çökme raporlama. Uygulamada Firebase'den yalnızca bu kullanılır:
/// içerik, analitik ve App Check yoktur.
///
/// `GoogleService-Info.plist` uygulama paketinde yoksa hiçbir şey yapmaz. Hata ayıklama
/// derlemelerinde rapor toplama kapalıdır; yalnızca TestFlight ve App Store sürümleri gönderir.
public enum CrashReporting {

  /// `start` başarıyla çalıştı mı. `FirebaseApp.app()` yapılandırmadan önce sorulursa Firebase
  /// hata logu bastığı için durum burada tutulur.
  @MainActor private static var hasStarted = false

  /// Firebase'i yapılandırır ve Crashlytics'i başlatır; dosya yoksa false döner.
  @MainActor
  @discardableResult
  public static func start(bundle: Bundle = .main) -> Bool {
    guard !hasStarted else { return true }
    guard
      let path = bundle.path(forResource: "GoogleService-Info", ofType: "plist"),
      let options = FirebaseOptions(contentsOfFile: path)
    else { return false }
    FirebaseApp.configure(options: options)
    hasStarted = true
    #if DEBUG
    Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
    #else
    Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
    #endif
    return true
  }

  /// Crashlytics başlatıldı mı.
  @MainActor public static var isRunning: Bool { hasStarted }

  /// Çökme raporuna eklenecek kısa bir iz kaydı bırakır (kişisel veri yazılmamalıdır).
  @MainActor public static func log(_ message: String) {
    guard isRunning else { return }
    Crashlytics.crashlytics().log(message)
  }

  /// Çökmeyen ama raporlanması gereken bir hatayı kaydeder.
  @MainActor public static func record(_ error: any Error) {
    guard isRunning else { return }
    Crashlytics.crashlytics().record(error: error)
  }
}
