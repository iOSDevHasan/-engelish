import Foundation
import Testing

@testable import CrashReportingKit

@Suite("CrashReporting")
@MainActor
struct CrashReportingTests {
  /// Yapılandırma dosyası olmayan pakette Firebase başlatılmaz ve çağrılar sessizce geçer.
  @Test func startsNothingWithoutConfigFile() {
    let started = CrashReporting.start(bundle: Bundle(for: BundleToken.self))
    #expect(started == false)
    #expect(CrashReporting.isRunning == false)
    CrashReporting.log("test")
    CrashReporting.record(CocoaError(.fileNoSuchFile))
  }
}

/// Test paketini bulmak için boş sınıf.
private final class BundleToken {}
