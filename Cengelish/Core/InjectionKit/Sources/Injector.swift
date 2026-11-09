import Foundation

public enum Lifetime {
  case singleton(eager: Bool = false)
  case factory
}

@MainActor
public enum Injector {
  private static var singletons: [ObjectIdentifier: Any] = [:]
  private static var factories: [ObjectIdentifier: () -> Any] = [:]
  private static var factoryScopes: Set<ObjectIdentifier> = []
  private static var resolvingStack: Set<ObjectIdentifier> = []

  public static func register<T>(
    value: @autoclosure @escaping () -> T,
    for interface: T.Type,
    scope: Lifetime = .factory
  ) {
    let key = ObjectIdentifier(interface)

    switch scope {
    case .singleton(let eager):
      factoryScopes.remove(key)
      if eager {
        singletons[key] = value()
      } else {
        factories[key] = value
      }

    case .factory:
      factoryScopes.insert(key)
      factories[key] = value
      singletons[key] = nil
    }
  }

  public static func resolve<T>() -> T {
    let key = ObjectIdentifier(T.self)

    if let override = testOverrides[key] as? T {
      return override
    }

    #if DEBUG
    if isRunningTests {
      assertionFailure(
        """
        '\(T.self)' accessed in test without override.
        Add Injector.override(\(T.self).self, with: mockInstance) in your test setup.
        """
      )
    }
    #endif

    if resolvingStack.contains(key) {
      fatalError("Circular dependency detected for '\(T.self)'")
    }

    if let factory = factories[key] {
      resolvingStack.insert(key)
      defer { resolvingStack.remove(key) }

      if let instance = factory() as? T {
        if !factoryScopes.contains(key) {
          singletons[key] = instance
          factories[key] = nil
        }
        return instance
      }
    }

    if let instance = singletons[key] as? T {
      return instance
    }

    fatalError("'\(T.self)' not registered. Call Injector.register() first.")
  }

  public static func isRegistered<T>(_ type: T.Type) -> Bool {
    let key = ObjectIdentifier(type)
    return singletons[key] != nil || factories[key] != nil
  }

  public static func reset() {
    singletons.removeAll()
    factories.removeAll()
    factoryScopes.removeAll()
    resolvingStack.removeAll()
  }

  public static var registeredTypes: [String] {
    let singletonTypes = singletons.keys.map { "\($0) (singleton)" }
    let factoryTypes = factories.keys.map { key in
      factoryScopes.contains(key) ? "\(key) (factory)" : "\(key) (lazy singleton)"
    }
    return singletonTypes + factoryTypes
  }

  public static func assertRegistered<T>(
    _ type: T.Type, file: StaticString = #file, line: UInt = #line
  ) {
    assert(isRegistered(type), "'\(type)' should be registered", file: file, line: line)
  }
}
