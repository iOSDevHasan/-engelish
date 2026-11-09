import Testing
@testable import FirebaseContentKit

struct FirebaseContentKitTests {

  @Test("Testlerde GoogleService-Info.plist olmadığı için Firebase yapılandırılmaz")
  @MainActor
  func notConfiguredWithoutPlist() {
    #expect(FirebaseBootstrap.configureIfAvailable() == false)
  }
}
