import AppComposition
import SwiftUI

/// Composition root view: registers dependencies, then hosts the navigation stack.
struct AppRootView: View {
  @ObservedObject var navigator: AppRouter
  @State private var isDependenciesReady = false
  @State private var pendingDeepLink: URL?

  var body: some View {
    Group {
      if isDependenciesReady {
        RouterStack(navigator: navigator) {
          HomeRootView()
        }
        .onOpenURL { url in
          _ = navigator.handleDeepLink(url)
        }
      } else {
        Color(uiColor: .systemBackground)
          .ignoresSafeArea()
      }
    }
    .onOpenURL { url in
      if !isDependenciesReady {
        pendingDeepLink = url
      }
    }
    .task {
      DependencyRegistration.registerAll(navigator: navigator)
      DeepLinkRegistration.registerAll(on: navigator)
      isDependenciesReady = true
      if let url = pendingDeepLink {
        pendingDeepLink = nil
        _ = navigator.handleDeepLink(url)
      }
    }
  }
}
