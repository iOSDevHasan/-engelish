# InjectionKit

**Layer**: Core (shared) — always linked
**Purpose**: Runtime dependency injection: a `@Inject` property wrapper resolved from a central `Injector` registry.

## Public API

```swift
@MainActor @propertyWrapper
final class Inject<Value>            // resolves lazily on first access, then caches

enum Lifetime { case singleton(eager: Bool = false), factory }

@MainActor enum Injector
  static func register<T>(value: @autoclosure @escaping () -> T, for: T.Type, scope: Lifetime = .factory)
  static func resolve<T>() -> T          // traps on unregistered type or cycle
  static func isRegistered<T>(_: T.Type) -> Bool
  static func reset()
  static func override<T>(_: T.Type, with: T)   // tests
  static func resetOverrides()
```

- Register **interfaces**, not concrete types: `register(value: HomeCoordinator(), for: HomeModuleInterface.self)`.
- In test targets, resolving without an override asserts — override every dependency the SUT touches.

## Structure

```
Sources/
├── Dependency.swift
├── Injector.swift
└── InjectorOverrides.swift
```

## Dependencies

None.
