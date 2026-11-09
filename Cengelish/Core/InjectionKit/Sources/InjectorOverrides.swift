import Foundation
@MainActor
public extension Injector {
  internal static var testOverrides: [ObjectIdentifier: Any] = [:]

  static var isRunningTests: Bool {
    ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
  }

  static func override<T>(_ type: T.Type, with instance: T) {
    testOverrides[ObjectIdentifier(type)] = instance
  }

  static func resetOverrides() {
    testOverrides.removeAll()
  }

  internal static func hasTestOverride<T>(_ type: T.Type) -> Bool {
    testOverrides[ObjectIdentifier(type)] != nil
  }
}
