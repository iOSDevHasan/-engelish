import AppComposition
import SwiftUI

@main
struct CengelishApp: App {
  @StateObject private var navigator = AppRouter()

  init() {
    AppBootstrap.configure()
  }

  var body: some Scene {
    WindowGroup {
      AppRootView(navigator: navigator)
    }
  }
}
