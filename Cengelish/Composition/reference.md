# AppComposition

**Layer**: Composition (app root)
**Purpose**: The single package the Xcode target links. Owns DI registration (`DependencyRegistration`), process bootstrap (`AppBootstrap`) and re-exports the backbone kits and module interfaces to the app target.

## Public API

```swift
enum DependencyRegistration { static func registerAll(navigator: AppRouter) }
enum AppBootstrap { static func configure() }
```

## Structure

```
Sources/
├── AppBootstrap.swift
├── DependencyRegistration.swift   — jarvis:register-kits / jarvis:register-modules markers
└── Exports.swift                  — @_exported imports (interfaces only for modules)
```

## Dependencies

- Shared Core backbone: InjectionKit, RouterKit (other shared kits only when added)
- Every Module and Kit of the app
