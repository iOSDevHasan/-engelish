import Foundation
import Testing
@testable import DesignKit

struct DesignKitTests {

  @Test("Avatar seçimi kodlanıp geri çözülünce aynı kalır")
  func avatarRoundTrip() throws {
    let config = AvatarConfig(body: .pink, accessory: .crown, background: .night)
    let data = try JSONEncoder().encode(config)
    #expect(try JSONDecoder().decode(AvatarConfig.self, from: data) == config)
  }
}
