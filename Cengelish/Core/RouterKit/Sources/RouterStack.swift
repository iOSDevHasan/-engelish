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
        // Her rota kendi kimliğiyle çizilir: yığında aynı konuma aynı türde yeni bir ekran gelince
        // (ör. bitiş ekranından "sonraki bulmaca") eski ekranın durumu yeni ekrana taşınmaz.
        .nbNavigationDestination(for: RouteView.self) { $0.view.id($0.id) }
    }
    .environment(\.requestFlowExit, exitRequestClosure)
    .fullScreenCover(item: $navigator.modal) { $0.view }
  }

  private var exitRequestClosure: (@MainActor () -> Void)? {
    guard navigator.flowExitContext != nil else { return nil }
    return { [weak navigator] in
      navigator?.isFlowExitDialogPresented = true
    }
  }
}
