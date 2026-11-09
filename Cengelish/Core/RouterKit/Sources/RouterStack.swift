import SwiftUI
import NavigationBackport
import RouterKitInterface

public struct RouterStack<Content: View>: View {
  @ObservedObject private var navigator: AppRouter
  private let rootView: Content

  public init(navigator: AppRouter, @ViewBuilder rootView: () -> Content) {
    self.navigator = navigator
    self.rootView = rootView()
  }

  public var body: some View {
    NBNavigationStack(path: $navigator.navigationPath) {
      rootView
        .nbNavigationDestination(for: RouteView.self) { $0.view }
    }
    .environment(\.requestFlowExit, exitRequestClosure)
  }

  private var exitRequestClosure: (@MainActor () -> Void)? {
    guard navigator.flowExitContext != nil else { return nil }
    return { [weak navigator] in
      navigator?.isFlowExitDialogPresented = true
    }
  }
}
