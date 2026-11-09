# RouterKit

**Layer**: Core (shared) — always linked
**Purpose**: Stack-based SwiftUI navigation (NavigationBackport, iOS 15+) with deep-link routing and a flow-exit confirmation hook.

## Public API

### Interface product (`RouterKitInterface`) — what modules depend on
```swift
@MainActor protocol Routing: AnyObject
  var stackCount: Int { get }
  var flowExitContext: (@MainActor () -> Void)? { get set }
  func push<V: View>(_ view: V)
  func pop(); func pop(count: Int); func popToRoot(); func popToNavigationRoot(); func clearStack()
  func setRoot<V: View>(_ view: V)
  func registerDeepLink<V: View>(_ path: DeepLinkPath, handler: () -> V)       // sets root
  func registerDeepLink(_ path: DeepLinkPath, urlHandler: (URL) -> Void)       // custom handling
  func handleDeepLink(_ url: URL) -> Bool                                      // matches host, then path

struct DeepLinkPath: RawRepresentable, ExpressibleByStringLiteral   // extend: static let home: Self = "home"

EnvironmentValues.requestFlowExit: (@MainActor () -> Void)?        // non-nil while flowExitContext is set
```

### Implementation product (`RouterKit`) — app/composition only
```swift
@MainActor final class AppRouter: ObservableObject, Routing
  @Published var navigationPath: [RouteView]
  @Published var isFlowExitDialogPresented: Bool
struct RouterStack<Content: View>: View   // init(navigator:rootView:)
```

Flow exit: a multi-step flow sets `nav.flowExitContext = { … }`; back buttons call
`requestFlowExit`, the app root shows the confirmation alert and runs the context on confirm.

## Structure

```
InterfaceSources/
├── NavigationRouter.swift      — Routing protocol
├── DeepLink.swift              — DeepLinkPath
└── FlowExitRequestKey.swift
Sources/
├── RouterKit.swift
├── RouterStack.swift
└── RouteView.swift
```

## Dependencies

- **NavigationBackport** (0.9+)
