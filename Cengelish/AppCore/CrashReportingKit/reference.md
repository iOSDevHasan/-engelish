# CrashReportingKit

**Layer**: AppCore
**Purpose**: Firebase Crashlytics ile çökme raporlama. Uygulamada Firebase'den yalnızca bu kullanılır (içerik, analitik, App Check yok). `GoogleService-Info.plist` yoksa devre dışı; hata ayıklama derlemelerinde rapor toplama kapalı.

## Public API

```swift
enum CrashReporting {
  @MainActor static func start(bundle: Bundle = .main) -> Bool   // AppBootstrap.configure() çağırır
  @MainActor static var isRunning: Bool
  @MainActor static func log(_ message: String)        // çökme raporuna iz (kişisel veri yazma)
  @MainActor static func record(_ error: any Error)    // çökmeyen hata
}
```

## Structure

Sources/CrashReporting.swift · Tests/CrashReportingTests.swift

dSYM yükleme: uygulama hedefinde yalnızca Release'te çalışan "Crashlytics dSYM" Run Script aşaması
(`firebase-ios-sdk/Crashlytics/run`).

## Dependencies

- firebase-ios-sdk (FirebaseCore, FirebaseCrashlytics)
