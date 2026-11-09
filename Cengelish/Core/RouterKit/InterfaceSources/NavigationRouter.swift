import SwiftUI

@MainActor
public protocol Routing: AnyObject {
  var stackCount: Int { get }
  var flowExitContext: (@MainActor () -> Void)? { get set }
  func push<V: View>(_ view: V)
  func pop()
  func pop(count: Int)
  func popToRoot()
  func popToNavigationRoot()
  func clearStack()
  func setRoot<V: View>(_ view: V)
  func registerDeepLink<V: View>(_ path: DeepLinkPath, @ViewBuilder handler: @escaping () -> V)
  func registerDeepLink(_ path: DeepLinkPath, urlHandler: @escaping @MainActor (URL) -> Void)
  func handleDeepLink(_ url: URL) -> Bool
}
