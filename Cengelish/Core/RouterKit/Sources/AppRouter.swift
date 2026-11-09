import SwiftUI
import RouterKitInterface

@MainActor
public final class AppRouter: ObservableObject, Routing {
  @Published public var navigationPath: [RouteView] = []
  @Published public var flowExitContext: (@MainActor () -> Void)?
  @Published public var isFlowExitDialogPresented: Bool = false

  private var deepLinkHandlers: [DeepLinkPath: () -> AnyView] = [:]
  private var deepLinkURLHandlers: [DeepLinkPath: @MainActor (URL) -> Void] = [:]

  public init() {}
}

public extension AppRouter {

  var stackCount: Int {
    navigationPath.count
  }

  func push<V: View>(_ view: V) {
    navigationPath.append(RouteView(AnyView(view)))
  }

  func pop() {
    guard !navigationPath.isEmpty else { return }
    _ = navigationPath.popLast()
  }

  func pop(count: Int) {
    for _ in 0..<count {
      guard !navigationPath.isEmpty else { break }
      _ = navigationPath.popLast()
    }
  }

  func clearStack() {
    navigationPath.removeAll()
  }

  func popToRoot() {
    navigationPath.removeAll()
  }

  func popToNavigationRoot() {
    guard navigationPath.count > 1 else { return }
    navigationPath = Array(navigationPath.prefix(1))
  }

  func setRoot<V: View>(_ view: V) {
    navigationPath = [RouteView(AnyView(view))]
  }
}

// MARK: - DeepLink
public extension AppRouter {

  func registerDeepLink<V: View>(_ path: DeepLinkPath, @ViewBuilder handler: @escaping () -> V) {
    deepLinkHandlers[path] = { AnyView(handler()) }
  }

  func registerDeepLink(_ path: DeepLinkPath, urlHandler: @escaping @MainActor (URL) -> Void) {
    deepLinkURLHandlers[path] = urlHandler
  }

  func handleDeepLink(_ url: URL) -> Bool {
    let host = url.host?.lowercased() ?? ""
    let path = url.path
      .lowercased()
      .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

    return handleCandidate(host, url: url) || handleCandidate(path, url: url)
  }

  private func handleCandidate(_ candidate: String, url: URL) -> Bool {
    guard !candidate.isEmpty else { return false }
    let deepLinkPath = DeepLinkPath(rawValue: candidate)

    if let urlHandler = deepLinkURLHandlers[deepLinkPath] {
      urlHandler(url)
      return true
    }

    if let handler = deepLinkHandlers[deepLinkPath] {
      setRoot(handler())
      return true
    }

    return false
  }
}
